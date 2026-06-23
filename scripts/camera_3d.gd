extends Camera3D

@export var bob_amount: float = 0.1
@export var bob_sway: float = 0.03

var _bob_tween: Tween = null

func do_bob(duration: float) -> void:
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()

	_bob_tween = create_tween()
	# First half: down + slightly forward
	_bob_tween.tween_property(self, "position:y", -bob_amount, duration * 0.5)
	_bob_tween.parallel().tween_property(self, "position:z", bob_sway, duration * 0.5)
	# Second half: back to neutral
	_bob_tween.tween_property(self, "position:y", 0.0, duration * 0.5)
	_bob_tween.parallel().tween_property(self, "position:z", 0.0, duration * 0.5)
