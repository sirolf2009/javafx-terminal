package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class Newline implements Command {

	override execute(TerminalCanvas it) {
		newLine()
	}

}
