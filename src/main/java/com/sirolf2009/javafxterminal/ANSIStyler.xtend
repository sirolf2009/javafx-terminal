package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.ANSIParser.AnsiControlSequence
import java.util.ArrayList
import java.util.Collection
import java.util.HashSet
import java.util.List
import java.util.Set
import java.util.stream.Collectors
import org.fxmisc.richtext.model.StyleSpan
import org.fxmisc.richtext.model.StyleSpans
import org.fxmisc.richtext.model.StyleSpansBuilder

class ANSIStyler {

	def static StyleSpans<Collection<String>> buildStyles(List<StyleSpan<Collection<String>>> styles) {
		val StyleSpansBuilder<Collection<String>> spansBuilder = new StyleSpansBuilder()
		styles.forEach[spansBuilder.add(it)]
		return spansBuilder.create()
	}

	def static getStyles(ParsedAnsi parsedAnsi) {
		return getStyles(parsedAnsi.getText(), parsedAnsi.getAnsiCodes().filter[it instanceof AnsiControlSequence].map[it as AnsiControlSequence].toList())
	}

	def static getStyles(String text, List<AnsiControlSequence> commands) {
		if(commands.size() > 0) {
			val styles = new HashSet()
			val formattedStyles = (#[new StyleSpan<Collection<String>>(new ArrayList(), commands.get(0).getIndex())] + commands.map [
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
								case "10": {
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
									println("Unknown style " + it)
							}
						]
					}
					return new StyleSpan<Collection<String>>(new ArrayList(styles.stream().collect(Collectors.toList())), length)
				} else {
					return null
				}
			]).toList()
			return new StyledAnsi(text, commands, formattedStyles)
		}
		return new StyledAnsi(text, commands, #[new StyleSpan<Collection<String>>(#[], text.length())])
	}

	def static setForeground(Set<String> classes, String background) {
		classes.removeAll(classes.filter[startsWith("terminal-foreground")].toList())
		classes.add(background)
	}
	
}