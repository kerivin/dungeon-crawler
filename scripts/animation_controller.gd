extends Node

signal movement_completed
signal turn_completed

@export var player: Node3D
@export var camera: Camera3D
@export var overlay: CanvasLayer

func _ready() -> void:
	idle()

func idle() -> void:
	if overlay and overlay.has_method("play_idle"):
		overlay.play_idle()

func move_to(target_pos: Vector3, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, duration)
	tween.tween_callback(func():
		idle()
		movement_completed.emit())

	if camera and camera.has_method("do_bob"):
		camera.do_bob(duration)

func turn_by(angle_delta: float, duration: float) -> void:
	var current = player.rotation_degrees.y
	var target = current + angle_delta
	var tween = create_tween()
	tween.tween_property(player, "rotation_degrees:y", target, duration)
	tween.tween_callback(func(): turn_completed.emit())
