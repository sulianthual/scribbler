@tool
extends Control

## select how to save

@onready var from_file: Button=%from_file
@onready var from_node: Button=%from_node
@onready var save_sheet: Button=%save_sheet

func _ready() -> void:
	from_file.connect("pressed",_on_from_file_pressed)
	from_node.connect("pressed",_on_from_node_pressed)
	save_sheet.connect("pressed",_on_save_sheet_pressed)
	
func _on_from_file_pressed():
	pass
func _on_from_node_pressed():
	pass
	
var as_sheet: bool=false
func _on_save_sheet_pressed():
	as_sheet=not as_sheet
	if as_sheet:
		save_sheet.text="yes"
	else:
		save_sheet.text="no"
