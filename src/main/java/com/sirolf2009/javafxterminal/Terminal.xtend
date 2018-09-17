package com.sirolf2009.javafxterminal

import com.pty4j.PtyProcess
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.io.PrintWriter
import java.util.List
import javafx.scene.input.KeyCode
import javafx.scene.input.KeyEvent

/**
 * The division of labor between the terminal and the shell is not completely obvious. Here are their main tasks.

    Input: the terminal converts keys into control sequences (e.g. Left → \e[D). The shell converts control sequences into commands (e.g. \e[D → backward-char).
    Line edition, input history and completion are provided by the shell.
        The terminal may provide its own line edition, history and completion instead, and only send a line to the shell when it's ready to be executed. The only common terminal that operates in this way is M-x shell in Emacs.
    Output: the shell emits instructions such as “display foo”, “switch the foreground color to green”, “move the cursor to the next line”, etc. The terminal acts on these instructions.
    The prompt is purely a shell concept.
    The shell never sees the output of the commands it runs (unless redirected). Output history (scrollback) is purely a terminal concept.
    Inter-application copy-paste is provided by the terminal (usually with the mouse or key sequences such as Ctrl+Shift+V or Shift+Insert). The shell may have its own internal copy-paste mechanism as well (e.g. Meta+W and Ctrl+Y).
    Job control (launching programs in the background and managing them) is mostly performed by the shell. However, it's the terminal that handles key combinations like Ctrl+C to kill the foreground job and Ctrl+Z to suspend it.
 
 */
class Terminal extends TerminalView {

	val PtyProcess process

	new(List<String> command) throws IOException {
		this(PtyProcess.exec(command, #{"TERM" -> "ansi", "COLORTERM" -> "truecolor", "GDM_LANG" -> "en-US.UTF-8", "LANG" -> "en_US.UTF-8"}))
	}

	new(PtyProcess process) {
		super(new InputStreamReader(process.getInputStream()))
		this.process = process
		setEditable(true)
//		caretSelectionBind.showCaret = CaretVisibility.ON

//		val preventSelectionOrRightArrowNavigation = InputMap.consume(
//			anyOf(
//				mousePressed(),
//				// prevent selection via (CTRL + ) SHIFT + [LEFT, UP, DOWN]
//				keyPressed(LEFT, SHIFT_DOWN, SHORTCUT_ANY),
//				keyPressed(KP_LEFT, SHIFT_DOWN, SHORTCUT_ANY),
//				keyPressed(UP, SHIFT_DOWN, SHORTCUT_ANY),
//				keyPressed(KP_UP, SHIFT_DOWN, SHORTCUT_ANY),
//				keyPressed(DOWN, SHIFT_DOWN, SHORTCUT_ANY),
//				keyPressed(KP_DOWN, SHIFT_DOWN, SHORTCUT_ANY),
//				// prevent selection via mouse events
//				eventType(MouseEvent.MOUSE_DRAGGED),
//				eventType(MouseEvent.DRAG_DETECTED),
//				// prevent any right arrow movement, regardless of modifiers
//				keyPressed(RIGHT, SHORTCUT_ANY, SHIFT_ANY),
//				keyPressed(KP_RIGHT, SHORTCUT_ANY, SHIFT_ANY)
//			)
//		);
//		Nodes.addInputMap(this, preventSelectionOrRightArrowNavigation)
//		Nodes.addInputMap(this, InputMap.sequence(
//			consume(keyPressed(LEFT, SHORTCUT_ANY, SHIFT_ANY)) [
//				println(getStyleSpans(0, getText().length()))
//				println(getStyleSpans(0, getText().length()).size())
//			]
//		))
		val writer = new PrintWriter(new OutputStreamWriter(process.getOutputStream()))
		val left = "\u001B[D"
		addEventFilter(KeyEvent.ANY) [
			if(#[KeyCode.DOWN, KeyCode.UP].contains(getCode())) {
				consume()
			}
		]
		onKeyPressed = [
			if(getCode().equals(KeyCode.LEFT)) {
				println("printing left")
				writer.append(left)
				writer.flush()
				consume()
			} else if(getCode().equals(KeyCode.UP)) {
				println("printing up")
				writer.append("\u001B[A")
				writer.flush()
				consume()
			} else {
				writer.append(getText())
				writer.flush()
			}
//			if(getCode().isLetterKey()) {
//				print(getText())
//				writer.print(getText())
//				writer.flush()
//			} else if(getCode().equals(KeyCode.ENTER)) {
//				println(" newline")
//				writer.println()
//				writer.flush()
//			} else if(getCode().equals(KeyCode.SPACE)) {
//				writer.print(" ")
//				writer.flush()
//			}
		]
	}

}
