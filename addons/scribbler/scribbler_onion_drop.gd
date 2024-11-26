@tool
extends Button

## DROP onion texturesx
@export var onion_indicator: TextureRect

func _ready() -> void:
	connect("pressed",on_pressed)
	connect("mouse_entered",on_mouse_entered)
	connect("mouse_exited",on_mouse_exited)

signal clear_onions
signal toggle_onions_visibilty
func on_pressed():
	toggle_onions_visibilty.emit()
	#if onion_indicator:
		#onion_indicator.clear_onions()
var is_hovered: bool=false		
func on_mouse_entered():
	is_hovered=true
func on_mouse_exited():
	is_hovered=false
	rmouse_pressed=false

var rmouse_pressed: bool=false
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:# UNDO
			if not rmouse_pressed and is_hovered:
				clear_onions.emit()
			rmouse_pressed=true
		else:
			rmouse_pressed=false


	
func _can_drop_data(position, data):
	#print("_can_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="png":
			return true
		if data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			return true
	return false
	
signal data_dropped(value: String)# return the png file
func _drop_data(position, data):
	#print(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))# works
	#print("_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="png":
			data_dropped.emit(data.files[0])# let menu handle loading
			#if onion_indicator:
				#onion_indicator.add_onion(data.files[0])
		elif data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			data_dropped.emit(data.resource.resource_path)
			#if onion_indicator:
				#onion_indicator.add_onion(data.resource.resource_path)
