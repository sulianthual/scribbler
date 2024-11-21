@tool
extends TextureRect

## Scribbler: Draw and save images in Godot (for game prototyping)

## Drawing is active or not
var active: bool=false



@export_subgroup("image")
## Width in pixels
@export var px: int=128:
	set(value):
		px=value
		img_w=py
		px_changed.emit()
## Height in pixels
@export var py: int=128:
	set(value):
		py=value
		img_h=py
		py_changed.emit()
		img_w=img.get_width()


# Brush
@export_subgroup("brush")
### Scaling factor of brush
@export var brush_scaling: float=0.5
### Brush color
@export var brush_color: Color


###############################################################################
## SETUP
# Image
var img: Image# the image created or edited
var img_w: int# width in pixels (=px)
var img_h: int# height in pixels (=py)

# Brush
var brush_path: String="res://addons/scribbler/brush.png"
var brush_img: Image=Image.new()
var brush_size: int# brush size (same for x,y)
# Logic
var mouse_pos: Vector2# mouse position
var mouse_pos_last: Vector2# last moust position
var is_drawing: bool=false# pen is doing a drawing stroke
var is_erasing: bool=false# erase has been called
var img_history: Array[Image]=[]# backup of img from previous strokes

signal px_changed(value: int)
signal py_changed(value: int)
func _ready():
	load_brush()
	new_drawing()# there is always a drawing on display


###############################################################################
## FILES

func new_drawing():# create texture as image
	# Deduce image from existing Sprite 2D
	#var px_=int(texture.get_width()*scale.x)# account for scale and texture size
	#var py_=int(texture.get_height()*scale.y)
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	#img.fill(Color(1,1,1,0))# fill with transparent
	img.fill(Color(0,0,1,1))# TEST
	texture_from_img()
	
func load_drawing(filename_: String):## CALLS FROM SCRIBBLER
	if FileAccess.file_exists(filename_):
		img=Image.new()
		img.load(filename_)
		img.convert(Image.FORMAT_RGBA8)
		px=img.get_width()
		py=img.get_height()
		texture_from_img()
		# Deduce image from existing Sprite 2D
		#if px==img_w and py==img_h:# dimensions match 
			#texture_from_img()

func save_drawing(filename_: String):## CALLS FROM SCRIBBLER
	if img:
		img.save_png(filename_)

func close_drawing():## CALLS FROM SCRIBBLER
	new_drawing()# just make empty new drawing
###############################################################################
## IMAGE AND TEXTURE

func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture# beware of scale (should be 1,1)
	#set_texture(texture)# equivalent

func resize_drawing(input_px: int,input_py: int):
	var _last_img: Image=Image.new()# make image copy and blend to it
	_last_img.copy_from(img)
	img=Image.create(input_px,input_py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(Color(0,0,1,1))# TEST
	px=input_px
	py=input_py
	var ix: int=int(img_w/2-_last_img.get_width()/2)# top left corner for blending
	var iy: int=int(img_h/2-_last_img.get_height()/2)
	img.blend_rect(_last_img,Rect2(0,0,_last_img.get_width(),_last_img.get_height()),Vector2(ix,iy))
	texture_from_img()


###############################################################################
## BRUSH

func load_brush():# set the brush
	if FileAccess.file_exists(brush_path):
		brush_img.load(brush_path)
	brush_img.convert(Image.FORMAT_RGBA8)
	brush_img.resize(brush_scaling*brush_img.get_width(),brush_scaling*brush_img.get_height())
	brush_size = brush_img.get_width()
	if true:# ensure transparent background
		img=Image.new()
		img.copy_from(brush_img)
		img.fill(Color(0,0,0,1))# fill with transparent
		brush_img.blend_rect_mask(img,brush_img,Rect2(0,0,brush_img.get_width(),brush_img.get_height()),Vector2(0,0))
	#brush_img=utils.swap_img_color(brush_img,Color(0,0,0,1),brush_color)# initial image is black lines


	
###############################################################################
## DRAWING

var _drawing: bool=false# is drawing (within drawing area, Left Mouse Pressed)
var _first_point: bool=false# is drawing first point (no line-fill)
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			#print("pressed")
			_drawing=true
			_first_point=true
			_draw_point()
		else:
			#print("released")
			_drawing=false
	elif _drawing and event is InputEventMouseMotion:
		_draw_point()

var _last_ix: int# record last ix drawn for line filling
var _last_iy: int# record last ix drawn for line filling
var line_fill: bool=false
func _draw_point():
	var _mouse_pos: Vector2=get_global_mouse_position()
	var _rect: Rect2=get_global_rect()
	if _rect.has_point(_mouse_pos):
		if not line_fill or _first_point: # just a point
			var _diff: Vector2=_mouse_pos-_rect.get_center()# viewport global coords (pixels)
			var ix: int=int(_diff[0]/_rect.size[0]*px)# convert to image coords (pixels)
			var iy: int=int(_diff[1]/_rect.size[1]*py)
			img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(ix-brush_size/2+img_w/2,iy-brush_size/2+img_h/2))
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
				img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(lx-brush_size/2+img_w/2,ly-brush_size/2+img_h/2))
			_last_ix=ix# record last drawn point position
			_last_iy=iy
		texture.update(img)
		_first_point=false# no longer first point
	else:# outside edges
		_drawing=false
	
###############################################################################
## CALLS (from Scribbler)

func get_texture()->ImageTexture:
	return texture

func activate():
	active=true

func deactivate():
	active=false
	#clear_history()
	
###############################################################################
## DRAFTS


	#bru
	#if event.is_action_type()
#func _draw():# redraw (when calling _draw, not every _process)
	#if texture:# and active
		#texture.update(img)# update on an already made texture
#
#func _process(delta):
	#if not active:
		#return
	### TEST
	#img.fill(Color(1,0,0,1))
	##img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(0-brush_size/2+img_w/2,0-brush_size/2+img_h/2))
	#queue_redraw()# call draw again
	#return
	##
#
	### controls
	#mouse_pos_last=mouse_pos# last one
	#mouse_pos=get_global_mouse_position()
	### drawing
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#if not is_drawing:
			#is_drawing=true
			#start_stroke()
			#add_strokepart_start()
		#else:
			#add_strokepart()
	#else:	
		#if is_drawing:
			#is_drawing=false
			#end_stroke()
	### erasing
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#if not is_erasing:
			#is_erasing=true
			#remove_stroke()
	#else:
		#if is_erasing:
			#is_erasing=false

###########################################
### DRAWING FUNCTIONS

func start_stroke():# start new stroke when pressing lmouse
	is_drawing=true
	add_to_history()
func add_strokepart_start():# strokepart start (draw dot at current mouse)
	var ix= int(round(mouse_pos.x-global_position.x))
	var iy= int(round(mouse_pos.y-global_position.y))
	img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(ix-brush_size/2+img_w/2,iy-brush_size/2+img_h/2))
func add_strokepart():# strokepart (draw line between last mouse - current mouse)
	var ix0= (mouse_pos_last.x-global_position.x)
	var iy0= (mouse_pos_last.y-global_position.y)
	var ix1= (mouse_pos.x-global_position.x)
	var iy1= (mouse_pos.y-global_position.y)
	var dist=max(abs(ix1-ix0),abs(iy1-iy0))
	for i in range(dist):
		#var ix=ix0+i/dist*(ix1-ix0)
		#var iy=iy0+i/dist*(iy1-iy0)
		var ix=int(round(ix0+i/dist*(ix1-ix0)))
		var iy=int(round(iy0+i/dist*(iy1-iy0)))
		#img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(int(round(ix-brush_size/2+img_w/2)),int(round(iy-brush_size/2+img_h/2))))
		img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(ix-brush_size/2+img_w/2,iy-brush_size/2+img_h/2))
	queue_redraw()# call draw again
func end_stroke():
	is_drawing=false
	#save_drawing()# save drawing systematically
func remove_stroke():# remove stroke with rmouse
	if len(img_history)>0:
		img=img_history[-1]# replace with former one
		img_history.pop_back()# remove last from history (as it become the img)
	else:
		clear_drawing()
	queue_redraw()# call draw again
func clear_drawing():
	img.fill(Color(1,1,1,0))# empty transparent canvas
	clear_history()
	#erase_drawing_save()# erase the saved drawing too
func add_to_history():# add former image to histor
	var img_former=Image.new()# save former stroke
	img_former.copy_from(img)
	img_history.append(img_former)
func clear_history():# clear history of strokes
	img_history=[]

###########################################
### SUBFUNCTIONS


#func save_drawing():
	#if img:
		#var filename_=get_filename()
		#img.save_png(filename_)
#func erase_drawing_save():
	#var filename_=get_filename()
	#if FileAccess.file_exists(filename_):
		#DirAccess.remove_absolute(filename_)
#func drawing_exists():
	#var filename_=get_filename()
	#return FileAccess.file_exists(filename_)





#############################################################################
## CALLS


	
