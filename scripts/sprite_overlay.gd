extends CanvasLayer

@onready var hands = $HandsAnchor/Hands
@onready var head = $HeadAnchor/Head

func play_walk() -> void:
	hands.play("default")

func play_idle() -> void:
	hands.play("default")
