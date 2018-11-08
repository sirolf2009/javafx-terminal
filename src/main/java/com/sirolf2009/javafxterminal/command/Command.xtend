package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas

interface Command {
	
	def void execute(TerminalCanvas it)
	
}