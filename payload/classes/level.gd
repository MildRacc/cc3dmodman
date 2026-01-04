extends RefCounted

var node: Node
var name: String

func _init(level_node: Node, level_name: String):
    node = level_node
    name = level_name
