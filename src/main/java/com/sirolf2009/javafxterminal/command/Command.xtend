package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView

interface Command {
	
	def void execute(TerminalView it)
	
}