@tool
extends Button

## DROP onion texturesx
@export var onion_indicator: TextureRect

func _ready() -> void:
	connect("pressed",on_pressed)
func on_pressed():
	if onion_indicator:
		onion_indicator.clear_onions()
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
			#data_dropped.emit(data.files[0])# let menu handle loading
			if onion_indicator:
				onion_indicator.add_onion(data.files[0])
		elif data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			#data_dropped.emit(data.resource.resource_path)
			if onion_indicator:
				onion_indicator.add_onion(data.resource.resource_path)
