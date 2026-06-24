class_name TileDefinition
extends Resource

@export var id: int = -1
@export var floor_texture: Texture2D
@export var ceiling_texture: Texture2D
@export var wall_texture: Texture2D

var texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR

func place_floor_and_ceiling(parent: Node3D, x: int, y: int, cell_size: float, wall_height: float) -> void:
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

func place_wall(parent: Node3D, x: int, y: int, cell_size: float, wall_height: float, side: int) -> void:
	if not wall_texture:
		return

	var mesh = MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	mesh.mesh.size = Vector2(cell_size, wall_height)
	mesh.mesh.orientation = PlaneMesh.FACE_Z

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = wall_texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mesh.material_override = mat

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
	parent.add_child(mesh)
	
