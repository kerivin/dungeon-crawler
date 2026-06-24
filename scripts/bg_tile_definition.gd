class_name BgTileDefinition
extends Resource

@export var id: int = -1
@export var floor_texture: Texture2D
@export var ceiling_texture: Texture2D
@export var texture: Texture2D
@export var horizontal_repeat: int = 1
@export var vertical_repeat: int = 1

func get_billboard_transforms(x: int, y: int, cell_size: float, wall_height: float) -> Array[Transform3D]:
	if not texture:
		return []
	
	var center = Vector3(
		x * cell_size + cell_size / 2.0,
		wall_height / 2.0,
		y * cell_size + cell_size / 2.0
	)

	var out: Array[Transform3D] = []

	# X‑facing planes (normal +X) – rotated 90° around Y
	var step_x = cell_size / horizontal_repeat
	for i in range(horizontal_repeat):
		var x_offset = (i - (horizontal_repeat - 1) / 2.0) * step_x
		var pos = center + Vector3(x_offset, 0, 0)
		out.append(Transform3D(Basis.from_euler(Vector3(0, PI / 2.0, 0)), pos))

	# Z‑facing planes (normal +Z) – no rotation
	var step_z = cell_size / vertical_repeat
	for i in range(vertical_repeat):
		var z_offset = (i - (vertical_repeat - 1) / 2.0) * step_z
		var pos = center + Vector3(0, 0, z_offset)
		out.append(Transform3D(Basis(), pos))

	return out

func get_floor_transform(x: int, y: int, cell_size: float):
	if not floor_texture:
		return null
	
	var world_pos = Vector3(x * cell_size + cell_size / 2.0, 0.0, y * cell_size + cell_size / 2.0)
	return Transform3D(Basis(), world_pos)

func get_ceiling_transform(x: int, y: int, cell_size: float, wall_height: float):
	if not ceiling_texture:
		return null
	
	var world_pos = Vector3(x * cell_size + cell_size / 2.0, wall_height, y * cell_size + cell_size / 2.0)
	var basis = Basis.from_euler(Vector3(PI, 0, 0))   # 180° around X
	return Transform3D(basis, world_pos)
