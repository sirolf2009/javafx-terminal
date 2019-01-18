package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class CursorPosition implements Command {
	
	val int x
	val int y
	
	override execute(TerminalCanvas it) {
		moveTo(x, y)
	}
	
}