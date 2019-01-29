package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class CarriageReturn extends AbstractCommand {

	override execute(TerminalCanvas it) {
		moveTo(0, getCurrentLine())
	}

}
