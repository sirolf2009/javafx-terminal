package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalCanvas
import org.eclipse.xtend.lib.annotations.Data

@Data class MoveCaretRight extends AbstractCommand {
	
	val int amount

	override execute(TerminalCanvas it) {
		moveCaretRight(amount)
	}

}
