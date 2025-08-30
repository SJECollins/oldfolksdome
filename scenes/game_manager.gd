extends Node

@onready var time_manager = $"../TimeManager"
@onready var character_manager = $"../CharacterManager"
@onready var hud = $"../HUD"
@onready var arena = $"../SkirmishArena"
@onready var music = $"../BGMusicPlayer"

func _ready() -> void:
	if Global.game_type == "saved":
		SaveManager.load_game(Global.slot)
	time_manager.week_changed.connect(_week_events)
	time_manager.day_changed.connect(_day_events)
	character_manager.granny_created.connect(_update_hud_granny)
	hud.granny_recruited.connect(_recruit_updates)
	hud.granny_skirmish.connect(_trigger_skirmish)
	hud.granny_selected.connect(_start_a_skirmish)
	hud.skip_skirmish.connect(_skip_skirmish)
	hud.change_time_speed.connect(_change_speed)
	hud.buy_item.connect(_buy_item)
	hud.hire_staff.connect(_hire_staff)
	hud.final_granny_selected.connect(_start_final_fight)
	arena.end_skirmish.connect(_end_skirmish)
	arena.visible = false
	await get_tree().create_timer(2.0).timeout
	_update_hud_time()
	_update_hud_granny()
	_update_hud_gold()


func _day_events() -> void:
	for granny in Global.recruited_grannies:
		granny.update_training()
		granny.recover("post fight")


func _week_events(weeks_remaining: int) -> void:
	_update_hud_time()
	var create_new_grannies = [0, 1].pick_random()
	if create_new_grannies == 0:
		var new_grannies = randi() % 5
		character_manager.create_new_granny_group(new_grannies)
	_deduct_expenses()
	if weeks_remaining == 0:
		_end_fight()
	else:
		if weeks_remaining % 2 == 0:
			_trigger_skirmish()


func _trigger_skirmish() -> void:
	time_manager.pause_time()
	hud.display_skirmish_select()


func _end_fight() -> void:
	time_manager.pause_time()
	hud.end_fight()


func _deduct_expenses() -> void:
	var granny_cost = Global.recruited_grannies.size() * Global.COST_PER_GRANNY
	Global.gold -= granny_cost
	var staff_cost = Global.staff.size() * Global.COST_PER_STAFF
	Global.gold -= staff_cost
	_update_hud_gold()
	if Global.gold <= 0:
		time_manager.pause_time()
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/outro.tscn")


func _update_hud_time() -> void:
	hud.update_week_display(time_manager.get_countdown_string())


func _update_hud_granny() -> void:
	print(Global.recruited_grannies)
	hud.update_granny_display(str(Global.recruited_grannies.size()))


func _update_hud_gold() -> void:
	hud.update_gold_display(str(Global.gold))


func _change_speed(speed: String) -> void:
	time_manager.set_speed(speed)


func _recruit_updates(granny: CharacterBody2D) -> void:
	character_manager.recruit_granny(granny)
	_update_hud_granny()


func _reset_granny_after_skirmish(granny) -> void:
	character_manager.replace_granny(granny)
	granny.facing_dir = Vector2.LEFT
	time_manager.unpause_time()
	_update_hud_gold()


func _start_a_skirmish(f1: CharacterBody2D) -> void:
	music.stop()
	arena.visible = true
	var f2 = Global.all_grannies[0]
	if f2.get_parent():
		f2.get_parent().remove_child(f2)
	arena.start_skirmish(f1, f2)


func _skip_skirmish() -> void:
	time_manager.unpause_time()


func _end_skirmish(granny) -> void:
	music.play()
	_reset_granny_after_skirmish(granny)


func _final_fight() -> void:
	time_manager.pause_time()
	hud.display_final_select()


func _start_final_fight(gran) -> void:
	Global.final_granny = gran
	if gran.get_parent():
		gran.get_parent().remove_child(gran)
	var final_arena = load("res://scenes/final_arena.tscn")
	get_tree().change_scene_to_file(final_arena)


func _buy_item(item: String) -> void:
	if item == "spoon" and Global.gold >= 20:
		Global.weapons.append("spoon")
		Global.gold -= 20
	if item == "cane" and Global.gold >= 50:
		Global.weapons.append("cane")
		Global.gold -= 50
	if item == "walker" and Global.gold >= 50:
		Global.weapons.append("walker")
		Global.gold -= 100
	_update_hud_gold()
	print("Bought: " + item)


func _hire_staff(staff_member) -> void:
	character_manager.add_child(staff_member)
	Global.staff.append(staff_member)
	staff_member.hired = true
	staff_member.set_new_position()
	Global.gold -= staff_member.cost


func export_staff_data() -> Array:
	var staff_data = []
	for staff in Global.staff:
		var staff_dict = {
			"type": staff.staff_type,
			"hired": staff.hired
		}
		staff_data.append(staff_dict)
	return staff_data

func load_staff_data(staff_array: Array) -> void:
	Global.staff = []
	var staff_scene = load("res://assets/characters/staff.tscn")
	for staff in staff_array:
		var staff_instance = staff_scene
		staff_instance.staff_type = staff.staff_type
		staff_instance.hired = staff.hired
		Global.staff.append(staff_instance)
		staff_instance.set_position()
