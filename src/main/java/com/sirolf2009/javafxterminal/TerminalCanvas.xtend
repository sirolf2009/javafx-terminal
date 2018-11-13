package com.sirolf2009.javafxterminal

import com.google.common.collect.HashBasedTable
import com.google.common.collect.TreeBasedTable
import com.pty4j.WinSize
import com.sun.javafx.tk.Toolkit
import java.util.List
import java.util.function.Consumer
import javafx.animation.KeyFrame
import javafx.animation.Timeline
import javafx.beans.property.IntegerProperty
import javafx.beans.property.ObjectProperty
import javafx.beans.property.SimpleIntegerProperty
import javafx.beans.property.SimpleObjectProperty
import javafx.geometry.Point2D
import javafx.geometry.VPos
import javafx.scene.canvas.Canvas
import javafx.scene.canvas.GraphicsContext
import javafx.scene.paint.Color
import javafx.scene.text.Font
import javafx.util.Duration
import com.sirolf2009.javafxterminal.theme.ITheme
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors class TerminalCanvas extends Canvas {

	val ITheme theme
	val TreeBasedTable<Integer, Integer, Character> grid
	val HashBasedTable<Integer, Integer, List<Consumer<GraphicsContext>>> stylesGrid
	val IntegerProperty focusedRow = new SimpleIntegerProperty(0)
	val font = Font.font("Monospaced")
	val float charWidth
	val float charHeight
	val ObjectProperty<Point2D> anchor
	val ObjectProperty<Point2D> caret

	new(ITheme theme) {
		super(400, 400)
		this.theme = theme
		setFocusTraversable(true)
		grid = TreeBasedTable.create()
		stylesGrid = HashBasedTable.create()
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
		caret = new SimpleObjectProperty(this, "caret", new Point2D(0, 0))
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
		setStroke(theme.foreground())
		if(!grid.isEmpty()) {
			val lines = grid.rowKeySet().last()
			(focusedRow.get() .. Math.min(focusedRow.get() + getWinHeight(), lines)).forEach[drawLine(it)]
		}
		drawCursor()
		restore()
	}

	def void drawLine(int y) {
		extension val g = getGraphicsContext2D()
		save()
		grid.row(y).entrySet().forEach [
			val x = getKey()
			val char = getValue()
			stylesGrid.get(y, x)?.forEach [
				accept(g)
			]
			strokeText(char.toString(), x.columnToScreen(), y.rowToScreen())
		]
		restore()
	}
	
	def void drawCursor() {
		extension val g = getGraphicsContext2D()
		save()
		setFill(Color.gray(0.5, System.currentTimeMillis() % 1000 / 500))
		val pos = caret.get()
		fillText("█", pos.getX().intValue().columnToScreen(), pos.getY().intValue().rowToScreen())
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
		setText(grid.row(y).lastKey() + 1, y, "\n")
		(y + 2 ..< getLines()).toList().reverse().forEach [
			setText(it + 2, getLine(it + 1))
		]
		clearLine(y + 1)
		moveTo(0, y + 1)
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
		moveCaretLeft()
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
		val newLoc = new Point2D(caret.getX().intValue() + text.length(), caret.getY().intValue())
		this.caret.set(newLoc)
		return newLoc
	}
	
	def String getGridString() {
		return grid.toGridString()
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
		val newLoc = new Point2D(caret.getX().intValue() + text.length(), caret.getY().intValue())
		this.caret.set(newLoc)
		return newLoc
	}

	def insertStyles(List<Consumer<GraphicsContext>> styles) {
		val caret = caret.get()
		setStyle(caret.getX().intValue(), caret.getY().intValue(), styles)
		val newLoc = new Point2D(caret.getX().intValue() + 1, caret.getY().intValue())
		this.caret.set(newLoc)
		return newLoc
	}

	def void setText(int x, int y, String text) {
		if(x < 0) {
			throw new IllegalArgumentException('''Cannot set text «text» at negative indeces («x», «y»)''')
		} else if(x+text.length() > getWinWidth()) {
			throw new IllegalArgumentException('''Cannot set text «text» @ («x», «y»)-(«x+text.length()», «y») outside the screen width «getWinWidth()»''')
		}
		text.toCharArray().forEach [ it, index |
			grid.put(y, x + index, it)
		]
	}

	def void setStyle(int x, int y, List<Consumer<GraphicsContext>> stylesList) {
		if(x < 0) {
			throw new IllegalArgumentException('''Cannot set styles «stylesList» at negative indeces («x», «y»)''')
		} else if(x > getWinWidth()) {
			throw new IllegalArgumentException('''Cannot set styles «stylesList» outside the screen («x», «y»)''')
		}
		stylesGrid.put(y, x, stylesList)
	}

	def void clearLine() {
		clearLine(caret.getValue().getY().intValue())
	}

	def void clearLine(int y) {
		grid.row(y).keySet().sort().toList().forEach[x|clear(x, y)]
	}

	def void clear(int xFrom, int xTo, int y) {
		(xFrom ..< xTo).forEach[x|clear(x, y)]
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
	
	def getLineCount() {
		grid.rowKeySet().last() + 1
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
