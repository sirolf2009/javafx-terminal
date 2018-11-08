package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import java.util.function.Consumer
import javafx.scene.canvas.GraphicsContext

@Data class InsertChar implements Command {
	
	val char character
	val List<Consumer<GraphicsContext>> styles
	
	override execute(TerminalCanvas it) {
		insertText(character.toString(), styles)
	}
	
}