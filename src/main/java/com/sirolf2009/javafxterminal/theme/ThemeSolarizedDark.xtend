package com.sirolf2009.javafxterminal.theme

import de.oehme.xtend.contrib.Cached
import java.util.List
import javafx.scene.paint.Color

class ThemeSolarizedDark implements ITheme {

	val List<Color> color256 = buildColors256()

	override background() {
		return backgroundBlack()
	}

	override foreground() {
		return foregroundBlack()
	}

	override foregroundBlack() {
		return Color.rgb(253, 246, 227)
	}

	override get256Color(int color) {
		color256.get(color)
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

	def static buildColors256() {
		(0 ..< 6).flatMap [ red |
			(0 ..< 6).flatMap [ green |
				(0 ..< 6).map [blue|
					val code = 36 * red + 6 * green + blue
					val color = Color.rgb(
						if(red > 0) 40 * red + 55 else 0,
						if(green > 0) 40 * green + 55 else 0,
						if(blue > 0) 40 * blue + 55 else 0
					)
					code -> color
				]
			]
		].toList().sortBy[getKey()].map[getValue()]
	}

}
