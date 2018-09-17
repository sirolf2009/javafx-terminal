package com.sirolf2009.javafxterminal

import java.util.Collection
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import org.fxmisc.richtext.model.StyleSpan

@Data class StyledAnsi extends ParsedAnsi {

	val List<StyleSpan<Collection<String>>> styles

	override toDebugString() {
		val superString = super.toDebugString()
		styles.forEach[println(it)]
		val stylesLength = styles.map[getLength()].reduce[a,b|a+b]
		return superString+"\n"+"Length: "+stylesLength
	}

}
