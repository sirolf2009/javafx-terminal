package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.ANSI.AnsiControlSequence
import com.sirolf2009.javafxterminal.ANSI.AnsiOperatingSystemCommand
import java.io.StringReader
import java.util.ArrayList
import org.junit.Assert
import org.junit.Test
import java.nio.file.Files
import java.nio.file.Paths
import java.text.DecimalFormat

class ANSITest {

	@Test
	def void testSimple() {
		val text = "\u001B[36mTerminal View\u001B[0m"
		val parsed = ANSI.parse(new StringReader(text))
		Assert.assertEquals("Terminal View", parsed.getKey())
		Assert.assertEquals(#[
			new AnsiControlSequence(0, #["36"], 'm'),
			new AnsiControlSequence(13, #["0"], 'm')
		], parsed.getValue())
	}

	@Test
	def void testOperatingSystemCommand() {
		val text = "\u001B]0;fish  /folder/path\u0007"
		val parsed = ANSI.parse(new StringReader(text))
		Assert.assertEquals("", parsed.getKey())
		Assert.assertEquals(#[
			new AnsiOperatingSystemCommand(0, new ArrayList(#["0", "fish  /folder/path"]))
		], parsed.getValue())
	}

	@Test
	def void testOutput() {
		val text = Files.readAllLines(Paths.get("src/test/resources/output")).join("\n")
		val parsed = ANSI.parse(new StringReader(text))
		println(parsed)
		Assert.assertEquals(#[
			new AnsiOperatingSystemCommand(0, new ArrayList(#["0", "fish  /home/floris/eclipse-workspace/javafx-terminal"])),
			new AnsiControlSequence(0, new ArrayList(#["30"]), 'm'),
			new AnsiControlSequence(0, new ArrayList(#["0", "10"]), 'm'),
			new AnsiOperatingSystemCommand(0, new ArrayList(#["0", "fish  /home/floris/eclipse-workspace/javafx-terminal"])),
			new AnsiControlSequence(0, new ArrayList(#["30"]), 'm'),
			new AnsiControlSequence(0, new ArrayList(#["0", "10"]), 'm')
		], parsed.getValue())
		Assert.assertEquals(" ", parsed.getKey())
	}

	@Test
	def void testBashOutput() {
		val text = Files.readAllLines(Paths.get("src/test/resources/bash-output")).join("\n")
		val parsed = ANSI.parse(new StringReader(text))

		val decimalFormat = new DecimalFormat("000")
		println((0 ..< parsed.getKey().length()).map[decimalFormat.format(it) + ""].toList())
		println(parsed.getKey().toCharArray().map [
			if(it.equals('\n'.charAt(0))) {
				" \\n"
			} else {
				"  " + it
			}
		].toList())
		println((0 ..< parsed.getKey().length()).map [
			val ansiCode = parsed.getValue().findFirst[code|code.getIndex() == it]
			if(ansiCode !== null) "m" else " "
		].join().toCharArray().map["  " + it].toList())
		
		println(TerminalView.getStyles(parsed.getKey(), parsed.getValue().filter[it instanceof AnsiControlSequence].map[it as AnsiControlSequence].toList()).flatMap[
			(0 ..< length).map[index| hashCode.toString().substring(0, 3)]
		].toList())
		//terminal app returns 121 here
		//we return 119 here
		//TODO fix that
		println("length "+TerminalView.getStyles(parsed.getKey(), parsed.getValue().filter[it instanceof AnsiControlSequence].map[it as AnsiControlSequence].toList()).map[getLength()].reduce[a,b| a+b])

		println()
		parsed.getValue().forEach [
			println(getIndex() + " " + getParams() + " " + (if(getParams().get(0).equals("30")) "black" else "blue" ))
		]

		Assert.assertEquals(new ArrayList(#[
			new AnsiControlSequence(0, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(4, new ArrayList(#["34", "1"]), 'm'),
			new AnsiControlSequence(21, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(24, new ArrayList(#["34", "1"]), 'm'),
			new AnsiControlSequence(25, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(28, new ArrayList(#["34", "1"]), 'm'),
			new AnsiControlSequence(47, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(50, new ArrayList(#["30", "1"]), 'm')
		]), parsed.getValue())
		Assert.assertEquals(" ", parsed.getKey())
	}

}
