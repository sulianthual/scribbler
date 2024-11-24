@tool
extends Control

@onready var drawing: TextureRect=%drawing
###############################################################################
## DROP DATA 

func _can_drop_data(position, data):
	#print("_can_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="png":
			return true
		if data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			return true
	return false
func _drop_data(position, data):
	#print("_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="png":
			drawing.load_drawing(data.files[0])# if PNG
		elif data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			drawing.load_drawing(data.resource.resource_path)
			print("loaded: ",data.resource.resource_path)
