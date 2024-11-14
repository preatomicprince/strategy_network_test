extends Node2D

@onready var peer = ENetMultiplayerPeer.new()

const PORT = 9999
const ADDRESS = "192.168.1.196"
var connected_ids = []

func _on_join_pressed() -> void:
	$Menu.visible = false
	peer.create_client(ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func _on_host_pressed() -> void:
	$Menu.visible = false
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	load_map(1)
	
	multiplayer.peer_connected.connect(
		func(new_peer_id):
			rpc_id(new_peer_id, "load_map", new_peer_id)
			
			rpc_id(new_peer_id, "load_input", new_peer_id)
			load_input(new_peer_id)
			
			load_player(new_peer_id)
			rpc("load_player", new_peer_id)
			rpc_id(new_peer_id, "load_prev_players", connected_ids)
			
			connected_ids.append(new_peer_id)
			if $Map.current_player_turn == 0:
				$Map.current_player_turn = connected_ids.front()
	)

@rpc
func load_map(peer_id):
	var new_map = preload("res://scenes/map.tscn").instantiate()
	new_map.name = "Map"
	new_map.peer_id = peer_id
	add_child(new_map)


@rpc
func load_player(peer_id):
	var new_player = preload("res://scenes/player.tscn").instantiate()
	$Map.players[peer_id] = new_player
	new_player.name = "Player" + str(peer_id)
	$Map.add_child(new_player)


@rpc
func load_prev_players(peer_id_list):
	for peer_id in peer_id_list:
		load_player(peer_id)


@rpc
func load_input(peer_id):
	var new_input = preload("res://scenes/input.tscn").instantiate()
	new_input.set_multiplayer_authority(peer_id)
	new_input.peer_id = peer_id
	new_input.name = "Input" + str(peer_id)
	$Map.inputs[peer_id] = new_input
	add_child(new_input)
