@tool
extends TextureRect


func _can_drop_data(position, data):
	print("_can_drop_data: ",data)
	return true
func _drop_data(position, data):
	pass
	#print("_drop_data: ",data)
