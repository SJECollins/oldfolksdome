extends AnimatedSprite2D

@export var staff_type: String = "doctor"
@export var hired: bool = false
@export var cost: int = 200

func _ready() -> void:
	if hired:
		set_new_position()

func set_new_position() -> void:
	offset = Vector2(0, 0)
	match staff_type:
		"doctor":
			sprite_frames = load("res://assets/spritesheets/doctor.tres")
			position = Vector2(256, 132)
			cost = 200
		"wellness":
			sprite_frames = load("res://assets/spritesheets/wellness.tres")
			position = Vector2(320, 132)
			cost = 400
		"trainer":
			sprite_frames = load("res://assets/spritesheets/trainer.tres")
			position = Vector2(416, 132)
			cost = 250
		"physio":
			sprite_frames = load("res://assets/spritesheets/physio.tres")
			position = Vector2(512, 132)
			cost = 300
	animation = "default"
	play()
