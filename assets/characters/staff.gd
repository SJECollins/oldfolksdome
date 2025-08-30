extends AnimatedSprite2D

@export var staff_type: String = "doctor"
@export var hired: bool = false
@export var cost: int = 200

func _ready() -> void:
	set_sprite()
	if hired:
		set_new_position()


func set_sprite():
	match staff_type:
		"doctor":
			sprite_frames = load("res://assets/spritesheets/doctor.tres")
			cost = 200
		"wellness":
			sprite_frames = load("res://assets/spritesheets/wellness.tres")
			cost = 400
		"trainer":
			sprite_frames = load("res://assets/spritesheets/trainer.tres")
			cost = 250
		"physio":
			sprite_frames = load("res://assets/spritesheets/physio.tres")
			cost = 300


func set_new_position() -> void:
	offset = Vector2(0, 0)
	match staff_type:
		"doctor":
			position = Vector2(256, 132)
		"wellness":
			position = Vector2(320, 132)
		"trainer":
			position = Vector2(416, 132)
		"physio":
			position = Vector2(512, 132)
	animation = "default"
	play()
