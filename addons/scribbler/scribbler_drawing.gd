@tool
extends TextureRect

## Scribbler: Draw and save images in Godot (for game prototyping)



@export_subgroup("image")
## Width in pixels
@export var px: int=256:
	set(value):
		var prev_value: int=px
		px=value
		if prev_value!=value:
			px_changed.emit(px)
## Height in pixels
@export var py: int=256:
	set(value):
		var prev_value: int=py
		py=value
		if prev_value!=value:
			py_changed.emit(py)






###############################################################################
## SETUP
# Image
var img: Image# the image created or edited
const back_color: Color=Color.TRANSPARENT#background color on new_drawing or resize (ignored in loaded images)
# Brush
const brush_path: String="res://addons/scribbler/scribbler_brush.png"
const brush_size_min: float=0.2# brush size min
const brush_size_max: float=10.0# brush size max
const brush_size_start: float=1.0# brush size start
const brush_resize_rate: float=1.01# rate of increase/decrease of brush size
var brush_img_base: Image=Image.new()# base brush
var brush_img: Image=Image.new()# image for brush
var eraser_img: Image=Image.new()# image for eraser (brush_img with transparency inverted)
var brush_scaling: float=1.0:# brush scaling respective to size start
	set(value):
		brush_scaling=value
		brush_scaling_changed.emit()
var brush_color: Color=Color.BLACK:# Brush color (at ready)
	set(value):
		brush_color=value
		brush_color_changed.emit()
var brush_size: int# brush size tracked (for maths)
# Logic
var active: bool=false# drawing active or not (able to receive inputs)
# Signals
signal px_changed(value: int)
signal py_changed(value: int)
signal mouse_position_changed()
signal brush_scaling_changed()
signal brush_color_changed()
#
func _ready():
	load_brush()
	_postready.call_deferred()
func _postready():
	pass
	#brush_color_changed.emit()# emit for other nodes

###############################################################################
## FILES

func new_drawing(input_px: int, input_py: int):# create texture as image
	px=input_px
	py=input_py
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(back_color)
	texture_from_img()
	
func load_drawing(filename_: String):## CALLS FROM SCRIBBLER
	if FileAccess.file_exists(filename_):
		img=Image.new()
		img.load(filename_)
		img.convert(Image.FORMAT_RGBA8)
		#img.copy_from(_swap_color(img,back_color_in_file,back_color))# swap colors
		px=img.get_width()
		py=img.get_height()
		# Replace back_color_on_file with back_color
		texture_from_img()

func save_drawing(filename_: String):## CALLS FROM SCRIBBLER
	if img:
		img.save_png(filename_)
		#_swap_color(img,back_color,back_color_in_file).save_png(filename_)# swap color
		

	
###############################################################################
## IMAGE AND TEXTURE

func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture# beware of scale (should be 1,1)
	#set_texture(texture)# equivalent

func resize_drawing(input_px: int,input_py: int):
	var _last_img: Image=Image.new()# make image copy and blend to it
	_last_img.copy_from(img)
	px=input_px
	py=input_py
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(back_color)
	var ix: int=int(px/2-_last_img.get_width()/2)# top left corner for blending
	var iy: int=int(py/2-_last_img.get_height()/2)
	img.blend_rect(_last_img,Rect2(0,0,_last_img.get_width(),_last_img.get_height()),Vector2(ix,iy))
	texture_from_img()

func _swap_color(input_image: Image,source_color: Color, new_color: Color):
	var _new_img: Image=Image.new()
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(input_image)
	for iy in _new_img.get_height():
			for ix in _new_img.get_width():
				if _new_img.get_pixel(ix, iy) == source_color:
					_new_img.set_pixel(ix, iy, new_color)
	return _new_img

## swap anythin that ISNT source color with new_color
func _swap_noncolor(input_image: Image,source_color: Color, new_color: Color):
	var _new_img: Image=Image.new()
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(input_image)
	for iy in _new_img.get_height():
			for ix in _new_img.get_width():
				if _new_img.get_pixel(ix, iy) != source_color:
					_new_img.set_pixel(ix, iy, new_color)
	return _new_img

###############################################################################
## BRUSH AND ERASER

func load_brush():# set the brush
	if FileAccess.file_exists(brush_path):
		brush_img_base.load(brush_path)
	brush_img_base.convert(Image.FORMAT_RGBA8)
	brush_img.convert(Image.FORMAT_RGBA8)
	brush_img.copy_from(brush_img_base)
	resize_brush(brush_size_start)
	

func resize_brush(input_brush_scaling: float):## CALLS FROM SCRIBBLER
	brush_scaling=input_brush_scaling
	brush_img.copy_from(brush_img_base)
	brush_img.resize(brush_scaling*brush_img.get_width(),brush_scaling*brush_img.get_height(),Image.INTERPOLATE_NEAREST)
	brush_size = brush_img.get_width()
	recolor_brush(brush_color)
	eraser_from_brush()

func recolor_brush(input_color: Color):
	brush_color=input_color
	brush_img=_swap_noncolor(brush_img,Color.TRANSPARENT,brush_color)

func eraser_from_brush():
	eraser_img.copy_from(brush_img)
	eraser_img.fill(Color.TRANSPARENT)
	

###############################################################################
## DRAWING

## INPUTS
var _drawing: bool=false# is drawing (within drawing area, Left Mouse Pressed)
var _erasing: bool=false# is ersing (within drawing area, Right Mouse Pressed)
var _first_point: bool=false# is drawing first point (no line-fill)
func _input(event):
	if active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				#print("pressed")
				_drawing=true
				_erasing=false
				_first_point=true
				_draw_point()
			else:
				#print("released")
				_drawing=false
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				#print("pressed")
				_drawing=false
				_erasing=true
				_first_point=true
				_draw_point()
			else:
				#print("released")
				_erasing=false
		elif event is InputEventMouseMotion:
			mouse_position_changed.emit()
			if _drawing or _erasing:
				_draw_point()
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_WHEEL_UP:
			resize_brush(clamp(brush_scaling*brush_resize_rate,brush_size_min,brush_size_max))
			_drawing=false
			_erasing=false
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			resize_brush(clamp(brush_scaling/brush_resize_rate,brush_size_min,brush_size_max))
			_drawing=false
			_erasing=false
## DRAW
var _last_ix: int# record last ix drawn for line filling
var _last_iy: int# record last ix drawn for line filling

var line_fill: bool=false## TODO: test interpolation as is NOT WORKING
var _rect: Rect2# area of drawing rectangle (important)
func _draw_point():
	var _mouse_pos: Vector2=get_global_mouse_position()
	# determine drawing rectangle (must control for margins)
	var _rectm: Rect2=get_global_rect()# drawable rectangle +potential margins
	var _rectc: Vector2=_rectm.get_center()# center
	var _rects: Vector2=_rectm.size# size
	var _rectr: float=float(px)/float(py)/float(_rectm.size[0])*float(_rectm.size[1])# ratio
	#var _rect: Rect2=_rectm
	if _rectr<1.0:# has width margins
		_rect=rect_from_centered_rect(Rect2(_rectc,Vector2(_rects[0]*_rectr,_rects[1])))
	elif _rectr>1.0:# has height margins
		_rect=rect_from_centered_rect(Rect2(_rectc,Vector2(_rects[0],_rects[1]/_rectr)))
	else:# no margins
		_rect=_rectm
	# draw
	if _rect.has_point(_mouse_pos):
		if not line_fill or _first_point: # just a point
			var _diff: Vector2=_mouse_pos-_rect.get_center()# viewport global coords (pixels)
			var ix: int=int(_diff[0]/_rect.size[0]*px)# convert to image coords (pixels)
			var iy: int=int(_diff[1]/_rect.size[1]*py)
			if _drawing:
				img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(ix-brush_size/2+px/2,iy-brush_size/2+py/2))
			elif _erasing:
				img.blit_rect_mask(eraser_img,brush_img,Rect2(0,0,brush_size,brush_size),Vector2(ix-brush_size/2+px/2,iy-brush_size/2+py/2))
			_last_ix=ix# record last drawn point position
			_last_iy=iy
		else: # fill to last line ## TODO NOT WORKING
			var _diff: Vector2=_mouse_pos-_rect.get_center()# in screen pixels
			var ix: int=int(_diff[0]/_rect.size[0]*px)
			var iy: int=int(_diff[1]/_rect.size[1]*py)
			var _dist=max(abs(ix-_last_ix),abs(iy-_last_iy))
			for i in range(_dist):
				var lx=int(round(_last_ix+float(i/_dist)*float(ix-_last_ix)))
				var ly=int(round(_last_iy+float(i/_dist)*float(iy-_last_iy)))
				if _drawing:
					img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(lx-brush_size/2+px/2,ly-brush_size/2+py/2))
				elif _erasing:
					img.blit_rect_mask(eraser_img,brush_img,Rect2(0,0,brush_size,brush_size),Vector2(lx-brush_size/2+px/2,ly-brush_size/2+py/2))
			_last_ix=ix# record last drawn point position
			_last_iy=iy
		texture.update(img)
		_first_point=false# no longer first point
	else:# outside edges
		_drawing=false

func rect_from_centered_rect(rectc: Rect2)->Rect2:# convert a Rect(center:Vector2,size:Vector2) to regular
	return Rect2(rectc.position[0]-rectc.size[0]/2,rectc.position[1]-rectc.size[1]/2,rectc.size[0],rectc.size[1])
###############################################################################
## CALLS (from Scribbler)

func get_texture()->ImageTexture:
	return texture

func activate():
	active=true

func deactivate():
	active=false
	_drawing=false
	_erasing=false
	
###############################################################################
