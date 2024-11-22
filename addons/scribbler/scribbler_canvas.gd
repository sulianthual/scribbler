@tool
extends TextureRect


## canvas behind drawing, blank color
## should move in the same way

## background color
@export var back_color: Color=Color.WHITE

@onready var drawing: TextureRect=%drawing
var img: Image=Image.new()
var px: int=128
var py: int=128
func _ready():
	drawing.connect("px_changed",on_px_changed)
	drawing.connect("py_changed",on_py_changed)
	update_canvas()
func on_px_changed(input_px:int):
	px=input_px
	update_canvas()
func on_py_changed(input_py:int):
	py=input_py
	update_canvas()
func update_canvas():
	img=Image.create(px,py,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(back_color)
	texture_from_img()

func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture
