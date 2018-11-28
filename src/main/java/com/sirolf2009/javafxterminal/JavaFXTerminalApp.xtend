package com.sirolf2009.javafxterminal

import com.sirolf2009.javafxterminal.command.Command
import com.sirolf2009.javafxterminal.theme.ThemeSolarizedDark
import io.reactivex.rxjavafx.schedulers.JavaFxScheduler
import java.util.Date
import javafx.application.Application
import javafx.beans.binding.Bindings
import javafx.scene.Scene
import javafx.scene.control.Button
import javafx.scene.control.ContextMenu
import javafx.scene.control.Label
import javafx.scene.control.ListCell
import javafx.scene.control.ListView
import javafx.scene.control.MenuItem
import javafx.scene.control.ScrollPane
import javafx.scene.control.Tab
import javafx.scene.control.TabPane
import javafx.scene.control.ToolBar
import javafx.scene.layout.AnchorPane
import javafx.scene.layout.GridPane
import javafx.scene.layout.HBox
import javafx.scene.layout.Priority
import javafx.scene.layout.VBox
import javafx.stage.Stage
import org.controlsfx.control.PopOver

class JavaFXTerminalApp extends Application {

	override start(Stage primaryStage) throws Exception {
		val terminal = new Terminal(#["/usr/bin/fish"], new ThemeSolarizedDark()) => [
			drawTimeline()
			HBox.setHgrow(it, Priority.ALWAYS)
		]

		val newStage = new Stage()
		val commands = createCommandListview(terminal)
		terminal.commands.observeOn(JavaFxScheduler.platform()).subscribe [
			commands.getItems().add(it)
		]
		val aggregatedCommands = createCommandListview(terminal)
		terminal.aggregatedCommands.observeOn(JavaFxScheduler.platform()).subscribe [
			aggregatedCommands.getItems().add(it)
		]
		val grid = createGrid(terminal)
		newStage.setScene(new Scene(new TabPane(
			new Tab("Commands", new HBox(commands, aggregatedCommands)),
			new Tab("Grid", new ScrollPane(grid))
		), 1024, 768))
		newStage.show()
		val parent = new AnchorPane(terminal)
		terminal.widthProperty().bind(parent.widthProperty())
		terminal.heightProperty().bind(parent.heightProperty())
		val scene = new Scene(parent, 1024, 768)

		primaryStage.setScene(scene)
		primaryStage.onCloseRequest = [System.exit(0)]
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
						getItems().add(new MenuItem("Show console from here") => [
							onAction = [
								val newTerminal = new TerminalCanvas(new ThemeSolarizedDark())
								val parent = new AnchorPane(newTerminal)
								newTerminal.widthProperty().bind(parent.widthProperty())
								newTerminal.heightProperty().bind(parent.heightProperty())
								VBox.setVgrow(parent, Priority.ALWAYS)
								val caretLabel = new Label()
								caretLabel.textProperty().bind(Bindings.createStringBinding(['''Caret: «newTerminal.getCaret().get()»'''], newTerminal.getCaret()))
								val anchorLabel = new Label()
								anchorLabel.textProperty().bind(Bindings.createStringBinding(['''Anchor: «newTerminal.getAnchor().get()»'''], newTerminal.getAnchor()))
								val stats = new HBox(caretLabel, anchorLabel)
								val scene = new Scene(new VBox(parent, stats), 1024, 768)
								new Stage() => [
									setScene(scene)
									show()
									list.getItems().subList(0, cell.getIndex() + 1).forEach[execute(newTerminal)]

									newTerminal.drawTimeline()
								]
							]
						])
					])
				]
			]
		]
	}

	def static createGrid(TerminalCanvas canvas) {
		val grid = new GridPane()
		grid.setGridLinesVisible(true)
		grid.setHgap(20)
		grid.setVgap(20)

		val update = new Button("update") => [
			onAction = [
				grid.getChildren().clear()
				if(!canvas.getBuffer().getGrid().isEmpty()) {
					(0 ..< canvas.getBuffer().getGrid().rowMap().values().map[size()].max()).forEach [ x |
						grid.add(new Label(x + ""), x + 1, 0)
					]
					(0 ..< canvas.getBuffer().getGrid().rowKeySet().last()).forEach [ y |
						grid.add(new Label(y + ""), 0, y + 1)
					]
					canvas.getBuffer().getGrid().cellSet().forEach [
						val character = if(getValue().toString().equals("\n")) "↵" else getValue().toString()
						val label = new Label(character)
						label.onMouseClicked = [evt|
							new PopOver(new Label(canvas.getBuffer().getStylesGrid().get(getRowKey(), getColumnKey()).toString())).show(label)
						]
						grid.add(label, getColumnKey().intValue() + 1, getRowKey().intValue() + 1)
					]
				}
			]
		]

		VBox.setVgrow(grid, Priority.ALWAYS)
		new VBox(new ToolBar(update), grid)
	}

	def static void main(String[] args) {
		launch(args)
	}

}
