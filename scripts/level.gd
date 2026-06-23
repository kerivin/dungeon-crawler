extends Node3D

@export var map_file: String = "res://maps/map.txt"
@export var tile_definitions: Array[TileDefinition] = []
@export var cell_size: float = 2.0
@export var wall_height: float = 2.0

var map_width: int = 0
var map_height: int = 0
# id at (x,y) = cell_ids[x + y * width]
var cell_ids: PackedInt32Array = []

# id -> TileDefinition lookup
var _id_to_def: Dictionary = {}

func _ready() -> void:
	_build_lookup()
	_load_map()
	_generate_floors_and_ceilings()
	_generate_walls()
	_spawn_player()

func _build_lookup() -> void:
	_id_to_def.clear()
	for def in tile_definitions:
		_id_to_def[def.id] = def
	print("_id_to_def: ", _id_to_def)

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
	# First line sets the width
	var first_tokens = lines[0].split(" ", false, 0)
	map_width = first_tokens.size()

	# Validate all rows have the same width
	for i in range(map_height):
		var tokens = lines[i].split(" ", false, 0)
		if tokens.size() != map_width:
			push_error("Row %d has %d columns, expected %d" % [i, tokens.size(), map_width])
			return

	cell_ids.resize(map_width * map_height)
	for y in range(map_height):
		var tokens = lines[y].split(" ", false, 0)
		for x in range(map_width):
			var id = int(tokens[x])
			cell_ids[x + y * map_width] = id

func _get_tile_def(x: int, y: int) -> TileDefinition:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return null
	var id = cell_ids[x + y * map_width]
	return _id_to_def.get(id, null)

func _is_void(x: int, y: int) -> bool:
	return _get_tile_def(x, y) == null

func _generate_floors_and_ceilings() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var def = _get_tile_def(x, y)
			if def == null:
				continue
			var world_pos = Vector3(x * cell_size, 0, y * cell_size)

			if def.floor_texture:
				var floor_mesh = MeshInstance3D.new()
				floor_mesh.mesh = PlaneMesh.new()
				floor_mesh.mesh.size = Vector2(cell_size, cell_size)
				floor_mesh.rotation_degrees = Vector3(0, 0, 0)
				var mat = StandardMaterial3D.new()
				mat.albedo_texture = def.floor_texture
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
				floor_mesh.material_override = mat
				floor_mesh.position = world_pos + Vector3(cell_size/2, 0, cell_size/2)
				add_child(floor_mesh)

			if def.ceiling_texture:
				var ceil_mesh = MeshInstance3D.new()
				ceil_mesh.mesh = PlaneMesh.new()
				ceil_mesh.mesh.size = Vector2(cell_size, cell_size)
				ceil_mesh.rotation_degrees = Vector3(180, 0, 0)
				var mat = StandardMaterial3D.new()
				mat.albedo_texture = def.ceiling_texture
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
				ceil_mesh.material_override = mat
				ceil_mesh.position = world_pos + Vector3(cell_size/2, wall_height, cell_size/2)
				add_child(ceil_mesh)

func _generate_walls() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var def = _get_tile_def(x, y)
			if def == null:
				continue
			if not def.wall_texture:
				continue

			# North ( -Z direction )
			if _is_void(x, y - 1):
				_place_wall(x, y, 0, def.wall_texture)
			# East ( +X direction )
			if _is_void(x + 1, y):
				_place_wall(x, y, 1, def.wall_texture)
			# South ( +Z direction )
			if _is_void(x, y + 1):
				_place_wall(x, y, 2, def.wall_texture)
			# West ( -X direction )
			if _is_void(x - 1, y):
				_place_wall(x, y, 3, def.wall_texture)

func _place_wall(x: int, y: int, side: int, texture: Texture2D) -> void:
	# side: 0=north, 1=east, 2=south, 3=west
	var mesh = MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	mesh.mesh.size = Vector2(cell_size, wall_height)
	mesh.mesh.orientation = PlaneMesh.FACE_Z

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mesh.material_override = mat

	# Position: center of the cell edge, with y = wall_height/2
	var center_x = x * cell_size + cell_size / 2.0
	var center_z = y * cell_size + cell_size / 2.0
	var pos = Vector3.ZERO
	var rot_deg = 0.0

	match side:
		0:  # North (edge at z = y*cell_size, outward -Z)
			pos = Vector3(center_x, wall_height / 2.0, y * cell_size)
			rot_deg = 0.0   # flip normal from +Z to -Z
		1:  # East (edge at x = (x+1)*cell_size, outward +X)
			pos = Vector3((x + 1) * cell_size, wall_height / 2.0, center_z)
			rot_deg = -90.0   # rotate +Z to +X
		2:  # South (edge at z = (y+1)*cell_size, outward +Z)
			pos = Vector3(center_x, wall_height / 2.0, (y + 1) * cell_size)
			rot_deg = 180.0     # +Z is correct
		3:  # West (edge at x = x*cell_size, outward -X)
			pos = Vector3(x * cell_size, wall_height / 2.0, center_z)
			rot_deg = 90.0    # rotate +Z to -X

	mesh.position = pos
	mesh.rotation_degrees.y = rot_deg
	add_child(mesh)

func is_walkable(x: int, y: int) -> bool:
	return not _is_void(x, y)

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
