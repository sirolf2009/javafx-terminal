package com.sirolf2009.javafxterminal.command

import java.util.Date
import org.eclipse.xtend.lib.annotations.Data

@Data abstract class AbstractCommand implements Command {
	
	val Date timestamp
	
	new() {
		timestamp = new Date()
	}
	
}