package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.theme.ThemeSolarizedDark
import javafx.scene.Scene
import javafx.scene.layout.StackPane
import javafx.stage.Stage
import org.junit.Test
import org.testfx.framework.junit.ApplicationTest
import com.sirolf2009.javafxterminal.command.InsertText
import org.junit.Assert
import javafx.scene.paint.Color
import com.sirolf2009.javafxterminal.command.ClearLine

class TerminalCanvasTest extends ApplicationTest {
	
	var TerminalCanvas terminal
	
	override start(Stage stage) throws Exception {
		terminal = new TerminalCanvas(new ThemeSolarizedDark())
		val stackPane = new StackPane(terminal)
		terminal.widthProperty().bind(stackPane.widthProperty())
		terminal.heightProperty().bind(stackPane.heightProperty())
		val scene = new Scene(stackPane, 800, 600)
		stage.setScene(scene)
		stage.show()
	}
	
	@Test
	def void testHelloWorld() {
		assertCaretAt(0, 0)
		val context = new RenderingContext()
		new InsertText("Hello World!", #[context]).execute(terminal)
		assertTextAt("Hello World!", 0, 0)
		assertCaretAt("Hello World!".length(), 0)
	}
	
	@Test
	def void testRainbow() {
		assertCaretAt(0, 0)
		val context = new RenderingContext()
		new InsertText("R", #[context.foreground(Color.RED)]).execute(terminal)
		new InsertText("a", #[context.foreground(Color.ORANGE)]).execute(terminal)
		new InsertText("i", #[context.foreground(Color.YELLOW)]).execute(terminal)
		new InsertText("n", #[context.foreground(Color.GREEN)]).execute(terminal)
		new InsertText("b", #[context.foreground(Color.BLUE)]).execute(terminal)
		new InsertText("o", #[context.foreground(Color.INDIGO)]).execute(terminal)
		new InsertText("w", #[context.foreground(Color.VIOLET)]).execute(terminal)
		assertTextAt("Rainbow", 0, 0)
		Assert.assertEquals(getRenderingContextAt(0, 0), context.foreground(Color.RED))
		Assert.assertEquals(getRenderingContextAt(1, 0), context.foreground(Color.ORANGE))
		Assert.assertEquals(getRenderingContextAt(2, 0), context.foreground(Color.YELLOW))
		Assert.assertEquals(getRenderingContextAt(3, 0), context.foreground(Color.GREEN))
		Assert.assertEquals(getRenderingContextAt(4, 0), context.foreground(Color.BLUE))
		Assert.assertEquals(getRenderingContextAt(5, 0), context.foreground(Color.INDIGO))
		Assert.assertEquals(getRenderingContextAt(6, 0), context.foreground(Color.VIOLET))
		assertCaretAt("Rainbow".length(), 0)
		terminal.draw()
		Thread.sleep(2000)
	}
	
	@Test
	def void testClearLine() {
		val context = new RenderingContext().foreground(Color.CYAN)
		new InsertText("Hello World!", #[context]).execute(terminal)
		assertTextAt("Hello World!", 0, 0)
		new ClearLine().execute(terminal)
		(0 ..< "Hello World!".length()).forEach[assertTextAt("", it, 0)]
		(0 ..< "Hello World!".length()).forEach[terminal.getStylesGrid().get(0, it)]
	}
	
	def void assertTextAt(String text, int x, int y) {
		text.toCharArray().indexed().forEach[
			Assert.assertEquals('''«text»: check char «getKey()» «getValue()»''', getValue(), terminal.getGrid().get(y,x+getKey()))
		]
	}
	
	def void assertCaretAt(int x, int y) {
		val caretPos = terminal.getCaret().get()
		Assert.assertEquals('''Expecting caret «caretPos» @ («x», «y»)''', caretPos.getX().intValue(), x)
		Assert.assertEquals('''Expecting caret «caretPos» @ («x», «y»)''', caretPos.getY().intValue(), y) 
	}
	
	def RenderingContext getRenderingContextAt(int x, int y) {
		return terminal.getStylesGrid().get(y, x).get(0) as RenderingContext
	}
	
}