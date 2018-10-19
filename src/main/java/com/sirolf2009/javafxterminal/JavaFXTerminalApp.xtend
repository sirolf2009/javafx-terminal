package com.sirolf2009.javafxterminal

import javafx.application.Application
import javafx.geometry.Orientation
import javafx.scene.Scene
import javafx.scene.control.Button
import javafx.scene.control.ToolBar
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

		val terminal = new Terminal(#["/usr/bin/fish"]) => [
			solarizedDark()
			HBox.setHgrow(it, Priority.ALWAYS)
		] 
		
		val undo = new Button("undo") => [
			onAction = [terminal.undo()]
		]
		
			val toolbar = new ToolBar(undo) => [
			orientation = Orientation.VERTICAL
		]

		root.getChildren().add(toolbar)

		root.getChildren().add(terminal)
		
		val scene = new Scene(root, 1024, 768)

		primaryStage.setScene(scene)
		primaryStage.show()
	}
	
	def static void main(String[] args) {
		launch(args)
	}
	
}