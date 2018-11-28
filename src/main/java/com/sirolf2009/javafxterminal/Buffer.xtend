package com.sirolf2009.javafxterminal

import com.google.common.collect.HashBasedTable
import com.google.common.collect.TreeBasedTable
import java.util.List
import javafx.beans.binding.Bindings
import javafx.beans.property.BooleanProperty
import javafx.beans.property.SimpleBooleanProperty
import javafx.beans.value.ObservableValue

class Buffer {
	
	val BooleanProperty alternate
	val ObservableValue<TreeBasedTable<Integer, Integer, Character>> gridProperty
	val ObservableValue<HashBasedTable<Integer, Integer, List<CharModifier>>> stylesGridProperty
	val TreeBasedTable<Integer, Integer, Character> normalGrid
	val HashBasedTable<Integer, Integer, List<CharModifier>> normalStylesGrid
	val TreeBasedTable<Integer, Integer, Character> altGrid
	val HashBasedTable<Integer, Integer, List<CharModifier>> altStylesGrid
	
	new() {
		alternate = new SimpleBooleanProperty(false)
		
		normalGrid = TreeBasedTable.create()
		normalStylesGrid = HashBasedTable.create()
		altGrid = TreeBasedTable.create()
		altStylesGrid = HashBasedTable.create()
		
		gridProperty = Bindings.createObjectBinding([if(alternate.get()) altGrid else normalGrid], alternate)
		stylesGridProperty = Bindings.createObjectBinding([if(alternate.get()) altStylesGrid else normalStylesGrid], alternate)
	}
	
	def alternate(boolean alternate) {
		this.alternate.set(alternate)
	}
	
	def getGrid() {
		return gridProperty.getValue()
	}
	
	def getStylesGrid() {
		return stylesGridProperty.getValue()
	}
	
}