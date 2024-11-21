extends Resource
class_name SignalAnchor


## SignalAnchor: Emit or Receive Signal



## Label of Signal Anchor (indicative only, helps tracking multiple resources)
@export var anchor_label: String

## Signal going through SignalAnchor has ONE argument or none.
## (Signals with multiple arguments are unsupported).
@export var has_argument: bool=false
#
@export_group("Notes")
## Custom notes (who emits in game)
@export_multiline var emitted_by: String=""
## Custom notes (who receives in game)
@export_multiline var received_by: String=""

@export_group("Instructions")
@export_multiline var instructions: String="""SignalAnchor instructions:

# Emitting Node: 
@export var out: SignalAnchor
out.connectout(self,signal_out)# -> connect signal (one or no argument specified by has_argument) 
out.emit()#-> directly emit (no argument)
out.emit(toto)#-> directly emit (one argument)
 
# Receving node
@export var in: SignalAnchor
in.connectin(self,_on_receiving_function)#-> function must accept corresponding number of arguments

# Notes
using emit, signal is emited once thus using one game frame
using connectout, signal is reemited thus using two game frames
"""

signal relay# no argument
signal relay_arg(input)# one argument

func _signalin():
	relay.emit()
func _signalin_arg(input):
	print("sginal anchor relay ",input)
	relay_arg.emit(input)
	
#######################################################
## CALLS

# Directly emit signal (optionally passing an argument)
func emit(_argument=null)->void:
	if has_argument: 
		relay_arg.emit(_argument)
	else:
		relay.emit()

# Make signal connection (in an Emitting Node)
func connectout(emit_node: Node, signal_input: Signal):
	if emit_node and signal_input:
		if has_argument:
			emit_node.connect(signal_input.get_name(),_signalin_arg)
		else:
			emit_node.connect(signal_input.get_name(),_signalin)

# Make signal connection (in a Receiving Node)
func connectin(receiving_node: Node, receiving_function: Callable):
	if receiving_node and receiving_function and receiving_node.has_method(receiving_function.get_method()):
		var receiving_callable=Callable(receiving_node, receiving_function.get_method())
		if has_argument:
			connect("relay_arg",receiving_callable)
		else:
			connect("relay",receiving_callable)
 
