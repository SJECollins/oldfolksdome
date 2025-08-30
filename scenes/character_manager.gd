extends Node

# Signal for when a granny is created
signal granny_created

# The granny scene 
@onready var granny_scene := preload("res://assets/characters/granny.tscn")

# All the spritesheets to randomly choose from
var nan_spritesheets := [
	load("res://assets/spritesheets/nansheet_one.png"),
	load("res://assets/spritesheets/nansheet_two.png"),
	load("res://assets/spritesheets/nansheet_three.png"),
	load("res://assets/spritesheets/nansheet_four.png"),
	load("res://assets/spritesheets/nansheet_five.png"),
	load("res://assets/spritesheets/nansheet_six.png"),
	load("res://assets/spritesheets/nansheet_seven.png"),
	load("res://assets/spritesheets/nansheet_eight.png"),
	load("res://assets/spritesheets/nansheet_nine.png"),
	load("res://assets/spritesheets/nansheet_ten.png"),
	load("res://assets/spritesheets/nansheet_eleven.png"),
	load("res://assets/spritesheets/nansheet_twelve.png"),
	load("res://assets/spritesheets/nansheet_thirteen.png"),
	load("res://assets/spritesheets/nansheet_fourteen.png"),
	load("res://assets/spritesheets/nansheet_fifteen.png"),
	load("res://assets/spritesheets/nansheet_sixteen.png"),
	load("res://assets/spritesheets/nansheet_seventeen.png"),
	load("res://assets/spritesheets/nansheet_eighteen.png"),
]

# Positions available in the yard
var granny_positions = [
	{"occupied-by": null, "pos": [352.0, 175.0]},
	{"occupied-by": null, "pos": [416.0, 175.0]},
	{"occupied-by": null, "pos": [480.0, 175.0]},
	{"occupied-by": null, "pos": [320.0, 207.0]},
	{"occupied-by": null, "pos": [384.0, 207.0]},
	{"occupied-by": null, "pos": [448.0, 207.0]},
	{"occupied-by": null, "pos": [352.0, 239.0]},
	{"occupied-by": null, "pos": [416.0, 239.0]},
	{"occupied-by": null, "pos": [480.0, 239.0]}
]

# Positions for the staff
var staff_position = [
	{"occupied-by": null, "pos": [0.0, 0.0]},
	{"occupied-by": null, "pos": [0.0, 0.0]},
	{"occupied-by": null, "pos": [0.0, 0.0]},
	{"occupied-by": null, "pos": [0.0, 0.0]}
]

# Names, strings for levels of fame, stat/exp ranges for creating defaults, id
var granny_names := ["Elbowin' Ethel", "Dropkick Doris", "Brawlin' Beryl", "Mean Mabel", "Maulin' Myrtle", "Grapplin' Gladys", "Wallopin' Winifred", "Crackin' Clarice", "Evadin' Ester", "Thumpin' Thelma", "Pummelin' Pearl", "Hammerin' Hilda", "Deckin' Delores", "Mashin' Mildred", "Jabbin' Josephine", "Throwdown Tilda", "Belting Beatrice", "Uppercut Edna", "Anklelock Agnes", "Eye-Gougin' Eunice"]
var fame_strings := ["Unknown", "Up-And-Coming", "Notorious", "Famous", "Superstar"]
var stat_ranges := {"low": [1, 30], "med": [31, 60], "high": [61, 90]}
var granny_id := 1

func _ready() -> void:
	if Global.game_type == "new":
		var first_granny = generate_granny("low") # Create player's first granny
		recruit_granny(first_granny)
		granny_created.emit() 
		create_new_granny_group(3)

func create_new_granny_group(num_grannies: int):
	# Function to create a number of grannies
	var total = num_grannies
	for num in total:
		var experience = ["low", "med", "high"].pick_random()
		Global.all_grannies.append(generate_granny(experience))
		total -= 1

func generate_granny(experience: String) -> CharacterBody2D:
	# Function to generate and return a granny
	var new_granny = granny_scene.instantiate()
	new_granny.granny_stats = generate_stats(experience)
	granny_fame(new_granny)
	new_granny.spritesheet = nan_spritesheets.pick_random()
	return new_granny

func generate_stats(experience: String) -> Granny:
	# Function to generate stats for a granny depending on experience stat range passed in
	var new_granny_stats = Granny.new()
	new_granny_stats.id = granny_id
	new_granny_stats.name = granny_names.pick_random()
	granny_names.erase(new_granny_stats.name)
	new_granny_stats.aggression = randi_range(stat_ranges["low"][0], stat_ranges["low"][1])
	new_granny_stats.strength = randi_range(stat_ranges["low"][0], stat_ranges["low"][1])
	new_granny_stats.dexterity = randi_range(stat_ranges["low"][0], stat_ranges["low"][1])
	new_granny_stats.courage = randi_range(stat_ranges["low"][0], stat_ranges["low"][1])
	match experience: # For now just some random wins and losses
		"med":
			new_granny_stats.wins = randi() % 5
			new_granny_stats.losses = randi() % 5
		"high":
			new_granny_stats.wins = randi_range(5, 10)
			new_granny_stats.losses = randi_range(5, 10)
	granny_id += 1
	return new_granny_stats

func granny_fame(granny) -> void:
	# Set fame and fame string based on wins and losses
	if !granny.granny_stats.recruited:
		if granny.granny_stats.wins == 0 and granny.granny_stats.losses == 0:
			granny.granny_stats.fame = 0
		else:
			granny.granny_stats.fame = (granny.granny_stats.wins * 10) - (granny.granny_stats.losses * 5)
	else:
		granny.granny_stats.fame = calculate_fame(granny.granny_stats.wins, granny.granny_stats.losses)
	if granny.granny_stats.fame < 20:
		granny.granny_stats.fame_string = fame_strings[0]
	elif granny.granny_stats.fame < 40:
		granny.granny_stats.fame_string = fame_strings[1]
	elif granny.granny_stats.fame < 60:
		granny.granny_stats.fame_string = fame_strings[2]
	elif granny.granny_stats.fame < 80:
		granny.granny_stats.fame_string = fame_strings[3]
	else:
		granny.granny_stats.fame_string = fame_strings[4]

func calculate_fame(wins, losses) -> int:
	return wins * 10 - losses * 5 # Needs a proper calculation really (influenced by fame of other figher?)

func replace_granny(granny) -> void:
	for position in granny_positions:
		if position["occupied-by"] == granny or position["occupied-by"] == null:
			position["occupied-by"] = granny
			granny.position = Vector2(position["pos"][0], position["pos"][1])
			granny.facing_dir = Vector2.LEFT
			add_child(granny)
			break

func recruit_granny(granny) -> void:
	for position in granny_positions:
		if position["occupied-by"] == null:
			granny.position = Vector2(position["pos"][0], position["pos"][1])
			position["occupied-by"] = granny
			add_child(granny)
			Global.recruited_grannies.append(granny)
			granny.granny_stats.recruited = true
			granny.facing_dir = Vector2.LEFT
			break


func export_granny_data() -> Array:
	var granny_data = []
	for granny in Global.recruited_grannies:
		var granny_dict = {
			"stats": granny.granny_stats,
			"spritesheet": granny.spritesheet.get_path()
		}
		if granny.weapon:
			granny.clear_old_weapon(granny.weapon)
		granny_data.append(granny_dict)
	for granny in Global.all_grannies:
		var granny_dict = {
			"stats": granny.granny_stats,
			"spritesheet": granny.spritesheet.get_path()
		}
		granny_data.append(granny_dict)
	for granny in Global.retired_grannies:
		var granny_dict = {
			"stats": granny.granny_stats,
			"spritesheet": granny.spritesheet.get_path()
		}
		granny_data.append(granny_dict)
	print(granny_data)
	return granny_data


func load_granny_data(granny_array: Array) -> void:
	Global.recruited_grannies = []
	Global.retired_grannies = []
	Global.all_grannies = []
	print("Recruited: ", Global.recruited_grannies)
	print("All: ", Global.all_grannies)
	for granny in granny_array:
		var gran = granny_scene.instantiate()
		gran.granny_stats = granny.stats
		gran.spritesheet = load(granny.spritesheet)
		if gran.granny_stats.recruited:
			Global.recruited_grannies.append(gran)
			replace_granny(gran)
		elif gran.granny_stats.retired:
			Global.retired_grannies.append(gran)
		else:
			Global.all_grannies.append(gran)
