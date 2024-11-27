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
		if copy_button:
			copy_button.set_filename(edited_file)
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
@onready var grid_indicator = %grid_indicator
## drop
@onready var copy_button: Button=%copy
## on
@onready var onion_drop: Button = %onion_drop
@onready var onion_indicator: TextureRect = %onion_indicator
@onready var onion_onoff: Label = %onion_onoff
## dock
@onready var detach: Button=%detach# update image size
@onready var hide_button: Button=%hide# update image size
@onready var help: Button=%help
@onready var menu: Button = %menu

## file
#@onready var mode_button: Button = %mode
@onready var new: Button = %new# new drawing
@onready var load: Button = %load# load drawing
@onready var save: Button = %save# save drawing
## edit/options
#@onready var onion_drop: Button = %onion_drop
@onready var clear: Button = %clear# clear drawing (same as new drawing)
@onready var resize: Button=%resize# update image size
@onready var as_sheet_button: Button = %as_sheet# save drawing
@onready var grid_button: Button = %grid
## drawing tools
@onready var pen_button: Button=%pen
@onready var pen_overfirstbehindblack_button: Button=%pen_overfirstbehindblack
@onready var pen_black_button: Button=%pen_black
@onready var eraser_button: Button=%eraser
@onready var bucket_button: Button=%bucket
@onready var pen_behindblack_button: Button=%pen_behindblack# behind black
## colors
@onready var brush_color_1: Button = %brush_color1
@onready var brush_color_2: Button = %brush_color2
@onready var brush_color_3: Button = %brush_color3
@onready var brush_color_4: Button = %brush_color4
@onready var brush_color_5: Button = %brush_color5
@onready var brush_color_6: Button = %brush_color6
@onready var brush_color_7: Button = %brush_color7
@onready var brush_buttons: Array[Button]=[brush_color_1,brush_color_2,brush_color_3,brush_color_4,brush_color_5,brush_color_6,brush_color_7]
#@onready var brush_color_button: Button=%brush_color# deprecated
## containers (for visibility)
@onready var brush_row: HBoxContainer = %brush_row
@onready var colors_row: HBoxContainer = %colors_row
@onready var edit_row:HBoxContainer = %edit_row
@onready var option_row: HBoxContainer = %option_row
@onready var file_row: HBoxContainer = %file_row
## test
#@onready var test: Button=%test

func _ready():
	## drawer
	drawing.connect("data_dropped",_on_drawing_data_dropped)
	drawing.connect("px_changed",_on_drawing_px_changed)
	drawing.connect("py_changed",_on_drawing_py_changed)
	drawing.connect("mouse_entered",drawing.activate)
	drawing.connect("mouse_exited",drawing.deactivate)
	drawing.connect("brush_scaling_changed",on_drawing_brush_scaling_changed)
	drawing.connect("color_picked",on_drawing_color_picked)
	## onion
	onion_drop.connect("data_dropped",on_onion_drop_data_dropped)
	onion_drop.connect("clear_onions",on_onion_drop_clear_onions)
	onion_drop.connect("toggle_onions_visibilty",on_onion_drop_toggle_onions_visibility)
	## utils
	detach.connect("pressed",_on_detach_pressed)
	hide_button.connect("pressed",_on_hide_pressed)
	help.connect("pressed",_on_help_pressed)
	menu.connect("pressed",_on_menu_pressed)
	## edit buttons
	clear.connect("pressed",_on_clear_pressed)
	resize.connect("pressed",_on_resize_pressed)
	as_sheet_button.connect("toggled",_on_as_sheet_toggled)
	grid_button.connect("toggled",_on_grid_toggled)
	## files
	new.connect("pressed",_on_new_pressed)
	save.connect("pressed",_on_save_pressed)
	load.connect("pressed",_on_load_pressed)
	## tools
	pen_black_button.connect("pressed",_on_draw_mode_pressed.bind("penblack"))
	pen_button.connect("pressed",_on_draw_mode_pressed.bind("pen"))
	pen_behindblack_button.connect("pressed",_on_draw_mode_pressed.bind("penbehindblack"))
	pen_overfirstbehindblack_button.connect("pressed",_on_draw_mode_pressed.bind("penoverfirstbehindblack"))
	eraser_button.connect("pressed",_on_draw_mode_pressed.bind("eraser"))
	bucket_button.connect("pressed",_on_draw_mode_pressed.bind("bucket"))
	## colors
	var ic: int=0
	for i in brush_buttons:
		i.connect("pressed",_on_brush_color_i_pressed.bind(ic))
		i.connect("mouse_entered",_on_brush_color_i_mouse_entered.bind(ic))
		i.connect("mouse_exited",_on_brush_color_i_mouse_exited.bind(ic))
		i.connect("data_dropped",_on_brush_color_i_data_dropped.bind(ic))
		i.connect("colors_dropped",_on_brush_color_i_colors_dropped.bind(ic))
		ic+=1
	## others
	_update_buttons_visibility()
	_update_image_size_label()
	update_detach_button()
	ready_brush_color()# wa make_brush+color
	_update_draw_mode()
	ready_onion_controls()
	grid_button.visible=false# WE DONT USE IT
	
	## deferred
	_postready.call_deferred()
	
func _postready()->void:
	parent_container=get_parent()# must know own parent to be able to detach
	drawing.new_drawing(px,py)
	on_drawing_brush_scaling_changed()


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

## MENU INPUTS
## some button (e.g. colors) can be right clicked
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if brush_color_i_hovered!=-1:
				# could have consecutive mouse events, put exclusive window unfocuses the window
				brush_color_i_pick_color()

## HIDE BUTTONS
var hiding_buttons: bool=false# hidden by X
var menu_expanded: bool=true# menu is expanded
func _on_hide_pressed():
	hiding_buttons=not hiding_buttons
	_update_buttons_visibility()
## EXPAND MENU BUTTON
func _on_menu_pressed():
	menu_expanded=not menu_expanded
	_update_buttons_visibility()
	#_update_hiding_buttons()
func _update_buttons_visibility():
	brush_row.visible=not hiding_buttons
	colors_row.visible=not hiding_buttons
	edit_row.visible=not hiding_buttons and menu_expanded
	file_row.visible=not hiding_buttons and menu_expanded
	option_row.visible=not hiding_buttons and menu_expanded
	menu.visible=not hiding_buttons
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
	## column to row
	#for i in [brush_row,edit_row,file_row]:
		#i.get_parent().remove_child(i)
		#row.add_child(i)
	detached=true
	update_detach_button()
	var file_dialogue = Window.new()
	file_dialogue.set_size(Vector2(640, 360))
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("close_requested",_reatach_dialogue)
	#file_dialogue.set_flag(Window.Flags.FLAG_POPUP,true)
	#file_dialogue.set_flag(Window.Flags.FLAG_BORDERLESS,true)
	file_dialogue.set_mode(Window.MODE_MAXIMIZED)
	file_dialogue.title="Scribbler"
	file_dialogue.keep_title_visible=false
	parent_container.remove_child(self)
	file_dialogue.add_child(self)
	file_dialogue.popup()
	return file_dialogue
func _reatach_dialogue():
	## column to row
	#for i in [brush_row,edit_row,file_row]:
		#i.get_parent().remove_child(i)
		#column.add_child(i)
	detached=false
	update_detach_button()
	var _window: Window=get_parent()
	_window.remove_child(self)
	parent_container.add_child(self)
	_window.queue_free()
func update_detach_button():
	if detached:
		detach.text="-"
	else:
		detach.text="+"
	
## HELP
func _on_help_pressed():
	_help_dialogue()
func _help_dialogue():
	var file_dialogue = AcceptDialog.new()
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.title="Help"
	file_dialogue.dialog_text="""Scribbler (sul 2024, Godot v4.2+ plugin): \
	Make basic drawings without leaving the editor, useful for prototyping. 
	
	Drawing Area:
	Draw with left mouse, Undo with right mouse, Change pen size with mouse wheel, Pick pen color with middle mouse. \
	Pen size and color is indicated in top left corner, image dimensions (in pixels) in top right, and filename (if any) in bottom.
	
	Tools:
	color pen/eraser/bucket fill: classic paint tools
	black pen: draw outlines with dedicated black pen (with dedicated pen size and color)
	color pen alt1: draw with color pen but behind black strokes
	color pen alt2: draw with color pen but behind black strokes and only over starting color
	color slots: left click to apply to color pens, right click to pick color. Last color in row is modified by color picker (middle mouse). 
	
	Buttons:
	x/menu/+: minimize/expand and detach/attach dock
	load/save/new: manage PNG files in res://.
	clear: clear the scribble (can be undone)
	size: resize the scribble (choose new width and height in pixels, and resize mode)
	sheet: if toggled, will load/save scribble as a subregion of the image on disk.
	copy: Drag the PNG file saved on disk from here to any texture in Editor. Can be dropped to "onions" or colors slots too.
	onions: Onion skinnings show original (black) outlines as semi-transparent and are non editable. \
	Drop files/textures to add. Left mouse: toggle onion skins visibility. Right mouse: clear all onions. 
	
	Drag and Drop:
	drawing area: drop any file or texture from Filesystem/Inspector/etc (with a PNG) to load it.
	copy: drag edited image from "copy", drop to any texture to apply it (image must be saved on disk).
	colors slots: drop files/textures to any slot to load colors found in image.
	onions: drop files or textures to load them as onion skinning. \
	drop colors to change color of new onion skins.

	Warnings: \
	Do not "Make Floating" the Scribbler dock if detached (may close plugin). \
	This plugin is made by a amateurish Godot coder, use with caution if editing nice assets. Likely inefficient for large files.
	"""
	file_dialogue.dialog_autowrap=true
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.popup()
	return file_dialogue


################################################################
## EDIT
	
## CLEAR DRAWING
func _on_clear_pressed():
	drawing.clear_drawing()

## RESIZE DRAWING (POPUP)
var resize_mode: String="crop_centered"
func _on_resize_pressed():
	_resize_dialogue()
func _resize_dialogue():
	
	var file_dialogue = ConfirmationDialog.new()
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
	resize_mode=_dialogue.get_scale_mode()#"crop_centered"# as in ready of packedscene
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

func _on_grid_toggled(toggle_on: bool):
	grid_indicator.set_grid_visibility(toggle_on)
#############################################################################################3
## DRAWING TOOLS
## Draw mode (must match drawing.gd)
var draw_mode: String="penblack"
func _on_draw_mode_pressed(input_tool: String):
	if input_tool=="pen":# color pen
		draw_mode="pen"
	elif input_tool=="penblack":
		draw_mode="penblack"
		drawing.resize_brush(pen_black_brush_scaling)
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="penoverfirst":# color pen
		draw_mode="penoverfirst"
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="penoverfirstbehindblack":# color pen
		draw_mode="penoverfirstbehindblack"
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="penbehindblack":
		draw_mode="penbehindblack"
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="eraser":
		draw_mode="eraser"
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="bucket":
		draw_mode="bucket"
	elif input_tool=="bucketbrush":
		draw_mode="bucketbrush"
	_update_draw_mode()
func _update_draw_mode():
	drawing.set_draw_mode(draw_mode)

## BRUSH SIZE
## we track separately brush size for black pen or color pen
var pen_black_brush_scaling: float=1.0
var pen_color_brush_scaling: float=1.0
#brush_scaling_changed.emit()
func on_drawing_brush_scaling_changed():
	if draw_mode=="pen_black":
		pen_black_brush_scaling=drawing.brush_scaling
	elif draw_mode=="regular" or draw_mode=="behindblack":
		pen_color_brush_scaling=drawing.brush_scaling


## BRUSH COLOR
## brush color (as controlled here instead of drawing)
var brush_colors: Array[Color]=[Color.WHITE,Color.DIM_GRAY,\
Color.DARK_RED,Color.DARK_GREEN,\
Color.DARK_BLUE,Color.ORANGE_RED,\
Color.TRANSPARENT]
var last_brush_color_button_pressed_index: int=0# last button selected
var brush_color: Color=brush_colors[last_brush_color_button_pressed_index]
func ready_brush_color():# choose all the colors
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()
func update_brush_color_buttons():
	var ic: int=0
	for i in brush_buttons:
		i.modulate=brush_colors[ic]
		ic+=1
func recolor_brush_from_last_color_button():
	brush_color=brush_colors[last_brush_color_button_pressed_index]
	drawing.recolor_brush(brush_color)
func _on_brush_color_i_pressed(index: int):# left click
	last_brush_color_button_pressed_index=index
	recolor_brush_from_last_color_button()
	#brush_color=brush_colors[index]
	#drawing.recolor_brush(brush_color)

var brush_color_i_hovered: int=-1# -1 if none
func _on_brush_color_i_data_dropped(input_color: Color,index: int):# dropped a color
	brush_colors[index]=input_color
	last_brush_color_button_pressed_index=index
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()
	#brush_color=brush_colors[index]
	#drawing.recolor_brush(brush_color)	
func _on_brush_color_i_colors_dropped(input_colors: Array[Color],index: int)->void: # drop array of colors, apply to row
	var ic:int=0
	for i in input_colors:
		brush_colors[ic]=i
		ic+=1
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()
func _on_brush_color_i_mouse_entered(index: int):
	#print("entered: ",index)
	brush_color_i_hovered=index
func _on_brush_color_i_mouse_exited(index: int):
	#print("exited: ",index)
	brush_color_i_hovered=-1
func brush_color_i_pick_color():# right clicked
	if brush_color_i_hovered!=-1:
		_brush_color_i_dialogue(brush_color_i_hovered)
func _brush_color_i_dialogue(index: int):
	var file_dialogue = ConfirmationDialog.new()
	file_dialogue.set_size(Vector2(320, 180))
	file_dialogue.title="Pick Brush Color"
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("confirmed",_on_brush_color_i_dialogue_confirmed)
	var _dialog: ColorPicker=ColorPicker.new()
	_dialog.connect("color_changed",_on_brush_color_i_dialogue_color_changed.bind(index))
	_dialog.color=brush_colors[index]
	_dialog.picker_shape=ColorPicker.SHAPE_VHS_CIRCLE
	_dialog.deferred_mode=true
	_dialog.edit_alpha=true
	_dialog.can_add_swatches=false
	_dialog.color_modes_visible=false
	_dialog.hex_visible=false
	_dialog.presets_visible=false
	_dialog.sampler_visible=true
	_dialog.sliders_visible=true
	file_dialogue.add_child(_dialog)
	file_dialogue.popup()
	return file_dialogue
func _on_brush_color_i_dialogue_color_changed(input_color: Color, index: int):## SIGNAL FROM DIALOGUE
	last_brush_color_button_pressed_index=index
	brush_colors[index]=input_color
func _on_brush_color_i_dialogue_confirmed():
	recolor_brush_from_last_color_button()
	update_brush_color_buttons()
## BRUSH COLOR FROM DRAWING COLOR PICKER
func on_drawing_color_picked(input_color: Color):
	#print("color picked:",input_color)
	#if input_color!=Color.BLACK:# only change last color in row
	last_brush_color_button_pressed_index=len(brush_colors)-1
	brush_colors[-1]=input_color
	#brush_color=brush_colors[-1]
	#drawing.recolor_brush(brush_color)
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()




################################################################
## FILES

## USE SHEETS OR NOT
var as_sheet: bool=false# use sheet for loading/saving
func _on_as_sheet_toggled(toggle_on: bool):
	as_sheet=toggle_on

## NEW DRAWING
func _on_new_pressed():
	drawing.new_drawing(px,py)
	reset_sheet()
	edited_file=""

###
## LOAD FROM FILE

func _on_load_pressed():
	if edited_file:
		_load_dialogue().set_current_path(edited_file)# doesnt display name
	else:
		_load_dialogue()
func _load_dialogue():
	var file_dialogue = EditorFileDialog.new()
	file_dialogue.clear_filters()
	file_dialogue.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialogue.filters = ["*.png ; PNG File"]
	file_dialogue.set_size(Vector2(640, 360))
	#file_dialogue.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_LIST)
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("file_selected", _on_load_dialogue_file_loaded)
	file_dialogue.popup()
	return file_dialogue
func _on_load_dialogue_file_loaded(input_file: String):
	load_selected(input_file)
func load_selected(input_file: String):
	if as_sheet:
		if input_file!=edited_file:
			reset_sheet()
		_load_from_sheet_select_subset_dialogue(input_file)
	else:
		drawing.load_drawing(input_file)
		edited_file=input_file
## LOAD SCRIBBLE FROM SHEET
var sheet_dialogue_input_subset: Array[int]=[1,1,1,1]# subx,suby,ix,iy, subset of source image
var load_from_sheet_selected_file: String# pass selected file
func reset_sheet():
	sheet_dialogue_input_subset=[1,1,1,1]
func _load_from_sheet_select_subset_dialogue(input_file: String):
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
	#file_dialogue.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_LIST)
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
## ONIONS

func ready_onion_controls():
	onion_onoff.visible=false
func on_onion_drop_clear_onions():## signal from onion_drop
	onion_indicator.clear_onions()
	onion_onoff.visible=false
func on_onion_drop_toggle_onions_visibility():
	onion_indicator.visible=not onion_indicator.visible
	onion_onoff.visible=onion_indicator.visible
func on_onion_drop_data_dropped(filename_: String):## signal from onion_drop
	if as_sheet:
		_load_onion_from_sheet_select_subset_dialogue(filename_)
	else:
		onion_indicator.add_onion(filename_)
		onion_indicator.visible=true
		onion_onoff.visible=true


## LOAD SCRIBBLE FROM SHEET
#var sheet_dialogue_input_subset: Array[int]=[1,1,1,1]# subx,suby,ix,iy, subset of source image
var load_onion_from_sheet_selected_file: String# pass selected file
func _load_onion_from_sheet_select_subset_dialogue(input_file: String):
	load_onion_from_sheet_selected_file=input_file
	var file_dialogue = ConfirmationDialog.new()
	file_dialogue.set_size(Vector2(640, 360))
	file_dialogue.title="Select Sheet Subset"
	EditorInterface.popup_dialog_centered(file_dialogue)
	file_dialogue.connect("confirmed",_on_load_onion_from_sheet_dialogue_confirmed)
	var _dialogue: Control=sheet_dialogue.instantiate()
	_dialogue.connect("subset_changed",_on_load_onion_from_sheet_dialogue_subset_changed)
	file_dialogue.add_child(_dialogue)
	_dialogue.set_subset(sheet_dialogue_input_subset)
	_dialogue.make(input_file,null)# make with null edited image
	file_dialogue.popup()
	return file_dialogue
func _on_load_onion_from_sheet_dialogue_subset_changed(input_subset: Array[int]):# subx,suby,ix,iy
	sheet_dialogue_input_subset=input_subset
func _on_load_onion_from_sheet_dialogue_confirmed():
	if load_onion_from_sheet_selected_file:
		onion_indicator.add_onion_from_sheet(load_onion_from_sheet_selected_file, sheet_dialogue_input_subset)
		onion_indicator.visible=true
		onion_onoff.visible=true
		load_onion_from_sheet_selected_file=""
		
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
## DEPRECATED

## SINGLE COLOR BUTTON CONTROLLING ALL COLORS
#func _on_brush_color_pressed():# deprecated
	#_brush_color_dialogue()
#func _brush_color_dialogue():
	#var file_dialogue = ConfirmationDialog.new()
	#file_dialogue.set_size(Vector2(320, 180))
	#file_dialogue.title="Pick Brush Color"
	#EditorInterface.popup_dialog_centered(file_dialogue)
	#file_dialogue.connect("confirmed",_on_brush_color_dialogue_confirmed)
	#var _hbox: HBoxContainer=HBoxContainer.new()
	#file_dialogue.add_child(_hbox)
	#for i in range(5):
		#var _dialog: ColorPicker=ColorPicker.new()
		#_dialog.connect("color_changed",_on_brush_color_dialogue_color_changed.bind(i))
		#_dialog.color=brush_colors[i]
		#_dialog.picker_shape=ColorPicker.SHAPE_VHS_CIRCLE
		#_dialog.deferred_mode=true
		#_dialog.edit_alpha=true
		#_dialog.can_add_swatches=false
		#_dialog.color_modes_visible=false
		#_dialog.hex_visible=false
		#_dialog.presets_visible=false
		#_dialog.sampler_visible=true
		#_dialog.sliders_visible=true
		#_hbox.add_child(_dialog)
	#file_dialogue.popup()
	#return file_dialogue
#func _on_brush_color_dialogue_color_changed(input_color: Color, index: int):## SIGNAL FROM DIALOGUE
	#brush_colors[index]=input_color
#func _on_brush_color_dialogue_confirmed():
	#update_brush_color_buttons()
