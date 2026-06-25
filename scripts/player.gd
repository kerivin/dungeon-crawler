extends Node3D

var grid_position: Vector2i = Vector2i.ZERO
var cell_size: float = 2.0
var map_node: Node

@export var move_speed: float = 3.0          # units per second
#@export var turn_speed: float = 180.0        # degrees per second
@export var eye_height: float = 1.2
@export var mouse_sensitivity: float = 0.2   # degrees per pixel
@export var move_threshold: float = 0.3
@export var output_moving_info: bool = false

@onready var anim: Node = $AnimationController

var _moving: bool = false
var _current_axis := Vector3.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_snap_to_grid()

func _process(delta: float) -> void:
	_process_movement(delta)

func _process_movement(delta: float) -> void:
	var raw_move: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		raw_move = Vector2(0, 1)
	elif Input.is_action_pressed("move_backward"):
		raw_move = Vector2(0, -1)
	elif Input.is_action_pressed("move_left"):
		raw_move = Vector2(-1, 0)
	elif Input.is_action_pressed("move_right"):
		raw_move = Vector2(1, 0)
	
	if raw_move.is_zero_approx():
		_stop_moving("raw_move.is_zero_approx(): %s" % raw_move)
		return
	
	var world_dir: Vector2 = _get_world_direction(raw_move)
	if world_dir.length_squared() < 0.00001:
		_stop_moving("world_dir.length_squared() < 0.00001: %s" % world_dir)
		return
	
	var cell_center = Vector3(grid_position.x * cell_size + cell_size / 2., eye_height, grid_position.y * cell_size + cell_size / 2.)
	var at_cell_center = global_position.distance_to(cell_center) < 0.01
	if at_cell_center:
		global_position = cell_center # to avoid bs
		var snap_axis = _get_snap_axis(world_dir)
		if !snap_axis.is_zero_approx():
			_current_axis = snap_axis
			_start_moving("!snap_axis.is_zero_approx(): %s" % snap_axis)
		else:
			_stop_moving("snap_axis.is_zero_approx(): %s" % snap_axis)
			return
	
	var dir_sign = _get_axis_projection_sign(world_dir, 0)
	if dir_sign != 0:
		var from_center: bool = sign((_current_axis * dir_sign).dot(cell_center.direction_to(global_position))) > 0
		if from_center:
			var next_cell = grid_position + Vector2i(int(_current_axis.x), int(_current_axis.z)) * dir_sign
			if map_node.is_walkable(next_cell.x, next_cell.y):
				_start_moving("map_node.is_walkable(next_cell.x, next_cell.y): %s" % next_cell)
			else:
				_stop_moving("!map_node.is_walkable(next_cell.x, next_cell.y): %s" % next_cell)
		else:
			_start_moving("from_center: %s" % from_center)
	else:
		return
	
	if _moving:
		global_position += _current_axis * dir_sign * move_speed * delta
		grid_position = map_node.world_to_grid(global_position)

func _get_world_direction(raw_move: Vector2) -> Vector2:
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var world_movement = Vector2(right.x, right.z) * raw_move.x + Vector2(forward.x, forward.z) * raw_move.y
	return world_movement

func _get_axis_projection_sign(world_dir: Vector2, default_value: int = 0) -> int:
	var proj = world_dir.x * _current_axis.x + world_dir.y * _current_axis.z
	return sign(proj) if abs(proj) > 0.001 else default_value

func _get_snap_axis(world_dir: Vector2) -> Vector3:
	if abs(world_dir.x) < move_threshold && abs(world_dir.y) < move_threshold:
		return Vector3.ZERO
	world_dir = world_dir.normalized()
	var axis: Vector3 = Vector3(sign(world_dir.x), 0, 0) if abs(world_dir.x) > abs(world_dir.y) else Vector3(0, 0, sign(world_dir.y))
	var next_cell = Vector2i(grid_position.x + int(axis.x), grid_position.y + int(axis.z))
	if !map_node.is_walkable(next_cell.x, next_cell.y):
		return Vector3.ZERO
	
	return axis

func _start_moving(message: String) -> void:
	if !_moving:
		_moving = true
		anim.start_moving()
		if output_moving_info:
			print("moving: ", message)

func _stop_moving(message: String) -> void:
	if _moving:
		_moving = false
		anim.stop_moving()
		if output_moving_info:
			print("not moving: ", message)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _snap_to_grid() -> void:
	global_position = map_node.grid_to_world(grid_position.x, grid_position.y) +\
		Vector3(cell_size / 2., 0., cell_size / 2.) +\
		Vector3.UP * eye_height
	anim.stop_moving()
