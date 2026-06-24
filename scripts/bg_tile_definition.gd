class_name BgTileDefinition
extends Resource

@export var id: int = -1
@export var floor_texture: Texture2D
@export var ceiling_texture: Texture2D
@export var texture: Texture2D
@export var horizontal_repeat: int = 1
@export var vertical_repeat: int = 1

var texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR

func place_tile(parent: Node3D, x: int, y: int, cell_size: float, wall_height: float) -> void:
	_place_floor_and_ceiling(parent, x, y, cell_size, wall_height)
	_place_billboard(parent, x, y, cell_size, wall_height)

func _place_billboard(parent: Node3D, x: int, y: int, cell_size: float, wall_height: float) -> void:
	var center = Vector3(x * cell_size + cell_size / 2.0,
						 wall_height / 2.0,
						 y * cell_size + cell_size / 2.0)

	var total_planes = horizontal_repeat + vertical_repeat   # X‑facing + Z‑facing

	var mm_instance = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = total_planes

	# Build the two mesh variants
	var mesh_x = PlaneMesh.new()
	mesh_x.size = Vector2(cell_size, wall_height)       # Z and Y
	mesh_x.orientation = PlaneMesh.FACE_X                # normal +X

	var mesh_z = PlaneMesh.new()
	mesh_z.size = Vector2(cell_size, wall_height)       # X and Y
	mesh_z.orientation = PlaneMesh.FACE_Z                # normal +Z

	var base_mesh = PlaneMesh.new()
	base_mesh.size = Vector2(cell_size, wall_height)
	base_mesh.orientation = PlaneMesh.FACE_Z
	multimesh.mesh = base_mesh

	var transforms = PackedFloat32Array()
	transforms.resize(total_planes * 12)

	var index = 0

	# --- X‑facing planes (normal +X) ---
	# Their mesh is FACE_Z rotated 90° around Y.
	var step_x = cell_size / horizontal_repeat
	for i in range(horizontal_repeat):
		var x_offset = (i - (horizontal_repeat - 1) / 2.0) * step_x
		var pos = center + Vector3(x_offset, 0, 0)
		_set_transform(transforms, index, pos, Vector3(0, deg_to_rad(90), 0), Vector3.ONE)
		index += 1

	# --- Z‑facing planes (normal +Z) ---
	# These use the base FACE_Z mesh as‑is.
	var step_z = cell_size / vertical_repeat
	for i in range(vertical_repeat):
		var z_offset = (i - (vertical_repeat - 1) / 2.0) * step_z
		var pos = center + Vector3(0, 0, z_offset)
		_set_transform(transforms, index, pos, Vector3.ZERO, Vector3.ONE)
		index += 1

	multimesh.buffer = transforms
	mm_instance.multimesh = multimesh

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = texture_filter
	mm_instance.material_override = mat

	parent.add_child(mm_instance)

func _set_transform(arr: PackedFloat32Array, index: int, pos: Vector3, euler: Vector3, scale: Vector3) -> void:
	var basis = Basis.from_euler(euler).scaled(scale)
	var offset = index * 12
	arr[offset + 0] = basis.x.x; arr[offset + 1] = basis.x.y; arr[offset + 2] = basis.x.z; arr[offset + 3] = pos.x
	arr[offset + 4] = basis.y.x; arr[offset + 5] = basis.y.y; arr[offset + 6] = basis.y.z; arr[offset + 7] = pos.y
	arr[offset + 8] = basis.z.x; arr[offset + 9] = basis.z.y; arr[offset +10] = basis.z.z; arr[offset +11] = pos.z
func _place_floor_and_ceiling(parent: Node3D, x: int, y: int, cell_size: float, wall_height: float) -> void:
	var world_pos = Vector3(x * cell_size, 0, y * cell_size)
	
	if floor_texture:
		var floor_mesh = MeshInstance3D.new()
		floor_mesh.mesh = PlaneMesh.new()
		floor_mesh.mesh.size = Vector2(cell_size, cell_size)
		floor_mesh.rotation_degrees = Vector3(0, 0, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = floor_texture
		mat.texture_filter = texture_filter
		floor_mesh.material_override = mat
		floor_mesh.position = world_pos + Vector3(cell_size/2, 0, cell_size/2)
		parent.add_child(floor_mesh)
		
	if ceiling_texture:
		var ceil_mesh = MeshInstance3D.new()
		ceil_mesh.mesh = PlaneMesh.new()
		ceil_mesh.mesh.size = Vector2(cell_size, cell_size)
		ceil_mesh.rotation_degrees = Vector3(180, 0, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = ceiling_texture
		mat.texture_filter = texture_filter
		ceil_mesh.material_override = mat
		ceil_mesh.position = world_pos + Vector3(cell_size/2, wall_height, cell_size/2)
		parent.add_child(ceil_mesh)
