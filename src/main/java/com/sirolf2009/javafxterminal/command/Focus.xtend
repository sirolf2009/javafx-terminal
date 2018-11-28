package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class Focus implements Command {
	
	val int row
	
	override execute(TerminalCanvas it) {
		focus(row)
	}
	
}