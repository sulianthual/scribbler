extends Node

## SignalInOut: when a signal is emitted, we trigger some function
## (no arguments accepted)

## This signal triggers
@export var trigger: SignalIn
## Which calls this function
@export var function: SignalOut

# Called when the node enters the scene tree for the first time.
func _ready():
	if trigger:
		trigger.connectin(self,on_trigger)
	if function:
		function.connectout(self,signal_out)
signal signal_out
func on_trigger():
	signal_out.emit()
