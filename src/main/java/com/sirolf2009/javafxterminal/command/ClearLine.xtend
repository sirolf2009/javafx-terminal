package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView
import org.eclipse.xtend.lib.annotations.Data

@Data class ClearLine implements Command {
	
	override execute(TerminalView it) {
		clearLine()
	}

}
