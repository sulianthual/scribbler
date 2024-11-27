@tool
extends Button

## DROP onion texturesx
@onready var onion_indicator: TextureRect=%onion_indicator

func _ready() -> void:
	connect("pressed",on_pressed)
	connect("mouse_entered",on_mouse_entered)
	connect("mouse_exited",on_mouse_exited)

signal clear_onions
signal toggle_onions_visibilty
func on_pressed():
	toggle_onions_visibilty.emit()# let menu handle it
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
				reset_onions()
			rmouse_pressed=true
		else:
			rmouse_pressed=false

func reset_onions():
	clear_onions.emit()
	modulate=Color.WHITE
	#add_theme_stylebox_override()
	onion_indicator.reset_outlines_color()
	
func _can_drop_data(position, data):
	#print("_can_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="png":
			return true
		if data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			return true
	elif typeof(data)==TYPE_COLOR:
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
	elif typeof(data)==TYPE_COLOR:
		#print("dropped color")
		modulate=data
		onion_indicator.set_outlines_color(data)
