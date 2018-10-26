package com.sirolf2009.javafxterminal

class CharacterNames {
	//https://www.w3schools.com/charsets/ref_utf_basic_latin.asp
	static val characterNames = #{
		0 -> "Null character",
		1 -> "Start of header",
		2   -> "start of text",
		3   -> "end of text",
		4   -> "end of transmission",
		5   -> "enquiry",
		6   -> "acknowledge",
		7   -> "bell (ring)",
		8   -> "backspace",
		9   -> "horizontal tab",
		10  -> "line feed",
		11  -> "vertical tab",
		12  -> "form feed",
		13  -> "carriage return",
		14  -> "shift out",
		15  -> "shift in",
		16  -> "data link escape",
		17  -> "device control 1",
		18  -> "device control 2",
		19  -> "device control 3",
		20  -> "device control 4" ,
		21  -> "negative acknowledge",
		22  -> "synchronize",
		23  -> "end transmission block",
		24  -> "cancel",
		25  -> "end of medium",
		26  -> "substitute",
		27  -> "escape",
		28  -> "file separator",
		29  -> "group separator",
		30  -> "record separator",
		31  -> "unit separator",
		32  -> "space",
		127 -> "delete (rubout)"
	}
	
	def static getCharacterName(int character) {
		return characterNames.get(character)
	}
	
	def static getCharacterName(char character) {
		return characterNames.get(character as int)
	}
	
}