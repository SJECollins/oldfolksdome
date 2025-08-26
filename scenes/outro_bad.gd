extends Control

@onready var intro_text = $OutroContainer
var menu_scene = null

func _ready() -> void:
	intro_text.get_node("BtnEnd").disabled = true
	await get_tree().create_timer(2.0).timeout
	for child in intro_text.get_children():
		if child is Label:
			fade_in(child)
			await get_tree().create_timer(3.0).timeout
	intro_text.get_node("BtnEnd").disabled = false
	intro_text.get_node("BtnEnd").modulate.a = 1.0

func fade_in(label) -> void:
	label.modulate.a = 0.0
	var duration = 2.0
	var time_passed = 0.0
	while time_passed < duration:
		await get_tree().process_frame
		time_passed += get_process_delta_time()
		label.modulate.a = time_passed / duration
	label.modulate.a = 1.0

func fade_out(label) -> void:
	label.modulate.a = 1.0
	var duration = 1.0
	var time_passed = 0.0
	while time_passed < duration:
		await get_tree().process_frame
		time_passed += get_process_delta_time()
		label.modulate.a = 1.0 - (time_passed / duration)
	label.modulate.a = 0.0

func _on_btn_continue_pressed() -> void:
	for child in intro_text.get_children():
		if child is Label:
			fade_in(child)
			await get_tree().create_timer(1.0).timeout
	menu_scene = preload("res://ui/main_menu.tscn").instantiate()
	add_child(menu_scene)
