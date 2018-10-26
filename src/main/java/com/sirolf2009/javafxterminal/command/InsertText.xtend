package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

@Data class InsertText implements Command {
	
	val String characters
	val List<String> styles
	
	override execute(TerminalView it) {
		characters.toCharArray().forEach[character|
			insertChar(character, styles)
		]
	}
	
}