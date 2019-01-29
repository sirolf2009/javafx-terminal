package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class DeleteText extends AbstractCommand {

	val int type

	override execute(TerminalCanvas it) {
		switch (type) {
			case 0:
				clear(getCurrentColumn(), getLine(getCurrentLine()).length(), getCurrentLine())
			case 1:
				clear(0, getCurrentColumn(), getCurrentLine())
			case 2: {
				focus(getLines() + 1)
				moveTo(0, getLines() + 1)
			}
			case 3: {
				clear()
				moveTo(0, 0)
			}
		}
	}

}
