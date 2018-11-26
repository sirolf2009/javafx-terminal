package com.sirolf2009.javafxterminal

import javafx.scene.canvas.GraphicsContext

interface CharModifier {
	
	def void accept(extension TerminalCanvas canvas, extension GraphicsContext g, extension Point point)
	
}