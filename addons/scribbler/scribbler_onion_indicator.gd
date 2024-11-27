@tool
extends TextureRect


## brush indicator (in front of drawing)
##
## displays size of brush
## same properties as drawing so resizes accordingly

## background color
@export var back_color: Color=Color.TRANSPARENT

@onready var drawing: TextureRect=%drawing

var img: Image=Image.new()
var px: int=128
var py: int=128
func _ready():
	drawing.connect("px_changed",on_px_changed)
	drawing.connect("py_changed",on_py_changed)
	_postready.call_deferred()
func _postready():
	px=drawing.px
	py=drawing.py
	#img=load("res://demo/head.png")## TEST
	clear_canvas()

func on_px_changed(input_px:int):
	px=input_px
	clear_canvas()
func on_py_changed(input_py:int):
	py=input_py
	clear_canvas()
func clear_onions():## calls from Scribbler
	clear_canvas()
func clear_canvas():
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(back_color)
	texture_from_img()
func add_onion(filename_: String):## Calls from scribbler
	if ResourceLoader.exists(filename_):
		var _img: Image=Image.new()
		#_img.load(filename_)
		_img=image_load(filename_)
		_img.convert(Image.FORMAT_RGBA8)
		_img=filter_onion(_img)
		var _img_rect: Rect2i=Rect2i(0,0,_img.get_width(),_img.get_height())
		img.blend_rect(_img,_img_rect,Vector2(0,0))
		texture_from_img()
		
func add_onion_from_sheet(filename_: String,input_subset: Array[int]):## Calls from scribbler
	if FileAccess.file_exists(filename_):
	#if ResourceLoader.exists(filename_):
		var subx: int=input_subset[0]
		var suby: int=input_subset[1]
		var ix: int=input_subset[2]
		var iy: int=input_subset[3]
		var source_img: Image=Image.new()
		#source_img.load(filename_)
		source_img=image_load(filename_)
		source_img.convert(Image.FORMAT_RGBA8)
		var subset_rect: Rect2i=_get_image_subset_rect(source_img,subx,suby,ix,iy)# subset region
		var _img: Image=Image.new()
		_img.convert(Image.FORMAT_RGBA8)
		_img=source_img.get_region(subset_rect)
		_img=filter_onion(_img)
		var _img_rect: Rect2i=Rect2i(0,0,_img.get_width(),_img.get_height())
		img.blend_rect(_img,_img_rect,Vector2(0,0))
		texture_from_img()

## Filter onion image
var filter_mode="outlines"
var transparency_factor: float=0.5
var outlines_color_ref: Color=Color(0,0,0,transparency_factor)
var outlines_color: Color=outlines_color_ref

func filter_onion(image: Image)->Image:
	var _img: Image=Image.create(image.get_width(),image.get_height(),false, Image.FORMAT_RGBA8)
	_img.convert(Image.FORMAT_RGBA8)
	_img.copy_from(image)
	if filter_mode=="semitransparent":
		image=_make_transparent(image,transparency_factor)# just transparent
	elif filter_mode=="outlines":
		_img=_swap_notcolor(_img,Color.BLACK, Color.TRANSPARENT)
		_img=_swap_color(_img,Color.BLACK, outlines_color)
	#_img.blit_rect_mask(image)
	return _img
func set_outlines_color(input_color: Color)->void: ## CALLS from scribbler or onion_drop
	outlines_color=input_color
	outlines_color.a=outlines_color.a*transparency_factor
func reset_outlines_color()->void: ## CALLS from scribbler or onion_drop
	outlines_color=outlines_color_ref
	

	
####################################
## UTILS

func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture

func image_load(filename_: String)->Image:# image must be loaded as textures then converted
	if FileAccess.file_exists(filename_):
		var _texture: CompressedTexture2D=load(filename_)
		return _texture.get_image()
	else:
		return Image.new()

func _get_image_subset_rect(source_img: Image,subx: int, suby:int, ix:int, iy:int)->Rect2i:#->determine subset
	# ix,iy are the coordinates and start at 1,1
	var subset_rect_w: int=roundi(source_img.get_width()/subx)
	var subset_rect_h: int=roundi(source_img.get_height()/suby)
	var subset_rect_x: int=subset_rect_w*clamp(ix-1,0,subx-1)
	var subset_rect_y: int=subset_rect_h*clamp(iy-1,0,suby-1)
	var subset_rect: Rect2i=Rect2i(subset_rect_x,subset_rect_y,subset_rect_w,subset_rect_h)
	return subset_rect
	
## swap anything that isnt source color with new_color
func _make_transparent(input_image: Image, factor: float):
	var _new_img: Image=Image.new()
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(input_image)
	for _iy in _new_img.get_height():
		for _ix in _new_img.get_width():
			var _col: Color=_new_img.get_pixel(_ix, _iy)
			_col.a=clamp(_col.a*factor,0,1)
			_new_img.set_pixel(_ix, _iy, _col)
	return _new_img

## swap anything that isnt source color with new_color
func _swap_notcolor(input_image: Image,source_color: Color, new_color: Color):
	var _new_img: Image=Image.new()
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(input_image)
	for _iy in _new_img.get_height():
		for _ix in _new_img.get_width():
			if _new_img.get_pixel(_ix, _iy) != source_color:
				_new_img.set_pixel(_ix, _iy, new_color)
	return _new_img

func _swap_color(input_image: Image,source_color: Color, new_color: Color):
	var _new_img: Image=Image.new()
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(input_image)
	for _iy in _new_img.get_height():
		for _ix in _new_img.get_width():
			if _new_img.get_pixel(_ix, _iy) == source_color:
				_new_img.set_pixel(_ix, _iy, new_color)
	return _new_img
	
