extends Resource
class_name SignalOut


## Resource Class for an Emitting Signal: identifies receiving target
# Allows making signal connection between Emitting and Receiving Node
# In emitting node, add @export var trigger: SignalOut, fill the info
# make signal connection with: trigger.connectout(self,signal)
# where signal_name (String) is the name of an existing signal in emitting node
# now listen_function in receiving node is connected to the signal from emitting node



## SignalOut emits signal to this Listening node
@export var listen_node: NodePath

## SignalOut activates this listening function in Listening Node.
## (Number of arguments in signal and function must match, or signal wont transmit).
@export var listen_function: String

@export_subgroup("options")
## SignalOut instead emits signal to a SignalAnchor
@export var use_anchor: bool=false
## SignalOut emits signal to all Listening nodes in this group
@export var listen_group: String
## SignalAnchor that SignalOut emits to.
@export var signal_anchor: SignalAnchor


# Make signal connection (this is equivalent to "connect" for regular signals)
func connectout(emit_node: Node, signal_input: Signal):
	if not use_anchor:
		## connect node
		var node_ref: Node =emit_node.get_node_or_null(listen_node)
		if node_ref and signal_input and node_ref.has_method(listen_function):
			var receiving_callable=Callable(node_ref, listen_function)
			emit_node.connect(signal_input.get_name(),receiving_callable)
		## connect group
		if listen_group:
			for _node_ref in emit_node.get_tree().get_nodes_in_group(listen_group):
				if _node_ref and signal_input and _node_ref.has_method(listen_function):
					var receiving_callable=Callable(_node_ref, listen_function)
					emit_node.connect(signal_input.get_name(),receiving_callable)
	else:
		if signal_anchor:
			signal_anchor.connectout(emit_node,signal_input)



	


###############################################
