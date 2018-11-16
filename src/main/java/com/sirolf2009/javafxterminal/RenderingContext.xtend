package com.sirolf2009.javafxterminal

import java.util.ArrayList
import java.util.function.Consumer
import javafx.scene.canvas.GraphicsContext
import javafx.scene.paint.Color
import javafx.scene.text.Font
import javafx.scene.text.FontPosture
import javafx.scene.text.FontWeight
import org.eclipse.xtend.lib.annotations.EqualsHashCode
import com.sirolf2009.javafxterminal.theme.ITheme

@EqualsHashCode class RenderingContext implements Consumer<GraphicsContext> {

	val ITheme theme
	var FontWeight fontWeight
	var FontPosture fontPosture
	var Color background
	var Color foreground

	new(ITheme theme) {
		this.theme = theme
		background = theme.background()
		foreground = theme.foreground()
	}

	new(RenderingContext r) {
		this.theme = r.theme
		this.fontWeight = r.fontWeight
		this.fontPosture = r.fontPosture
		this.background = r.background
		this.foreground = r.foreground
	}

	override accept(GraphicsContext t) {
		t.setFont(Font.font("Monospaced", fontWeight, fontPosture, -1))
		if(background !== null) {
		}
		if(foreground !== null) {
			t.setFill(foreground)
		}
	}

	@Deprecated
	def copy() {
		return new RenderingContext(this)
	}

	def RenderingContext clear() {
		return new RenderingContext(theme)
	}

	def RenderingContext bold() {
		val ctx = new RenderingContext(this)
		ctx.fontWeight = FontWeight.BOLD
		return ctx
	}

	def RenderingContext thin() {
		val ctx = new RenderingContext(this)
		ctx.fontWeight = FontWeight.THIN
		return ctx
	}

	def RenderingContext italic() {
		val ctx = new RenderingContext(this)
		ctx.fontPosture = FontPosture.ITALIC
		return ctx
	}

	def RenderingContext background(Color color) {
		val ctx = new RenderingContext(this)
		ctx.background = color
		return ctx
	}

	def RenderingContext foreground(Color color) {
		val ctx = new RenderingContext(this)
		ctx.foreground = color
		return ctx
	}

	override toString() {
		val segments = new ArrayList()
		if(fontWeight !== null || fontPosture !== null) segments.add('''Font: «Font.font("Monospaced", fontWeight, fontPosture, -1)»''')
		if(foreground !== null) segments.add('''Foreground: «foreground» «if(foreground == theme.foreground()) "(default)"»''')
		if(background !== null) segments.add('''Background: «background» «if(background == theme.background()) "(default)"»''')
		return '''RenderingContext [«segments.join(", ")»]'''
	}

}
