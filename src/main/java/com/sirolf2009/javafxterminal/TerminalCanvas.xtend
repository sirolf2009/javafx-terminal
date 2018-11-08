package com.sirolf2009.javafxterminal

import com.google.common.collect.HashBasedTable
import com.google.common.collect.TreeBasedTable
import com.pty4j.WinSize
import com.sun.javafx.tk.Toolkit
import java.util.List
import java.util.function.Consumer
import javafx.beans.property.ObjectProperty
import javafx.beans.property.SimpleObjectProperty
import javafx.geometry.Point2D
import javafx.geometry.VPos
import javafx.scene.canvas.Canvas
import javafx.scene.canvas.GraphicsContext
import javafx.scene.paint.Color
import javafx.scene.text.Font
import javafx.beans.property.IntegerProperty
import javafx.beans.property.SimpleIntegerProperty

class TerminalCanvas extends Canvas {

	val TreeBasedTable<Integer, Integer, Character> grid
	val HashBasedTable<Integer, Integer, List<Consumer<GraphicsContext>>> styles
	val IntegerProperty focusedRow = new SimpleIntegerProperty(0)
	val font = Font.font("Monospaced")
	val float charWidth
	val float charHeight
	val ObjectProperty<Point2D> anchor
	val ObjectProperty<Point2D> caret

	new() {
		super(400, 400)
		grid = TreeBasedTable.create()
		styles = HashBasedTable.create()
		getGraphicsContext2D() => [
			setFont(font)
			setLineWidth(1.0)
			setFill(Color.BLACK)
			setTextBaseline(VPos.TOP)
		]
		val metrics = Toolkit.getToolkit().getFontLoader().getFontMetrics(font)
		charWidth = metrics.computeStringWidth("a")
		charHeight = metrics.getLineHeight()
		anchor = new SimpleObjectProperty(this, "anchor")
		caret = new SimpleObjectProperty(this, "caret")
	}

	def void draw() {
		extension val g = getGraphicsContext2D()
		save()
		val lines = grid.rowKeySet().last()
		(focusedRow.get() .. Math.min(focusedRow.get()+getWinHeight(), lines)).forEach [ drawLine(it) ]
		restore()
	}

	def void drawLine(int y) {
		extension val g = getGraphicsContext2D()
		save()
		clearRect(0, y.rowToScreen(), getWidth(), (y + 1).rowToScreen())
		grid.row(y).entrySet().forEach [
			val x = getKey()
			val char = getValue()
			styles.get(y, x)?.forEach [
				accept(g)
			]
			strokeText(char.toString(), x.columnToScreen(), y.rowToScreen())
		]
		restore()
	}
	
	def void focus(int row) {
		focusedRow.set(row)
	}
	
	def int getLines() {
		return grid.rowKeySet().last()
	}
	
	def void newLine() {
		val y = caret.get().getY().intValue()
		setText(grid.row(y).lastKey()+1, y, "\n")
		(y+2 ..< getLines()).toList().reverse().forEach[
			setText(it+2, getLine(it+1))
		]
		clearLine(y+1)
		moveTo(0, y+1)
	}
	
	def void moveCaretDown() {
		moveCaretDown(1)
	}
	
	def void moveCaretDown(int amount) {
		caret.set(new Point2D(caret.get().getX().intValue(), caret.get().getY().intValue() + amount))
	}
	
	def void moveCaretLeft() {
		moveCaretLeft(1)
	}
	
	def void moveCaretLeft(int amount) {
		caret.set(new Point2D(caret.get().getX().intValue() - amount, caret.get().getY().intValue()))
	}
	
	def void moveCaretRight() {
		moveCaretRight(1)
	}
	
	def void moveCaretRight(int amount) {
		caret.set(new Point2D(caret.get().getX().intValue() + amount, caret.get().getY().intValue()))
	}
	
	def void moveCaretUp() {
		moveCaretUp(1)
	}
	
	def void moveCaretUp(int amount) {
		caret.set(new Point2D(caret.get().getX().intValue(), caret.get().getY().intValue() - amount))
	}
	
	def void moveTo(int x, int y) {
		caret.set(new Point2D(x, y))
	}
	
	def void deletePreviousChar() {
		val caret = caret.getValue()
		clear(caret.getX().intValue() - 1, caret.getY().intValue())
	}
	
	def getCurrentLine() {
		return caret.get().getY().intValue()
	}
	
	def getCurrentColumn() {
		return caret.get().getX().intValue()
	}
	
	def String getLine(int y) {
		return grid.row(y).values().join()
	}

	def void setLine(int x, int y, String text) {
		clearLine(y)
		setText(x, y, text)
	}

	def insertText(String text, List<Consumer<GraphicsContext>> styles) {
		val caret = caret.get()
		setText(caret.getX().intValue(), caret.getY().intValue(), text)
		setStyle(caret.getX().intValue(), caret.getY().intValue(), styles)
		val newLoc = new Point2D(caret.getX().intValue()+text.length(), caret.getY().intValue())
		this.caret.set(newLoc)
		return newLoc
	}

	def insertText(String text) {
		val caret = caret.get()
		setText(caret.getX().intValue(), caret.getY().intValue(), text)
		val newLoc = new Point2D(caret.getX().intValue()+text.length(), caret.getY().intValue())
		this.caret.set(newLoc)
		return newLoc
	}

	def insertStyles(List<Consumer<GraphicsContext>> styles) {
		val caret = caret.get()
		setStyle(caret.getX().intValue(), caret.getY().intValue(), styles)
		val newLoc = new Point2D(caret.getX().intValue()+1, caret.getY().intValue())
		this.caret.set(newLoc)
		return newLoc
	}

	def void setText(int x, int y, String text) {
		text.toCharArray().forEach [ it, index |
			grid.put(y, x + index, it)
		]
	}

	def void setStyle(int x, int y, List<Consumer<GraphicsContext>> stylesList) {
		styles.put(y, x, stylesList)
	}

	def void clearLine() {
		clearLine(caret.getValue().getY().intValue())
	}

	def void clearLine(int y) {
		grid.row(y).values().forEach[x|clear(x, y)]
	}

	def void clear(int xFrom, int xTo, int y) {
		(xFrom ..< xTo).forEach[x| clear(x, y)]
	}

	def void clear(int x, int y) {
		grid.remove(y, x)
	}
	
	def void clear() {
		grid.clear()
	}

	def getRowWidth(int row) {
		grid.row(row).size()
	}

	def rowToScreen(int row) {
		return row * charHeight
	}

	def columnToScreen(int column) {
		return column * charWidth
	}

	def getWinSize() {
		return new WinSize(getWinWidth(), getWinHeight())
	}

	def getWinWidth() {
		return Math.floor(getWidth() / charWidth) as int
	}

	def getWinHeight() {
		return Math.floor(getHeight() / charHeight) as int
	}

}
