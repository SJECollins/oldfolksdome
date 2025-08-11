extends Resource

class_name StaffMember

@export_enum("trainer", "doctor", "physio", "chef", "seamstress") var type: String
@export var employed: bool = false
@export var position: Vector2
