@tool
extends EditorPlugin

## Plugin Setup for Scribbler (sul 2024)

var dock
func _enter_tree():
	# Initialization of the plugin goes here.
	dock=preload("res://addons/scribbler/scribbler.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL,dock)

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_control_from_docks(dock)
	dock.free()
