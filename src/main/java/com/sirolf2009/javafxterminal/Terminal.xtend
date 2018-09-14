package com.sirolf2009.javafxterminal

import com.pty4j.PtyProcess
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.io.PrintWriter
import java.util.List
import javafx.scene.input.KeyCode
import java.util.ArrayList
import com.sirolf2009.javafxterminal.ANSI.AnsiCode

class Terminal extends TerminalView {
	
	val PtyProcess process

	new(List<String> command) throws IOException {
		this(PtyProcess.exec(command, #{"TERM" -> "ansi", "COLORTERM" -> "truecolor", "GDM_LANG" -> "en-US.UTF-8", "LANG" -> "en_US.UTF-8"}))
	}

	new(PtyProcess process) {
		super(new InputStreamReader(process.getInputStream()))
		this.process = process
		setEditable(true)

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
		onKeyPressed = [
			if(getCode().isLetterKey()) {
				print(getText())
				writer.print(getText())
				writer.flush()
			} else if(getCode().equals(KeyCode.ENTER)) {
				println(" newline")
				writer.println()
				writer.flush()
			} else if(getCode().equals(KeyCode.SPACE)) {
				writer.print(" ")
				writer.flush()
			}
		]
	}
	
	override set(Pair<String, ArrayList<AnsiCode>> parsed) {
		super.set(parsed)
		process.getOutputStream().flush()
	}

}
