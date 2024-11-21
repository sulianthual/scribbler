extends Sprite2D

## Scribbler: Draw and save images in Godot (for game prototyping)

## Drawing is active or not
@export var active: bool=true

@export_subgroup("file")
## save directory
@export_dir var directory: String
## drawing name 
@export var dname: String
## Drawing extension
@export var extension: String="png"
## Load drawing
@export var load: bool=false:
	set(value):
		load_drawing()
		load=false
## Save drawing
@export var save: bool=false:
	set(value):
		save_drawing()
		save=false

@export_subgroup("image")
## Width in pixels
@export var px: int=128#=int(texture.get_width()*scale.x)# account for scale and texture size
## Height in pixels
@export var py: int=128#=int(texture.get_height()*scale.y)
##clear drawing
@export var clear: bool=false:
	set(value):
		clear_drawing()
		clear=false

# Brush
@export_subgroup("brush")
### Scaling factor of brush
@export var brush_scaling: float=0.5
### Brush color
@export var brush_color: Color
## Texture used for brush
@export var brush_texture: Texture2D


###############################################################################
## SETUP
# Image
var sprite: Sprite2D=self# Sprite holding the Image
var img: Image# the image created or edited
var img_w: int# width in pixels
var img_h: int# height in pixels
#var texture_: ImageTexture# the image texture
# Brush
@onready var brush_img: Image=Image.new()# image for the brush
var brush_size: int# brush size (same for x,y)
# Logic
var mouse_pos: Vector2# mouse position
var mouse_pos_last: Vector2# last moust position
var is_drawing: bool=false# pen is doing a drawing stroke
var is_erasing: bool=false# erase has been called
var img_history: Array[Image]=[]# backup of img from previous strokes



func _ready():
	load_drawing()
	load_brush()
	place_everything()
		


func load_brush():# set the brush
	if brush_texture:
		brush_img=brush_texture.get_image()
	brush_img.convert(Image.FORMAT_RGBA8)
	brush_img.resize(brush_scaling*brush_img.get_width(),brush_scaling*brush_img.get_height())
	brush_size = brush_img.get_width()
	if true:# ensure transparent background
		var img_=Image.new()
		img_.copy_from(brush_img)
		img_.fill(Color(0,0,0,1))# fill with transparent
		brush_img.blend_rect_mask(img_,brush_img,Rect2(0,0,brush_img.get_width(),brush_img.get_height()),Vector2(0,0))
	#brush_img=utils.swap_img_color(brush_img,Color(0,0,0,1),brush_color)# initial image is black lines

@onready var borders: Panel=%borders
func place_everything():# place every element relative to drawing
	
	var sx_=px#texture.get_width()*scale.x
	var sy_=py#texture.get_height()*scale.y
	borders.position=Vector2(-sx_/2,-sy_/2)
	borders.size.x=sx_
	borders.size.y=sy_

###############################################################################
## METHODS

func _draw():# redraw (when calling _draw, not every _process)
	if active and texture:
		texture.update(img)# update on an already made texture

func _process(delta):
	if not active:
		return
	## controls
	mouse_pos_last=mouse_pos# last one
	mouse_pos=get_global_mouse_position()
	## drawing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not is_drawing:
			is_drawing=true
			start_stroke()
			add_strokepart_start()
		else:
			add_strokepart()
	else:	
		if is_drawing:
			is_drawing=false
			end_stroke()
	## erasing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not is_erasing:
			is_erasing=true
			remove_stroke()
	else:
		if is_erasing:
			is_erasing=false

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
	if FileAccess.file_exists(filename_):
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
func create_empty_drawing():# create texture as image
	# Deduce image from existing Sprite 2D
	#var px_=int(texture.get_width()*scale.x)# account for scale and texture size
	#var py_=int(texture.get_height()*scale.y)
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(Color(1,1,1,0))# fill with transparent
	img_w=img.get_width()
	img_h=img.get_height()
	texture_from_img()

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
	
