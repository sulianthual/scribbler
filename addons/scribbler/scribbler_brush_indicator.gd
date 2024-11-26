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
	drawing.connect("brush_changed_in_chain",update_canvas)
	drawing.connect("draw_mode_changed",update_canvas)
	_postready.call_deferred()

func _postready():
	px=drawing.px
	py=drawing.py
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
	if drawing.draw_blackpen:
		img.blend_rect(drawing.black_pen_img,Rect2(0,0,drawing.black_pen_img.get_width(),drawing.black_pen_img.get_height()),Vector2(0,0))
	else:
		img.blend_rect(drawing.brush_img,Rect2(0,0,drawing.brush_img.get_width(),drawing.brush_img.get_height()),Vector2(0,0))
	texture_from_img()

func texture_from_img():# update displayed texture from image
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture=_texture
