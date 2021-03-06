package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class CursorHorizontalAbsolute extends AbstractCommand {
	
	val int n
	
	override execute(TerminalCanvas it) {
		moveTo(n, getCurrentLine())
	}
	
}