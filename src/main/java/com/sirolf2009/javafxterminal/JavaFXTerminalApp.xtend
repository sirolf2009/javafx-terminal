package com.sirolf2009.javafxterminal

import javafx.application.Application
import javafx.scene.Scene
import javafx.scene.layout.HBox
import javafx.scene.layout.Priority
import javafx.stage.Stage

class JavaFXTerminalApp extends Application {
	
	override start(Stage primaryStage) throws Exception {
		val root = new HBox()
//		root.getChildren().add(new TerminalView(new BufferedReader(new StringReader("\u001B[36mTerminal View\u001B[0m"))) => [
//			solarizedDark()
//			HBox.setHgrow(it, Priority.ALWAYS)
//		])
		root.getChildren().add(new Terminal(#["/bin/bash"]) => [
			solarizedDark()
			HBox.setHgrow(it, Priority.ALWAYS)
		])
		
		val scene = new Scene(root, 1024, 768)

		primaryStage.setScene(scene)
		primaryStage.show()
	}
	
	def static void main(String[] args) {
		launch(args)
	}
	
}