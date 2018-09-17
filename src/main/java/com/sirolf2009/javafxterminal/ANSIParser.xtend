package com.sirolf2009.javafxterminal

import java.io.Reader
import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.annotations.ToString
import org.eclipse.xtend.lib.annotations.EqualsHashCode

class ANSIParser {
	
	static val BEL = 7 as char
	static val ESCAPE = 27 as char
	
	//CSI = Control Sequence Introducer
	static val MULTI_CSI = '['.toCharArray().get(0)
	static val SINGLE_CSI = 155 as char
	
	//OSC = Operating System Command
	static val MULTI_OSC = ']'.toCharArray().get(0)
	
	def static parse(Reader reader) {
		val output = new StringBuilder()
		val commands = newArrayList()
		var int character
		val counter = new AtomicInteger()
		while((character = reader.read()) != -1) {
			if(character == SINGLE_CSI) {
				commands.add(parseControlSequence(reader, counter.get()))
			} else if(character == ESCAPE) {
				val next = reader.read()
				if(next == -1) {
					output.append(character as char)
				} else if(next == MULTI_CSI) {
					commands.add(parseControlSequence(reader, counter.get()))
				} else if(next == MULTI_OSC) {
					commands.add(parseOperatingSystemCommand(reader, counter.get()))
				} else {
					output.append(character as char)
					output.append(next as char)
					counter.incrementAndGet()
					counter.incrementAndGet()
				}
			} else {
				output.append(character as char)
				counter.incrementAndGet()
			}
		}
		return new ParsedAnsi(output.toString(), commands)
	}
	
	def static parseControlSequence(Reader reader, int index) {
		val params = new StringBuilder()
		var int character
		while((character = reader.read()) != -1) {
			if ( (character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z')) {
				val array = params.toString().split(";").filter[!isEmpty()].toList()
				return new AnsiControlSequence(index, array, character as char);
			} else {
				params.append(character as char);
			}
		}
	}
	
	def static parseOperatingSystemCommand(Reader reader, int index) {
		val params = new StringBuilder()
		var int character
		while((character = reader.read()) != -1) {
			if(character as char == BEL) {
				val array = params.toString().split(";").filter[!isEmpty()].toList()
				return new AnsiOperatingSystemCommand(index, array);
			} else {
				params.append(character as char);
			}
		}
	}
	
	@FinalFieldsConstructor @ToString @Accessors @EqualsHashCode static class AnsiCode {
		val int index
		val List<String> params
	}
	@FinalFieldsConstructor @ToString @Accessors @EqualsHashCode static class AnsiControlSequence extends AnsiCode {
		val char command
	}
	@FinalFieldsConstructor @ToString @Accessors @EqualsHashCode static class AnsiOperatingSystemCommand extends AnsiCode {
	}
	
	def static hex(byte b) {
		return String.format("%02x", b)
	}
	
}