package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.ANSIParser.AnsiControlSequence
import com.sirolf2009.javafxterminal.ANSIParser.AnsiOperatingSystemCommand
import java.io.StringReader
import java.nio.file.Files
import java.nio.file.Paths
import java.util.ArrayList
import java.util.LinkedList
import org.junit.Assert
import org.junit.Test

class ANSIParserTest {
	
	@Test
	def void testDictionary() {
		val dict = #{
			"\u001B[A" -> new ParsedAnsi("", #[new AnsiControlSequence(0, #[], "A")]),
			"\u001B[B" -> new ParsedAnsi("", #[new AnsiControlSequence(0, #[], "B")]),
			"\u001B[C" -> new ParsedAnsi("", #[new AnsiControlSequence(0, #[], "C")]),
			"\u001B[D" -> new ParsedAnsi("", #[new AnsiControlSequence(0, #[], "D")])
		}
		dict.entrySet().forEach [
			val parsed = ANSIParser.parse(new StringReader(getKey()))
			println(parsed.toDebugString())
			Assert.assertEquals(getKey(), getValue(), parsed)
		]
	}

	@Test
	def void testSimple() {
		val text = "\u001B[36mTerminal View\u001B[0m"
		val parsed = ANSIParser.parse(new StringReader(text))
		println(parsed.toDebugString())
		Assert.assertEquals("Terminal View", parsed.getText())
		Assert.assertEquals(#[
			new AnsiControlSequence(0, #["36"], 'm'),
			new AnsiControlSequence(13, #["0"], 'm')
		], parsed.getAnsiCodes())
	}

	@Test
	def void testOperatingSystemCommand() {
		val text = "\u001B]0;fish  /folder/path\u0007"
		val parsed = ANSIParser.parse(new StringReader(text))
		Assert.assertEquals("", parsed.getText())
		Assert.assertEquals(#[
			new AnsiOperatingSystemCommand(0, new ArrayList(#["0", "fish  /folder/path"]))
		], parsed.getAnsiCodes())
	}

	@Test
	def void testOutput() {
		val text = Files.readAllLines(Paths.get("src/test/resources/output")).join("\n")
		val parsed = ANSIParser.parse(new StringReader(text))
		println(parsed)
		Assert.assertEquals(#[
			new AnsiOperatingSystemCommand(0, new ArrayList(#["0", "fish  /home/floris/eclipse-workspace/javafx-terminal"])),
			new AnsiControlSequence(0, new ArrayList(#["30"]), 'm'),
			new AnsiControlSequence(0, new ArrayList(#["0", "10"]), 'm'),
			new AnsiOperatingSystemCommand(0, new ArrayList(#["0", "fish  /home/floris/eclipse-workspace/javafx-terminal"])),
			new AnsiControlSequence(0, new ArrayList(#["30"]), 'm'),
			new AnsiControlSequence(0, new ArrayList(#["0", "10"]), 'm')
		], parsed.getAnsiCodes())
		Assert.assertEquals(" ", parsed.getText())
	}

	@Test
	def void testBashOutput() {
//		val text = Files.readAllLines(Paths.get("src/test/resources/bash-output")).join("\n")
		val text = Files.readAllLines(Paths.get("output")).join("\n")
		val parsed = ANSIParser.parse(new StringReader(text))

		println(parsed.toDebugString())

		val expected = new LinkedList(#[
			new AnsiControlSequence(2, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(3, new ArrayList(#["34", "1"]), 'm'),
			new AnsiControlSequence(20, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(23, new ArrayList(#["34", "1"]), 'm'),
			new AnsiControlSequence(24, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(27, new ArrayList(#["34", "1"]), 'm'),
			new AnsiControlSequence(46, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(49, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(52, new ArrayList(#["32", "1"]), 'm'),
			new AnsiControlSequence(98, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(101, new ArrayList(#["32", "1"]), 'm'),
			new AnsiControlSequence(114, new ArrayList(#["30", "1"]), 'm'),
			new AnsiControlSequence(119, new ArrayList(#["0"]), 'm')
		])

		Assert.assertEquals(expected.size(), parsed.getAnsiCodes().size())
		parsed.getAnsiCodes.forEach [ it, index |
			Assert.assertEquals('''Ansi Code «index»''', expected.pop(), it)
		]
	}

}
