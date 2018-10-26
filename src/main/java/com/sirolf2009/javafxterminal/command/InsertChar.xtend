package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

@Data class InsertChar implements Command {
	
	val char character
	val List<String> styles
	
	override execute(TerminalView it) {
		insertChar(character, styles)
	}
	
}