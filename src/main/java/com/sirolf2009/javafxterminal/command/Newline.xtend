package com.sirolf2009.javafxterminal.command

import com.sirolf2009.javafxterminal.TerminalView
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

@Data class Newline implements Command {

	val List<String> styles

	override execute(TerminalView it) {
		moveTo(getCurrentParagraph(), getParagraph(getCurrentParagraph()).length())
		insertChar('\n', styles)
	}

}
