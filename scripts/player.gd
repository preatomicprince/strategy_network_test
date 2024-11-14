extends Node2D


var selected_tile: Vector2 = Vector2(-1, -1)
var selected_char: Node = null

var peer_id: int

func deselect_all():
	selected_tile = Vector2(-1, -1)
	if selected_char != null:
		selected_char.set_selected(false)
		selected_char = null

@rpc
func update_client(auth_selected_char):
	selected_char = auth_selected_char
	
func _process(delta: float) -> void:
	update_client(selected_char)
