extends Node2D


"""///////////////////////////////
  ///   vars, consts, defs    ///
 ///////////////////////////////"""


enum Char_Class {
	fighter,
	rouge,
	mage
}

# Peer ID of owner
var owner_id: int

var moves
var dmg
var health

var moves_remaining
var tile: Vector2

var prev_selected: bool = false
var selected: bool = false
var nav_path = []

@export var char_class: Char_Class


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"..".new_turn.connect(
		func():
			moves_remaining = moves
			nav_path = [])
			
	if char_class == Char_Class.fighter:
		$Sprite.texture = load("res://sprites/tile_0007.png")
		moves = 5
		dmg = 5
		health = 15
		
	elif char_class == Char_Class.rouge:
		$Sprite.texture = load("res://sprites/tile_0005.png")
		moves = 7
		dmg = 4
		health = 8
		
	elif char_class == Char_Class.mage:
		$Sprite.texture = load("res://sprites/tile_0004.png")
		moves = 4
		dmg = 6
		health = 10
		
	moves_remaining = moves


"""/////////////////////////
  ///   _process funcs  ///
 /////////////////////////"""

@rpc
func sync(auth_health, auth_moves_remaining, auth_pos, auth_selected):
	health = auth_health
	moves_remaining = auth_moves_remaining
	position = auth_pos
	set_selected(auth_selected)
	
func set_selected(select: bool) -> void:
	$Highlight.set_visible(selected)
	$Highlight.visible = select
	$Data.visible = select
	selected = select

func _set_nav_path() -> void:
	if not prev_selected:
		prev_selected = selected
		return
	if not $".."/".."/Input.mouse_click:
		prev_selected = selected
		return
		
	nav_path = $"..".nav_grid.get_id_path(tile,
	$"..".local_to_map($".."/".."/Input.mouse_pos)).slice(1)
	
	# Check enough moves availiable
	if len(nav_path) > moves:
		nav_path = []
	# Check all tiles are walkable
	for tile in nav_path:
		var data = $"..".get_cell_tile_data(tile)
		if data == null:
			return
		if not data.get_custom_data("passable"):
			nav_path = []
			break
	
	"""# Stops instant deselection
	if prev_selected == selected:
		$".."/".."/Player.deselect_all()
	prev_selected = selected"""
	
func _update_labels() -> void:
	$Data/Health.text = "HP: " + str(health)
	$Data/Moves.text = "MV: " + str(moves_remaining)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_labels()
	if not is_multiplayer_authority():
		return
		
	rpc("sync", health, moves_remaining, position, selected)	
	if nav_path.is_empty():
		return
	if moves_remaining <= 0:
		return
		
	var target_pos = $"..".map_to_local(nav_path.front())
	position = position.move_toward(target_pos, 1)
	
	# Handle reaching next tile
	if position == target_pos:
		moves_remaining -= 1
		
		# Update tile and nav_path data
		$"..".tile_char[str(tile)] = null
		tile = nav_path.front()
		$"..".tile_char[str(tile)] = self
		nav_path.pop_front()
		
		
