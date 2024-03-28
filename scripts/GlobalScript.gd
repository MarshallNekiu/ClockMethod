class_name GlobalScript
extends Node

########################################################
const SCRIPT = preload("res://scripts/GlobalScript.gd")#
########################################################

static func get_Debugger(requester: Node) -> TextEdit:
	if requester.has_node("Debugger"):
		return requester.get_node("Debugger/TextEdit")
	
	var window := Window.new()
	window.name = "Debugger"
	window.size = requester.get_viewport_rect().size * 0.5
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	requester.add_child(window, true, Node.INTERNAL_MODE_BACK)
	window.connect("close_requested", func (): window.queue_free())
	
	var text := TextEdit.new()
	text.size = window.size
	window.connect("size_changed", func (): text.size = window.size)
	window.add_child(text, true)
	
	return text











