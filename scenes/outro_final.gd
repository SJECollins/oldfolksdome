extends Control

@onready var outro_text = $OutroContainer

func _ready() -> void:
	if Global.winner == Global.final_granny.granny_stats.name:
		outro_text.get_node("LblLineTwo").text = Global.final_granny.granny_stats.name + " did it!"
		outro_text.get_node("LblLineThree").text = "The prize is enough for all your grannies to retire!"
		outro_text.get_node("LblLineFour").text = "They won't have to take any more chances in the"
	else:
		outro_text.get_node("LblLineTwo").text = Global.final_granny.granny_stats.name + " wasn't good enough..."
		outro_text.get_node("LblLineThree").text = "Your grannies won't be able to retire."
		outro_text.get_node("LblLineFour").text = "Maybe they can try again next year in the"
	outro_text.get_node("BtnEnd").disabled = true
	await get_tree().create_timer(2.0).timeout
	for child in outro_text.get_children():
		if child is Label:
			fade_in(child)
			await get_tree().create_timer(3.0).timeout
	outro_text.get_node("BtnEnd").disabled = false
	outro_text.get_node("BtnEnd").modulate.a = 1.0

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


func _on_btn_end_pressed() -> void:
	for child in outro_text.get_children():
		if child is Label:
			fade_out(child)
			await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
