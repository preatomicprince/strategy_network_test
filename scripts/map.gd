extends TileMapLayer

"""///////////////////////////////
  ///   vars, consts, defs    ///
 ///////////////////////////////"""

@export var map_size: Vector2 = Vector2(32, 16)
const TILE_SIZE = Vector2(8, 8)

var nav_grid: AStarGrid2D

var tile_char = {}
var chars = []

var inputs = {}
var players = {}

var current_player_turn: int = 0
var turn_count: int = 1
signal new_turn

var peer_id: int
var input_processed: bool = true

"""///////////////////////////////
  ///   _ready() functions    ///
 ///////////////////////////////"""

func _spawn_char(tile: Vector2):
	var new_char = preload("res://scenes/character.tscn").instantiate()
	new_char.tile = tile
	tile_char[str(tile)] = new_char
	new_char.position = map_to_local(Vector2i(tile.x, tile.y))
	chars.append(new_char)
	add_child(new_char)

#generates tilemap, based on map size
func _generate_map() -> void:
	var tile_pos = local_to_map(Vector2(0, 0))
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			if x == 0 && y == 0:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(0, 0))
			elif x == map_size.x -1 && y == 0:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(3, 0))
			elif y == 0:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(1, 0))
			elif x == 0 && y == map_size.y - 1:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(0, 2))
			elif x == map_size.x - 1 && y == map_size.y - 1:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(3, 2))
			elif y == map_size.y - 1:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(1, 0))
			elif x == 0:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(0, 1))
			elif x == map_size.x - 1:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(3, 1))
			else:
				set_cell(Vector2i(tile_pos.x + x, tile_pos.y + y), 0, Vector2i(1, 1))
				
			tile_char[str(Vector2(x, y))] = null
				
func _generate_nav_grid() -> void:
	nav_grid = AStarGrid2D.new()
	nav_grid.region = get_used_rect()
	nav_grid.cell_size = TILE_SIZE
	nav_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav_grid.update()
	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_generate_map()
	_generate_nav_grid()	

"""/////////////////////////////////
  ///   _process() functions    ///
 /////////////////////////////////"""

func _generate_nav_path(peer_id) -> void: 
	var player = players[peer_id]
	var input = inputs[peer_id]
	
	if player.selected_char == null:
		return
		
	if not player.selected_char.prev_selected:
		player.selected_char.prev_selected = player.selected_char.selected
		return
		
	var nav_path = nav_grid.get_id_path(player.selected_char.tile, local_to_map(input.mouse_pos)).slice(1)
	
	# Check enough moves availiable
	if len(nav_path) > player.selected_char.moves:
		nav_path = []
		
	# Check all tiles are walkable
	for tile in nav_path:
		var data = get_cell_tile_data(tile)
		if data == null:
			return
		if not data.get_custom_data("passable"):
			nav_path = []
			break
			
	player.selected_char.nav_path = nav_path
	if nav_path.is_empty():
		players[current_player_turn].deselect_all()

	
func update_peer_highlight(peer_id):
	var input = inputs[peer_id]
	
	var tile_pos = local_to_map(input.mouse_pos)
	if tile_pos == null:
		return
	
	# Stores data from moused over tile
	var data = get_cell_tile_data(tile_pos)
	if data == null:
		return
	
	# Checks custom data field "passable" to find if it can be walked on, and highlights
	if data.get_custom_data("passable"):
		var tile_world_pos = map_to_local(tile_pos) 
		rpc_id(peer_id, "set_highlight", tile_world_pos)

@rpc
func set_highlight(auth_pos):
	$Highlight.position = auth_pos
	
@rpc
func set_current_player_turn(current_player_id):
	current_player_turn = current_player_id
	if current_player_turn == peer_id:
		$Next_Turn.visible = true
	else:
		$Next_Turn.visible = false

func _handle_click(peer_id: int, pos: Vector2):
	if set_unit_select(peer_id, pos):
		return
	else:
		_generate_nav_path(peer_id)
	

func set_unit_select(peer_id: int, pos: Vector2) -> int:
	var input = inputs[peer_id]
	var player = players[peer_id]
	
	var tile_pos = local_to_map(pos)

	#select tile
	if tile_char[str(tile_pos)] != null:
		if tile_char[str(tile_pos)].owner_id == peer_id:
			tile_char[str(tile_pos)].selected = true
			player.selected_char = tile_char[str(tile_pos)]
			tile_char[str(tile_pos)].set_selected(true)
			return 1
	return 0
		

@rpc("call_local")
func spawn_unit(peer_id: int, pos: Vector2):
	var map_pos = local_to_map(pos)
	if tile_char[str(map_pos)] != null:
		return
		
	var new_unit = preload("res://scenes/character.tscn").instantiate()
	new_unit.tile = map_pos
	new_unit.owner_id = peer_id
	new_unit.position = pos
	tile_char[str(map_pos)] = new_unit
	chars.append(new_unit)
	add_child(new_unit)
	
func _next_turn():
	if $"..".connected_ids.back() == current_player_turn:
		current_player_turn = $"..".connected_ids[0]
	else:
		current_player_turn =  $"..".connected_ids[$"..".connected_ids.find(current_player_turn) + 1]

	turn_count += 1
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	rpc("set_current_player_turn", current_player_turn)
	
	for peer_id in $"..".connected_ids:
		update_peer_highlight(peer_id)
	#_set_nav_path()
	
	var active_id = current_player_turn
	
	if active_id == 0:
		return
	
	for peer_id in $"..".connected_ids:
		var event_queue = inputs[peer_id].event_queue
		
		if peer_id != current_player_turn:
			continue
			
		while not event_queue.is_empty():
			var event = event_queue.pop_front()
			if typeof(event) == 5:
				_handle_click(peer_id, event)
			elif event == 0:
				_next_turn()
			elif event == 1:
				var unit_pos = local_to_map(inputs[peer_id].mouse_pos)
				unit_pos = map_to_local(unit_pos)
				
				rpc("spawn_unit", peer_id, unit_pos)
				#spawn_unit(peer_id, unit_pos)
				

func _on_next_turn_pressed() -> void:
	emit_signal("new_turn")
	for peer_id in $"..".connected_ids:
		players[peer_id].deselect_all()
