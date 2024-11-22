@tool
extends TextureButton

## Change brush color toggling several ones

signal color_changed(value: Color)
const brush_colors: Array[Color]=[Color.BLACK,Color.DARK_RED,Color.DARK_ORANGE,Color.YELLOW,Color.DARK_BLUE,Color.DARK_GREEN,Color.DARK_MAGENTA]
const bx: int=40
const by: int=20
var index:int=0# index of brush colors
func _ready():
	connect("pressed",_on_pressed)
	make_initial_texture()
	update_color()
	

func make_initial_texture():
	var img: Image =Image.create(bx,by,false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var _texture: ImageTexture=ImageTexture.create_from_image(img)
	texture_normal=_texture
	
func _on_pressed():
	index+=1
	if index>len(brush_colors)-1:
		index=0
	update_color()
	
func update_color():
	modulate=brush_colors[index]
	color_changed.emit(brush_colors[index])
