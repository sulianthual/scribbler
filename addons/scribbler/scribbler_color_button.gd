@tool
extends Button

# button with drag and drop of color

func _can_drop_data(position, data):
	#print("_can_drop_data: ",data, typeof(data))
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="png":
			return true
		if data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			return true
	elif typeof(data)==TYPE_COLOR:
		return true
	return false

signal data_dropped(value: Color)# return the png file
signal colors_dropped(value: Array[Color])
func _drop_data(position, data):
	if typeof(data)==TYPE_COLOR:
		data_dropped.emit(data)
	elif typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="png":
			var colors: Array[Color]=get_image_colors(data.files[0],7)
			colors_dropped.emit(colors)
		elif data.type=="resource" and data.resource.resource_path and data.resource.resource_path.get_extension()=="png":
			var colors: Array[Color]=get_image_colors(data.resource.resource_path,7)
			colors_dropped.emit(colors)
		#modulate=data# handled by scribbler menu

func _get_drag_data(at_position: Vector2):
	var _preview: ColorRect=ColorRect.new()
	_preview.color=modulate
	_preview.custom_minimum_size=Vector2i(20,20)
	set_drag_preview(_preview)
	return modulate
	
func get_image_colors(filename_:String,max_colors:int)->Array[Color]:
	var colors_found: Array[Color]=[]
	if FileAccess.file_exists(filename_):# overwrite an existing file editing a subset
		var _new_img: Image=Image.new()
		_new_img.convert(Image.FORMAT_RGBA8)
		_new_img=image_load(filename_)
		var maxed_out: bool=false
		for _iy in _new_img.get_height():
			if maxed_out:
				break
			for _ix in _new_img.get_width():
				if maxed_out:
					break
				var _col: Color=_new_img.get_pixel(_ix, _iy)
				if _col!=Color.BLACK and _col.a>0 and _col not in colors_found:
					colors_found.append(_col)
					if len(colors_found)>=max_colors:
						maxed_out=true
	return colors_found

func image_load(filename_: String)->Image:# image must be loaded as textures then converted
	if FileAccess.file_exists(filename_):
		var _texture: CompressedTexture2D=load(filename_)
		return _texture.get_image()
	else:
		return Image.new()
