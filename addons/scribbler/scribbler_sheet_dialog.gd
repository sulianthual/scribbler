@tool
extends Control

## Select subset from a source image

@onready var source_image: TextureRect=%source_image
@onready var grid_image: TextureRect=%grid_image
@onready var subx: SpinBox=%subx
@onready var suby: SpinBox=%suby
@onready var ix: SpinBox=%ix
@onready var iy: SpinBox=%iy
@onready var image_label: Label=%image_name
@onready var image_size: Label=%image_size
@onready var region_size: Label=%region_size

signal subset_changed(value: Array[int])# array subx,suby,ix,iy

var px: int# dimensions pixel of source image
var py: int
var edited_image: Image# edited image to overlay (for saving subset region)

func _ready():
	for i in [subx,suby,ix,iy]:
		i.connect("value_changed",on_subset_changed)


################################################
## CALLS

func set_subset(input_subset: Array[int]):# subx,suby,ix,iy## CALLS SCRIBBLER OR SELF
	subx.value=input_subset[0]
	suby.value=input_subset[1]
	ix.value=input_subset[2]
	iy.value=input_subset[3]
	update_region_size()
	
func make_source_image(filename_: String):## CALLS from scribbler
	if FileAccess.file_exists(filename_):
		var img: Image=Image.new()
		img.load(filename_)
		img.convert(Image.FORMAT_RGBA8)
		px=img.get_width()
		py=img.get_height()
		image_size.text=str(px)+"x"+str(py)
		var _texture: ImageTexture=ImageTexture.create_from_image(img)
		source_image.texture=_texture
		image_label.text=filename_
		update_grid()
		update_region_size()

func make_edited_image(input_image: Image):
	edited_image=Image.create(input_image.get_width(),input_image.get_height(),false, Image.FORMAT_RGBA8)
	edited_image.convert(Image.FORMAT_RGBA8)
	edited_image.fill(Color.WHITE)# background to hide below
	edited_image.blend_rect(input_image,Rect2i(0,0,input_image.get_width(),input_image.get_height()),Vector2(0,0))
	update_grid()
################################################
## METHODS

## Select subset with mouse
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var _mouse_pos: Vector2=get_global_mouse_position()
		# determine drawing rectangle (must control for margins)
		var _rectm: Rect2=source_image.get_global_rect()# drawable rectangle +potential margins
		var _rectc: Vector2=_rectm.get_center()# center
		var _rects: Vector2=_rectm.size# size
		var _rectr: float=float(px)/float(py)/float(_rectm.size[0])*float(_rectm.size[1])# ratio
		var _rect: Rect2=_rectm
		if _rectr<1.0:# has width margins
			_rect=rect_from_centered_rect(Rect2(_rectc,Vector2(_rects[0]*_rectr,_rects[1])))
		elif _rectr>1.0:# has height margins
			_rect=rect_from_centered_rect(Rect2(_rectc,Vector2(_rects[0],_rects[1]/_rectr)))
		else:# no margins
			_rect=_rectm
		if _rect.has_point(_mouse_pos):
			var ic: int=(_mouse_pos.x-_rect.position.x)/_rect.size[0]*subx.value
			var jc: int=(_mouse_pos.y-_rect.position.y)/_rect.size[1]*suby.value
			set_subset([subx.value,suby.value,ic+1,jc+1])
func rect_from_centered_rect(rectc: Rect2)->Rect2:# convert a Rect(center:Vector2,size:Vector2) to regular
	return Rect2(rectc.position[0]-rectc.size[0]/2,rectc.position[1]-rectc.size[1]/2,rectc.size[0],rectc.size[1])




func on_subset_changed(input_value: float):# from any of subx,suby,ix,iy
	if ix.value>subx.value:
		ix.value=subx.value
	elif iy.value>suby.value:
		iy.value=suby.value
	else:
		var _array: Array[int]=[subx.value,suby.value,ix.value,iy.value]
		subset_changed.emit(_array)
		update_grid()# if/elif above will retrigger subset_changed and this
		update_region_size()
	


var grid_color: Color=Color.BLACK
var grid_select_color: Color=Color.RED
func update_grid():
	if source_image and source_image.texture:
		var img: Image=source_image.texture.get_image()
		img.fill(Color.TRANSPARENT)
		## Parameters
		var subset_rect_w: int=floori(img.get_width()/subx.value)
		var subset_rect_h: int=floori(img.get_height()/suby.value)
		var subset_rect_x: int=subset_rect_w*clamp(ix.value-1,0,subx.value-1)
		var subset_rect_y: int=subset_rect_h*clamp(iy.value-1,0,suby.value-1)
		## BLIT edited_image if any
		if edited_image:
			#var _recte: Rect2i=Rect2i(0,0,edited_image.get_width(),edited_image.get_height())
			var _rectedited: Rect2i=Rect2i(0,0,subset_rect_w,subset_rect_h)
			var _posedited: Vector2i=Vector2(subset_rect_x,subset_rect_y)
			img.blit_rect(edited_image,_rectedited,_posedited)
		## grid lines
		# columns
		for j in img.get_height():
			for ii in range(subx.value):	
				var i: int=subset_rect_w*ii
				img.set_pixel(i,j, grid_color)
			img.set_pixel(img.get_width()-1,j, grid_color)# last
		# rows
		for i in img.get_width():
			for jj in range(suby.value):	
				var j: int=subset_rect_h*jj
				img.set_pixel(i,j, grid_color)
			img.set_pixel(i,img.get_height()-1, grid_color)# last
		# selector (change color of grid)
		for i in range(subset_rect_x,subset_rect_x+subset_rect_w-1):
			img.set_pixel(i,subset_rect_y, grid_select_color)
			img.set_pixel(i,subset_rect_y+subset_rect_h-1, grid_select_color)
		for j in range(subset_rect_y,subset_rect_y+subset_rect_h-1):
			img.set_pixel(subset_rect_x,j, grid_select_color)
			img.set_pixel(subset_rect_x+subset_rect_w-1,j, grid_select_color)
		img.set_pixel(subset_rect_x+subset_rect_w-1,subset_rect_y+subset_rect_h-1, grid_select_color)
		# texture
		var _texture: ImageTexture=ImageTexture.create_from_image(img)
		grid_image.texture=_texture

func update_region_size():
	region_size.text=str(px/subx.value)+"x"+str(py/suby.value)
