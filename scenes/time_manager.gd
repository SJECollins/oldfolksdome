extends Node

signal week_changed(weeks_remaining: int)
signal day_changed

var weeks_remaining := 52
var day_countdown := 7
#var seconds_per_week := 300 / 225 / 150
var seconds_per_day := 40

var day_timer: Timer

func _ready() -> void:
	setup_timer()

func setup_timer():
	day_timer = Timer.new()
	day_timer.wait_time = seconds_per_day
	day_timer.timeout.connect(_on_day_changed)
	day_timer.autostart = true
	add_child(day_timer)

func _on_day_changed() -> void:
	day_changed.emit()
	day_countdown -= 1
	if day_countdown == 0:
		_on_week_changed()
		day_countdown = 7

func _on_week_changed() -> void:
	weeks_remaining -= 1
	week_changed.emit(weeks_remaining)

func set_speed(speed: String) -> void:
	print(speed)
	match speed:
		"normal":
			seconds_per_day = 40
		"medium":
			seconds_per_day = 30
		"fast":
			seconds_per_day = 5
		_:
			seconds_per_day = 40 # just in case
	if day_timer:
		day_timer.wait_time = seconds_per_day
		day_timer.start()

func pause_time() -> void:
	day_timer.paused = true

func unpause_time() -> void:
	day_timer.paused = false

func get_countdown_string() -> String:
	return "%s weeks left" % weeks_remaining
