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

var _id_to_tile_def: Dictionary[int, TileDefinition] = {}
var _id_to_bg_tile_def: Dictionary[int, BgTileDefinition] = {}

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
	var horizontal_transforms: Dictionary = {}
	var wall_transforms: Dictionary = {}
	var billboard_transforms: Dictionary = {}
	
	var neighbours = [
		Vector2i(0, -1),   # north
		Vector2i(1,  0),   # east
		Vector2i(0,  1),   # south
		Vector2i(-1, 0)    # west
	]
	
	for y in range(map_height):
		for x in range(map_width):
			match _get_cell_type(x, y):
				CellType.WALKABLE:
					var def = _get_tile_def(x, y)
					if def:
						var floor_transform = def.get_floor_transform(x, y, cell_size)
						if floor_transform:
							horizontal_transforms.get_or_add(def.floor_texture, []).append(floor_transform)
						
						var ceiling_transform = def.get_ceiling_transform(x, y, cell_size, wall_height)
						if ceiling_transform:
							horizontal_transforms.get_or_add(def.ceiling_texture, []).append(ceiling_transform)
#
						for side in range(4):
							var nx = x + neighbours[side].x
							var ny = y + neighbours[side].y
							if _is_void(nx, ny):
								var wall_transform = def.get_wall_transform(x, y, cell_size, wall_height, side)
								if wall_transform:
									wall_transforms.get_or_add(def.wall_texture, []).append(wall_transform)

				CellType.BACKGROUND:
					var def = _get_bg_tile_def(x, y)
					if def:
						var floor_transform = def.get_floor_transform(x, y, cell_size)
						if floor_transform:
							horizontal_transforms.get_or_add(def.floor_texture, []).append(floor_transform)
						
						var ceiling_transform = def.get_ceiling_transform(x, y, cell_size, wall_height)
						if ceiling_transform:
							horizontal_transforms.get_or_add(def.ceiling_texture, []).append(ceiling_transform)
						
						var billboard_transform = def.get_billboard_transforms(x, y, cell_size, wall_height)
						if not billboard_transform.is_empty():
							billboard_transforms.get_or_add(def.texture, []).append_array(billboard_transform)
							
	_create_multimesh_for(horizontal_transforms, 
		_create_plane_mesh(Vector2(cell_size, cell_size), PlaneMesh.FACE_Y),
		"floor_ceiling")

	_create_multimesh_for(wall_transforms,
		_create_plane_mesh(Vector2(cell_size, wall_height), PlaneMesh.FACE_Z),
		"walls")

	_create_multimesh_for(billboard_transforms,
		_create_plane_mesh(Vector2(cell_size, wall_height), PlaneMesh.FACE_Z),
		"billboards",
		true)

func _create_plane_mesh(size: Vector2, orientation = PlaneMesh.FACE_Z) -> PlaneMesh:
	var mesh = PlaneMesh.new()
	mesh.size = size
	mesh.orientation = orientation
	return mesh

func _create_multimesh_for(transforms_by_texture: Dictionary, base_mesh: PlaneMesh, group_name: String, use_alpha_scissor = false) -> void:
	for texture in transforms_by_texture:
		var list: Array = transforms_by_texture[texture]
		if list.is_empty():
			continue

		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = base_mesh
		mm.instance_count = list.size()
		mm.buffer = _pack_transforms(list)

		var mi = MultiMeshInstance3D.new()
		print("MultiMeshInstance3D transform: ", mi.transform)
		mi.multimesh = mm
		mi.material_override = _make_material(texture, use_alpha_scissor)
		mi.name = "%s_%s" % [group_name, texture.resource_path.get_file() if texture.resource_path else str(texture.get_instance_id())]
		add_child(mi)

func _pack_transforms(transforms: Array) -> PackedFloat32Array:
	var arr = PackedFloat32Array()
	arr.resize(transforms.size() * 12)
	for i in transforms.size():
		var mesh_transform = transforms[i]
		var b = mesh_transform.basis
		var o = mesh_transform.origin
		var off = i * 12
		arr[off+0] = b.x.x; arr[off+1] = b.x.y; arr[off+2] = b.x.z; arr[off+3] = o.x
		arr[off+4] = b.y.x; arr[off+5] = b.y.y; arr[off+6] = b.y.z; arr[off+7] = o.y
		arr[off+8] = b.z.x; arr[off+9] = b.z.y; arr[off+10]= b.z.z; arr[off+11]= o.z
	return arr

func _make_material(texture: Texture2D, alpha_scissor: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	if alpha_scissor:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.5
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

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
