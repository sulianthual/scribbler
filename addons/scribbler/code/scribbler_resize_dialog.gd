@tool
extends Control

## Pickup px,py dimesnions of image

## preset nodes parent
@onready var px: SpinBox=%px
@onready var py: SpinBox=%py
@onready var smode: Button=%scale_mode
@onready var ratio: Label=%ratio# info on the ratio

## preset buttons
@onready var preset_grid: GridContainer=%GridContainer

## multipliers and swap
@onready var multby: Button=%multby
@onready var dividby: Button=%dividby
@onready var factx: SpinBox=%factx
@onready var facty: SpinBox=%facty
@onready var swap: Button=%swap
## adders
@onready var addx = %addx
@onready var addy = %addy
@onready var add = %add
@onready var substract = %substract

enum SCALEMODE {STRETCH, CROP_CENTERED,CROP_CORNERED}
signal scale_mode_changed(value: String)
var scale_mode: SCALEMODE=SCALEMODE.CROP_CORNERED:
	set(value):
		var prev_value: SCALEMODE=scale_mode
		scale_mode=value
		if prev_value!=value:
			if scale_mode==SCALEMODE.STRETCH:
				scale_mode_changed.emit("stretch")
			elif scale_mode==SCALEMODE.CROP_CENTERED:
				scale_mode_changed.emit("crop_centered")
			elif scale_mode==SCALEMODE.CROP_CORNERED:
				scale_mode_changed.emit("crop_cornered")

func _ready():
	make_mults()
	make_adds()
	make_presets()
	make_scale_mode()
	update_ratio()
	px.connect("value_changed",_on_any_pxpy_changed)
	py.connect("value_changed",_on_any_pxpy_changed)

func set_factors(factors: Vector2):## CALLS from SCRIBBLER
	#px.value=px.value*factors[0]
	#py.value=py.value*factors[1]
	#print(factors)
	factx.value=snappedf(factors[0],0.01)
	facty.value=snappedf(factors[1],0.01)

func _on_any_pxpy_changed(value: float):
	update_ratio()
func update_ratio():
	var _text: String
	var _rounding: float=0.01
	if px.value>py.value:
		_text="ratio "+str(round(px.value/py.value/_rounding)*_rounding)+":1"
	elif px.value<py.value:
		_text="ratio 1:"+str(round(py.value/px.value/_rounding)*_rounding)
	else:
		_text="ratio 1:1"
	ratio.text=_text
func make_scale_mode():
	smode.connect("pressed",change_scale_mode)
	update_scale_mode_button()
	
signal resize_mode_changed(value:String)
		
func change_scale_mode():
	if scale_mode==SCALEMODE.CROP_CORNERED:
		scale_mode=SCALEMODE.CROP_CENTERED
	elif scale_mode==SCALEMODE.CROP_CENTERED:
		scale_mode=SCALEMODE.STRETCH
	elif scale_mode==SCALEMODE.STRETCH:
		scale_mode=SCALEMODE.CROP_CORNERED
		
	update_scale_mode_button()
func update_scale_mode_button():
	if scale_mode==SCALEMODE.STRETCH:
		smode.text="mode: stretch image"
	elif scale_mode==SCALEMODE.CROP_CENTERED:
		smode.text="mode: crop from center"
	elif scale_mode==SCALEMODE.CROP_CORNERED:
		smode.text="mode: crop from corner"
func get_scale_mode():## CALLS from scribbler
	if scale_mode==SCALEMODE.STRETCH:
		return "stretch"
	elif scale_mode==SCALEMODE.CROP_CENTERED:
		return "crop_centered"
	elif scale_mode==SCALEMODE.CROP_CORNERED:
		return "crop_cornered"
	return ""
func make_mults():
	multby.connect("pressed",_on_multby_pressed)
	dividby.connect("pressed",_on_dividby_pressed)
	#dividby.connect("pressed",multiply_pxpy.bind(1.0,2.0))
	#wx1p5.connect("pressed",multiply_pxpy.bind(1.5,1.0))
	#hx1p5.connect("pressed",multiply_pxpy.bind(1.0,1.5))
	swap.connect("pressed",swap_pxpy)
func _on_multby_pressed():
	multiply_pxpy(factx.value,facty.value)
func _on_dividby_pressed():
	multiply_pxpy(1.0/factx.value,1.0/facty.value)
func multiply_pxpy(input_px_mult: float, input_py_mult: float):
	px.value=px.value*input_px_mult
	py.value=py.value*input_py_mult
func swap_pxpy():
	var _px=px.value
	var _py=py.value
	px.value=_py
	py.value=_px
	
func make_adds():
	add.connect("pressed",_on_add_pressed)
	substract.connect("pressed",_on_substract_pressed)
func _on_add_pressed():
	px.value=clamp(px.value+addx.value,0,1920)
	py.value=clamp(py.value+addy.value,0,1080)
func _on_substract_pressed():
	px.value=clamp(px.value-addx.value,0,1920)
	py.value=clamp(py.value-addy.value,0,1080)

func make_presets():
	## make presets
	var preset_list: Array[String]=[]
	# small
	preset_list.append("1x1")
	preset_list.append("16x16")
	preset_list.append("64x64")
	preset_list.append("256x256")
	preset_list.append("1024x1024")
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
