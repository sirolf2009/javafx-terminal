package com.sirolf2009.javafxterminal

import java.io.Reader
import java.util.HashSet
import java.util.List
import java.util.Set
import javafx.application.Platform
import org.fxmisc.richtext.CodeArea

class TerminalView extends CodeArea {

	// https://www.w3schools.com/charsets/ref_utf_basic_latin.asp
	static val BEL = 7 as char
	static val NEWLINE = 10 as char
	static val ESCAPE = 27 as char

	// http://ascii-table.com/ansi-escape-sequences.php
	// CSI = Control Sequence Introducer
	static val MULTI_CSI = '['.toCharArray().get(0)
	static val SINGLE_CSI = 155 as char

	// OSC = Operating System Command
	static val MULTI_OSC = ']'.toCharArray().get(0)

	val styles = new HashSet<String>()

	new(Reader reader) {
		getStyleClass().add("terminal")
		setEditable(false)

		new Thread [
			val buffer = new StringBuffer()
			var char = 0
			while((char = reader.read) != -1) {
				buffer.append(char as char)
				val character = char as char
				println("new character " + char + ": " + character)

				if(character == SINGLE_CSI) {
					parseControlSequence(reader)
				} else if(character == BEL) {
					println("bell")
				} else if(character == ESCAPE) {
					val next = reader.read()
					if(next == -1) {
						val stylesCopy = styles.toList()
						Platform.runLater [
							insertChar(character, stylesCopy)
						]
					} else if(next == MULTI_CSI) {
						parseControlSequence(reader)
					} else if(next == MULTI_OSC) {
						parseOperatingSystemCommand(reader)
					} else if(next == BEL) {
						println("bell")
					} else {
						val stylesCopy = styles.toList()
						Platform.runLater [
							insertChar(character, stylesCopy)
							insertChar(next as char, stylesCopy)
						]
					}
				} else if(char >= 32 || char == NEWLINE as int) {
					val stylesCopy = styles.toList()
					Platform.runLater [
						insertChar(character, stylesCopy)
					]
				}
			}
			reader.close()
		].start()
	}

	def parseControlSequence(Reader reader) {
		val params = new StringBuilder()
		var int characterCode
		var char character
		while((characterCode = reader.read()) != -1) {
			character = characterCode as char
			if((character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z')) {
				val array = params.toString().split(";").filter[!isEmpty()].toList()
				if(character.toString().equals("m")) {
					array.map[Integer.parseInt(it)].forEach [
						switch (it) {
							case 0:
								styles.clear()
							case 1:
								styles.add("terminal-bold")
							case 2:
								styles.add("terminal-faint")
							case 3:
								styles.add("terminal-italic")
							case 4:
								styles.add("terminal-underline")
							case 7: {
								val foreground = styles.findFirst[startsWith("terminal-foreground")]
								val background = styles.findFirst[startsWith("terminal-background")]
								styles.removeAll(foreground, background)
								styles.add(foreground.replace("terminal-foreground", "terminal-background"))
								styles.add(background.replace("terminal-background", "terminal-foreground"))
							}
							case 10: {
								//TODO primary font
							}
							case 30:
								styles.setForeground("terminal-foreground-black")
							case 31:
								styles.setForeground("terminal-foreground-red")
							case 32:
								styles.setForeground("terminal-foreground-green")
							case 33:
								styles.setForeground("terminal-foreground-yellow")
							case 34:
								styles.setForeground("terminal-foreground-blue")
							case 35:
								styles.setForeground("terminal-foreground-magenta")
							case 36:
								styles.setForeground("terminal-foreground-cyan")
							case 37:
								styles.setForeground("terminal-foreground-white")
							case 40:
								styles.setBackground("terminal-background-black")
							case 41:
								styles.setBackground("terminal-background-red")
							case 42: 
								styles.setBackground("terminal-background-green")
							case 43:
								styles.setBackground("terminal-background-yellow")
							case 44:
								styles.setBackground("terminal-background-blue")
							case 45:
								styles.setBackground("terminal-background-magenta")
							case 46:
								styles.setBackground("terminal-background-cyan")
							case 47:
								styles.setBackground("terminal-background-white")
							default:
								throw new RuntimeException("Unknown style " + it + " with params " + params)
						}
					]
				} else if(character.toString().equals("A")) {
					println("caret up")
					moveCaretUp(1)
				} else if(character.toString().equals("B")) {
					println("caret down")
					moveCaretDown(1)
				} else if(character.toString().equals("C")) {
					println("caret right")
					moveCaretRight(1)
				} else if(character.toString().equals("D")) {
					println("caret left")
					moveCaretLeft(1)
				} else if(character.toString().equals("K")) {
					println("clearLine")
					Platform.runLater [
						clearLine()
					]
				} else {
					throw new IllegalArgumentException("Unknown command " + character + " with params " + params)
				}
				return
			} else {
				params.append(character as char);
			}
		}
	}

	def parseOperatingSystemCommand(Reader reader) {
		val params = new StringBuilder()
		var int character
		while((character = reader.read()) != -1) {
			if(character as char == BEL) {
				val array = params.toString().split(";").filter[!isEmpty()].toList()
//				return new AnsiOperatingSystemCommand(index, array);
				// TODO execute command
				return
			} else {
				params.append(character as char);
			}
		}
	}

	def solarizedDark() {
		getStylesheets().add(TerminalView.getResource("/solarized_dark.css").toExternalForm())
	}

	def static setForeground(Set<String> classes, String foreground) {
		classes.removeAll(classes.filter[startsWith("terminal-foreground")].toList())
		classes.add(foreground)
	}

	def static setBackground(Set<String> classes, String background) {
		classes.removeAll(classes.filter[startsWith("terminal-background")].toList())
		classes.add(background)
	}

	def moveCaretLeft(int amount) {
		moveTo(getCaretPosition() - amount)
	}

	def moveCaretRight(int amount) {
		moveTo(getCaretPosition() + amount)
	}

	def moveCaretUp(int amount) {
		val currentLineDistance = getCaretColumn()
		val targetLineDistance = getParagraph(getCurrentParagraph() - amount).getText().length() - getCaretColumn()
		val inbetweenLinesDistance = (0 ..< amount - 1).map[getParagraph(getCurrentParagraph() - it)].map[getText().length()].reduce[a, b|a + b]
		moveCaretLeft(currentLineDistance + targetLineDistance + inbetweenLinesDistance)
	}

	def moveCaretDown(int amount) {
		val currentLineDistance = getParagraph(getCurrentParagraph()).getText().length() - getCaretColumn()
		val targetLineDistance = getCaretColumn()
		val inbetweenLinesDistance = (0 ..< amount - 1).map[getParagraph(getCurrentParagraph() + it)].map[getText().length()].reduce[a, b|a + b]
		moveCaretRight(currentLineDistance + targetLineDistance + inbetweenLinesDistance)
	}

	def insertChar(Character character, List<String> styles) {
		if(getCaretPosition() == getLength()) {
			insertText(getCaretPosition(), character.toString())
		} else {
			replaceText(getCaretPosition(), getCaretPosition() + 1, character.toString())
		}
		setStyle(getCaretPosition() - 1, getCaretPosition(), styles.toList())
	}

	def clearLine() {
		replaceText(getCurrentParagraph(), getCaretColumn(), getCurrentParagraph(), getParagraph(getCurrentParagraph()).length(), "")
	}

}
