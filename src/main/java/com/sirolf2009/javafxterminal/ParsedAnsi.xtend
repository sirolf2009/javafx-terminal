package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.ANSIParser.AnsiCode
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import java.text.DecimalFormat

@Data class ParsedAnsi {

	val String text
	val List<? extends AnsiCode> ansiCodes

	def toDebugString() {
		val buffer = new StringBuffer()
		val cellWidth = text.length().toString().toCharArray().size()
		val decimalFormat = new DecimalFormat((0 ..< cellWidth).map["0"].join())
		buffer.append((0 ..< text.length()).map[decimalFormat.format(it) + ""].toList() + "\n")
		buffer.append(text.toCharArray().map [
			if(it.equals('\n'.charAt(0))) {
				spaces(cellWidth - 2) + "\\n"
			} else if(it.equals('\r'.charAt(0))) {
				spaces(cellWidth - 2) + "\\r"
			} else {
				spaces(cellWidth - 1) + it
			}
		].toList() + "\n")
		buffer.append((0 ..< text.length()).map [
			val ansiCode = ansiCodes.findFirst[code|code.getIndex() == it]
			if(ansiCode !== null) appendSpaces(cellWidth, ansiCode.getIndex()) else spaces(cellWidth)
		].toList() + "\n")
		buffer.append(ansiCodes.map [
			getIndex() + " " + getParams()
		].join("\n"))
		return buffer.toString()
	}

	def appendSpaces(int expectedCharacterCount, Object object) {
		return appendSpaces(expectedCharacterCount, object.toString())
	}

	def appendSpaces(int expectedCharacterCount, String text) {
		return spaces(expectedCharacterCount - text.length()) + text
	}

	def spaces(int count) {
		return (0 ..< count).map[" "].join()
	}

}
