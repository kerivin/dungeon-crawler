extends Node3D

var grid_position: Vector2i = Vector2i.ZERO
var cell_size: float = 2.0
var map_node: Node

# Direction index: 0=north (-Z), 1=west (+X), 2=south (+Z), 3=east (-X)
var direction: int = 0
const DIR_VECTORS = [
	Vector2i(0, -1),   # north
	Vector2i(-1, 0),    # west
	Vector2i(0, 1),    # south
	Vector2i(1, 0)    # east
]

var is_animating: bool = false

@export var eye_height: float = 1.2
@export var move_duration: float = 0.4
@export var turn_duration: float = 0.2

@onready var anim: Node = $AnimationController

func _ready() -> void:
	_snap_to_grid()

func _process(_delta: float) -> void:
	if is_animating:
		return

	if Input.is_action_pressed("turn_left"):
		_turn(90.0)
		return
	if Input.is_action_pressed("turn_right"):
		_turn(-90.0)
		return

	if Input.is_action_pressed("move_forward"):
		_move(1)
	elif Input.is_action_pressed("move_backward"):
		_move(-1)

func _move(forward: int) -> void:
	var step = DIR_VECTORS[direction] * forward
	var target_grid = grid_position + step
	if not map_node.is_walkable(target_grid.x, target_grid.y):
		return

	var target_world = _grid_to_world(target_grid.x, target_grid.y) + Vector3.UP * eye_height

	is_animating = true
	anim.move_to(target_world, move_duration)
	await anim.movement_completed
	grid_position = target_grid
	is_animating = false

func _turn(angle_delta: float) -> void:
	is_animating = true
	anim.turn_by(angle_delta, turn_duration)
	await anim.turn_completed
	var dir_delta = 1 if angle_delta > 0 else -1
	direction = (direction + dir_delta + 4) % 4
	rotation_degrees.y = direction * 90.0
	is_animating = false

func _grid_to_world(gx: int, gy: int) -> Vector3:
	return Vector3(
		gx * cell_size + cell_size / 2.0,
		0.0,
		gy * cell_size + cell_size / 2.0
	)

func _snap_to_grid() -> void:
	global_position = _grid_to_world(grid_position.x, grid_position.y) + Vector3.UP * eye_height
	rotation_degrees.y = direction * 90.0
