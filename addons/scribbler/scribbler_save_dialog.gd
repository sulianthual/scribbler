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
	
var as_node: bool=false
func _on_from_file_pressed():
	as_node=false
	as_node_update()
func _on_from_node_pressed():
	as_node=true
	as_node_update()
func as_node_update():
	if as_node:
		from_file.text="no"
		from_node.text="yes"
	else:
		from_file.text="yes"
		from_node.text="no"
	
var as_sheet: bool=false
func _on_save_sheet_pressed():
	as_sheet=not as_sheet
	if as_sheet:
		save_sheet.text="yes"
	else:
		save_sheet.text="no"
