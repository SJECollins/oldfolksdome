extends Node

const SAVE_DIR := "user://saves/"
const SAVE_DATA_RESOURCE := preload("res://assets/resources/save_data.gd")

func get_save_path(slot: int) -> String:
	return "%ssave_%d.tres" % [SAVE_DIR, slot]

func get_next_available_slot() -> int:
	var existing_slots = get_save_slots()
	var slot = 1
	while slot in existing_slots:
		slot += 1
	return slot

func save_game(slot: int):
	var game_manager = get_node("/root/Game/GameManager")
	var character_manager = get_node("/root/Game/CharacterManager")
	var time_manager = get_node("/root/Game/TimeManager")
	
	var save_data: SaveData = SAVE_DATA_RESOURCE.new()
	save_data.gold = Global.gold
	save_data.weeks_remaining = time_manager.weeks_remaining
	save_data.num_grannies = Global.recruited_grannies.size()
	save_data.granny_data = character_manager.export_granny_data()
	save_data.staff_data = game_manager.export_staff_data()
	save_data.weapons = Global.weapons.duplicate(true)
	
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var err = ResourceSaver.save(save_data, get_save_path(slot))
	if err != OK:
		push_error("Failed to save slot %d, error code: %d" % [slot, err])

func load_game(slot: int):
	var game_manager = get_node("/root/Game/GameManager")
	var character_manager = get_node("/root/Game/CharacterManager")
	var time_manager = get_node("/root/Game/TimeManager")
	var path = get_save_path(slot)
	
	if not FileAccess.file_exists(path):
		push_warning("No save file found in slot %d." % slot)
		return
	
	var loaded_data = ResourceLoader.load(path)
	if loaded_data:
		Global.gold = loaded_data.gold
		time_manager.weeks_remaining = loaded_data.weeks_remaining
		character_manager.load_granny_data(loaded_data.granny_data)
		game_manager.load_staff_data(loaded_data.staff_data)
		Global.weapons = loaded_data.weapons.duplicate(true)

func get_save_slots() -> Array:
	var slots := []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") and file_name.begins_with("save_"):
				var parts = file_name.split('_')
				if parts.size() > 1:
					var slot_str = parts[1].split('.')[0]
					var slot_num = int(slot_str)
					slots.append(slot_num)
			file_name = dir.get_next()
		dir.list_dir_end()
	slots.sort()
	return slots

func get_save_info(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	var info = {}
	
	if not FileAccess.file_exists(path):
		return info
	
	var save_data = ResourceLoader.load(path)
	if save_data:
		info["slot"] = slot
		info["gold"] = save_data.gold
		info["weeks_remaining"] = save_data.weeks_remaining
		info["num_grannies"] = save_data.num_grannies
		info["granny_data"] = save_data.granny_data
		info["last_modified"] = FileAccess.get_modified_time(path)
	return info

func get_all_save_info() -> Array:
	var save_info = []
	var slots = get_save_slots()
	for slot in slots:
		var info = get_save_info(slot)
		if not info.is_empty():
			save_info.append(info)
	return save_info


func delete_save(slot: int) -> bool:
	var path = get_save_path(slot)

	var dir = DirAccess.open("user://")
	if dir == null:
		push_error("Failed to open user directory.")
		return false

	if dir.remove(path) != OK:
		push_error("Failed to delete save file: %s" % path)
		return false

	print("Save file deleted successfully: %s" % path)
	return true


func delete_all_saves():
	var slots = get_save_slots()
	for slot in slots:
		delete_save(slot)
