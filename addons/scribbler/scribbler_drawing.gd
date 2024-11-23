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
# Drawing
const line_fill: bool=true# use line algorithm to fill gaps
const max_undos: int=10## Max number of undos (important, high=performance issues)
# Brush
const brush_path: String="res://addons/scribbler/scribbler_brush.png"# must be square!
var brush_size_min: float=0.1# brush size min: (1x1 adjust according to base) 
const brush_size_max: float=10.0# brush size max
const brush_size_start: float=1.0# brush size start
const brush_resize_rate: float=1.03# rate of increase/decrease of brush size
var brush_img_base: Image=Image.new()# base brush
var brush_img: Image=Image.new()# image for brush
var eraser_img: Image=Image.new()# image for eraser (brush_img with transparency inverted)
var brush_scaling: float=1.0# brush scaling respective to size start
var brush_color: Color=Color.BLACK# Brush color (at ready)
const brush_line_step_ratio: float=0.25# draw line skiping brush_size*ratio (high=performance gain but possible gaps)
var brush_size: int# brush size tracked (for maths): Brush needs to be square!
# Logic
var active: bool=false# drawing active or not (able to receive inputs)
# Signals
signal px_changed(value: int)
signal py_changed(value: int)
signal mouse_position_changed()
signal brush_scaling_changed()
signal brush_color_changed()
signal brush_changed_in_chain()# end of chained changes (scaling, color)
#
func _ready():
	load_brush()
	_postready.call_deferred()
func _postready():
	pass


###############################################################################
## FILES

func new_drawing(input_px: int, input_py: int):# create texture as image
	px=input_px
	py=input_py
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(back_color)
	texture_from_img()
	clear_undo_history()#-> clears all previous
	
func load_drawing(filename_: String):## CALLS FROM SCRIBBLER
	if FileAccess.file_exists(filename_):
		img=Image.new()
		img.load(filename_)
		img.convert(Image.FORMAT_RGBA8)
		#img.copy_from(_swap_color(img,back_color_in_file,back_color))# swap colors
		px=img.get_width()
		py=img.get_height()
		texture_from_img()
		clear_undo_history()#-> clears all previous!

func save_drawing(filename_: String):## CALLS FROM SCRIBBLER
	if img:
		img.save_png(filename_)
		#_swap_color(img,back_color,back_color_in_file).save_png(filename_)# swap color
		
### SHEETS: load or save subset
func load_drawing_subset(filename_: String, input_subset: Array[int]):## CALLS FROM SCRIBBLER, subset=subx,suby,ix,iy
	if FileAccess.file_exists(filename_):
		var source_img: Image=Image.new()
		source_img.convert(Image.FORMAT_RGBA8)
		source_img.load(filename_)
		var subx: int=input_subset[0]
		var suby: int=input_subset[1]
		var ix: int=input_subset[2]
		var iy: int=input_subset[3]
		var subset_rect: Rect2i=_get_image_subset_rect(source_img,subx,suby,ix,iy)# subset region
		img=Image.new()
		img.convert(Image.FORMAT_RGBA8)
		img=source_img.get_region(subset_rect)
		px=img.get_width()
		py=img.get_height()
		texture_from_img()
		clear_undo_history()#-> clears all previous!

func save_drawing_subset(filename_: String,input_subset: Array[int]):## CALLS FROM SCRIBBLER, subset=subx,suby,ix,iy
	if FileAccess.file_exists(filename_):
		var source_img: Image=Image.new()
		source_img.convert(Image.FORMAT_RGBA8)
		source_img.load(filename_)
		var subx: int=input_subset[0]
		var suby: int=input_subset[1]
		var ix: int=input_subset[2]
		var iy: int=input_subset[3]
		var subset_rect: Rect2i=_get_image_subset_rect(source_img,subx,suby,ix,iy)# subset region
		var img_rect: Rect2i=Rect2i(0,0,img.get_width(),img.get_height())
		source_img.blit_rect(img,img_rect,subset_rect.position)
		source_img.save_png(filename_)

func _get_image_subset_rect(source_img: Image,subx: int, suby:int, ix:int, iy:int)->Rect2i:#->determine subset
	# ix,iy are the coordinates and start at 1,1
	var subset_rect_w: int=roundi(source_img.get_width()/subx)
	var subset_rect_h: int=roundi(source_img.get_height()/suby)
	var subset_rect_x: int=subset_rect_w*clamp(ix-1,0,subx-1)
	var subset_rect_y: int=subset_rect_h*clamp(iy-1,0,suby-1)
	var subset_rect: Rect2i=Rect2i(subset_rect_x,subset_rect_y,subset_rect_w,subset_rect_h)
	return subset_rect
###############################################################################
## IMAGE AND TEXTURE

func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture# beware of scale (should be 1,1)

func clear_drawing():
	save_img_to_undo_history()
	img.fill(back_color)
	texture_from_img()
	
func resize_drawing(input_px: int,input_py: int):# crop mode
	save_img_to_undo_history()#-> save to history
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

func rescale_drawing(input_px: int,input_py: int, interpolation_mode: Image.Interpolation):# stretch mode
	save_img_to_undo_history()#-> save to history
	px=input_px
	py=input_py
	img.resize(input_px,input_py,interpolation_mode)
	texture_from_img()


func _swap_color(input_image: Image,source_color: Color, new_color: Color):
	var _new_img: Image=Image.new()
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(input_image)
	for _iy in _new_img.get_height():
		for _ix in _new_img.get_width():
			if _new_img.get_pixel(_ix, _iy) == source_color:
				_new_img.set_pixel(_ix, _iy, new_color)
	return _new_img

## swap anythin that ISNT transparent with new_color
func _swap_color_nontransparent(input_image: Image,new_color: Color):
	var _new_img: Image=Image.create(input_image.get_width(),input_image.get_height(),false, Image.FORMAT_RGBA8)
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.fill(Color.TRANSPARENT)
	var _cfill: Image=Image.create(input_image.get_width(),input_image.get_height(),false, Image.FORMAT_RGBA8)
	_cfill.convert(Image.FORMAT_RGBA8)
	_cfill.fill(new_color)
	_new_img.blit_rect_mask(_cfill,input_image,Rect2(0,0,input_image.get_width(),input_image.get_height()),Vector2(0,0))
	return _new_img

## swap transparent and visible (transparent becomes white)->for making masks
func _swap_transparent(input_image: Image)->Image:
	var _new_img: Image=Image.create(input_image.get_width(),input_image.get_height(),false, Image.FORMAT_RGBA8)
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(input_image)
	_new_img=_swap_color_nontransparent(_new_img,Color.RED)
	_new_img=_swap_color(_new_img,Color.TRANSPARENT, Color.WHITE)
	_new_img=_swap_color(_new_img,Color.RED, Color.TRANSPARENT)
	return _new_img
###############################################################################
## BRUSH AND ERASER

func load_brush():# set the brush
	if FileAccess.file_exists(brush_path):
		brush_img_base.load(brush_path)
	brush_img_base.convert(Image.FORMAT_RGBA8)
	brush_img.convert(Image.FORMAT_RGBA8)
	brush_size_min=float(1.5/brush_img_base.get_width())# 1x1 min size (1.5 instead of 1 or disappears from rounding artifacts)
	resize_brush(brush_size_start)
	

func resize_brush(input_brush_scaling: float):## CALLS FROM SCRIBBLER
	brush_scaling=input_brush_scaling
	brush_img.copy_from(brush_img_base)
	brush_size = brush_img.get_width()
	brush_img.resize(round(brush_scaling*brush_size),round(brush_scaling*brush_size),Image.INTERPOLATE_NEAREST)
	brush_size = brush_img.get_width()# brush must be square
	brush_scaling_changed.emit()
	recolor_brush(brush_color)
	eraser_from_brush()

func recolor_brush(input_color: Color):
	brush_color=input_color
	brush_img=_swap_color_nontransparent(brush_img,brush_color)
	brush_color_changed.emit()
	brush_changed_in_chain.emit()# Single signal after size, color changed

func eraser_from_brush():
	eraser_img.copy_from(brush_img)
	eraser_img.fill(Color.TRANSPARENT)
	

###############################################################################
## DRAWING

## UNDOS HISTORY
var undo_imgs: Array[Image]
func undo():## CALLS FROM SCRIBBLER
	if len(undo_imgs)>1:
		img=undo_imgs[-2]
		px=img.get_width()
		py=img.get_height()
		texture_from_img()
		undo_imgs.pop_back()
func save_img_to_undo_history():
	if len(undo_imgs)>=max_undos:
		undo_imgs.pop_front()
	var _new_img: Image=Image.create(img.get_width(),img.get_height(),false, Image.FORMAT_RGBA8)
	_new_img.convert(Image.FORMAT_RGBA8)
	_new_img.copy_from(img)
	undo_imgs.append(_new_img)
func clear_undo_history():
	undo_imgs=[]
	save_img_to_undo_history()
	
## MODE
var draw_over: bool=false# draw over existing 
var draw_behind: bool=false# draw behind existing
func set_draw_mode(input_draw_mode: String):## CALLS FROM SCRIBBLER
	if input_draw_mode=="regular":
		draw_over=false
		draw_behind=false
	elif input_draw_mode=="over":
		draw_over=true
		draw_behind=false
	elif input_draw_mode=="behind":
		draw_over=false
		draw_behind=true

## INPUTS
var _drawing: bool=false# is drawing (within drawing area, Left Mouse Pressed)
var _erasing: bool=false# is ersing (within drawing area, Right Mouse Pressed)
var _first_point: bool=false# is drawing first point (no line-fill)
func _input(event):
	print(active)

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
				save_img_to_undo_history()
				_drawing=false
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				#print("pressed")
				_drawing=false
				_erasing=true
				_first_point=true
				_draw_point()
			else:
				save_img_to_undo_history()
				#print("released")
				_erasing=false
		elif event is InputEventMouseMotion:
			mouse_position_changed.emit()
			if not _first_point and (_drawing or _erasing):
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
var _last_ix: float# record last ix drawn for line filling (as float for accuracy)
var _last_iy: float# record last ix drawn for line filling
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
		if not line_fill or _first_point: # blit brush at a point
			var _diff: Vector2=_mouse_pos-_rect.get_center()# viewport global coords (pixels)
			var ix: float=_diff[0]/float(_rect.size[0])*float(px)# convert to image coords (pixels)
			var iy: float=_diff[1]/float(_rect.size[1])*float(py)# as float for refined positining
			var offr: Rect2=Rect2(0,0,brush_size,brush_size)
			var offx: float=-float(brush_size)/2+float(px)/2# precompute
			var offy: float=-float(brush_size)/2+float(py)/2
			if _drawing:
				if draw_behind:
					var _region: Rect2i=Rect2i(roundi(ix+offx),roundi(iy+offy),brush_size,brush_size)# region being drawn
					var _mask: Image=_swap_transparent(img.get_region(_region))
					img.blend_rect_mask(brush_img,_mask,offr,Vector2(roundi(ix+offx),roundi(iy+offy)))
				elif draw_over:
					var _region: Rect2i=Rect2i(roundi(ix+offx),roundi(iy+offy),brush_size,brush_size)# region being drawn
					var _mask: Image=img.get_region(_region)
					img.blend_rect_mask(brush_img,_mask,offr,Vector2(roundi(ix+offx),roundi(iy+offy)))
				else:
					img.blend_rect(brush_img,offr,Vector2(roundi(ix+offx),roundi(iy+offy)))
			elif _erasing:
				img.blit_rect_mask(eraser_img,brush_img,offr,Vector2(roundi(ix+offx),roundi(iy+offy)))
			_last_ix=ix# record last drawn point position (as int!)
			_last_iy=iy
			_first_point=false# no longer first point
		else: # blit brush along a line between last point and current point
			var _diff: Vector2=_mouse_pos-_rect.get_center()# in screen pixels
			var ix: float=_diff[0]/float(_rect.size[0])*float(px)# convert to image coords (pixels)
			var iy: float=_diff[1]/float(_rect.size[1])*float(py)
			#var _dist: float=max(abs(ix-_last_ix),abs(iy-_last_iy))
			var _dist: float=ceili(sqrt((ix-_last_ix)**2+(iy-_last_iy)**2))
			var offr: Rect2=Rect2(0,0,brush_size,brush_size)
			var offx: float=-float(brush_size)/2+float(px)/2# precompute
			var offy: float=-float(brush_size)/2+float(py)/2
			var _step: int=clampi(int(brush_size*brush_line_step_ratio),1,brush_size)
			for i in range(0,_dist+1,_step):# fill while trying to skip steps to increase performance
				var lx: float=_last_ix+float(i)/_dist*(ix-_last_ix)
				var ly: float=_last_iy+float(i)/_dist*(iy-_last_iy)
				if _drawing:
					if draw_behind:
						var _region: Rect2i=Rect2i(roundi(lx+offx),roundi(ly+offy),brush_size,brush_size)# region being drawn
						var _mask: Image=_swap_transparent(img.get_region(_region))
						img.blend_rect_mask(brush_img,_mask,offr,Vector2(roundi(lx+offx),roundi(ly+offy)))
					elif draw_over:
						var _region: Rect2i=Rect2i(roundi(lx+offx),roundi(ly+offy),brush_size,brush_size)# region being drawn
						var _mask: Image=img.get_region(_region)
						img.blend_rect_mask(brush_img,_mask,offr,Vector2(roundi(lx+offx),roundi(ly+offy)))
					else:
						img.blend_rect(brush_img,offr,Vector2(roundi(lx+offx),roundi(ly+offy)))
				elif _erasing:
					img.blit_rect_mask(eraser_img,brush_img,offr,Vector2(roundi(lx+offx),roundi(ly+offy)))
			_last_ix=ix# record last drawn point position (as int!)
			_last_iy=iy
		texture.update(img)
		
	else:# outside edges
		_drawing=false
		_erasing=false
		save_img_to_undo_history()

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
