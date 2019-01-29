package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import java.util.Date

interface Command {
	
	def void execute(TerminalCanvas it)
	def Date getTimestamp()
	
}