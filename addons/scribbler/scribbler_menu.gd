@tool
extends Control

## Scribbler: Scribble drawings in the editor
##

## Path of file currently edited ("" for none)
@export var edited_file: String="":
	set(value):
		edited_file=value
		if edited_file_label:
			edited_file_label.text=edited_file
		if drag:
			drag.set_filename(edited_file)
## image width (pixels) (as controlled here instead of drawing)
@export var px: int=256
## image height (pixels) (as controlled here instead of drawing)
@export var py: int=256


## Dialogue Control scene for resizing
@export var resize_dialogue: PackedScene
## Dialogue Control scene for sheet 
@export var sheet_dialogue: PackedScene


#############################################################
## SETUP

## menu
@onready var parent_container: Control# ref to parent before detach
## drawing
@onready var drawing: TextureRect=%drawing
@onready var image_size_label: Label=%image_size
@onready var edited_file_label: Label=%edited_file
## drop
@onready var drag: Button=%drag
## dock
@onready var detach: Button=%detach# update image size
@onready var hide_button: Button=%hide# update image size
@onready var help: Button=%help
## file
#@onready var mode_button: Button = %mode
@onready var new: Button = %new# new drawing
@onready var load: Button = %load# load drawing
@onready var save: Button = %save# save drawing
@onready var as_sheet_button: Button = %as_sheet# save drawing
## edit
@onready var undo: Button=%undo# update image size
@onready var clear: Button = %clear# clear drawing (same as new drawing)
@onready var resize: Button=%resize# update image size
## drawing settings
@onready var draw_mode_button: Button=%draw_mode
@onready var brush_color_button: Button=%brush_color
## test
#@onready var test: Button=%test

func _ready():
	## drawer
	drawing.connect("data_dropped",_on_drawing_data_dropped)
	drawing.connect("px_changed",_on_drawing_px_changed)
	drawing.connect("py_changed",_on_drawing_py_changed)
	drawing.connect("mouse_entered",drawing.activate)
	drawing.connect("mouse_exited",drawing.deactivate)
	## buttons
	#mode_button.connect("pressed",_on_mode_pressed)
	clear.connect("pressed",_on_clear_pressed)
	new.connect("pressed",_on_new_pressed)
	save.connect("pressed",_on_save_pressed)
	load.connect("pressed",_on_load_pressed)
	resize.connect("pressed",_on_resize_pressed)
	help.connect("pressed",_on_help_pressed)
	detach.connect("pressed",_on_detach_pressed)
	brush_color_button.connect("pressed",_on_brush_color_pressed)
	draw_mode_button.connect("pressed",_on_draw_mode_pressed)
	undo.connect("pressed",_on_undo_pressed)
	hide_button.connect("pressed",_on_hide_pressed)
	as_sheet_button.connect("toggled",_on_as_sheet_toggled)
	#test.connect("pressed",_on_test_pressed)
	## others
	#_update_mode()
	_update_draw_mode()
	_update_hiding_buttons()
	_update_image_size_label()
	update_detach_button()
	## deferred
	_postready.call_deferred()
	
func _postready()->void:
	parent_container=get_parent()# must know own parent to be able to detach
	drawing.new_drawing(px,py)

################################################################
## DRAWING WINDOW

func _on_drawing_px_changed(input_px: int):## SIGNAL FROM DRAWING
	px=input_px# happens e.g. when loading new file
	_update_image_size_label()
func _on_drawing_py_changed(input_py: int):## SIGNAL FROM DRAWING
	py=input_py
	_update_image_size_label()
func _update_image_size_label():
	image_size_label.text=str(px)+"x"+str(py)
	
func _on_drawing_data_dropped(_filename: String):
	if ResourceLoader.exists(_filename):
		load_selected(_filename)
################################################################
## MENU

## HIDE BUTTONS
var hiding_buttons: bool=false
func _on_hide_pressed():
	hiding_buttons=not hiding_buttons
	_update_hiding_buttons()
func _update_hiding_buttons():
	# removed detach
	for i in [new,clear,save,load,resize,help,brush_color_button,draw_mode_button,undo,as_sheet_button]:
		i.visible=not hiding_buttons
	detach.visible=not hiding_buttons and can_detach

## DETACH MENU (POPUP)
var detached: bool=false# dock starts detached or not
var can_detach: bool=true# MAY INTERFERE WITH MAKE FLOATING
func _on_detach_pressed():
	if can_detach and not detached:
		_detach_dialogue()
	else:
		_reatach_dialogue()
func _detach_dialogue():
	detached=true
	update_detach_button()
	var file_dialogue = Window.new()
	file_dialogue.set_size(Vector2(640, 360))
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("close_requested",_reatach_dialogue)
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
	update_detach_button()
	var _window: Window=get_parent()
	_window.remove_child(self)
	parent_container.add_child(self)
	_window.queue_free()
func update_detach_button():
	if detached:
		detach.text="attach"
	else:
		detach.text="detach"
	
## HELP
func _on_help_pressed():
	_help_dialogue()
func _help_dialogue():
	var file_dialogue = AcceptDialog.new()
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.title="Help"
	file_dialogue.dialog_text="""Scribbler Instructions (sul 2024, Godot 4.2): \
	Make basic drawings without leaving the editor, useful for prototyping.
	
	Controls:
	Draw with left mouse, Erase with right mouse, Change brush size with mouse wheel.
	Brush is indicated in top left corner, scribble dimensions (in pixels) in top right, and filename (if any) in bottom.
	Drag and drop any file or texture to the window to load and edit their image (must be a PNG).
	You can make the dock floating for more drawing space.
		
	Buttons:
	x: minimize/expand menu
	detach dock: detach the Scribbler dock to a popup window. attach dock to reattach.
	help: show help
	undo: undo last stroke (only 10 undos allowed)
	clear: clear the scribble
	resize: resize the scribble (choose new width and height in pixels, and resize mode)
	just draw: draw normally, behind existing strokes or over existing strokes.
	color: pick a new brush color
	load: generate scribble from existing PNG file in res://.
	save: save scribble to an existing or new PNG file in res://.
	new: new scribble.
	sheet: if toggled, will load/save scribble as a subregion of the image on disk.
	
	Warnings:
	Do not "make floating" the dock if already detached (may close plugin).
	You will get many warnings "Loaded resource as image file", its normal just ignore them.
	The plugin may be buggy or inefficient for large files (I dunno), use with caution if editing nice assets.
	"""
	file_dialogue.dialog_autowrap=true
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.popup()
	return file_dialogue


################################################################
## DRAWING AND BRUSH
func _on_undo_pressed():
	drawing.undo()
	
## CLEAR DRAWING
func _on_clear_pressed():
	drawing.clear_drawing()

## RESIZE DRAWING (POPUP)
var resize_mode: String="crop_centered"
func _on_resize_pressed():
	_resize_dialogue()
func _resize_dialogue():
	resize_mode="crop_centered"
	var file_dialogue = AcceptDialog.new()
	file_dialogue.set_size(Vector2(640, 360))
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
	_dialogue.connect("scale_mode_changed",_on_resize_dialogue_resize_mode_changed)
	file_dialogue.popup()
	return file_dialogue
## FROM DRAWING
func _on_resize_dialogue_px_changed(input_px: float):## SIGNAL FROM DRAWING
	px=int(input_px)
func _on_resize_dialogue_py_changed(input_py: float):## SIGNAL FROM DRAWING
	py=int(input_py)
func _on_resize_dialogue_resize_mode_changed(input_mode: String):## SIGNAL FROM DRAWING
	resize_mode=input_mode
func _on_resize_dialogue_confirmed():
	if resize_mode=="stretch":
		drawing.rescale_drawing(px,py,Image.INTERPOLATE_NEAREST)
	elif resize_mode=="crop_centered":
		drawing.crop_drawing_centered(px,py)
	elif resize_mode=="crop_cornered":
		drawing.crop_drawing_cornered(px,py)


## CHANGE DRAW MODE
## Draw mode (must match drawing.gd)
var draw_mode: String="regular"
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

## BRUSH COLOR
## brush color (as controlled here instead of drawing)
var brush_color: Color=Color.BLACK
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
func _on_brush_color_dialogue_color_changed(input_color: Color):## SIGNAL FROM DIALOGUE
	brush_color=input_color
func _on_brush_color_dialogue_confirmed():
	drawing.recolor_brush(brush_color)
	
################################################################
## FILE

## USE SHEETS OR NOT
var as_sheet: bool=false# use sheet for loading/saving
func _on_as_sheet_toggled(toggle_on: bool):
	as_sheet=toggle_on
#func _update_as_sheet_button():
	#if as_sheet:
		#as_sheet_button.text="sheet: on"
	#else:
		#as_sheet_button.text="sheet: off"
## NEW DRAWING
func _on_new_pressed():
	drawing.new_drawing(px,py)
	edited_file=""

###
## LOAD FROM FILE

func _on_load_pressed():
	_load_dialogue()
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
	load_selected(input_file)
func load_selected(input_file: String):
	if as_sheet:
		_load_from_sheet_select_subset_dialogue(input_file)
	else:
		drawing.load_drawing(input_file)
		edited_file=input_file
## LOAD SCRIBBLE FROM SHEET
var sheet_dialogue_input_subset: Array[int]=[1,1,1,1]# subx,suby,ix,iy, subset of source image
var load_from_sheet_selected_file: String# pass selected file
func _load_from_sheet_select_subset_dialogue(input_file: String):
	sheet_dialogue_input_subset=[1,1,1,1]
	load_from_sheet_selected_file=input_file
	var file_dialogue = ConfirmationDialog.new()
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.title="Select Sheet Subset"
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("confirmed",_on_load_from_sheet_dialogue_confirmed)
	var _dialogue: Control=sheet_dialogue.instantiate()
	_dialogue.connect("subset_changed",_on_load_from_sheet_dialogue_subset_changed)
	file_dialogue.add_child(_dialogue)
	_dialogue.set_subset(sheet_dialogue_input_subset)
	_dialogue.make(input_file,null)# make with null edited image
	file_dialogue.popup()
	return file_dialogue
func _on_load_from_sheet_dialogue_subset_changed(input_subset: Array[int]):# subx,suby,ix,iy
	sheet_dialogue_input_subset=input_subset
func _on_load_from_sheet_dialogue_confirmed():
	if load_from_sheet_selected_file and ResourceLoader.exists(load_from_sheet_selected_file):
		drawing.load_drawing_subset(load_from_sheet_selected_file, sheet_dialogue_input_subset)
		edited_file=load_from_sheet_selected_file
		load_from_sheet_selected_file=""
		
#########################################################################################
## SAVE TO FILE


func _on_save_pressed():
	if edited_file:
		_save_dialogue().set_current_path(edited_file)
	else:
		_save_dialogue()

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
	if as_sheet:
		_save_from_sheet_select_subset_dialogue(input_file)
	else:
		drawing.save_drawing(input_file)
		edited_file=input_file
		_rescan_filesystem()
## SAVE SCRIBBLE TO SHEET
var save_from_sheet_selected_file: String# pass selected file
func _save_from_sheet_select_subset_dialogue(input_file: String):
	sheet_dialogue_input_subset=[1,1,1,1]
	save_from_sheet_selected_file=input_file
	var file_dialogue = ConfirmationDialog.new()
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.title="Select Sheet Subset"
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("confirmed",_on_save_from_sheet_dialogue_confirmed)
	var _dialogue: Control=sheet_dialogue.instantiate()
	_dialogue.connect("subset_changed",_on_save_from_sheet_dialogue_subset_changed)
	file_dialogue.add_child(_dialogue)
	_dialogue.set_subset(sheet_dialogue_input_subset)
	_dialogue.make(input_file,drawing.get_image())# make with edited image
	file_dialogue.popup()
	return file_dialogue
func _on_save_from_sheet_dialogue_subset_changed(input_subset: Array[int]):# subx,suby,ix,iy
	sheet_dialogue_input_subset=input_subset
func _on_save_from_sheet_dialogue_confirmed():
	if save_from_sheet_selected_file:
		drawing.save_drawing_subset(save_from_sheet_selected_file,sheet_dialogue_input_subset)
		edited_file=save_from_sheet_selected_file
		save_from_sheet_selected_file=""
		_rescan_filesystem()


################################################################
################################################################

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
################################################################

	
## 
func _on_test_pressed():
	pass
