package com.sirolf2009.javafxterminal

import io.reactivex.rxjavafx.schedulers.JavaFxScheduler
import javafx.application.Application
import javafx.scene.Scene
import javafx.scene.control.ListView
import javafx.scene.layout.HBox
import javafx.scene.layout.Priority
import javafx.stage.Stage
import javafx.stage.StageStyle

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

		root.getChildren().add(terminal)

		val scene = new Scene(root, 1024, 768)

		primaryStage.setScene(scene)
		primaryStage.show()
		
		val newStage = new Stage(StageStyle.UTILITY)
		val commands = new ListView()
		terminal.commands.observeOn(JavaFxScheduler.platform()).subscribe [
			commands.getItems().add(it)
		]
		newStage.setScene(new Scene(commands))
		newStage.show()
	}

	def static void main(String[] args) {
		launch(args)
	}

}
