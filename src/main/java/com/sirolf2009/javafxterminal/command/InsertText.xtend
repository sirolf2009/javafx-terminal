package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.CharModifier
import com.sirolf2009.javafxterminal.TerminalCanvas
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

@Data class InsertText implements Command {

	val String characters
	val List<CharModifier> styles

	override execute(TerminalCanvas it) {
		insertText(characters, styles)
		jumpDown()
	}

}
