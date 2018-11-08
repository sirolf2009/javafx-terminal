package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import java.util.List
import java.util.function.Consumer
import javafx.scene.canvas.GraphicsContext
import org.eclipse.xtend.lib.annotations.Data

@Data class InsertText implements Command {

	val String characters
	val List<Consumer<GraphicsContext>> styles

	override execute(TerminalCanvas it) {
		insertText(characters, styles)
	}

}
