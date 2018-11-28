package com.sirolf2009.javafxterminal

import com.pty4j.PtyProcess
import com.sirolf2009.javafxterminal.theme.ITheme
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.io.PrintWriter
import java.util.List
import javafx.scene.input.KeyCode
import javafx.scene.input.KeyEvent
import javafx.scene.input.MouseEvent
import org.eclipse.xtend.lib.annotations.Accessors
import javafx.scene.input.ScrollEvent

/**
 * The division of labor between the terminal and the shell is not completely obvious. Here are their main tasks.

 *     Input: the terminal converts keys into control sequences (e.g. Left → \e[D). The shell converts control sequences into commands (e.g. \e[D → backward-char).
 *     Line edition, input history and completion are provided by the shell.
 *         The terminal may provide its own line edition, history and completion instead, and only send a line to the shell when it's ready to be executed. The only common terminal that operates in this way is M-x shell in Emacs.
 *     Output: the shell emits instructions such as “display foo”, “switch the foreground color to green”, “move the cursor to the next line”, etc. The terminal acts on these instructions.
 *     The prompt is purely a shell concept.
 *     The shell never sees the output of the commands it runs (unless redirected). Output history (scrollback) is purely a terminal concept.
 *     Inter-application copy-paste is provided by the terminal (usually with the mouse or key sequences such as Ctrl+Shift+V or Shift+Insert). The shell may have its own internal copy-paste mechanism as well (e.g. Meta+W and Ctrl+Y).
 *     Job control (launching programs in the background and managing them) is mostly performed by the shell. However, it's the terminal that handles key combinations like Ctrl+C to kill the foreground job and Ctrl+Z to suspend it.
 *  
 */
@Accessors class Terminal extends TerminalView implements AutoCloseable {

	val PtyProcess process
	val PrintWriter writer

	new(List<String> command, ITheme theme) throws IOException {
		this(PtyProcess.exec(command, #{"TERM" -> "xterm-256color", "COLORTERM" -> "truecolor", "GDM_LANG" -> "en-US.UTF-8", "LANG" -> "en_US.UTF-8"}), theme)
	}

	new(PtyProcess process, ITheme theme) {
		super(new BufferedReader(new InputStreamReader(process.getInputStream())), theme)
		new Thread[
			new BufferedReader(new InputStreamReader(process.getErrorStream())).lines().forEach[System.err.println(it)]
		].start()
		this.process = process
		writer = new PrintWriter(new OutputStreamWriter(process.getOutputStream()))
		addEventFilter(KeyEvent.ANY) [
			if(getEventType() == KeyEvent.KEY_RELEASED) {
				if(getCode().equals(KeyCode.UP)) {
					command("\u001B[A")
				} else if(getCode().equals(KeyCode.RIGHT)) {
					command("\u001B[C")
				} else if(getCode().equals(KeyCode.DOWN)) {
					command("\u001B[B")
				} else if(getCode().equals(KeyCode.LEFT)) {
					command("\u001B[D")
				} else {
					command(getText())
				}
			}
			consume()
		]
		addEventFilter(MouseEvent.ANY) [
			if(getEventType() == MouseEvent.MOUSE_CLICKED) {
				requestFocus()
			}
			consume()
		]
		addEventFilter(ScrollEvent.ANY) [
			if(getEventType() == ScrollEvent.SCROLL) {
				if(getDeltaY() > 0) {
					moveFocusDown()
				} else {
					moveFocusUp()
				}
			}
			consume()
		]
		widthProperty().addListener[process.setWinSize(getWinSize())]
		heightProperty().addListener[process.setWinSize(getWinSize())]
		parentProperty().addListener[process.setWinSize(getWinSize())]
	}

	def synchronized command(String command) {
		writer.append(command)
		writer.flush()
	}

	override close() throws Exception {
		writer.close()
	}

}
