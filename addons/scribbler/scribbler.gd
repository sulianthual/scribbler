@tool
extends Control

## Scribbler: Scribble drawings in the editor
##
@onready var drawing: TextureRect=%drawing
@onready var apply: Button = %apply
@onready var save: Button = %save
@onready var load: Button = %load
@onready var px: SpinBox=%px
@onready var py: SpinBox=%py
@onready var filename: LineEdit=%filename
@onready var test: Button = %test

# Called when the node enters the scene tree for the first time.
func _ready():
	apply.connect("pressed",_on_apply_pressed)
	save.connect("pressed",_on_save_pressed)
	load.connect("pressed",_on_load_pressed)
	test.connect("pressed",_on_test_pressed)

func _on_test_pressed():
	print(EditorInterface.get_edited_scene_root())
	

## Apply scribble to selected node in scenetree
func _on_apply_pressed():
	var _selected_node:Node=EditorInterface.get_selection().get_selected_nodes()[0]
	if "texture" in _selected_node:
		_selected_node.set_texture(drawing.get_texture())
func _on_save_pressed():
	pass
func _on_load_pressed():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
