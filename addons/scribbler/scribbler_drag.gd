@tool
extends Button

## Drag image file to other drop somewhere else in editor
## Rq: drop is handled by drawing 

var drag_filename: String=""# data to be dragged
 
func _get_drag_data(at_position):
	if drag_filename and ResourceLoader.exists(drag_filename):
		var _dict: Dictionary={}
		_dict["type"]="files"
		_dict["files"]=[drag_filename]
		_dict["from"]=self
		return _dict
	else:
		return null

func set_filename(input_filename: String):
	drag_filename=input_filename
