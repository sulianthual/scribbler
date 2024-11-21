@tool
extends TextureRect

## Scribbler: Draw and save images in Godot (for game prototyping)

## Drawing is active or not
var active: bool=false

@export_subgroup("file")
## save directory
var directory: String="res://"
## drawing name 
var dname: String="toto"
## Drawing extension
var extension: String="png"

@export_subgroup("image")
## Width in pixels
@export var px: int=128#=int(texture.get_width()*scale.x)# account for scale and texture size
## Height in pixels
@export var py: int=128#=int(texture.get_height()*scale.y)


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
var img_w: int# width in pixels
var img_h: int# height in pixels
#var texture_: ImageTexture# the image texture
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

func _ready():
	#create_empty_drawing()
	#load_drawing()
	##
	##TEST
	if false:
		var _img: Image=Image.create(128,128,false, Image.FORMAT_RGBA8)
		_img.convert(Image.FORMAT_RGBA8)
		_img.fill(Color(0,0,1,1))
		_img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(0-brush_size/2+img_w/2,0-brush_size/2+img_h/2))
		#_img.save_png("res://test_control/toto.png")
		#_img.load("res://test_control/toto.png")
		#var _texture: ImageTexture=ImageTexture.new()
		var _texture: ImageTexture=ImageTexture.create_from_image(_img)
		texture=_texture
	## TEST 2
	if true:
		load_brush()
		create_empty_drawing()	
		var _texture: ImageTexture=ImageTexture.create_from_image(img)
		texture=_texture
		#print(_texture
		#print(_texture._get_width())
		
		#texture=_texture
		#queue_redraw()
		
func create_empty_drawing():# create texture as image
	# Deduce image from existing Sprite 2D
	#var px_=int(texture.get_width()*scale.x)# account for scale and texture size
	#var py_=int(texture.get_height()*scale.y)
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(Color(1,1,1,1))# fill with white
	img_w=img.get_width()
	img_h=img.get_height()
	#texture_from_img()

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

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var _mouse_position: Vector2=get_viewport().get_mouse_position()
		print(_mouse_position)
		var ix: int=int(_mouse_position[0])
		var iy: int=int(_mouse_position[1])
		#img.fill(Color(0,0,1,1))# fill with transparent
		img.blend_rect(brush_img,Rect2(0,0,brush_size,brush_size),Vector2(ix-brush_size/2+img_w/2,iy-brush_size/2+img_h/2))
		texture.update(img)

#func _draw():# redraw (when calling _draw, not every _process)
	#if texture:# and active
		#texture.update(img)# update on an already made texture
		
###############################################################################
## METHODS


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
	save_drawing()# save drawing systematically
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
	erase_drawing_save()# erase the saved drawing too
func add_to_history():# add former image to histor
	var img_former=Image.new()# save former stroke
	img_former.copy_from(img)
	img_history.append(img_former)
func clear_history():# clear history of strokes
	img_history=[]

###########################################
### SUBFUNCTIONS

func get_filename():
	return directory+"/"+dname+"."+extension
func save_drawing():
	if img:
		var filename_=get_filename()
		img.save_png(filename_)
func erase_drawing_save():
	var filename_=get_filename()
	if FileAccess.file_exists(filename_):
		DirAccess.remove_absolute(filename_)
func drawing_exists():
	var filename_=get_filename()
	return FileAccess.file_exists(filename_)
func load_drawing():
	var filename_=get_filename()
	if FileAccess.file_exists(filename_):## TEST
		img=Image.new()
		img.load(filename_)
		img.convert(Image.FORMAT_RGBA8)
		img_w=img.get_width()
		img_h=img.get_height()
		# Deduce image from existing Sprite 2D
		if px==img_w and py==img_h:# dimensions match 
			texture_from_img()
		else:# no match, make new drawing
			create_empty_drawing()
	else:
		create_empty_drawing()


func texture_from_img():# Make The Sprite2D Texture from Image (replaces whatever it was)
	scale=Vector2(1,1)# readjust Sprite 2D to have Texture from Image, and scale=(1,1)
	texture=ImageTexture.create_from_image(img)# (re)create image texture
	#set_texture(texture)# equivalent to former line

#############################################################################
## CALLS

func activate():
	active=true

func deactivate():
	active=false
	clear_history()
	
