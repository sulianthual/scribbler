@tool
extends Button

@onready var drawing: TextureRect=%drawing
## Resize: drop some obj_property that is vector 2 to resize
func _can_drop_data(position, data):
	#print("_can_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="obj_property" and data.has("value") and data["value"] is Vector2:
			return true
	return false
	
signal data_dropped(value: Vector2)# return the png file
func _drop_data(position, data):
	#print("_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="obj_property" and data.has("value") and data["value"] is Vector2:
			var px: int= roundi(drawing.px*data["value"][0])
			var py: int= roundi(drawing.py*data["value"][1])
			drawing.rescale_drawing(px,py)
