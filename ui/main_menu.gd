extends Control

@onready var new_display = $VBoxContainer/HBoxContainer/NewStartContainer
@onready var load_display = $VBoxContainer/HBoxContainer/LoadStartContainer
@onready var quit_display = $VBoxContainer/HBoxContainer/QuitContainer

func _ready() -> void:
	_change_menu("none")

func _change_menu(selection) -> void:
	new_display.visible = false
	load_display.visible = false
	quit_display.visible = false
	if selection == "new":
		new_display.visible = true
	elif selection == "load":
		load_display.visible = true
	elif selection == "quit":
		quit_display.visible = true

func _on_btn_new_game_pressed() -> void:
	_change_menu("new")

func _on_btn_load_game_pressed() -> void:
	_change_menu("load")
	
	# Clear any existing save buttons first
	for child in load_display.get_children():
		if child.name.begins_with("SaveSlot"):
			child.queue_free()
	
	var saved_games = SaveManager.get_save_slots()
	print(saved_games)
	if saved_games.size() == 0:
		var label = Label.new()
		label.name = "LblNoSaves"
		label.text = "No saved games"
		load_display.add_child(label)
	else:
		var save_info_list = SaveManager.get_all_save_info()
		for save_info in save_info_list:
			var slot = save_info.slot
			
			var button = Button.new()
			button.text = "Slot %d - Gold: %d - Grannies: %d - Week: %d" % [
				slot, 
				save_info.gold, 
				save_info.num_grannies, 
				save_info.weeks_remaining
			]
			button.custom_minimum_size = Vector2(400, 40)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#for slot in saved_games:
			#var button = Button.new()
			#button.name = "SaveSlot" + str(slot)
			#button.text = "Slot %d - Gold: %d - Grannies: %d - Weeks: %d" % [
				#slot, 
				#slot.gold, 
				#slot.recruited_grannies, 
				#slot.weeks_remaining
			#]
			#button.custom_minimum_size = Vector2(400, 40)
			#button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(_load_slot.bind(slot))
			load_display.add_child(button)

func _load_slot(slot: int):
	Global.game_type = "saved"
	Global.slot = slot
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_btn_quit_pressed() -> void:
	_change_menu("quit")

func _on_btn_cancel_pressed() -> void:
	_change_menu("none")

func _on_btn_cancel_quit_pressed() -> void:
	_change_menu("none")

func _on_btn_quit_confirm_pressed() -> void:
	get_tree().quit()

func _on_btn_start_new_pressed() -> void:
	Global.game_type = "new"
	Global.gold = 1000
	get_tree().change_scene_to_file("res://scenes/intro.tscn")
