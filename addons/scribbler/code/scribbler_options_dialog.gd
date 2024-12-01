@tool
extends Control

## Options dialogue

@onready var as_sheet = %as_sheet
@onready var grid = %grid

signal as_sheet_changed(value: bool)
signal grid_changed(value: bool)

func _ready():
	as_sheet.connect("toggled",on_as_sheet_toggled)
	grid.connect("toggled",on_grid_toggled)
func on_as_sheet_toggled(value: bool):
	as_sheet_changed.emit(value)
func on_grid_toggled(value: bool):
	grid_changed.emit(value)

func set_as_sheet(value: bool):## CALLS from scribbler
	as_sheet.button_pressed=value
func set_show_grid(value: bool):## CALLS from scribbler
	grid.button_pressed=value
