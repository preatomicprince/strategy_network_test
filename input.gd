extends Node2D

"""///////////////////////////////
  ///   vars, consts, defs    ///
 ///////////////////////////////"""

var mouse_pos: Vector2 
var mouse_click: bool = false
var next_turn: bool = false
var processed: bool = true

var peer_id: int
var event_queue = []

enum Actions {
	next_turn = 0,
	spawn = 1
}

func _ready() -> void:
	if is_multiplayer_authority():
		$".."/Map/Next_Turn.pressed.connect(_on_next_turn_pressed)

"""//////////////////////////
  ///   _process funcs   ///
 //////////////////////////"""

@rpc("reliable")
func server_update(auth_pos, auth_click, auth_turn_end, auth_new_events):
	mouse_pos = auth_pos
	mouse_click = auth_click
	next_turn = auth_turn_end
	
	for event in auth_new_events:
		event_queue.push_back(event)

func _on_next_turn_pressed() -> void:
	next_turn = true
	
func _process(delta: float) -> void:
	var new_events = []
	if not is_multiplayer_authority():
		return
		
	mouse_pos = get_local_mouse_position()
	if Input.is_action_just_pressed("left_mouse"):
		mouse_click = true
		new_events.push_back(mouse_pos)
	else:
		mouse_click = false
		
	if Input.is_action_just_pressed("spawn"):
		new_events.push_back(Actions.spawn)
	
	if next_turn:
		new_events.push_back(Actions.next_turn)
		next_turn = false
	# Checks if next turn before reseting
	# This check stops resetting to false before update has been applied on server
	#if $".."/Map.current_player_turn != peer_id:
		#next_turn = false
	rpc_id(1, "server_update", mouse_pos, mouse_click, next_turn, new_events)

	
	
