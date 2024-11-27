@tool
extends Button

## Drag image file to other drop somewhere else in editor
## Rq: drop is handled by drawing 

var drag_filename: String=""# data to be dragged
 
func _get_drag_data(at_position: Vector2):
	if drag_filename and ResourceLoader.exists(drag_filename):
		# Make preview (must be on the fly
		var _preview: Label=Label.new()
		_preview.text=drag_filename
		set_drag_preview(_preview)
		# Make dragged data (we hint dictionary structure used when dropping)
		var _dict: Dictionary={}
		_dict["type"]="files"
		_dict["files"]=[drag_filename]
		_dict["from"]=self
		return _dict
	else:
		return null

func set_filename(input_filename: String):
	drag_filename=input_filename
