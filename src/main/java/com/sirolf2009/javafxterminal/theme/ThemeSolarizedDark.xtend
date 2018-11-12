package com.sirolf2009.javafxterminal.theme

import javafx.scene.paint.Color
import de.oehme.xtend.contrib.Cached

class ThemeSolarizedDark implements ITheme {
	
	override background() {
		return backgroundBlack()
	}
	
	override foreground() {
		return foregroundWhite()
	}
	
	@Cached
	override Color backgroundBlack() {
		return Color.rgb(0, 43, 54)
	}
	
	@Cached
	override Color backgroundRed() {
		return Color.rgb(220, 50, 47)
	}
	
	@Cached
	override Color backgroundGreen() {
		return Color.rgb(133, 153, 0)
	}
	
	@Cached
	override Color backgroundYellow() {
		return Color.rgb(181, 137, 0)
	}
	
	@Cached
	override Color backgroundBlue() {
		return Color.rgb(38, 139, 210)
	}
	
	@Cached
	override Color backgroundMagenta() {
		return Color.rgb(211, 54, 130)
	}
	
	@Cached
	override Color backgroundCyan() {
		return Color.rgb(42, 161, 152)
	}
	
	@Cached
	override Color backgroundWhite() {
		return Color.rgb(253, 246, 227)
	}
	
}