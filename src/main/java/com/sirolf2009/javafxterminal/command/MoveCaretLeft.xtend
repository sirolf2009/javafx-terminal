package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView
import org.eclipse.xtend.lib.annotations.Data

@Data class MoveCaretLeft implements Command {
	
	val int amount

	override execute(TerminalView it) {
		moveCaretLeft(amount)
	}

}
