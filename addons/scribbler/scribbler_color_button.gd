@tool
extends Button

# button with drag and drop of color

func _can_drop_data(position, data):
	#print("_can_drop_data: ",data, typeof(data))
	return typeof(data)==TYPE_COLOR

signal data_dropped(value: Color)# return the png file
func _drop_data(position, data):
	if typeof(data)==TYPE_COLOR:
		data_dropped.emit(data)
		#modulate=data# handled by scribbler menu

func _get_drag_data(at_position: Vector2):
	var _preview: Control
	#set_drag_preview(_preview)
	return modulate
