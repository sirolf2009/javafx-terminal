package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.command.Command
import com.sirolf2009.javafxterminal.theme.ThemeSolarizedDark
import io.reactivex.rxjavafx.schedulers.JavaFxScheduler
import java.util.Date
import javafx.animation.KeyFrame
import javafx.animation.Timeline
import javafx.application.Application
import javafx.scene.Scene
import javafx.scene.control.ContextMenu
import javafx.scene.control.Label
import javafx.scene.control.ListCell
import javafx.scene.control.ListView
import javafx.scene.control.MenuItem
import javafx.scene.control.Tab
import javafx.scene.control.TabPane
import javafx.scene.layout.AnchorPane
import javafx.scene.layout.GridPane
import javafx.scene.layout.HBox
import javafx.scene.layout.Priority
import javafx.stage.Stage
import javafx.stage.StageStyle
import javafx.util.Duration

class JavaFXTerminalApp extends Application {

	override start(Stage primaryStage) throws Exception {
		val terminal = new Terminal(#["/usr/bin/fish"], new ThemeSolarizedDark()) => [
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
		val grid = createGrid(terminal)
		newStage.setScene(new Scene(new TabPane(
			new Tab("Commands", new HBox(aggregatedCommands, commands)),
			new Tab("Grid", grid)
		)))
		newStage.show()
		val parent = new AnchorPane(terminal)
		terminal.widthProperty().bind(parent.widthProperty())
		terminal.heightProperty().bind(parent.heightProperty())
		val scene = new Scene(parent, 1024, 768)

		primaryStage.setScene(scene)
		primaryStage.show()

		terminal.getProcess().setWinSize(terminal.getWinSize())

		new Thread [
			Thread.sleep(1000)
			println(terminal.getGridString())
		].start()
	}

	def static createCommandListview(Terminal terminal) {
		new ListView<Command>() => [ list |
			HBox.setHgrow(list, Priority.ALWAYS)
			list.cellFactory = [
				return new ListCell<Command>() {

					override protected updateItem(Command item, boolean empty) {
						super.updateItem(item, empty)
						if(item === null || empty) {
							setText("")
						} else {
							setText(new Date() + " " + item.toString())
						}
					}

				} => [ cell |
					cell.setContextMenu(new ContextMenu() => [
						getItems().add(new MenuItem("Re execute") => [
							onAction = [
								terminal.commands.onNext(cell.getItem())
							]
						])
						getItems().add(new MenuItem("Show console here") => [
							onAction = [
								val newTerminal = new TerminalCanvas(new ThemeSolarizedDark())
								list.getItems().subList(0, cell.getIndex()).forEach[execute(newTerminal)]
								val parent = new AnchorPane(newTerminal)
								newTerminal.widthProperty().bind(parent.widthProperty())
								newTerminal.heightProperty().bind(parent.heightProperty())
								val scene = new Scene(parent, 1024, 768)
								new Stage() => [
									setScene(scene)
									show()
								]
							]
						])
					])
				]
			]
		]
	}

	def static createGrid(TerminalCanvas canvas) {
		new GridPane() => [ grid |
			grid.setGridLinesVisible(true)
			grid.setHgap(20)
			grid.setVgap(20)
			val timeline = new Timeline()
			timeline.setCycleCount(Timeline.INDEFINITE)
			val kf = new KeyFrame(Duration.millis(16), [ evt |
				grid.getChildren().clear()
				(0 ..< canvas.getGrid().rowMap().values().map[size()].max()).forEach [ x |
					grid.add(new Label(x + ""), x + 1, 0)
				]
				(0 ..< canvas.getGrid().rowKeySet().last()).forEach [ y |
					grid.add(new Label(y + ""), 0, y + 1)
				]
				canvas.getGrid().cellSet().forEach [
					val character = if(getValue().toString().equals("\n")) "↵" else getValue().toString()
					grid.add(new Label(character), getColumnKey().intValue() + 1, getRowKey().intValue() + 1)
				]
			])
			timeline.getKeyFrames().add(kf)
			timeline.play()
		]
	}

	def static void main(String[] args) {
		launch(args)
	}

}
