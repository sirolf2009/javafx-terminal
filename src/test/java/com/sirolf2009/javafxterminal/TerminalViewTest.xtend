package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.command.CarriageReturn
import com.sirolf2009.javafxterminal.command.Command
import com.sirolf2009.javafxterminal.command.InsertChar
import com.sirolf2009.javafxterminal.command.InsertText
import io.reactivex.Observable
import java.util.List
import org.junit.Test

import static extension com.sirolf2009.javafxterminal.TerminalView.*
import org.junit.Assert

class TerminalViewTest {
	
	@Test
	def void aggregateCommands() {
		val List<Command> rawCommands = #[
			new CarriageReturn(),
			new InsertChar('<', #["terminal-foreground-cyan"]),
			new InsertChar('@', #["terminal-foreground-cyan"]),
			new InsertChar('j', #["terminal-foreground-cyan"]),
			new InsertChar('a', #["terminal-foreground-cyan"]),
			new InsertChar('v', #["terminal-foreground-cyan"]),
			new InsertChar('a', #["terminal-foreground-cyan"]),
			new InsertChar('f', #["terminal-foreground-cyan"]),
			new InsertChar('x', #["terminal-foreground-cyan"]),
			new InsertChar('-', #["terminal-foreground-cyan"]),
			new InsertChar('t', #["terminal-foreground-cyan"]),
			new InsertChar('e', #["terminal-foreground-cyan"]),
			new InsertChar('r', #["terminal-foreground-cyan"]),
			new InsertChar('m', #["terminal-foreground-cyan"]),
			new InsertChar('i', #["terminal-foreground-cyan"]),
			new InsertChar('n', #["terminal-foreground-cyan"]),
			new InsertChar('a', #["terminal-foreground-cyan"]),
			new InsertChar('l', #["terminal-foreground-cyan"]),
			new InsertChar('>', #["terminal-foreground-cyan"]),
			new InsertChar('-', #["terminal-foreground-blue"]),
			new InsertChar('<', #["terminal-foreground-blue"]),
			new InsertChar('⎇', #["terminal-foreground-blue"]),
			new InsertChar(' ', #["terminal-foreground-blue"]),
			new InsertChar('m', #["terminal-foreground-blue"]),
			new InsertChar('a', #["terminal-foreground-blue"]),
			new InsertChar('s', #["terminal-foreground-blue"]),
			new InsertChar('t', #["terminal-foreground-blue"]),
			new InsertChar('e', #["terminal-foreground-blue"]),
			new InsertChar('r', #["terminal-foreground-blue"]),
			new InsertChar('>', #["terminal-foreground-blue"])
		]
		val expected = #[
			new CarriageReturn(),
			new InsertText("<@javafx-terminal>", #["terminal-foreground-cyan"]),
			new InsertText("-<⎇ master>", #["terminal-foreground-blue"])
		]
		Assert.assertEquals(expected, Observable.fromIterable(#[rawCommands]).aggregate().toList().blockingGet())
	}
	
}