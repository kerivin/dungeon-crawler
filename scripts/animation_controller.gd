extends Node

@export var camera: Camera3D
@export var overlay: CanvasLayer

@export var camera_bob_idle: CameraBobAnimation = null
@export var camera_bob_walking: CameraBobAnimation = null

enum State { Null, Idle, Moving }

var _state: State = State.Null
var _bob_loop_tween: Tween = null

func start_moving() -> void:
	if _state == State.Moving:
		return
	_state = State.Moving
	_stop_bob_loop()
	_start_bob_loop(camera_bob_walking)
	if overlay and overlay.has_method("play_walk"):
		overlay.play_walk()

func stop_moving() -> void:
	if _state == State.Idle:
		return
	_state = State.Idle
	_stop_bob_loop()
	_start_bob_loop(camera_bob_idle)
	if overlay and overlay.has_method("play_idle"):
		overlay.play_idle()

func _start_bob_loop(animation: CameraBobAnimation) -> void:
	if !animation:
		return
	
	_bob_loop_tween = create_tween()
	_bob_loop_tween.set_loops()
	_bob_loop_tween.tween_callback(_do_single_bob.bind(animation))
	_bob_loop_tween.tween_interval(animation.interval)

func _stop_bob_loop() -> void:
	if _bob_loop_tween and _bob_loop_tween.is_valid():
		_bob_loop_tween.kill()

func _do_single_bob(animation: CameraBobAnimation) -> void:
	if camera and camera.has_method("do_bob"):
		camera.do_bob(animation.duration, animation.amount, animation.sway)
