extends Node

@onready var time_manager = $"../TimeManager"
@onready var character_manager = $"../CharacterManager"
@onready var hud = $"../HUD"
@onready var arena = $"../SkirmishArena"


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
	arena.end_skirmish.connect(_end_skirmish)
	arena.visible = false
	await get_tree().create_timer(2.0).timeout
	_update_hud_time()
	_update_hud_granny()


func _day_events() -> void:
	for granny in Global.recruited_grannies:
		granny.update_training()


func _week_events(weeks_remaining: int) -> void:
	_update_hud_time()
	var create_new_grannies = [0, 1].pick_random()
	if create_new_grannies == 0:
		var new_grannies = randi() % 5
		character_manager.create_new_granny_group(new_grannies)
	_deduct_expenses()
	if weeks_remaining > 2:
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


func _update_hud_time() -> void:
	hud.update_week_display(time_manager.get_countdown_string())


func _update_hud_granny() -> void:
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


func _start_a_skirmish(f1: CharacterBody2D) -> void:
	arena.visible = true
	var f2 = Global.all_grannies[0]
	arena.start_skirmish(f1, f2)


func _skip_skirmish() -> void:
	time_manager.unpause_time()


func _end_skirmish(granny) -> void:
	_reset_granny_after_skirmish(granny)


func _final_fight() -> void:
	pass
