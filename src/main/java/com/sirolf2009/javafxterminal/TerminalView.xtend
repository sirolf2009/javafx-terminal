package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.ANSIParser.AnsiControlSequence
import java.io.Reader
import java.io.StringReader
import java.nio.file.Files
import java.nio.file.Paths
import java.util.ArrayList
import java.util.Collection
import java.util.HashSet
import java.util.List
import java.util.Set
import java.util.stream.Collectors
import javafx.application.Platform
import org.fxmisc.richtext.CodeArea
import org.fxmisc.richtext.model.StyleSpan
import org.fxmisc.richtext.model.StyleSpans
import org.fxmisc.richtext.model.StyleSpansBuilder
import org.fxmisc.richtext.NavigationActions.SelectionPolicy

class TerminalView extends CodeArea {

	new(Reader reader) {
		getStyleClass().add("terminal")
		setEditable(false)

		new Thread [
			val buffer = new StringBuffer()
			var char = 0
			while((char = reader.read) != -1) {
				buffer.append(char as char)
				val character = char as char
				val parsed = ANSIParser.parse(new StringReader(buffer.toString().replaceAll("\\r", "")))
				Files.write(Paths.get("output"), buffer.toString().split("\n"))
//				Platform.runLater[set(parsed)]
				Platform.runLater[
					replaceChar(character)
				]
			}
			reader.close()
		].start()
	}
	
	def set(ParsedAnsi parsed) {
		set(ANSIStyler.getStyles(parsed))
	}

	def set(StyledAnsi styled) {
		clear()
		appendText(styled.getText())

		try {
			setStyleSpans(0, buildStyles(styled.getStyles()))
			paragraphs.forEach[it,index|
				println(index+": "+getText())
			]
		} catch(Exception e) {
			println(styled.toDebugString())
			throw e
		}
	}

	def solarizedDark() {
		getStylesheets().add(TerminalView.getResource("/solarized_dark.css").toExternalForm())
	}

	def static StyleSpans<Collection<String>> buildStyles(List<StyleSpan<Collection<String>>> styles) {
		val StyleSpansBuilder<Collection<String>> spansBuilder = new StyleSpansBuilder()
		styles.forEach[spansBuilder.add(it)]
		return spansBuilder.create()
	}

	def static getStyles(String text, List<AnsiControlSequence> commands) {
		if(commands.size() > 0) {
			val styles = new HashSet()
			return (#[new StyleSpan<Collection<String>>(new ArrayList(), commands.get(0).getIndex())] + commands.map [
				val length = if(commands.last() == it) {
						text.length() - index
					} else {
						val next = commands.get(commands.indexOf(it) + 1)
						next.index - index
					}
				if(command.toString().equals("m")) {
					if(params.isEmpty()) {
						styles.clear()
					} else {
						params.forEach [
							switch (it) {
								case "0":
									styles.clear()
								case "1":
									styles.add("terminal-bold")
								case "2":
									styles.add("terminal-faint")
								case "3":
									styles.add("terminal-italic")
								case "4":
									styles.add("terminal-underline")
								case "7": {
									val foreground = styles.findFirst[startsWith("terminal-foreground")]
									val background = styles.findFirst[startsWith("terminal-background")]
									styles.removeAll(foreground, background)
									styles.add(foreground.replace("terminal-foreground", "terminal-background"))
									styles.add(background.replace("terminal-background", "terminal-foreground"))
								}
								case "30":
									styles.setForeground("terminal-foreground-black")
								case "31":
									styles.setForeground("terminal-foreground-red")
								case "32":
									styles.setForeground("terminal-foreground-green")
								case "33":
									styles.setForeground("terminal-foreground-yellow")
								case "34":
									styles.setForeground("terminal-foreground-blue")
								case "35":
									styles.setForeground("terminal-foreground-magenta")
								case "36":
									styles.setForeground("terminal-foreground-cyan")
								case "37":
									styles.setForeground("terminal-foreground-white")
								default:
									throw new RuntimeException("Unknown style " + it)
							}
						]
					}
					return new StyleSpan<Collection<String>>(new ArrayList(styles.stream().collect(Collectors.toList())), length)
				} else {
					return null
				}
			]).toList()
		}
		return #[]
	}

	def static setForeground(Set<String> classes, String background) {
		classes.removeAll(classes.filter[startsWith("terminal-foreground")].toList())
		classes.add(background)
	}
	
	def moveCaretLeft(int amount) {
		moveTo(getCaretPosition()-amount)
	}
	
	def moveCaretRight(int amount) {
		moveTo(getCaretPosition()+amount)
	}
	
	def moveCaretUp(int amount) {
		val currentLineDistance = getCaretColumn()
		val targetLineDistance = getParagraph(getCurrentParagraph() - amount).getText().length() - getCaretColumn()
		val inbetweenLinesDistance = (0 ..< amount -1).map[getParagraph(getCurrentParagraph() - it)].map[getText().length()].reduce[a,b|a+b]
		moveCaretLeft(currentLineDistance + targetLineDistance + inbetweenLinesDistance)
	}
	
	def moveCaretDown(int amount) {
		val currentLineDistance = getParagraph(getCurrentParagraph()).getText().length() - getCaretColumn()
		val targetLineDistance = getCaretColumn()
		val inbetweenLinesDistance = (0 ..< amount -1).map[getParagraph(getCurrentParagraph() + it)].map[getText().length()].reduce[a,b|a+b]
		moveCaretRight(currentLineDistance + targetLineDistance + inbetweenLinesDistance)
	}
	
	def replaceChar(Character character) {
		if(getCaretPosition() + 1 > getText().length()) {
			appendText(character.toString())
		}
		moveTo(getCaretPosition())
		moveTo(getCaretPosition() + 1, SelectionPolicy.ADJUST)
		getSelection().replaceText(character.toString())
		moveTo(getCaretPosition())
	}
	
}
