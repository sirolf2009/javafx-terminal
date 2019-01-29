package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.CharModifier
import com.sirolf2009.javafxterminal.TerminalCanvas
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

@Data class InsertChar extends AbstractCommand {
	
	val char character
	val List<CharModifier> styles
	
	override execute(TerminalCanvas it) {
		insertText(character.toString(), styles)
	}
	
}