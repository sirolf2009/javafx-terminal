package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView

class Bell implements Command {
	
	override execute(TerminalView it) {
		bell()
	}
	
}