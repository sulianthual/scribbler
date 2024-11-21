@tool
extends Control

## Scribbler: Scribble drawings in the editor
##
@onready var drawing: TextureRect=%drawing
## file_row
@onready var mode_button: Button = %mode
@onready var new: Button = %clear# clear is same as new
@onready var load: Button = %load
@onready var save: Button = %save
## resize_row
@onready var resize: Button=%resize
@onready var px: SpinBox=%px
@onready var py: SpinBox=%py

#enum ACCEPTED_TEXTURE {ImageTexture, CompressedTexture2D]

# Called when the node enters the scene tree for the first time.
func _ready():
	## drawer
	drawing.connect("px_changed",_on_drawing_px_changed)
	drawing.connect("py_changed",_on_drawing_py_changed)
	## buttons
	mode_button.connect("pressed",_on_mode_pressed)
	new.connect("pressed",_on_new_pressed)
	save.connect("pressed",_on_save_pressed)
	load.connect("pressed",_on_load_pressed)
	resize.connect("pressed",_on_resize_pressed)
	## others
	_update_mode()
	## deferred
	_postready.call_deferred()
func _postready()->void:
	drawing.new_drawing(px.value,py.value)

## CHANGE MODE (FROM FILE OR NODE)
enum MODE {FILE,NODE}
var mode: MODE=MODE.FILE
func _on_mode_pressed():
	if mode==MODE.FILE:
		mode=MODE.NODE
	else:
		mode=MODE.FILE
	_update_mode()
func _update_mode():
	if mode==MODE.FILE:
		mode_button.set_text("FILE")
	elif mode==MODE.NODE:
		mode_button.set_text("NODE")
		
	
## NEW DRAWING
func _on_new_pressed():
	drawing.new_drawing(px.value,py.value)

## LOAD FROM FILE
func _on_load_pressed():
	if mode==MODE.FILE:
		_load_dialogue()
	elif mode==MODE.NODE:
		_load_node()
func _load_dialogue():
	var file_dialogue = EditorFileDialog.new()
	file_dialogue.clear_filters()
	file_dialogue.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialogue.filters = ["*.png ; PNG File"]
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_LIST)
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("file_selected", _on_load_dialogue_file_loaded)
	file_dialogue.popup()
	return file_dialogue
func _on_load_dialogue_file_loaded(input_file: String):
	drawing.load_drawing(input_file)
func _load_node():## get from selected node in Editor SceneView
	var _selected_node:Node=EditorInterface.get_selection().get_selected_nodes()[0]
	if _node_valid(_selected_node):
		var _texture=_selected_node.texture
		if _texture_valid(_texture):
			drawing.load_drawing(_texture.resource_path)
			#_load_dialogue().set_current_path(_texture.resource_path)# doesnt work for no reason

## SAVE TO FILE
func _on_save_pressed():
	if mode==MODE.FILE:
		_save_dialogue()
	elif mode==MODE.NODE:
		_save_node()
func _save_dialogue():
	var file_dialogue = EditorFileDialog.new()
	file_dialogue.clear_filters()
	file_dialogue.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialogue.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialogue.filters = ["*.png ; PNG File"]
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_LIST)
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("file_selected", _on_save_dialogue_file_selected)
	file_dialogue.popup()
	return file_dialogue
func _on_save_dialogue_file_selected(input_file: String):
	drawing.save_drawing(input_file)
	_rescan_filesystem()
func _save_node():## save to selected node in Editor SceneView
	var _selected_node:Node=EditorInterface.get_selection().get_selected_nodes()[0]
	if _node_valid(_selected_node):
		var _texture=_selected_node.texture
		if _texture==null:# empty, fill in
			_selected_node.texture=drawing.get_texture()# beware, if user doesnt save fills unsaved texture
			_save_dialogue()# beware, if user doesnt save
		else:# existing, use save dialogue
			if _texture_valid(_texture):
				_save_dialogue().set_current_path(_texture.resource_path)


## RESIZE DRAWING
func _on_resize_pressed():
	drawing.resize_drawing(px.value,py.value)

func _on_drawing_px_changed(input_px: int):## SIGNAL FROM DRAWING
	px.value=input_px
func _on_drawing_py_changed(input_py: int):## SIGNAL FROM DRAWING
	py.value=input_py
	
## rescan directory after changing files
func _rescan_filesystem():
	EditorInterface.get_resource_filesystem().scan()
## check if node holding texture is valid (non null, has texture...)
func _node_valid(input_node: Node):
	return input_node and "texture" in input_node
## check if texture is valid (non null, matching type, has resource path that is a png)
func _texture_valid(input_texture: Texture2D):
	var valid: bool=input_texture!=null
	valid=valid and (input_texture is ImageTexture or input_texture is CompressedTexture2D)
	valid=valid and input_texture.resource_path
	valid=valid and input_texture.resource_path.get_extension()=="png"
	return valid

########################################
## TESTS

func _on_test_pressed():
	print(EditorInterface.get_edited_scene_root())
	

## Apply scribble to selected node in scenetree
func _on_apply_pressed():
	var _selected_node:Node=EditorInterface.get_selection().get_selected_nodes()[0]
	if "texture" in _selected_node:
		_selected_node.set_texture(drawing.get_texture())
