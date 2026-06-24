class_name TileDefinition
extends Resource

@export var id: int = -1
@export var floor_texture: Texture2D
@export var ceiling_texture: Texture2D
@export var wall_texture: Texture2D

func get_wall_transform(x: int, y: int, cell_size: float, wall_height: float, side: int):
	if not wall_texture:
		return null
	
	var center_x = x * cell_size + cell_size / 2.0
	var center_z = y * cell_size + cell_size / 2.0
	var pos: Vector3
	var angle_y: float

	match side:
		0:  # North (edge at z = y*cell_size, outward -Z)
			pos = Vector3(center_x, wall_height / 2.0, y * cell_size)
			angle_y = 0.0
		1:  # East (edge at x = (x+1)*cell_size, outward +X)
			pos = Vector3((x + 1) * cell_size, wall_height / 2.0, center_z)
			angle_y = PI / 2.0
		2:  # South (edge at z = (y+1)*cell_size, outward +Z)
			pos = Vector3(center_x, wall_height / 2.0, (y + 1) * cell_size)
			angle_y = PI
		3:  # West (edge at x = x*cell_size, outward -X)
			pos = Vector3(x * cell_size, wall_height / 2.0, center_z)
			angle_y = -PI / 2.0

	var basis = Basis.from_euler(Vector3(0, angle_y, 0))
	return Transform3D(basis, pos)
	
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
