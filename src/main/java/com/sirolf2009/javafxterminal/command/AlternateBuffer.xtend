package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class AlternateBuffer implements Command {

	val boolean alternate

	override execute(TerminalCanvas it) {
		getBuffer().alternate(alternate)
	}

}
