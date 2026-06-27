extends Node3D

var grid_position: Vector2i = Vector2i.ZERO
var cell_size: float = 2.0
var map_node: Node

@export var move_speed: float = 3.0          # units per second
#@export var turn_speed: float = 180.0        # degrees per second
@export var eye_height: float = 1.2
@export var mouse_sensitivity: float = 0.2   # degrees per pixel
@export var axis_match_threshold: float = 0.3
@export var output_moving_info: bool = false

@onready var anim: Node = $AnimationController

var _moving: bool = false
var _current_axis := Vector3.ZERO
var _input_history = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_snap_to_grid()

func _process(delta: float) -> void:
	_process_movement(delta)

func _process_movement(delta: float) -> void:
	var actions: Dictionary = {
		"move_forward" :	[0, Vector2(0, 1)],
		"move_backward" :	[1, Vector2(0, -1)],
		"move_left" :		[2, Vector2(-1, 0)],
		"move_right" :		[3, Vector2(1, 0)],
	}
	
	for action in actions:
		if Input.is_action_just_pressed(action):
			_input_history.push_back(action)
		if Input.is_action_just_released(action):
			_input_history.erase(action)
	
	if _input_history.is_empty():
		_stop_moving("1: _input_history.is_empty()")
		return
	
	var cell_center = Vector3(grid_position.x * cell_size + cell_size / 2., eye_height, grid_position.y * cell_size + cell_size / 2.)
	var distance_to_cell_center = global_position.distance_to(cell_center)
	
	_input_history.sort_custom(func(a, b):
		return actions[a][0] > actions[b][0])

	for i in _input_history.size():
		if _process_action(actions[_input_history[-i - 1]][1], delta, cell_center, distance_to_cell_center):
			return

func _process_action(action: Vector2, delta: float, cell_center: Vector3, distance_to_cell_center: float) -> bool:
	var world_dir: Vector2 = _get_world_direction(action)
	if world_dir.length_squared() < 0.00001:
		_stop_moving("2: world_dir.length_squared() < 0.00001: %s" % world_dir)
		return false
	
	if distance_to_cell_center <= 0.02:
		global_position = cell_center # to avoid bs
		var snap_axis = _get_snap_axis(world_dir)
		if !snap_axis.is_zero_approx():
			_current_axis = snap_axis
			_start_moving("3: !snap_axis.is_zero_approx(): %s" % snap_axis)
		else:
			_stop_moving("3: snap_axis.is_zero_approx(): %s" % snap_axis)
			return false
	
	var dir_sign = _get_axis_projection_sign(world_dir, 0)
	if dir_sign != 0:
		var from_center: bool = sign((_current_axis * dir_sign).dot(cell_center.direction_to(global_position))) > 0
		if from_center:
			var next_cell = grid_position + Vector2i(int(_current_axis.x), int(_current_axis.z)) * dir_sign
			if map_node.is_walkable(next_cell.x, next_cell.y):
				_start_moving("4: map_node.is_walkable(next_cell.x, next_cell.y): %s" % next_cell)
			else:
				_stop_moving("4: !map_node.is_walkable(next_cell.x, next_cell.y): %s" % next_cell)
		else:
			_start_moving("5: from_center: %s" % from_center)
	else:
		_stop_moving("6: dir_sign: %s" % dir_sign)
		return false

	if !_moving:
		return false
	
	global_position += _current_axis * dir_sign * move_speed * delta
	grid_position = map_node.world_to_grid(global_position)
	return true

func _get_world_direction(raw_move: Vector2) -> Vector2:
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var world_movement = Vector2(right.x, right.z) * raw_move.x + Vector2(forward.x, forward.z) * raw_move.y
	return world_movement

func _get_axis_projection_sign(world_dir: Vector2, default_value: int = 0) -> int:
	var proj = world_dir.x * _current_axis.x + world_dir.y * _current_axis.z
	return sign(proj) if abs(proj) > axis_match_threshold else default_value

func _get_snap_axis(world_dir: Vector2) -> Vector3:
	var axis := Vector2i(sign(world_dir.x), 0) if abs(world_dir.x) > abs(world_dir.y) else Vector2i(0, sign(world_dir.y))
	var next_cell = Vector2i(grid_position.x + axis.x, grid_position.y + axis.y)
	if !map_node.is_walkable(next_cell.x, next_cell.y):
		return Vector3.ZERO
	
	return Vector3(axis.x, 0, axis.y)

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
