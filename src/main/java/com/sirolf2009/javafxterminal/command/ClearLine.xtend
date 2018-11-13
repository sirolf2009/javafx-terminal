package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class ClearLine implements Command {

	val int mode

	override execute(TerminalCanvas it) {
		switch (mode) {
			case 0: {
				clear(getCurrentColumn(), getWinWidth(), getCurrentLine())
			}
			case 1: {
				clear(0, getCurrentColumn(), getCurrentLine())
			}
			case 2: {
				clearLine()
			}
			default:
				throw new RuntimeException('''Unknown clear mode «mode»''')
		}
	}

}
