extends Control

signal end_skirmish(granny: CharacterBody2D)

@onready var start_panel := $PanelStartFight
@onready var end_panel := $PanelEndFight

@export var fighter_1: CharacterBody2D
@export var fighter_2: CharacterBody2D

@onready var music := $BGMusicPlayer
@onready var timer := $Timer
@onready var timer_label := $TimerLabel
@onready var judges := $Judges
@onready var crowd := $Crowd

var round_time_real := 30.0
var round_time_game := 60
var time_left_real := round_time_real
var round_active := false
var round_num := 1
var round_winner := []
var winner
var knockout: bool = false

func _ready():
	music.stop()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_panel.visible = false
	end_panel.visible = false
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.timeout.connect(_on_Timer_timeout)

func position_fighters():
	fighter_1.position = Vector2(268, 192)
	fighter_1.facing_dir = Vector2.RIGHT
	fighter_2.position = Vector2(372, 192)
	fighter_2.facing_dir = Vector2.LEFT

func start_skirmish(f1: CharacterBody2D, f2: CharacterBody2D):
	music.play()
	mouse_filter = Control.MOUSE_FILTER_STOP
	fighter_1 = f1
	fighter_2 = f2
	add_child(fighter_1)
	add_child(fighter_2)
	set_sprites()
	position_fighters()
	start_panel.visible = true
	start_panel.get_node("Column/LblNames").text = fighter_1.granny_stats.name + " vs " + fighter_2.granny_stats.name
	start_panel.get_node("Column/LblRound").text = "Round " + str(round_num) + " of 3"
	start_panel.get_node("Column/LblRoundWinner").visible = false

func set_sprites():
	var judges_choice = [0, 1].pick_random()
	if judges_choice == 0:
		judges.animation = "judges_one"
	else:
		judges.animation = "judges_two"
	if fighter_1.granny_stats.fame > 50 or fighter_2.granny_stats.fame > 50:
		crowd.animation = "largecrowd"
	elif fighter_1.granny_stats.fame > 30 or fighter_2.granny_stats.fame > 30:
		crowd.animation = "medcrowd"
	else:
		crowd.animation = "smallcrowd"
	judges.pause()
	judges.frame = 0
	crowd.pause()
	crowd.frame = 0

func start_round():
	fighter_1.opponent = fighter_2
	fighter_2.opponent = fighter_1
	time_left_real = round_time_real
	round_time_game = 60
	round_active = true
	timer.wait_time = round_time_real / round_time_game
	timer.start()
	update_timer_label()
	judges.play()
	crowd.play()

func _on_Timer_timeout():
	if not round_active:
		timer.stop()
		return
	round_time_game -= 1
	
	if fighter_1.is_out or fighter_2.is_out:
		timer.stop()
		print("Knockout")
		knockout = true
		await get_tree().create_timer(4.0).timeout
		_end_fight()
		round_active = false
		
	if round_time_game <= 0:
		round_time_game = 0
		round_active = false
		timer.stop()
		round_up()
	update_timer_label()

func update_timer_label():
	timer_label.text = str(round_time_game) + "s"

func round_up():
	print("Round end")
	round_active = false
	fighter_1.opponent = null
	fighter_2.opponent = null
	if fighter_1.granny_stats.health > fighter_2.granny_stats.health:
		round_winner.append(fighter_1.granny_stats.name)
	else:
		round_winner.append(fighter_2.granny_stats.name)
	round_num += 1
	if round_num < 4:
		print("Continue")
		fighter_1.recover("rest")
		fighter_2.recover("rest")
		position_fighters()
		_continue_fight()
	else:
		fighter_1.recover("end")
		fighter_2.recover("end")
		_end_fight()

func _continue_fight() -> void:
	start_panel.visible = true
	start_panel.get_node("Column/LblRoundWinner").visible = true
	start_panel.get_node("Column/LblRoundWinner").text = "Winner Round " + str(round_num - 1) + " " + round_winner[round_num - 2]
	if round_num != 3:
		start_panel.get_node("Column/LblRound").text = "Round " + str(round_num) + " of 3"
	else:
		start_panel.get_node("Column/LblRound").text = "Final round!"

func _end_fight() -> void:
	print("Fight over")
	print("Rounds: ", round_winner)
	var num = round_winner.count(fighter_1.granny_stats.name)
	print("Num: ", num)
	var prize = 0
	if knockout:
		if fighter_1.is_out:
			winner = fighter_2.granny_stats.name
			fighter_2.granny_stats.wins += 1
			fighter_1.granny_stats.losses += 1
		else:
			winner = fighter_1.granny_stats.name
			fighter_1.granny_stats.wins += 1
			fighter_2.granny_stats.losses += 1
			prize = 400 # adjust this
	else:
		if num >= 2:
			winner = fighter_1.granny_stats.name
			fighter_1.granny_stats.wins += 1
			fighter_2.granny_stats.losses += 1
			prize = 200
		else:
			winner = fighter_2.granny_stats.name
			fighter_2.granny_stats.wins += 1
			fighter_1.granny_stats.losses += 1
	end_panel.visible = true
	end_panel.get_node("Column/LblNames").text = fighter_1.granny_stats.name + " vs " + fighter_2.granny_stats.name
	end_panel.get_node("Column/LblWinner").text = "Winner: " + winner
	end_panel.get_node("Column/LblPrize").text = "You earned: " + str(prize)
	Global.gold += prize

func _end_skirmish() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fighter_1.get_parent():
		fighter_1.get_parent().remove_child(fighter_1)
	if fighter_2.get_parent():
		fighter_2.get_parent().remove_child(fighter_2)
	end_skirmish.emit(fighter_1)

func _on_btn_fight_pressed() -> void:
	start_round()
	start_panel.visible = false

func _on_btn_end_fight_pressed() -> void:
	end_panel.visible = false
	visible = false
	music.stop()
	_end_skirmish()
