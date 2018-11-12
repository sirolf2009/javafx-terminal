package com.sirolf2009.javafxterminal

import java.util.ArrayList
import java.util.function.Consumer
import javafx.scene.canvas.GraphicsContext
import javafx.scene.paint.Color
import javafx.scene.text.Font
import javafx.scene.text.FontPosture
import javafx.scene.text.FontWeight
import org.eclipse.xtend.lib.annotations.EqualsHashCode

@EqualsHashCode class RenderingContext implements Consumer<GraphicsContext> {

	var FontWeight fontWeight
	var FontPosture fontPosture
	var Color background
	var Color foreground

	new() {
	}

	new(RenderingContext r) {
		this.fontWeight = r.fontWeight
		this.fontPosture = r.fontPosture
		this.background = r.background
		this.foreground = r.foreground
	}

	override accept(GraphicsContext t) {
		if(fontWeight !== null || fontPosture !== null) {
			t.setFont(Font.font("Monospaced", fontWeight, fontPosture, -1))
		}
		if(background !== null) {
		}
		if(foreground !== null) {
			t.setStroke(foreground)
		}
	}

	def copy() {
		return new RenderingContext(this)
	}

	def void clear() {
		fontWeight = null
		fontPosture = null
		background = null
		foreground = null
	}

	def RenderingContext bold() {
		fontWeight = FontWeight.BOLD
		return this
	}

	def RenderingContext thin() {
		fontWeight = FontWeight.THIN
		return this
	}

	def RenderingContext italic() {
		fontPosture = FontPosture.ITALIC
		return this
	}

	def RenderingContext background(Color color) {
		background = color
		return this
	}

	def RenderingContext foreground(Color color) {
		foreground = color
		return this
	}

	override toString() {
		val segments = new ArrayList()
		if(fontWeight !== null || fontPosture !== null) segments.add('''Font: «Font.font("Monospaced", fontWeight, fontPosture, -1)»''')
		if(foreground !== null) segments.add('''Foreground: «foreground»''')
		if(background !== null) segments.add('''Background: «background»''')
		return '''RenderingContext [«segments.join(", ")»]'''
	}

}
