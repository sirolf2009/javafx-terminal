package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class SelectCharacterSet extends AbstractCommand {
	
	val boolean G0
	val Character type
	
	override execute(TerminalCanvas it) {
//		osCommand(params)
	}
	
}