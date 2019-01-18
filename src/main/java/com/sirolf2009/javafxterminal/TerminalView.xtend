package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.command.Bell
import com.sirolf2009.javafxterminal.command.CarriageReturn
import com.sirolf2009.javafxterminal.command.ClearLine
import com.sirolf2009.javafxterminal.command.Command
import com.sirolf2009.javafxterminal.command.DeletePreviousChar
import com.sirolf2009.javafxterminal.command.DeleteText
import com.sirolf2009.javafxterminal.command.InsertChar
import com.sirolf2009.javafxterminal.command.InsertText
import com.sirolf2009.javafxterminal.command.MoveCaretDown
import com.sirolf2009.javafxterminal.command.MoveCaretLeft
import com.sirolf2009.javafxterminal.command.MoveCaretRight
import com.sirolf2009.javafxterminal.command.MoveCaretUp
import com.sirolf2009.javafxterminal.command.MoveTo
import com.sirolf2009.javafxterminal.command.Newline
import com.sirolf2009.javafxterminal.command.OSCommand
import com.sirolf2009.javafxterminal.command.SelectCharacterSet
import com.sirolf2009.javafxterminal.theme.ITheme
import io.reactivex.Observable
import io.reactivex.rxjavafx.schedulers.JavaFxScheduler
import io.reactivex.schedulers.Schedulers
import io.reactivex.subjects.PublishSubject
import io.reactivex.subjects.Subject
import java.io.Reader
import java.util.ArrayList
import java.util.LinkedList
import java.util.List
import java.util.Optional
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import java.util.function.BiPredicate
import javafx.beans.property.SimpleIntegerProperty
import javafx.scene.paint.Color
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import com.sirolf2009.javafxterminal.command.AlternateBuffer
import com.sirolf2009.javafxterminal.command.Focus
import com.sirolf2009.javafxterminal.command.CursorNextLine
import com.sirolf2009.javafxterminal.command.CursorPreviousLine
import com.sirolf2009.javafxterminal.command.CursorHorizontalAbsolute
import com.sirolf2009.javafxterminal.command.CursorPosition

@Accessors class TerminalView extends TerminalCanvas {

	static val Logger log = LoggerFactory.getLogger(TerminalView)

	// TODO ansi support for most useful commands is finished, we should move to vt100 support
	// http://ascii-table.com/ansi-escape-sequences-vt-100.php
	// https://www.w3schools.com/charsets/ref_utf_basic_latin.asp
	static val BEL = 7 as char
	static val BACKSPACE = 8 as char
	static val HORIZONTAL_TAB = 9 as char
	static val NEWLINE = 10 as char
	static val CARRIAGE_RETURN = 13 as char
	static val ESCAPE = 27 as char
	static val LEFT_PAR = 40 as char
	static val RIGHT_PAR = 41 as char

	// http://ascii-table.com/ansi-escape-sequences.php
	// CSI = Control Sequence Introducer
	static val MULTI_CSI = '['.toCharArray().get(0)
	static val SINGLE_CSI = 155 as char

	// OSC = Operating System Command
	static val MULTI_OSC = ']'.toCharArray().get(0)

	var RenderingContext styleContext = new RenderingContext(theme)

	val columns = new SimpleIntegerProperty()
	val rows = new SimpleIntegerProperty()

	val ObservableReader reader
	val Subject<Character> characters = PublishSubject.create()
	val Subject<Command> commands = PublishSubject.create()
	val Observable<Command> aggregatedCommands

	new(Reader input, ITheme theme) {
		super(theme)
		getStyleClass().add("terminal")

		reader = new ObservableReader(input);

//		reader.characters.subscribe [
//			println('''read char «it» «CharacterNames.getCharacterName(it)»: «it as char»''')
//		]

		new Thread [
			val buffer = new StringBuffer()
			var char = 0
			while((char = reader.read) != -1) {
				characters.onNext(char as char)
				try {
					buffer.append(char as char)
					val character = char as char

					if(character == SINGLE_CSI) {
						parseControlSequence(reader)
					} else if(character == BEL) {
						commands.onNext(new Bell())
					} else if(character == ESCAPE) {
						val next = reader.read()
						if(next == -1) {
							commands.onNext(new InsertChar(character, getStyles()))
						} else if(next == MULTI_CSI) {
							parseControlSequence(reader)
						} else if(next == MULTI_OSC) {
							parseOperatingSystemCommand(reader)
						} else if(next == BEL) {
							commands.onNext(new Bell())
						} else if(next == LEFT_PAR) {
							parseSelectCharacterSetG0(reader)
						} else if(next == RIGHT_PAR) {
							parseSelectCharacterSetG1(reader)
						} else {
							commands.onNext(new InsertChar(character, getStyles()))
							commands.onNext(new InsertChar(next as char, getStyles()))
						}
					} else if(char >= 32) {
						commands.onNext(new InsertChar(character, getStyles()))
					} else if(char == NEWLINE) {
						commands.onNext(new Newline())
					} else if(char == CARRIAGE_RETURN) {
						commands.onNext(new CarriageReturn())
					} else if(char == BACKSPACE) {
						commands.onNext(new DeletePreviousChar())
					} else if(char == HORIZONTAL_TAB) {
						commands.onNext(new InsertChar(char as char, getStyles()))
					} else {
						System.err.println('''I don't know what to do with char «char» «CharacterNames.getCharacterName(char)»: «char as char»''')
					}
				} catch(Exception e) {
					System.err.println('''Failed to add char «char» «CharacterNames.getCharacterName(char)»: «char as char»''')
					e.printStackTrace()
				}
			}
			reader.close()
		].start()

		aggregatedCommands = commands.observeOn(Schedulers.computation).buffer(16, TimeUnit.MILLISECONDS).filter[size() > 0].aggregate()
		aggregatedCommands.observeOn(JavaFxScheduler.platform()).subscribe [
			try {
				execute(this)
			} catch(Exception e) {
				log.error("Failed to execute " + it, e)
			}
		]

		drawTimeline()
	}

	// https://github.com/JetBrains/jediterm/blob/master/terminal/src/com/jediterm/terminal/emulator/JediEmulator.java
	// https://github.com/JetBrains/jediterm/blob/master/terminal/src/com/jediterm/terminal/model/JediTerminal.java
	def parseControlSequence(Reader reader) {
		val params = new StringBuilder()
		var int characterCode
		var char character
		while((characterCode = reader.read()) != -1) {
			character = characterCode as char
			if(characterCode >= 0x40 && characterCode <= 0x7E) {
				val array = new LinkedList(params.toString().split(";").filter[!isEmpty()].toList())
				if(character.toString().equals("m")) {
					if(array.isEmpty()) {
						styleContext = styleContext.clear()
					} else {
						while(array.peek() !== null) {
							val it = Integer.parseInt(array.poll())
							switch (it) {
								case 0:
									styleContext = styleContext.clear()
								case 1:
									styleContext = styleContext.bold()
								case 2:
									styleContext = styleContext.thin()
								case 3:
									styleContext = styleContext.italic()
								case 4: {
									// TODO underline
								}
								case 5: {
									// TODO slow blink, less than 150 per minute
								}
								case 6: {
									// TODO fast blink, more than 150 per minute
								}
								case 7:
									styleContext = styleContext.inverse(true)
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
								case 24: {
									// TODO underline off
								}
								case 27: {
									styleContext = styleContext.inverse(false)
								}
								case 30:
									styleContext = styleContext.foreground(theme.foregroundBlack())
								case 31:
									styleContext = styleContext.foreground(theme.foregroundRed())
								case 32:
									styleContext = styleContext.foreground(theme.foregroundGreen())
								case 33:
									styleContext = styleContext.foreground(theme.foregroundYellow())
								case 34:
									styleContext = styleContext.foreground(theme.foregroundBlue())
								case 35:
									styleContext = styleContext.foreground(theme.foregroundMagenta())
								case 36:
									styleContext = styleContext.foreground(theme.foregroundCyan())
								case 37:
									styleContext = styleContext.foreground(theme.foregroundWhite())
								case 38: {
									switch (Integer.parseInt(array.poll())) {
										case 2:
											styleContext = styleContext.foreground(Color.rgb(Integer.parseInt(array.poll()), Integer.parseInt(array.poll()), Integer.parseInt(array.poll())))
										case 5: {
											val code = Integer.parseInt(array.poll())
											switch (code) {
												case 0:
													styleContext = styleContext.foreground(theme.foregroundBlack())
												case 1:
													styleContext = styleContext.foreground(theme.foregroundRed())
												case 2:
													styleContext = styleContext.foreground(theme.foregroundGreen())
												case 3:
													styleContext = styleContext.foreground(theme.foregroundYellow())
												case 4:
													styleContext = styleContext.foreground(theme.foregroundBlue())
												case 5:
													styleContext = styleContext.foreground(theme.foregroundMagenta())
												case 6:
													styleContext = styleContext.foreground(theme.foregroundCyan())
												case 7:
													styleContext = styleContext.foreground(theme.foregroundWhite())
												case 8:
													styleContext = styleContext.foreground(theme.foregroundBlackBright())
												case 9:
													styleContext = styleContext.foreground(theme.foregroundRedBright())
												case 11:
													styleContext = styleContext.foreground(theme.foregroundGreenBright())
												case 12:
													styleContext = styleContext.foreground(theme.foregroundYellowBright())
												case 13:
													styleContext = styleContext.foreground(theme.foregroundBlueBright())
												case 14:
													styleContext = styleContext.foreground(theme.foregroundMagentaBright())
												case 15:
													styleContext = styleContext.foreground(theme.foregroundCyanBright())
												case 16:
													styleContext = styleContext.foreground(theme.foregroundWhiteBright())
												case code >= 17 && code <= 231:
													styleContext = styleContext.foreground(theme.foregroundWhiteBright())
											}
										}
									}
								}
								case 39:
									styleContext = styleContext.foreground(null)
								case 40:
									styleContext = styleContext.background(theme.backgroundBlack())
								case 41:
									styleContext = styleContext.background(theme.backgroundRed())
								case 42:
									styleContext = styleContext.background(theme.backgroundGreen())
								case 43:
									styleContext = styleContext.background(theme.backgroundYellow())
								case 44:
									styleContext = styleContext.background(theme.backgroundBlue())
								case 45:
									styleContext = styleContext.background(theme.backgroundMagenta())
								case 46:
									styleContext = styleContext.background(theme.backgroundCyan())
								case 47:
									styleContext = styleContext.background(theme.backgroundWhite())
								case 48: {
									switch (Integer.parseInt(array.poll())) {
										case 2:
											styleContext = styleContext.background(Color.rgb(Integer.parseInt(array.poll()), Integer.parseInt(array.poll()), Integer.parseInt(array.poll())))
										case 5: {
											switch (Integer.parseInt(array.poll())) {
												case 0:
													styleContext = styleContext.background(theme.backgroundBlack())
												case 1:
													styleContext = styleContext.background(theme.backgroundRed())
												case 2:
													styleContext = styleContext.background(theme.backgroundGreen())
												case 3:
													styleContext = styleContext.background(theme.backgroundYellow())
												case 4:
													styleContext = styleContext.background(theme.backgroundBlue())
												case 5:
													styleContext = styleContext.background(theme.backgroundMagenta())
												case 6:
													styleContext = styleContext.background(theme.backgroundCyan())
												case 7:
													styleContext = styleContext.background(theme.backgroundWhite())
												case 8:
													styleContext = styleContext.background(theme.backgroundBlackBright())
												case 9:
													styleContext = styleContext.background(theme.backgroundRedBright())
												case 11:
													styleContext = styleContext.background(theme.backgroundGreenBright())
												case 12:
													styleContext = styleContext.background(theme.backgroundYellowBright())
												case 13:
													styleContext = styleContext.background(theme.backgroundBlueBright())
												case 14:
													styleContext = styleContext.background(theme.backgroundMagentaBright())
												case 15:
													styleContext = styleContext.background(theme.backgroundCyanBright())
												case 16:
													styleContext = styleContext.background(theme.backgroundWhiteBright())
											}
										}
									}
								}
								case 49:
									styleContext = styleContext.background(null)
								case 90:
									styleContext = styleContext.foreground(theme.foregroundBlackBright())
								case 91:
									styleContext = styleContext.foreground(theme.foregroundRedBright())
								case 92:
									styleContext = styleContext.foreground(theme.foregroundGreenBright())
								case 93:
									styleContext = styleContext.foreground(theme.foregroundYellowBright())
								case 94:
									styleContext = styleContext.foreground(theme.foregroundBlueBright())
								case 95:
									styleContext = styleContext.foreground(theme.foregroundMagentaBright())
								case 96:
									styleContext = styleContext.foreground(theme.foregroundCyanBright())
								case 97:
									styleContext = styleContext.foreground(theme.foregroundWhiteBright())
								case 100:
									styleContext = styleContext.background(theme.backgroundBlackBright())
								case 101:
									styleContext = styleContext.background(theme.backgroundRedBright())
								case 102:
									styleContext = styleContext.background(theme.backgroundGreenBright())
								case 103:
									styleContext = styleContext.background(theme.backgroundYellowBright())
								case 104:
									styleContext = styleContext.background(theme.backgroundBlueBright())
								case 105:
									styleContext = styleContext.background(theme.backgroundMagentaBright())
								case 106:
									styleContext = styleContext.background(theme.backgroundCyanBright())
								case 107:
									styleContext = styleContext.background(theme.backgroundWhiteBright())
								default:
									throw new RuntimeException("Unknown style " + it + " with params " + params)
							}
						}
					}
//					println("New Context: "+styleContext)
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
				} else if(character.toString().equals("E")) {
					val amount = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					commands.onNext(new CursorNextLine(amount))
				} else if(character.toString().equals("F")) {
					val amount = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					commands.onNext(new CursorPreviousLine(amount))
				} else if(character.toString().equals("G")) {
					val amount = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					commands.onNext(new CursorHorizontalAbsolute(amount))
				} else if(character.toString().equals("H")) {
					val x = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					val y = if(array.size() > 1) Integer.parseInt(array.get(1)) else 1
					commands.onNext(new CursorPosition(x, y))
				} else if(character.toString().equals("K")) {
					val mode = if(array.size() > 0) Integer.parseInt(array.get(0)) else 0
					commands.onNext(new ClearLine(mode))
				} else if(character.toString().equals("H")) {
					val x = if(array.size() > 0) Integer.parseInt(array.get(0)) else 1
					val y = if(array.size() > 1) Integer.parseInt(array.get(1)) else 1
					commands.onNext(new MoveTo(x, y))
				} else if(character.toString().equals("J")) {
					val type = if(array.size() > 0) Integer.parseInt(array.get(0)) else 0
					// TODO scrollback buffer
					commands.onNext(new DeleteText(type))
				} else if(character.toString().equals("h")) {
					if(array.size() > 0 && array.get(0).equals("?1049")) {
						commands.onNext(new AlternateBuffer(true))
					}
				} else if(character.toString().equals("l")) {
					if(array.size() > 0 && array.get(0).equals("?1049")) {
						commands.onNext(new AlternateBuffer(true))
					}
				} else if(character.toString().equals("r")) {
					//TODO
					//Name                  Description                            Esc Code
					//setwin DECSTBM        Set top and bottom line#s of a window  ^[[<v>;<v>r
					commands.onNext(new Focus(Integer.parseInt(array.get(0))))
				} else if(character.toString().equals("d")) {
					commands.onNext(new MoveCaretLeft(Integer.parseInt(array.get(0))))
				} else {
					println("Unknown command " + character + " with params " + params + " " + array)
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
			if(character == BEL as int) {
				val array = params.toString().split(";").filter[!isEmpty()].toList()
				commands.onNext(new OSCommand(array))
				return
			} else {
				params.append(character as char);
			}
		}
	}

	def parseSelectCharacterSetG0(Reader reader) {
		commands.onNext(new SelectCharacterSet(true, reader.read() as char))
	}

	def parseSelectCharacterSetG1(Reader reader) {
		commands.onNext(new SelectCharacterSet(false, reader.read() as char))
	}

	def List<CharModifier> getStyles() {
		return #[new RenderingContext(styleContext)]
	}

	def static aggregate(Observable<List<Command>> obs) {
		obs.flatMap [
			val commands = new ArrayList()
			val chars = new ArrayList<InsertChar>()
			val aggregate = [ List<InsertChar> list |
				val aggregatedCommand = new InsertText(list.map[getCharacter() + ""].join(), list.get(0).getStyles())
				commands.add(aggregatedCommand)
				chars.clear()
			]
			forEach[
				if(it instanceof InsertChar) {
					if(chars.isEmpty()) {
						chars.add(it)
					} else {
						if(chars.get(0).getStyles().equals(getStyles())) {
							chars.add(it)
						} else {
							aggregate.apply(chars)
							chars.add(it)
						}
					}
				} else {
					if(!chars.isEmpty()) {
						aggregate.apply(chars)
					}
					commands.add(it)
				}
			]
			if(!chars.isEmpty()) {
				aggregate.apply(chars)
			}
			return Observable.fromIterable(commands)
		]
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
