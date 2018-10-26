package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView
import org.eclipse.xtend.lib.annotations.Data

@Data class DeleteText implements Command {

	val int type

	override execute(TerminalView it) {
		switch (type) {
			case 0: deleteText(getCaretPosition(), getLength())
			case 1: deleteText(0, getCaretPosition())
			case 2: deleteText(0, getLength())
			case 3: deleteText(0, getLength())
		}
	}

}
