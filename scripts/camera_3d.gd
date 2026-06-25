extends Camera3D

var _bob_tween: Tween = null

func do_bob(duration: float, amount: float, sway: float) -> void:
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()

	_bob_tween = create_tween()
	# First half: down + slightly forward
	_bob_tween.tween_property(self, "position:y", -amount, duration * 0.5)
	_bob_tween.parallel().tween_property(self, "position:z", sway, duration * 0.5)
	# Second half: back to neutral
	_bob_tween.tween_property(self, "position:y", 0.0, duration * 0.5)
	_bob_tween.parallel().tween_property(self, "position:z", 0.0, duration * 0.5)
