@tool
extends Control

## Select subset from a source image

@onready var source_image: TextureRect=%source_image
@onready var grid_image: TextureRect=%grid_image
@onready var subx: SpinBox=%subx
@onready var suby: SpinBox=%suby
@onready var ix: SpinBox=%ix
@onready var iy: SpinBox=%iy

signal subset_changed(value: Array[int])# array subx,suby,ix,iy

func _ready():
	for i in [subx,suby,ix,iy]:
		i.connect("value_changed",on_subset_changed)

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#pass
################################################
## CALLS

func set_subset(input_subset: Array[int]):# subx,suby,ix,iy
	subx.value=input_subset[0]
	suby.value=input_subset[1]
	ix.value=input_subset[2]
	iy.value=input_subset[3]
	
func make_source_image(filename_: String):
	if FileAccess.file_exists(filename_):
		var img: Image=Image.new()
		img.load(filename_)
		img.convert(Image.FORMAT_RGBA8)
		var _texture: ImageTexture=ImageTexture.create_from_image(img)
		source_image.texture=_texture
		update_grid()

func on_subset_changed(input_value: float):# from any of subx,suby,ix,iy
	if ix.value>subx.value:
		ix.value=subx.value
	elif iy.value>suby.value:
		iy.value=suby.value
	else:
		var _array: Array[int]=[subx.value,suby.value,ix.value,iy.value]
		subset_changed.emit(_array)
		update_grid()# if/elif above will retrigger subset_changed and this
	
var grid_color: Color=Color.BLACK
var grid_select_color: Color=Color.RED
func update_grid():
	if source_image and source_image.texture:
		var img: Image=source_image.texture.get_image()
		img.fill(Color.TRANSPARENT)
		var subset_rect_w: int=roundi(img.get_width()/subx.value)
		var subset_rect_h: int=roundi(img.get_height()/suby.value)
		var subset_rect_x: int=subset_rect_w*clamp(ix.value-1,0,subx.value-1)
		var subset_rect_y: int=subset_rect_h*clamp(iy.value-1,0,suby.value-1)
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
		# texture
		var _texture: ImageTexture=ImageTexture.create_from_image(img)
		grid_image.texture=_texture
