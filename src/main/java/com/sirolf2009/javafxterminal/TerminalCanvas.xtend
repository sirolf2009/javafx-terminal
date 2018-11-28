package com.sirolf2009.javafxterminal

import com.google.common.collect.TreeBasedTable
import com.pty4j.WinSize
import com.sirolf2009.javafxterminal.theme.ITheme
import com.sun.javafx.tk.Toolkit
import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import javafx.animation.KeyFrame
import javafx.animation.Timeline
import javafx.beans.property.IntegerProperty
import javafx.beans.property.ObjectProperty
import javafx.beans.property.SimpleIntegerProperty
import javafx.beans.property.SimpleObjectProperty
import javafx.geometry.Point2D
import javafx.geometry.VPos
import javafx.scene.canvas.Canvas
import javafx.scene.paint.Color
import javafx.scene.text.Font
import javafx.util.Duration
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class TerminalCanvas extends Canvas {

	val ITheme theme
	val Buffer buffer
	val IntegerProperty focusedRow = new SimpleIntegerProperty(0)
	val font = Font.font("Monospaced")
	val float charWidth
	val float charHeight
	val ObjectProperty<Point> anchor
	val ObjectProperty<Point> caret

	new(ITheme theme) {
		super(400, 400)
		this.theme = theme
		setFocusTraversable(true)
		buffer = new Buffer()
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
		caret = new SimpleObjectProperty(this, "caret", new Point(0, 0))
	}
	
	def void drawTimeline() {
		val timeline = new Timeline(60)
		timeline.setCycleCount(Timeline.INDEFINITE)
		val kf = new KeyFrame(Duration.millis(16), [ evt |
			draw()
		])
		timeline.getKeyFrames().add(kf)
		timeline.play()
	}

	def void draw() {
		extension val g = getGraphicsContext2D()
		save()
		save()
		setFill(theme.background())
		fillRect(0, 0, getWidth(), getHeight())
		restore()
		setFill(theme.foreground())
		if(!buffer.getGrid().isEmpty()) {
			val lines = getLines()
			val counter = new AtomicInteger()
			(focusedRow.get() .. Math.min(focusedRow.get() + getWinHeight(), lines)).forEach[
				drawLine(it, (counter.getAndIncrement()*charHeight).intValue())
			]
		}
		drawCursor()
		restore()
	}

	def void drawLine(int row, int yPixel) {
		extension val g = getGraphicsContext2D()
		save()
		buffer.getGrid().row(row).entrySet().forEach [
			val x = getKey()
			val char = getValue()
			buffer.getStylesGrid().get(row, x)?.forEach [
				accept(this, g, new Point(x, row))
			]
			fillText(char.toString(), x.columnToScreen(), yPixel)
		]
		restore()
	}
	
	def void drawCursor() {
		extension val g = getGraphicsContext2D()
		save()
		setFill(Color.gray(0.5, System.currentTimeMillis() % 1000 / 500))
		fillText("█", getCurrentColumn().columnToScreen(), getCurrentLine().rowToScreen())
		restore()
	}

	def void newLine() {
		val y = getCurrentLine()
		setText(getRowWidth(y), y, "\n")
		(y + 2 ..< getLines()).toList().reverse().forEach [
			setText(it + 2, getLine(it + 1))
		]
		clearLine(y + 1)
		moveTo(0, y + 1)
	}
	
	def void jumpDown() {
		focus(Math.max(0, getLines()-getWinHeight()))
	}
	
	def void moveFocusUp() {
		moveFocusUp(1)
	}
	
	def void moveFocusUp(int amount) {
		focus(focusedRow.get() + amount)
	}
	
	def void moveFocusDown() {
		moveFocusDown(1)
	}
	
	def void moveFocusDown(int amount) {
		focus(focusedRow.get() - amount)
	}

	def void focus(int row) {
		focusedRow.set(Math.min(row, getLines()))
	}

	def void moveCaretDown() {
		moveCaretDown(1)
	}

	def void moveCaretDown(int amount) {
		moveTo(getCurrentColumn(), getCurrentLine()+amount)
	}

	def void moveCaretLeft() {
		moveCaretLeft(1)
	}

	def void moveCaretLeft(int amount) {
		moveTo(getCurrentColumn() - amount, getCurrentLine())
	}

	def void moveCaretRight() {
		moveCaretRight(1)
	}

	def void moveCaretRight(int amount) {
		moveTo(getCurrentColumn() + amount, getCurrentLine())
	}

	def void moveCaretUp() {
		moveCaretUp(1)
	}

	def void moveCaretUp(int amount) {
		moveTo(getCurrentColumn(), getCurrentLine()-amount)
	}

	def void moveTo(int x, int y) {
		caret.set(new Point(x, y))
	}

	def void deletePreviousChar() {
		clear(getCurrentColumn() -1, getCurrentLine())
		moveCaretLeft()
	}

	def getCurrentLine() {
		return caret.get().getY().intValue()
	}

	def getCurrentColumn() {
		return caret.get().getX().intValue()
	}

	def String getLine(int y) {
		return buffer.getGrid().row(y).values().join()
	}

	def void setLine(int x, int y, String text) {
		clearLine(y)
		setText(x, y, text)
	}

	def insertText(String text, List<CharModifier> styles) {
		val caret = caret.get()
		setText(caret.getX().intValue(), caret.getY().intValue(), text)
		(0 ..< text.length()).forEach[setStyle(caret.getX().intValue()+it, caret.getY().intValue(), styles)]
		moveCaretRight(text.length())
	}
	
	def String getGridString() {
		return buffer.getGrid().toGridString()
	}

	def String toGridString(TreeBasedTable<Integer, Integer, Character> grid) {
		if(grid.isEmpty()) {
			return "< EMPTY >"
		}
		val width = grid.rowMap().values().map[size()].max()
		val height = getLineCount()
		val charsPerColumn = Math.max(width.toString().length(), height.toString().length()) + 1
		val addPadding = [ String string |
			val padding = (0 ..< charsPerColumn - string.length()).map[" "].join()
			return padding + string
		]
		val topRow = addPadding.apply("") + (0 ..< width).map[addPadding.apply(toString())].join()
		val chars = (0 ..< height).map [ y |
			addPadding.apply(y.toString()) + (0 ..< grid.row(y).size()).map [ x |
				val character = String.valueOf(grid.get(y, x))
				if(character.equals("")) {
					addPadding.apply(character).substring(1)
				} else {
					val realCharacter = if(character.equals("\n"))
							"↵"
						else if(character.equals("null"))
							"\\0"
						else
							character
					addPadding.apply(realCharacter)
				}
			].join()
		].join("\n")
		return topRow + "\n" + chars
	}

	def insertText(String text) {
		val caret = caret.get()
		setText(caret.getX().intValue(), caret.getY().intValue(), text)
		moveCaretRight(text.length())
	}

	def insertStyles(List<CharModifier> styles) {
		val caret = caret.get()
		setStyle(caret.getX().intValue(), caret.getY().intValue(), styles)
		val newLoc = new Point2D(caret.getX().intValue() + 1, caret.getY().intValue())
		moveCaretRight(1)
		return newLoc
	}

	def void setText(int x, int y, String text) {
		//TODO support word wrapping
//		if(x < 0) {
//			throw new IllegalArgumentException('''Cannot set text «text» at negative indeces («x», «y»)''')
//		} else if(x+text.length() > getWinWidth()) {
//			throw new IllegalArgumentException('''Cannot set text «text» @ («x», «y»)-(«x+text.length()», «y») outside the screen width «getWinWidth()»''')
//		}
		text.toCharArray().forEach [ it, index |
			buffer.getGrid().put(y, x + index, it)
		]
	}

	def void setStyle(int x, int y, List<CharModifier> stylesList) {
		//TODO support word wrapping
//		if(x < 0) {
//			throw new IllegalArgumentException('''Cannot set styles «stylesList» at negative indeces («x», «y»)''')
//		} else if(x > getWinWidth()) {
//			throw new IllegalArgumentException('''Cannot set styles «stylesList» outside the screen («x», «y»)''')
//		}
		buffer.getStylesGrid().put(y, x, stylesList)
	}

	def void clearLine() {
		clearLine(caret.getValue().getY().intValue())
	}

	def void clearLine(int y) {
		buffer.getGrid().row(y).keySet().sort().toList().forEach[x|clear(x, y)]
	}

	def void clear(int xFrom, int xTo, int y) {
		(xFrom ..< xTo).forEach[x|clear(x, y)]
	}

	def void clear(int x, int y) {
		buffer.getGrid().remove(y, x)
	}

	def void clear() {
		buffer.getGrid().clear()
	}
	
	def getRowWidth(int row) {
		return buffer.getGrid().row(row).size()
	}
	
	def int getLines() {
		return buffer.getGrid().rowKeySet().last()
	}

	def rowToScreen(int row) {
		return (row * charHeight) - (focusedRow.get()*charHeight)
	}

	def columnToScreen(int column) {
		return column * charWidth
	}
	
	def getLineCount() {
		buffer.getGrid().rowKeySet().last() + 1
	}

	def getWinSize() {
		return new WinSize(getWinWidth(), getWinHeight(), getWidth().intValue(), getHeight().intValue())
	}

	def getWinWidth() {
		return Math.floor(getWidth() / charWidth) as int
	}

	def getWinHeight() {
		return Math.floor(getHeight() / charHeight) as int
	}

}
