package com.sirolf2009.javafxterminal.theme

import javafx.scene.paint.Color

interface ITheme {
	
	def Color background()
	def Color foreground()
	
	def Color backgroundBlack()
	def Color backgroundRed()
	def Color backgroundGreen()
	def Color backgroundYellow()
	def Color backgroundBlue()
	def Color backgroundMagenta()
	def Color backgroundCyan()
	def Color backgroundWhite()
	
	def Color backgroundBlackBright() {
		return backgroundBlack().brighter()
	}
	def Color backgroundRedBright() {
		return backgroundRed().brighter()
	}
	def Color backgroundGreenBright() {
		return backgroundGreen().brighter()
	}
	def Color backgroundYellowBright() {
		return backgroundYellow().brighter()
	}
	def Color backgroundBlueBright() {
		return backgroundBlue().brighter()
	}
	def Color backgroundMagentaBright() {
		return backgroundMagenta().brighter()
	}
	def Color backgroundCyanBright() {
		return backgroundCyan().brighter()
	}
	def Color backgroundWhiteBright() {
		return backgroundWhite().brighter()
	}
	
	
	def Color foregroundBlack() {
		return backgroundBlack()
	}
	def Color foregroundRed() {
		return backgroundRed()
	}
	def Color foregroundGreen() {
		return backgroundGreen()
	}
	def Color foregroundYellow() {
		return backgroundYellow()
	}
	def Color foregroundBlue() {
		return backgroundBlue()
	}
	def Color foregroundMagenta() {
		return backgroundMagenta()
	}
	def Color foregroundCyan() {
		return backgroundCyan()
	}
	def Color foregroundWhite() {
		return backgroundWhite()
	}
	
	def Color foregroundBlackBright() {
		return foregroundBlack().brighter()
	}
	def Color foregroundRedBright() {
		return foregroundRed().brighter()
	}
	def Color foregroundGreenBright() {
		return foregroundGreen().brighter()
	}
	def Color foregroundYellowBright() {
		return foregroundYellow().brighter()
	}
	def Color foregroundBlueBright() {
		return foregroundBlue().brighter()
	}
	def Color foregroundMagentaBright() {
		return foregroundMagenta().brighter()
	}
	def Color foregroundCyanBright() {
		return foregroundCyan().brighter()
	}
	def Color foregroundWhiteBright() {
		return foregroundWhite().brighter()
	}
	
}