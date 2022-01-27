extends BTLeaf

export (String) var blackboard_key := ""
export (NodePath) var to_node : NodePath
export (String) var to_property := ""

func tick(actor : Node, blackboard : Dictionary) -> int:
	var property = blackboard[blackboard_key]
	var node := get_node(to_node) as Node
	# would an assert be useful here? It'll break either way and I can debug from there
	node.set_indexed(to_property, property)
	return STATE_SUCCESS
