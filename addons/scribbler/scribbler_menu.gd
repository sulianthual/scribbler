@tool
extends Control

## Scribbler: Scribble drawings in the editor
##


## image width (pixels) (as controlled here instead of drawing)
@export var px: int=256
## image height (pixels) (as controlled here instead of drawing)
@export var py: int=256
## brush color (as controlled here instead of drawing)
@export var brush_color: Color=Color.BLACK
## Dialogue Control scene for resizing
@export var resize_dialogue: PackedScene
## Draw mode (must match drawing.gd)
@export_enum("regular","over","behind") var draw_mode: String="regular"
var detached: bool=false# dock starts detached or not
#############################################################
## SETUP

## menu
@onready var parent_container: Control# ref to parent before detach
## drawing
@onready var drawing: TextureRect=%drawing
@onready var draw_mode_button: Button=%draw_mode
## file
@onready var mode_button: Button = %mode
@onready var new: Button = %clear# clear drawing (same as new drawing)
@onready var load: Button = %load# load drawing
@onready var save: Button = %save# save drawing
## resize
@onready var resize: Button=%resize# update image size
## brush
@onready var brush_color_button: Button=%brush_color
## help
@onready var help: Button=%help
## detach
@onready var detach: Button=%detach# update image size
@onready var undo: Button=%undo# update image size
## test
#@onready var test: Button=%test

func _ready():
	## drawer
	drawing.connect("px_changed",_on_drawing_px_changed)
	drawing.connect("py_changed",_on_drawing_py_changed)
	drawing.connect("mouse_entered",drawing.activate)
	drawing.connect("mouse_exited",drawing.deactivate)
	## buttons
	mode_button.connect("pressed",_on_mode_pressed)
	new.connect("pressed",_on_new_pressed)
	save.connect("pressed",_on_save_pressed)
	load.connect("pressed",_on_load_pressed)
	resize.connect("pressed",_on_resize_pressed)
	help.connect("pressed",_on_help_pressed)
	detach.connect("pressed",_on_detach_pressed)
	brush_color_button.connect("pressed",_on_brush_color_pressed)
	draw_mode_button.connect("pressed",_on_draw_mode_pressed)
	undo.connect("pressed",_on_undo_pressed)
	#test.connect("pressed",_on_test_pressed)
	## others
	_update_mode()
	_update_draw_mode()
	## deferred
	_postready.call_deferred()
func _postready()->void:
	parent_container=get_parent()# must know own parent to be able to detach
	drawing.new_drawing(px,py)

################################################################
## MENU

## DETACH MENU (POPUP)

func _on_detach_pressed():
	if not detached:
		_detach_dialogue()
	else:
		_reatach_dialogue()
func _detach_dialogue():
	detached=true
	detach.text="attach dock"
	var file_dialogue = Window.new()
	file_dialogue.set_size(Vector2(640, 360))
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("confirmed",_reatach_dialogue)
	#file_dialogue.set_flag(Window.Flags.FLAG_POPUP,true)
	#file_dialogue.set_flag(Window.Flags.FLAG_BORDERLESS,true)
	file_dialogue.title="Scribbler"
	file_dialogue.keep_title_visible=false
	parent_container.remove_child(self)
	file_dialogue.add_child(self)
	file_dialogue.popup()
	return file_dialogue
func _reatach_dialogue():
	detached=false
	detach.text="detach dock"
	var _window: Window=get_parent()
	_window.remove_child(self)
	parent_container.add_child(self)
	_window.queue_free()
	

################################################################
## FILE

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
		mode_button.set_text("edit files")
	elif mode==MODE.NODE:
		mode_button.set_text("edit nodes")


## NEW DRAWING
func _on_new_pressed():
	drawing.new_drawing(px,py)
	
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
	file_dialogue.access = EditorFileDialog.ACCESS_RESOURCES
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
	file_dialogue.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialogue.filters = ["*.png ; PNG File"]
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_LIST)
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("file_selected", _on_save_dialogue_file_selected)
	file_dialogue.popup()
	return file_dialogue
func _on_save_dialogue_file_selected(input_file: String):
	drawing.save_drawing(input_file)
	_apply_saved_image_to_empty_node_texture(input_file)
	_rescan_filesystem()
func _save_node():## save to selected node in Editor SceneView
	var _selected_node:Node=EditorInterface.get_selection().get_selected_nodes()[0]
	if _node_valid(_selected_node):
		var _texture=_selected_node.texture
		if _texture==null:# empty, fill in
			_save_dialogue().set_current_file(_selected_node.name.to_lower()+".png")
		else:# existing, use save dialogue
			if _texture_valid(_texture):
				_save_dialogue().set_current_path(_texture.resource_path)
func _apply_saved_image_to_empty_node_texture(input_file: String):
	if mode==MODE.NODE:# if node selected has empty texture, update it with saved file
		var _selected_node:Node=EditorInterface.get_selection().get_selected_nodes()[0]
		if _node_valid(_selected_node):
			var _texture=_selected_node.texture
			if _texture==null:# empty, fill in
				#await get_tree().create_timer(0.5, false, false, true).timeout# wait to make sure resource is written
				await EditorInterface.get_resource_filesystem().filesystem_changed# wait for update in filesystem
				#-> Beware, for large image resource may not be written yet
				if ResourceLoader.exists(input_file):
					_selected_node.texture=ResourceLoader.load(input_file)


## UTILS
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

################################################################
## IMAGE AND BRUSH

func _on_undo_pressed():
	drawing.undo()
## PX,PY FROM DRAWING
func _on_drawing_px_changed(input_px: int):## SIGNAL FROM DRAWING
	px=input_px# happens e.g. when loading new file
func _on_drawing_py_changed(input_py: int):## SIGNAL FROM DRAWING
	py=input_py

## CHANGE DRAW MODE
func _on_draw_mode_pressed():
	if draw_mode=="regular":
		draw_mode="behind"
	elif draw_mode=="behind":
		draw_mode="over"
	elif draw_mode=="over":
		draw_mode="regular"
	_update_draw_mode()
func _update_draw_mode():
	drawing. set_draw_mode(draw_mode)
	if draw_mode=="over":
		draw_mode_button.set_text("draw over")
	elif draw_mode=="behind":
		draw_mode_button.set_text("draw behind")
	else:
		draw_mode_button.set_text("just draw")

## RESIZE DRAWING (POPUP)
func _on_resize_pressed():
	_resize_dialogue()
func _resize_dialogue():
	var file_dialogue = AcceptDialog.new()
	file_dialogue.set_size(Vector2(320, 180))
	file_dialogue.title="Resize Scribble"
	file_dialogue.dialog_autowrap=true
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("confirmed",_on_resize_dialogue_confirmed)
	var _dialogue: Control=resize_dialogue.instantiate()
	file_dialogue.add_child(_dialogue)
	_dialogue.px.value=px
	_dialogue.py.value=py
	_dialogue.px.connect("value_changed",_on_resize_dialogue_px_changed)
	_dialogue.py.connect("value_changed",_on_resize_dialogue_py_changed)
	file_dialogue.popup()
	return file_dialogue
## FROM DRAWING
func _on_resize_dialogue_px_changed(input_px: float):## SIGNAL FROM DRAWING
	px=int(input_px)
func _on_resize_dialogue_py_changed(input_py: float):## SIGNAL FROM DRAWING
	py=int(input_py)
func _on_resize_dialogue_confirmed():
	drawing.resize_drawing(px,py)

## BRUSH COLOR
func _on_brush_color_pressed():
	_brush_color_dialogue()
func _brush_color_dialogue():
	var file_dialogue = AcceptDialog.new()
	file_dialogue.set_size(Vector2(320, 180))
	file_dialogue.title="Pick Brush Color"
	file_dialogue.dialog_autowrap=true
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("confirmed",_on_brush_color_dialogue_confirmed)
	var _dialog: ColorPicker=ColorPicker.new()
	_dialog.connect("color_changed",_on_brush_color_dialogue_color_changed)
	_dialog.color=brush_color
	_dialog.deferred_mode=true
	_dialog.edit_alpha=true
	_dialog.can_add_swatches=false
	_dialog.color_modes_visible=false
	_dialog.hex_visible=false
	_dialog.presets_visible=false
	_dialog.sampler_visible=false
	_dialog.sliders_visible=true
	file_dialogue.add_child(_dialog)
	file_dialogue.popup()
	return file_dialogue
## FROM DRAWING
func _on_brush_color_dialogue_color_changed(input_color: Color):## SIGNAL FROM DIALOGUE
	brush_color=input_color
func _on_brush_color_dialogue_confirmed():
	drawing.recolor_brush(brush_color)


## HELP
func _on_help_pressed():
	_help_dialogue()
func _help_dialogue():
	var file_dialogue = AcceptDialog.new()
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.title="Help"
	file_dialogue.dialog_text="""Scribbler Instructions (sul 2024, Godot 4.2):
	
	With Scribbler you make basic drawings without leaving the editor, ideal for prototyping.
	
	Draw with left mouse, Erase with right mouse, Change brush size with mouse wheel. Brush is indicated in top left corner.
	
	load: generate scribble from existing PNG file (see MODE).
	save: save scribble to an existing or new PNG file (see MODE).
	detach dock: detach the Scribbler dock to a popup window. attach dock to reattach.
	clear: clear the scribble
	resize: resize the scribble (choose new width and height in pixels)
	
	if DRAW==just draw: draw normally.
	if DRAW==draw behind: draw behind existing strokes (noticeable if using a different brush color).
	if DRAW==draw over: draw only over existing strokes (typically using a different brush color).

	if MODE==FILE: scribble loads from and saves to PNG files in res://.
	if MODE==NODE: scribble loads from node selected in Scene View, from node.texture \
	(if texture is ImageTexture or CompressedTexture2D with a resource_path that is PNG). \
	Saving scribble modifies image texture, or generates a new one if empty.
	
	Any bugs or feedback use the github, enjoy!
	"""
	file_dialogue.dialog_autowrap=true
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.popup()
	return file_dialogue
	