@tool
extends TextureRect


## grid indicator

@onready var drawing: TextureRect=%drawing
var img: Image=Image.new()
var px: int=128
var py: int=128

var grid_on: bool=false# must match menu button
const grid_color: Color=Color(0.1,0.1,0.1,1)
var subx: int=4
var suby: int=4
func _ready():
	drawing.connect("px_changed",on_px_changed)
	drawing.connect("py_changed",on_py_changed)
	_postready.call_deferred()
func _postready():
	px=drawing.px
	py=drawing.py
	if grid_on:
		update_canvas()
func on_px_changed(input_px:int):
	px=input_px
	update_canvas()
func on_py_changed(input_py:int):
	py=input_py
	update_canvas()
func update_canvas():
	px=drawing.px
	py=drawing.py
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	if grid_on:
		var subset_rect_w: int=floori(img.get_width()/subx)
		var subset_rect_h: int=floori(img.get_height()/suby)
			## grid lines
		# columns
		for j in img.get_height():
			for ii in range(subx):	
				var i: int=subset_rect_w*ii
				img.set_pixel(i,j, grid_color)
			img.set_pixel(img.get_width()-1,j, grid_color)# last
		# rows
		for i in img.get_width():
			for jj in range(suby):	
				var j: int=subset_rect_h*jj
				img.set_pixel(i,j, grid_color)
			img.set_pixel(i,img.get_height()-1, grid_color)# last
	texture_from_img()

func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture

func set_grid_visibility(input_visibility: bool)->void: # CALLS from scribbler
	grid_on=input_visibility
	update_canvas()
