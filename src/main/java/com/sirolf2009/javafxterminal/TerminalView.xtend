package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.command.CarriageReturn
import com.sirolf2009.javafxterminal.command.ClearLine
import com.sirolf2009.javafxterminal.command.Command
import com.sirolf2009.javafxterminal.command.DeletePreviousChar
import com.sirolf2009.javafxterminal.command.DeleteText
import com.sirolf2009.javafxterminal.command.InsertChar
import com.sirolf2009.javafxterminal.command.MoveCaretDown
import com.sirolf2009.javafxterminal.command.MoveCaretLeft
import com.sirolf2009.javafxterminal.command.MoveCaretRight
import com.sirolf2009.javafxterminal.command.MoveCaretUp
import com.sirolf2009.javafxterminal.command.MoveTo
import com.sirolf2009.javafxterminal.command.Newline
import com.sun.javafx.tk.Toolkit
import io.reactivex.Observable
import io.reactivex.rxjavafx.schedulers.JavaFxScheduler
import io.reactivex.schedulers.Schedulers
import io.reactivex.subjects.PublishSubject
import io.reactivex.subjects.Subject
import java.io.Reader
import java.util.ArrayList
import java.util.HashSet
import java.util.List
import java.util.Optional
import java.util.Set
import java.util.concurrent.atomic.AtomicReference
import java.util.function.BiPredicate
import javafx.application.Platform
import javafx.beans.property.SimpleIntegerProperty
import javafx.scene.text.Font
import org.eclipse.xtend.lib.annotations.Accessors
import org.fxmisc.richtext.Caret.CaretVisibility
import org.fxmisc.richtext.CodeArea
import com.sirolf2009.javafxterminal.command.InsertText
import java.util.concurrent.TimeUnit

@Accessors class TerminalView extends CodeArea {

	// https://www.w3schools.com/charsets/ref_utf_basic_latin.asp
	static val BEL = 7 as char
	static val BACKSPACE = 8 as char
	static val NEWLINE = 10 as char
	static val CARRIAGE_RETURN = 13 as char
	static val ESCAPE = 27 as char

	// http://ascii-table.com/ansi-escape-sequences.php
	// CSI = Control Sequence Introducer
	static val MULTI_CSI = '['.toCharArray().get(0)
	static val SINGLE_CSI = 155 as char

	// OSC = Operating System Command
	static val MULTI_OSC = ']'.toCharArray().get(0)

	val styles = new HashSet<String>()

	val columns = new SimpleIntegerProperty()
	val rows = new SimpleIntegerProperty()

	val Subject<Command> commands = PublishSubject.create()

	new(Reader reader) {
		getStyleClass().add("terminal")
		setEditable(false)

		setShowCaret(CaretVisibility.ON)

		widthProperty().addListener[computeRowCols()]
		heightProperty().addListener[computeRowCols()]
		parentProperty().addListener[computeRowCols()]

		new Thread [
			val buffer = new StringBuffer()
			var char = 0
			while((char = reader.read) != -1) {
//				println('''read char «char» «char.getCharacterName()»: «char as char»''')
				try {
					buffer.append(char as char)
					val character = char as char

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
								getUndoManager().preventMerge()
							]
						} else if(next == MULTI_CSI) {
							parseControlSequence(reader)
						} else if(next == MULTI_OSC) {
							parseOperatingSystemCommand(reader)
						} else if(next == BEL) {
							println("bell")
						} else {
							commands.onNext(new InsertChar(character, styles.toList()))
							commands.onNext(new InsertChar(next as char, styles.toList()))
						}
					} else if(char >= 32) {
						commands.onNext(new InsertChar(character, styles.toList()))
					} else if(char == NEWLINE) {
						commands.onNext(new Newline(styles.toList()))
					} else if(char == CARRIAGE_RETURN) {
						commands.onNext(new CarriageReturn())
					} else if(char == BACKSPACE) {
						commands.onNext(new DeletePreviousChar())
					} else {
						System.err.println("I don't know what to do with char " + char + ": " + (char as char))
					}
				} catch(Exception e) {
					System.err.println("Failed to add char " + char + ": " + (char as char))
					e.printStackTrace()
				}
			}
			reader.close()
		].start()

		commands.observeOn(Schedulers.io).subscribe [
//			println(it)
		]
		commands.buffer(100, TimeUnit.MILLISECONDS).flatMap [
			val commands = new ArrayList()
			val chars = new ArrayList<InsertChar>()
			forEach[
				if(it instanceof InsertChar) {
					if(chars.isEmpty()) {
						chars.add(it)
					} else {
						if(chars.get(0).getStyles().equals(getStyles())) {
							chars.add(it)
						} else {
							commands.add(new InsertText(chars.map[getCharacter() + ""].join(), chars.get(0).getStyles()))
							chars.clear()
						}
					}
				} else {
					if(!chars.isEmpty()) {
						commands.add(new InsertText(chars.map[getCharacter() + ""].join(), chars.get(0).getStyles()))
						chars.clear()
					}
					commands.add(it)
				}
			]
			if(!chars.isEmpty()) {
				commands.add(new InsertText(chars.map[getCharacter() + ""].join(), chars.get(0).getStyles()))
				chars.clear()
			}
			return Observable.fromIterable(commands)
		].doOnNext [
			System.out.print("")
		].observeOn(JavaFxScheduler.platform()).subscribe [
			println(it)
			execute(this)
		]
	}

	def parseControlSequence(Reader reader) {
		val params = new StringBuilder()
		var int characterCode
		var char character
		while((characterCode = reader.read()) != -1) {
			character = characterCode as char
			if((character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z')) {
				val array = params.toString().split(";").filter[!isEmpty()].toList()
//				println("Running command " + character + " with params " + array)
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
							case 5: {
								// TODO slow blink, less than 150 per minute
							}
							case 6: {
								// TODO fast blink, more than 150 per minute
							}
							case 7: {
								val foreground = styles.findFirst[startsWith("terminal-foreground")]
								val background = styles.findFirst[startsWith("terminal-background")]
								styles.removeAll(foreground, background)
								styles.add(foreground.replace("terminal-foreground", "terminal-background"))
								styles.add(background.replace("terminal-background", "terminal-foreground"))
							}
							case 10: {
								// TODO primary font
							}
							case 11: {
								// TODO alternative font
							}
							case 12: {
								// TODO alternative font
							}
							case 13: {
								// TODO alternative font
							}
							case 14: {
								// TODO alternative font
							}
							case 15: {
								// TODO alternative font
							}
							case 16: {
								// TODO alternative font
							}
							case 17: {
								// TODO alternative font
							}
							case 18: {
								// TODO alternative font
							}
							case 19: {
								// TODO alternative font
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
							case 38: {
								if(array.get(0).equals("5")) {
									switch (Integer.parseInt(array.get(1))) {
										case 0:
											styles.setForeground("terminal-foreground-black")
										case 1:
											styles.setForeground("terminal-foreground-red")
										case 2:
											styles.setForeground("terminal-foreground-green")
										case 3:
											styles.setForeground("terminal-foreground-yellow")
										case 4:
											styles.setForeground("terminal-foreground-blue")
										case 5:
											styles.setForeground("terminal-foreground-magenta")
										case 6:
											styles.setForeground("terminal-foreground-cyan")
										case 7:
											styles.setForeground("terminal-foreground-white")
										case 8:
											styles.setForeground("terminal-foreground-black-bright")
										case 9:
											styles.setForeground("terminal-foreground-red-bright")
										case 11:
											styles.setForeground("terminal-foreground-green-bright")
										case 12:
											styles.setForeground("terminal-foreground-yellow-bright")
										case 13:
											styles.setForeground("terminal-foreground-blue-bright")
										case 14:
											styles.setForeground("terminal-foreground-magenta-bright")
										case 15:
											styles.setForeground("terminal-foreground-cyan-bright")
										case 16:
											styles.setForeground("terminal-foreground-white-bright")
									}
								}
							}
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
							case 90:
								styles.setForeground("terminal-foreground-black-bright")
							case 91:
								styles.setForeground("terminal-foreground-red-bright")
							case 92:
								styles.setForeground("terminal-foreground-green-bright")
							case 93:
								styles.setForeground("terminal-foreground-yellow-bright")
							case 94:
								styles.setForeground("terminal-foreground-blue-bright")
							case 95:
								styles.setForeground("terminal-foreground-magenta-bright")
							case 96:
								styles.setForeground("terminal-foreground-cyan-bright")
							case 97:
								styles.setForeground("terminal-foreground-white-bright")
							case 100:
								styles.setForeground("terminal-background-black-bright")
							case 101:
								styles.setForeground("terminal-background-red-bright")
							case 102:
								styles.setForeground("terminal-background-green-bright")
							case 103:
								styles.setForeground("terminal-background-yellow-bright")
							case 104:
								styles.setForeground("terminal-background-blue-bright")
							case 105:
								styles.setForeground("terminal-background-magenta-bright")
							case 106:
								styles.setForeground("terminal-background-cyan-bright")
							case 107:
								styles.setForeground("terminal-background-white-bright")
							default:
								throw new RuntimeException("Unknown style " + it + " with params " + params)
						}
					]
				} else if(character.toString().equals("A")) {
					commands.onNext(new MoveCaretUp(1))
				} else if(character.toString().equals("B")) {
					commands.onNext(new MoveCaretDown(1))
				} else if(character.toString().equals("C")) {
					val amount = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					commands.onNext(new MoveCaretRight(amount))
				} else if(character.toString().equals("D")) {
					val amount = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					commands.onNext(new MoveCaretLeft(amount))
				} else if(character.toString().equals("K")) {
					commands.onNext(new ClearLine())
				} else if(character.toString().equals("H")) {
					val x = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					val y = if(array.size() > 1) Integer.parseInt(array.get(1)) else 1
					commands.onNext(new MoveTo(x, y))
				} else if(character.toString().equals("J")) {
					val type = if(array.size() > 0) Integer.parseInt(array.get(0)) else 0
					// TODO scrollback buffer
					commands.onNext(new DeleteText(type))
				} else {
					throw new IllegalArgumentException("Unknown command " + character + " with params " + params + " " + array)
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
				println("os command with " + character + " with params " + array)
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
		(0 ..< amount).forEach [
			moveCaretLeft()
		]
	}

	def moveCaretLeft() {
		if(getCaretColumn() > 0) {
			moveTo(getCaretPosition() - 1)
		}
	}

	def moveCaretRight(int amount) {
		(0 ..< amount).forEach [
			moveCaretRight()
		]
	}

	def moveCaretRight() {
		val caretPosition = getCaretPosition()
		val length = getLength()
		val columns = columns.get()
		try {
			if(caretPosition < columns) {
				if(caretPosition > length) {
					insertChar(' ', #[])
					moveTo(getCaretPosition() + 1)
				} else {
					moveTo(getCaretPosition() + 1)
				}
			}
		} catch(Exception e) {
			throw new RuntimeException('''Failed to move the caret right with caretPosition=«caretPosition» and length=«length» and columns=«columns»''', e)
		}
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
		val caretPosition = getCaretPosition()
		val length = getLength()
		try {
			if(caretPosition >= length) {
				insertText(length, character.toString())
			} else {
				replaceText(getCaretPosition(), getCaretPosition() + 1, character.toString())
			}
			setStyle(getCaretPosition() - 1, getCaretPosition(), styles.toList())
			requestFollowCaret()
		} catch(Exception e) {
			throw new RuntimeException('''Failed to insert char «(character as char) as int»: «character» with styles «styles» and caretPosition=«caretPosition» and length=«length»''', e)
		}
	}

	def clearLine() {
		replaceText(getCurrentParagraph(), getCaretColumn(), getCurrentParagraph(), getParagraph(getCurrentParagraph()).length(), "")
	}

	def computeRowCols() {
		if(getWidth() != 0 && getHeight() != 0) {
			val font = Font.font("Monospaced")
			val metrics = Toolkit.getToolkit().getFontLoader().getFontMetrics(font)
			val charWidth = metrics.computeStringWidth("a")
			val charHeight = metrics.getLineHeight()
			columns.set(Math.floor(getWidth() / charWidth) as int)
			rows.set(Math.floor(getHeight() / charHeight) as int)
		}
	}

	def static <T> bufferWhile(Observable<T> obs, BiPredicate<T, T> predicate) {
		val currentItems = new ArrayList()
		val currentItem = new AtomicReference<T>()
		obs.map [
			if(currentItem.get() === null) {
				currentItem.set(it)
				currentItems.add(it)
				return Optional.empty()
			} else if(predicate.test(currentItem.get(), it)) {
				currentItem.set(it)
				currentItems.add(it)
				return Optional.empty()
			} else {
				currentItem.set(it)
				val copy = new ArrayList(currentItems)
				currentItems.clear()
				return Optional.of(copy)
			}
		].filter[isPresent()].map[get()]
	}

}
