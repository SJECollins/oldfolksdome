extends Node

var menu_scene = null

func _ready() -> void:
	menu_scene = preload("res://ui/main_menu.tscn").instantiate()
	add_child(menu_scene)
