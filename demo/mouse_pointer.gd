extends Node2D

## Mouse pointer: follow the mouse

@export var active: bool=true


func _ready():
	global_position=get_global_mouse_position()

func _input(event):
	if active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:# DRAW
				print("pressed")
			else:
				print("released")
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:# UNDO
				print("rmouse pressed")
			else:
				print("rmouse released")
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:# SWAP PENS/ERASERS
				print("midmouse pressed")
			else:
				print("midmouse released")
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_WHEEL_UP:
			pass
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			pass
		elif event is InputEventMouseMotion:
			global_position=get_global_mouse_position()
