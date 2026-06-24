extends Node3D

@export var map_file: String = "res://maps/map.txt"
@export var tile_definitions: Array[TileDefinition] = []
@export var bg_tile_definitions: Array[BgTileDefinition] = []
@export var cell_size: float = 2.0
@export var wall_height: float = 2.0

var map_separator: String = "\t"
var map_width: int = 0
var map_height: int = 0
# id at (x,y) = cell_ids[x + y * width]
var cell_ids: PackedInt32Array = []

var _id_to_tile_def: Dictionary = {}
var _id_to_bg_tile_def: Dictionary = {}

enum CellType { WALKABLE, BACKGROUND, VOID }

func _ready() -> void:
	_build_lookup()
	_load_map()
	_generate_tiles()
	_spawn_player()

func _build_lookup() -> void:
	_id_to_tile_def.clear()
	_id_to_bg_tile_def.clear()
	for def in tile_definitions:
		_id_to_tile_def[def.id] = def
	for def in bg_tile_definitions:
		_id_to_bg_tile_def[def.id] = def

func _load_map() -> void:
	var file = FileAccess.open(map_file, FileAccess.READ)
	if not file:
		push_error("Cannot open map file: %s" % map_file)
		return

	var lines: Array[String] = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			lines.append(line)
	file.close()

	if lines.is_empty():
		push_error("Map file is empty")
		return

	map_height = lines.size()
	var first_tokens = lines[0].split(map_separator, false, 0)
	map_width = first_tokens.size()

	for i in range(map_height):
		var tokens = lines[i].split(map_separator, false, 0)
		if tokens.size() != map_width:
			push_error("Row %d has %d columns, expected %d" % [i, tokens.size(), map_width])
			return

	cell_ids.resize(map_width * map_height)
	for y in range(map_height):
		var tokens = lines[y].split(map_separator, false, 0)
		for x in range(map_width):
			var id = int(tokens[x])
			cell_ids[x + y * map_width] = id

func _get_cell_type(x: int, y: int) -> int:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return CellType.VOID
	var id = cell_ids[x + y * map_width]
	if _id_to_tile_def.has(id):
		return CellType.WALKABLE
	if _id_to_bg_tile_def.has(id):
		return CellType.BACKGROUND
	return CellType.VOID

func _get_tile_def(x: int, y: int) -> TileDefinition:
	if _get_cell_type(x, y) == CellType.WALKABLE:
		return _id_to_tile_def[cell_ids[x + y * map_width]]
	return null

func _get_bg_tile_def(x: int, y: int) -> BgTileDefinition:
	if _get_cell_type(x, y) == CellType.BACKGROUND:
		return _id_to_bg_tile_def[cell_ids[x + y * map_width]]
	return null

func _is_void(x: int, y: int) -> bool:
	return _get_cell_type(x, y) == CellType.VOID

func is_walkable(x: int, y: int) -> bool:
	return _get_cell_type(x, y) == CellType.WALKABLE

func _generate_tiles() -> void:
	for y in range(map_height):
		for x in range(map_width):
			match _get_cell_type(x, y):
				CellType.WALKABLE:
					var def = _get_tile_def(x, y)
					if def:
						def.place_floor_and_ceiling(self, x, y, cell_size, wall_height)
						# North ( -Z direction )
						if _is_void(x, y - 1):
							def.place_wall(self, x, y, cell_size, wall_height, 0)
						# East ( +X direction )
						if _is_void(x + 1, y):
							def.place_wall(self, x, y, cell_size, wall_height, 1)
						# South ( +Z direction )
						if _is_void(x, y + 1):
							def.place_wall(self, x, y, cell_size, wall_height, 2)
						# West ( -X direction )
						if _is_void(x - 1, y):
							def.place_wall(self, x, y, cell_size, wall_height, 3)
				CellType.BACKGROUND:
					var def = _get_bg_tile_def(x, y)
					if def:
						def.place_tile(self, x, y, cell_size, wall_height)

func _spawn_player() -> void:
	for y in range(map_height):
		for x in range(map_width):
			if is_walkable(x, y):
				var player_scene = preload("res://scenes/player.tscn")
				var player = player_scene.instantiate()
				player.grid_position = Vector2i(x, y)
				player.cell_size = cell_size
				player.map_node = self
				add_child(player)
				return
