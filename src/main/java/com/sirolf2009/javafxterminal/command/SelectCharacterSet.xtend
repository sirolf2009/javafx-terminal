package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class SelectCharacterSet implements Command {
	
	val boolean G0
	val Character type
	
	override execute(TerminalCanvas it) {
//		osCommand(params)
	}
	
}