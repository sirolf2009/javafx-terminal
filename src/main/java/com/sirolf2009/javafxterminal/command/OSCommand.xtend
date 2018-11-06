package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView
import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor class OSCommand implements Command {
	
	val List<String> params
	
	override execute(TerminalView it) {
		osCommand(params)
	}
	
}