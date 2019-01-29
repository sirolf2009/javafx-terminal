package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.theme.ThemeSolarizedDark
import java.io.StringReader
import javafx.scene.Scene
import javafx.scene.layout.StackPane
import javafx.stage.Stage
import org.junit.Assert
import org.junit.Test
import org.testfx.framework.junit.ApplicationTest

class TerminalViewTest extends ApplicationTest {
	
	var TerminalCanvas terminal
	
	override start(Stage stage) throws Exception {
		terminal = new TerminalView(new StringReader("\u001B[31mHello World\u001B[0m"), new ThemeSolarizedDark())
		val stackPane = new StackPane(terminal)
		terminal.widthProperty().bind(stackPane.widthProperty())
		terminal.heightProperty().bind(stackPane.heightProperty())
		val scene = new Scene(stackPane, 800, 600)
		stage.setScene(scene)
		stage.show()
	}
	
	@Test
	def void testHelloWorld() {
		assertTextAt("Hello World", 0, 0)
		Assert.assertEquals(new ThemeSolarizedDark().foregroundRed(), getRenderingContextAt(0, 0).getForeground())
		Thread.sleep(2000)
	}
	
	def void assertTextAt(String text, int x, int y) {
		text.toCharArray().indexed().forEach[
			Assert.assertEquals('''«text»: check char «getKey()» «getValue()»''', getValue(), terminal.getBuffer().getGrid().get(y,x+getKey()))
		]
	}
	
	def RenderingContext getRenderingContextAt(int x, int y) {
		return terminal.getBuffer().getStylesGrid().get(y, x).get(0) as RenderingContext
	}
	
}