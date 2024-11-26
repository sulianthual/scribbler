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
	
func clear_onions():## calls from Scribbler
	clear_canvas()
	
func add_onion(filename_: String):## Calls from scribbler
	if ResourceLoader.exists(filename_):
		var _img: Image=Image.new()
		_img.load(filename_)
		_img.convert(Image.FORMAT_RGBA8)
		_img=_make_transparent(_img,0.5)
		var _img_rect: Rect2i=Rect2i(0,0,_img.get_width(),_img.get_height())
		img.blend_rect(_img,_img_rect,Vector2(0,0))
		texture_from_img()
		
func add_onion_from_sheet(filename_: String,input_subset: Array[int]):## Calls from scribbler
	if ResourceLoader.exists(filename_):
		var subx: int=input_subset[0]
		var suby: int=input_subset[1]
		var ix: int=input_subset[2]
		var iy: int=input_subset[3]
		var source_img: Image=Image.new()
		source_img.convert(Image.FORMAT_RGBA8)
		source_img.load(filename_)
		var subset_rect: Rect2i=_get_image_subset_rect(source_img,subx,suby,ix,iy)# subset region
		var _img: Image=Image.new()
		_img.convert(Image.FORMAT_RGBA8)
		_img=source_img.get_region(subset_rect)
		_img=_make_transparent(_img,0.5)
		var _img_rect: Rect2i=Rect2i(0,0,_img.get_width(),_img.get_height())
		img.blend_rect(_img,_img_rect,Vector2(0,0))
		texture_from_img()

func _get_image_subset_rect(source_img: Image,subx: int, suby:int, ix:int, iy:int)->Rect2i:#->determine subset
	# ix,iy are the coordinates and start at 1,1
	var subset_rect_w: int=roundi(source_img.get_width()/subx)
	var subset_rect_h: int=roundi(source_img.get_height()/suby)
	var subset_rect_x: int=subset_rect_w*clamp(ix-1,0,subx-1)
	var subset_rect_y: int=subset_rect_h*clamp(iy-1,0,suby-1)
	var subset_rect: Rect2i=Rect2i(subset_rect_x,subset_rect_y,subset_rect_w,subset_rect_h)
	return subset_rect
	
func on_px_changed(input_px:int):
	px=input_px
	clear_canvas()
func on_py_changed(input_py:int):
	py=input_py
	clear_canvas()
func clear_canvas():
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(back_color)
	#if drawing.draw_mode==drawing.DRAW_MODES.PENBLACK:
		#img.blend_rect(drawing.black_pen_img,Rect2(0,0,drawing.black_pen_img.get_width(),drawing.black_pen_img.get_height()),Vector2(0,0))
	#else:
		#img.blend_rect(drawing.brush_img,Rect2(0,0,drawing.brush_img.get_width(),drawing.brush_img.get_height()),Vector2(0,0))
	texture_from_img()
func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture

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
