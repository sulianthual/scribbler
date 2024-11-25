@tool
extends TextureRect


func _can_drop_data(position, data):
	print("_can_drop_data: ",data)
