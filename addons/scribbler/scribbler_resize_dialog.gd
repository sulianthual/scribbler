@tool
extends Control

## Pickup px,py dimesnions of image

## preset nodes parent
@onready var px: SpinBox=%px
@onready var py: SpinBox=%py
@onready var preset_grid: GridContainer=%GridContainer

@onready var wx2: Button=%wx2
@onready var hx2: Button=%hx2
@onready var wx1p5: Button=%wx1p5
@onready var hx1p5: Button=%hx1p5
@onready var swap: Button=%swap

func _ready():
	make_presets()
	make_mults()
	make_swap()
	
func make_mults():
	wx2.connect("pressed",multiply_pxpy.bind(2.0,1.0))
	hx2.connect("pressed",multiply_pxpy.bind(1.0,2.0))
	wx1p5.connect("pressed",multiply_pxpy.bind(1.5,1.0))
	hx1p5.connect("pressed",multiply_pxpy.bind(1.0,1.5))
func multiply_pxpy(input_px_mult: float, input_py_mult: float):
	px.value=px.value*input_px_mult
	py.value=py.value*input_py_mult

func make_swap():
	swap.connect("pressed",swap_pxpy)
func swap_pxpy():
	var _px=px.value
	var _py=py.value
	px.value=_py
	py.value=_px
	
func make_presets():
	## make presets
	var preset_list: Array[String]=[]
	# small
	preset_list.append("16x16")
	preset_list.append("32x32")
	preset_list.append("64x64")
	preset_list.append("128x128")
	preset_list.append("256x256")
	# med
	#preset_list.append("512x512")
	#preset_list.append("1024x1024")
	# screens 16:9
	preset_list.append("320x180")
	preset_list.append("640x360")
	preset_list.append("960x540")
	preset_list.append("1280x720")
	preset_list.append("1920x1080")
	## generate the preset buttons
	for i in preset_list:
		var _button: Button=Button.new()
		_button.text=i
		preset_grid.add_child(_button)
	## connect the preset buttons
	for i in preset_grid.get_children():
		var _dims=i.text.split("x")
		var _pxpy: Vector2i=Vector2i(int(float(_dims[0])),int(float(_dims[1])))
		i.connect("pressed",set_pxpy.bind(_pxpy))
func set_pxpy(input_pxpy: Vector2i):
	px.value=input_pxpy[0]
	py.value=input_pxpy[1]
