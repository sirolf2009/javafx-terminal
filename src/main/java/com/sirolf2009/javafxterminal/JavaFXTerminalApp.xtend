package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.command.Command
import io.reactivex.rxjavafx.schedulers.JavaFxScheduler
import java.util.Date
import javafx.application.Application
import javafx.scene.Scene
import javafx.scene.control.ContextMenu
import javafx.scene.control.ListCell
import javafx.scene.control.ListView
import javafx.scene.control.MenuItem
import javafx.scene.layout.HBox
import javafx.scene.layout.Priority
import javafx.stage.Stage
import javafx.stage.StageStyle

class JavaFXTerminalApp extends Application {

	override start(Stage primaryStage) throws Exception {
		val terminal = new Terminal(#["/usr/bin/fish"]) => [
			solarizedDark()
			HBox.setHgrow(it, Priority.ALWAYS)
		]

		val newStage = new Stage(StageStyle.UTILITY)
		val aggregatedCommands = createCommandListview(terminal)
		terminal.aggregatedCommands.observeOn(JavaFxScheduler.platform()).subscribe [
			aggregatedCommands.getItems().add(it)
		]
		val commands = createCommandListview(terminal)
		terminal.commands.observeOn(JavaFxScheduler.platform()).subscribe [
			commands.getItems().add(it)
		]
		newStage.setScene(new Scene(new HBox(aggregatedCommands, commands)))
		newStage.show()

		val scene = new Scene(terminal, 1024, 768)

		primaryStage.setScene(scene)
		primaryStage.show()
	}

	def static createCommandListview(Terminal terminal) {
		new ListView<Command>() => [
			cellFactory = [
				return new ListCell<Command>() {

					override protected updateItem(Command item, boolean empty) {
						super.updateItem(item, empty)
						if(item === null || empty) {
							setText("")
						} else {
							setText(new Date()+" "+ item.toString())
						}
					}

				} => [ cell |
					cell.setContextMenu(new ContextMenu() => [
						getItems().add(new MenuItem("Re execute") => [
							onAction = [
								terminal.commands.onNext(cell.getItem())
							]
						])
					])
				]
			]
		]
	}

	def static void main(String[] args) {
		launch(args)
	}

}
