extends Control

@onready var new_display = $VBoxContainer/HBoxContainer/NewStartContainer
@onready var load_display = $VBoxContainer/HBoxContainer/LoadStartContainer
@onready var quit_display = $VBoxContainer/HBoxContainer/QuitContainer
@onready var delete_all_button = $VBoxContainer/HBoxContainer/LoadStartContainer/BtnDeleteAll

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
	
	for child in load_display.get_children():
		if child.name.begins_with("SaveSlot"):
			child.queue_free()
	
	var save_info_list = SaveManager.get_all_save_info()
	if save_info_list.size() == 0:
		delete_all_button.visible = false
		var label = Label.new()
		label.name = "LblNoSaves"
		label.text = "No saved games"
		load_display.add_child(label)
	else:
		delete_all_button.visible = true
		for save_info in save_info_list:
			var slot = save_info.slot
			
			var hbox = HBoxContainer.new()
			hbox.name = "SaveSlot_%d" % slot
			hbox.custom_minimum_size = Vector2(400, 40)
			
			var load_button = Button.new()
			load_button.text = "Slot %d - Gold: %d - Grannies: %d - Week: %d" % [
				slot, 
				save_info.gold, 
				save_info.num_grannies, 
				save_info.weeks_remaining
			]
			load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			load_button.pressed.connect(_load_slot.bind(slot))
			hbox.add_child(load_button)
			
			var delete_button = Button.new()
			delete_button.text = "Delete"
			delete_button.pressed.connect(func(): _delete_slot(slot))
			hbox.add_child(delete_button)
			
			load_display.add_child(hbox)

func _delete_slot(slot: int):
	if SaveManager.delete_save(slot):
		_on_btn_load_game_pressed()


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
	Global.gold = 200
	get_tree().change_scene_to_file("res://scenes/intro.tscn")


func _on_btn_delete_all_pressed() -> void:
	SaveManager.delete_all_saves()
	_on_btn_load_game_pressed()
