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
import com.sirolf2009.javafxterminal.theme.ITheme
import io.reactivex.Observable
import io.reactivex.rxjavafx.schedulers.JavaFxScheduler
import io.reactivex.schedulers.Schedulers
import io.reactivex.subjects.PublishSubject
import io.reactivex.subjects.Subject
import java.io.Reader
import java.util.ArrayList
import java.util.List
import java.util.Optional
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import java.util.function.BiPredicate
import java.util.function.Consumer
import javafx.beans.property.SimpleIntegerProperty
import javafx.scene.canvas.GraphicsContext
import javafx.scene.paint.Color
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.Logger
import org.slf4j.LoggerFactory

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

	// http://ascii-table.com/ansi-escape-sequences.php
	// CSI = Control Sequence Introducer
	static val MULTI_CSI = '['.toCharArray().get(0)
	static val SINGLE_CSI = 155 as char

	// OSC = Operating System Command
	static val MULTI_OSC = ']'.toCharArray().get(0)

	val styleContext = new RenderingContext()

	val columns = new SimpleIntegerProperty()
	val rows = new SimpleIntegerProperty()

	val Subject<Command> commands = PublishSubject.create()
	val Observable<Command> aggregatedCommands

	new(Reader reader, ITheme theme) {
		super(theme)
		getStyleClass().add("terminal")

		new Thread [
			val buffer = new StringBuffer()
			var char = 0
			while((char = reader.read) != -1) {
//				println('''read char «char» «CharacterNames.getCharacterName(char)»: «char as char»''')
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
				println('''executing «it»''')
				execute(this)
				println('''done «it»''')
			} catch(Exception e) {
				log.error("Failed to execute "+it, e)
			}
		]
	}

	def parseControlSequence(Reader reader) {
		val params = new StringBuilder()
		var int characterCode
		var char character
		while((characterCode = reader.read()) != -1) {
			character = characterCode as char
			if(characterCode >= 0x40 && characterCode <= 0x7E) {
				val array = params.toString().split(";").filter[!isEmpty()].toList()
				if(character.toString().equals("m")) {
					array.map[Integer.parseInt(it)].forEach [
						switch (it) {
							case 0:
								styleContext.clear()
							case 1:
								styleContext.bold()
							case 2:
								styleContext.thin()
							case 3:
								styleContext.italic()
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
								styleContext.foreground(null).background(null)
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
							case 30:
								styleContext.foreground(theme.foregroundBlack())
							case 31:
								styleContext.foreground(theme.foregroundRed())
							case 32:
								styleContext.foreground(theme.foregroundGreen())
							case 33:
								styleContext.foreground(theme.foregroundYellow())
							case 34:
								styleContext.foreground(theme.foregroundBlue())
							case 35:
								styleContext.foreground(theme.foregroundMagenta())
							case 36:
								styleContext.foreground(theme.foregroundCyan())
							case 37:
								styleContext.foreground(theme.foregroundWhite())
							case 38: {
								if(array.get(0).equals("5")) {
									switch (Integer.parseInt(array.get(1))) {
										case 0:
											styleContext.foreground(theme.foregroundBlack())
										case 1:
											styleContext.foreground(theme.foregroundRed())
										case 2:
											styleContext.foreground(theme.foregroundGreen())
										case 3:
											styleContext.foreground(theme.foregroundYellow())
										case 4:
											styleContext.foreground(theme.foregroundBlue())
										case 5:
											styleContext.foreground(theme.foregroundMagenta())
										case 6:
											styleContext.foreground(theme.foregroundCyan())
										case 7:
											styleContext.foreground(theme.foregroundWhite())
										case 8:
											styleContext.foreground(theme.foregroundBlackBright())
										case 9:
											styleContext.foreground(theme.foregroundRedBright())
										case 11:
											styleContext.foreground(theme.foregroundGreenBright())
										case 12:
											styleContext.foreground(theme.foregroundYellowBright())
										case 13:
											styleContext.foreground(theme.foregroundBlueBright())
										case 14:
											styleContext.foreground(theme.foregroundMagentaBright())
										case 15:
											styleContext.foreground(theme.foregroundCyanBright())
										case 16:
											styleContext.foreground(theme.foregroundWhiteBright())
									}
								} else if(array.get(0).equals("2")) {
									styleContext.foreground(Color.rgb(Integer.parseInt(array.get(1)), Integer.parseInt(array.get(2)), Integer.parseInt(array.get(3))))
								}
							}
							case 39:
								styleContext.foreground(null)
							case 40: 
								styleContext.background(theme.backgroundBlack())
							case 41:
								styleContext.background(theme.backgroundRed())
							case 42:
								styleContext.background(theme.backgroundGreen())
							case 43:
								styleContext.background(theme.backgroundYellow())
							case 44:
								styleContext.background(theme.backgroundBlue())
							case 45:
								styleContext.background(theme.backgroundMagenta())
							case 46:
								styleContext.background(theme.backgroundCyan())
							case 47:
								styleContext.background(theme.backgroundWhite())
								case 48: {
								if(array.get(0).equals("5")) {
									switch (Integer.parseInt(array.get(1))) {
										case 0:
											styleContext.background(theme.backgroundBlack())
										case 1:
											styleContext.background(theme.backgroundRed())
										case 2:
											styleContext.background(theme.backgroundGreen())
										case 3:
											styleContext.background(theme.backgroundYellow())
										case 4:
											styleContext.background(theme.backgroundBlue())
										case 5:
											styleContext.background(theme.backgroundMagenta())
										case 6:
											styleContext.background(theme.backgroundCyan())
										case 7:
											styleContext.background(theme.backgroundWhite())
										case 8:
											styleContext.background(theme.backgroundBlackBright())
										case 9:
											styleContext.background(theme.backgroundRedBright())
										case 11:
											styleContext.background(theme.backgroundGreenBright())
										case 12:
											styleContext.background(theme.backgroundYellowBright())
										case 13:
											styleContext.background(theme.backgroundBlueBright())
										case 14:
											styleContext.background(theme.backgroundMagentaBright())
										case 15:
											styleContext.background(theme.backgroundCyanBright())
										case 16:
											styleContext.background(theme.backgroundWhiteBright())
									}
								} else if(array.get(0).equals("2")) {
									styleContext.background(Color.rgb(Integer.parseInt(array.get(1)), Integer.parseInt(array.get(2)), Integer.parseInt(array.get(3))))
								}
							}
							case 49:
								styleContext.background(null)
							case 90:
								styleContext.foreground(theme.foregroundBlackBright())
							case 91:
								styleContext.foreground(theme.foregroundRedBright())
							case 92:
								styleContext.foreground(theme.foregroundGreenBright())
							case 93:
								styleContext.foreground(theme.foregroundYellowBright())
							case 94:
								styleContext.foreground(theme.foregroundBlueBright())
							case 95:
								styleContext.foreground(theme.foregroundMagentaBright())
							case 96:
								styleContext.foreground(theme.foregroundCyanBright())
							case 97:
								styleContext.foreground(theme.foregroundWhiteBright())
							case 100:
								styleContext.background(theme.backgroundBlackBright())
							case 101:
								styleContext.background(theme.backgroundRedBright())
							case 102:
								styleContext.background(theme.backgroundGreenBright())
							case 103:
								styleContext.background(theme.backgroundYellowBright())
							case 104:
								styleContext.background(theme.backgroundBlueBright())
							case 105:
								styleContext.background(theme.backgroundMagentaBright())
							case 106:
								styleContext.background(theme.backgroundCyanBright())
							case 107:
								styleContext.background(theme.backgroundWhiteBright())
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

	def List<Consumer<GraphicsContext>> getStyles() {
		return #[styleContext.copy()]
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
