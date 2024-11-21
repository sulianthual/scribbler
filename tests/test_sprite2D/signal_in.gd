extends Resource
class_name SignalIn


## Resource Class for a Receiving Signal: identifies emitting target
# Allows making signal connection between Emitting and Receiving Node
# In receving node, add @export var trigger: SignalIn, fill the info
# make signal connection with: trigger.connectin(self,_on_receiving_function)
# now _on_receiving_function is connected to signal from emitting node


## SignalIn listens to a signal from this node
@export var emit_node: NodePath 
## SignalIn listens to this signal
@export var emitted_signal: String=""

@export_subgroup("options")
## Bind input signal one argument to callable with none
@export var unbind_one: bool=false
## Signal listens to a signal from any node in this group
@export var emit_group: String
## SignalAnchor that SignalIn listens to
@export var signal_anchor: SignalAnchor
###############################################
## CALLS

# Make signal connection (this is equivalent to "connect" for regular signals)
# Note: there is no checks on number of arguments passed by signal
# If they dont match in emitted signal and listening function, signal doesnt go through
func connectin(receiving_node: Node, receiving_function: Callable):
	if signal_anchor:
		signal_anchor.connectin(receiving_node,receiving_function)
	elif emit_group:
		for _node_ref in receiving_node.get_tree().get_nodes_in_group(emit_group):
			if _node_ref.has_signal(emitted_signal):
				var receiving_callable=Callable(receiving_node, receiving_function.get_method())
				if unbind_one:
					_node_ref.connect(emitted_signal,_unbind_one)
					connect("_unbind_one_reemit",receiving_callable)
				else:
					_node_ref.connect(emitted_signal,receiving_callable)
	else:
		var node_ref: Node =receiving_node.get_node_or_null(emit_node)
		if node_ref and node_ref.has_signal(emitted_signal):
			var receiving_callable=Callable(receiving_node, receiving_function.get_method())
			if unbind_one:
				node_ref.connect(emitted_signal,_unbind_one)
				connect("_unbind_one_reemit",receiving_callable)
			else:
				node_ref.connect(emitted_signal,receiving_callable)

## If changing number of arguments, must use relay to reemits the signal
signal _unbind_one_reemit
func _unbind_one(input_argument):# relay going from 1 to 0 arguments
	_unbind_one_reemit.emit()
