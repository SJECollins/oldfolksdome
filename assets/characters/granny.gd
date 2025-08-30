extends CharacterBody2D

@export var granny_stats: Granny
@export var spritesheet = preload("res://assets/spritesheets/nansheet_one.png")
@onready var shape = $GrannyShape
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var attack_ray: RayCast2D = $AttackRay
@onready var healthbar = $HealthBar
@onready var staminabar = $StaminaBar
@onready var plus_one = $LblPlusOne
@onready var stats = $Stats
@onready var weapon_list = $Stats/WeaponList
@onready var weapon_node = $WeaponNode

const ATTACK_RANGE := 32
const STAMINA_RECOVERY_RATE := 50.0
const MAX_STAMINA := 1000 
const STAMINA_RUN_DEPLETION := 1
const STAMINA_ATTACK_COST := 15
const STAMINA_DODGE_COST := 15
const STAMINA_BLOCK_COST := 10

const RUN_SPEED := 10.0 # Higher with dexterity????

const STUN_HEALTH_THRESHOLD := 30
const STUN_CHANCE := 0.15

const RUNAWAY_HEALTH_THRESHOLD := 25
const RUNAWAY_COURAGE_THRESHOLD := 30

const ACTION_COOLDOWN := 2.0 
const REST_CHANCE := 0.5
const REST_STAMINA_THRESHOLD := 600
const REST_DURATION := 3.0
const RUNAWAY_RANDOMNESS := 60.0

var stun_timer: float = 0.0
var is_stunned: bool = false
var is_out: bool = false
var is_action_playing: bool = false

# New state variables for slower behavior
var action_cooldown_timer: float = 0.0
var is_resting: bool = false
var rest_timer: float = 0.0
var last_action: String = ""

var facing_dir: Vector2 = Vector2.DOWN
var opponent: CharacterBody2D = null

var currently_training: String
var plus_one_pos := Vector2(8.0, -20.0)
var show_plus_one := false

var weapon
var weapon_sprite

func _ready():
	attack_ray.enabled = true
	$GrannySprite.texture = spritesheet
	_update_health()
	_update_stamina()
	stats.visible = false
	plus_one.visible = false
	weapon_list.visible = false
	_update_stats_display()

func add_weapon(weapon_name, sprite) -> void:
	weapon = weapon_name
	weapon_sprite = sprite
	weapon_node.add_child(weapon_sprite)
	if weapon_name == "spoon":
		granny_stats.strength += 10
	elif weapon_name == "cane":
		granny_stats.strength += 15
	elif weapon_name == "walker":
		granny_stats.strength += 20

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		stats.visible = true

func _update_health():
	healthbar.value = granny_stats.health

func _update_stamina():
	staminabar.value = granny_stats.stamina

func _update_stats_display():
	stats.get_node("Margins/Column/LblName").text = granny_stats.name
	stats.get_node("Margins/Column/LblFame").text = granny_stats.fame_string
	stats.get_node("Margins/Column/RowMiddle/BtnAggression").text = "A: " + str(granny_stats.aggression)
	stats.get_node("Margins/Column/RowMiddle/BtnStrength").text = "S: " + str(granny_stats.strength)
	stats.get_node("Margins/Column/RowMiddle/BtnDexterity").text = "D: " + str(granny_stats.dexterity)
	stats.get_node("Margins/Column/RowMiddle/BtnCourage").text = "C: " + str(granny_stats.courage)
	stats.get_node("Margins/Column/RowBottom/LblWins").text = "W: " + str(granny_stats.wins)
	stats.get_node("Margins/Column/RowBottom/LblLosses").text = "L: " + str(granny_stats.losses)

func _set_training(selected: String) -> void:
	currently_training = selected
	stats.get_node("Margins/Column/RowTop/LblTraining").text = "Training: " + selected.capitalize()

func update_training() -> void:
	plus_one.text = "+1"
	if currently_training == "aggression":
		granny_stats.aggression += 1
		for staff in Global.staff:
			if staff.staff_type == "wellness":
				granny_stats.aggression += 1
				plus_one.text = "+2"
	elif currently_training == "strength":
		granny_stats.strength += 1
		for staff in Global.staff:
			if staff.staff_type == "trainer":
				granny_stats.strength += 1
				plus_one.text = "+2"
	elif currently_training == "dexterity":
		granny_stats.dexterity += 1
		for staff in Global.staff:
			if staff.staff_type == "physio":
				granny_stats.strength += 1
				plus_one.text = "+2"
	elif currently_training == "courage":
		granny_stats.courage += 1  
	else:
		return
	_run_plus_one()
	_update_stats_display()

func _run_plus_one() -> void:
	plus_one.position = plus_one_pos
	plus_one.visible = true
	show_plus_one = true

func _physics_process(delta: float) -> void:
	if is_out:
		return
	
	if show_plus_one and plus_one.visible:
		plus_one.position.y -= 20 * delta 
		if plus_one.position.y < -32.0:
			plus_one.visible = false
			show_plus_one = false
	
	# Handle action cooldown timer
	if action_cooldown_timer > 0:
		action_cooldown_timer -= delta
	
	# Handle resting timer
	if is_resting:
		rest_timer -= delta
		if rest_timer <= 0:
			is_resting = false
		else:
			velocity = Vector2.ZERO
			_play_animation("idle" + _direction_suffix(facing_dir))
			move_and_slide()
			return
	
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		_play_animation("stun" + _direction_suffix(facing_dir))
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if opponent == null:
		for staff in Global.staff:
			if staff.staff_type == "doctor":
				granny_stats.health += 1
		_idle_behavior(delta)
		return
	
	_update_facing_dir()
	_update_attack_ray()
	_recover_stamina(delta)
	_decide_behavior(delta)
	move_and_slide()

func _idle_behavior(_delta: float) -> void:
	velocity = Vector2.ZERO
	_play_animation("idle" + _direction_suffix(facing_dir))

func _update_facing_dir() -> void:
	if opponent:
		var dir = (opponent.global_position - global_position)
		if dir.length() > 0:
			facing_dir = dir.normalized()

func _update_attack_ray() -> void:
	var ray_direction = facing_dir.normalized() if facing_dir != Vector2.ZERO else Vector2.DOWN
	attack_ray.target_position = ray_direction * ATTACK_RANGE
	attack_ray.force_raycast_update()

func _recover_stamina(delta: float) -> void:
	# Recover stamina faster when resting
	var recovery_rate = STAMINA_RECOVERY_RATE
	if is_resting:
		recovery_rate *= 3.0  # Triple recovery when actively resting
	
	granny_stats.stamina = clamp(granny_stats.stamina + recovery_rate * delta, 0, MAX_STAMINA)
	print(granny_stats.stamina)
	_update_stamina()

func _decide_behavior(delta: float) -> void:
	if opponent.is_out and !is_out:
		opponent = null
		return
	
	var dist = global_position.distance_to(opponent.global_position)
	
	# Check if granny should run away
	if granny_stats.health < RUNAWAY_HEALTH_THRESHOLD and granny_stats.courage < RUNAWAY_COURAGE_THRESHOLD:
		_run_away_behavior(delta)
		return
	
	# If stamina is 0 HAS to rest - suck it up and die if you must
	if granny_stats.stamina == 0:
		_start_resting()
	
	# Check if granny should rest (only if not in immediate danger)
	if dist > ATTACK_RANGE * 2 and granny_stats.stamina < REST_STAMINA_THRESHOLD and randf() < REST_CHANCE:
		_start_resting()
		return
	
	# If still in action cooldown, just idle
	if action_cooldown_timer > 0:
		velocity = Vector2.ZERO
		_play_animation("idle" + _direction_suffix(facing_dir))
		return
	
	_update_facing_dir()
	
	if dist > ATTACK_RANGE - 4:
		_run_towards_opponent(delta)
		return
	else:
		velocity = Vector2.ZERO
	
	if granny_stats.health < STUN_HEALTH_THRESHOLD and randf() < STUN_CHANCE:
		_stun(1.5)
		return
	
	var action_roll = randf()
	
	if granny_stats.stamina < STAMINA_DODGE_COST:
		if action_roll < 0.7:
			_perform_block()
		else:
			_idle_behavior(delta)
		return
	
	var attack_chance = granny_stats.aggression * 0.01 + granny_stats.courage * 0.005
	if action_roll < attack_chance and granny_stats.stamina >= STAMINA_ATTACK_COST:
		_perform_attack()
	elif action_roll < 0.5 and granny_stats.stamina >= STAMINA_BLOCK_COST:
		_perform_block()
	elif granny_stats.stamina >= STAMINA_DODGE_COST:
		_perform_dodge()
	else:
		_idle_behavior(delta)

func _start_resting() -> void:
	is_resting = true
	rest_timer = REST_DURATION
	last_action = "rest"

func _run_towards_opponent(delta: float) -> void:
	var speed_scale = clamp(float(granny_stats.stamina) / MAX_STAMINA, 0.1, 1.0)
	velocity = facing_dir * RUN_SPEED * speed_scale
	granny_stats.stamina = max(granny_stats.stamina - STAMINA_RUN_DEPLETION * delta, 0)
	_update_stamina()
	_play_animation("run" + _direction_suffix(facing_dir))


func _hit_wall() -> bool:
	if attack_ray.is_colliding():
		var collidor = attack_ray.get_collider()
		if opponent == collidor:
			return false
	return true


func _run_away_behavior(delta: float) -> void:
	# Add randomness to the runaway direction
	var away_dir = (global_position - opponent.global_position).normalized()
	
	# Add random angle offset
	var random_angle = randf_range(-deg_to_rad(RUNAWAY_RANDOMNESS/2), deg_to_rad(RUNAWAY_RANDOMNESS/2))
	away_dir = away_dir.rotated(random_angle)
	if _hit_wall():
		var turn_dir = [-1, 1].pick_random()
		away_dir = away_dir.rotated(turn_dir * PI/2)
	
	velocity = away_dir * RUN_SPEED
	
	granny_stats.stamina = max(granny_stats.stamina - STAMINA_RUN_DEPLETION * delta, 0)
	_update_stamina()
	
	_play_animation("run" + _direction_suffix(away_dir))


func _perform_attack() -> void:
	print("ATTACK PERFORMED!")
	granny_stats.stamina -= STAMINA_ATTACK_COST
	_update_stamina()
	velocity = Vector2.ZERO
	
	# Play attack at half speed
	anim.play("attack" + _direction_suffix(facing_dir), -1, 0.5)
	# Set action cooldown
	action_cooldown_timer = ACTION_COOLDOWN
	last_action = "attack"
	
	if attack_ray.is_colliding():
		var collider = attack_ray.get_collider()
		if collider == opponent:
			opponent.receive_attack(granny_stats.strength, self)


func _perform_block() -> void:
	print("BLOCK PERFORMED!")
	is_action_playing = true
	granny_stats.stamina -= STAMINA_BLOCK_COST
	_update_stamina()
	velocity = Vector2.ZERO
	
	# Play block animation
	anim.play("block" + _direction_suffix(facing_dir))
	
	# Set action cooldown
	action_cooldown_timer = ACTION_COOLDOWN
	last_action = "block"


func _perform_dodge() -> void:
	print("DODGE PERFORMED!")
	is_action_playing = true
	granny_stats.stamina -= STAMINA_DODGE_COST
	_update_stamina()
	velocity = Vector2.ZERO
	
	# Play dodge animation
	anim.play("dodge" + _direction_suffix(facing_dir))
	
	# Set action cooldown
	action_cooldown_timer = ACTION_COOLDOWN
	last_action = "dodge"


func receive_attack(incoming_strength: int, _from_fighter: Node) -> void:
	is_action_playing = true
	print("Received attack! Dexterity: ", granny_stats.dexterity, " Dodge chance: ", granny_stats.dexterity * 0.01)
	if randf() < granny_stats.dexterity * 0.01:
		print("DODGED!")
		_play_animation("dodge" + _direction_suffix(facing_dir))
		# Set cooldown after defensive dodge
		action_cooldown_timer = ACTION_COOLDOWN * 0.8
		return
	
	if anim.current_animation.begins_with("block"):
		print("BLOCKED! Reducing damage")
		var damage = max(1, incoming_strength - int(granny_stats.strength * 0.4))
		granny_stats.health -= damage
		_update_health()
	else:
		print("TOOK FULL DAMAGE")
		granny_stats.health -= incoming_strength
		_update_health()
	
	_play_animation("attack" + _direction_suffix(facing_dir))
	
	# Set cooldown after taking a hit
	action_cooldown_timer = ACTION_COOLDOWN * 0.6
	
	if granny_stats.health <= 0:
		is_out = true
		anim.play("collapse", -1, 0.5)


func _stun(duration: float) -> void:
	is_action_playing = true
	print("STUNNED for ", duration, " seconds!")
	is_stunned = true
	stun_timer = duration
	velocity = Vector2.ZERO


func _play_animation(anim_name: String) -> void:
	if is_action_playing and not (
		anim_name.begins_with("attack") or
		anim_name.begins_with("block") or
		anim_name.begins_with("dodge") or
		anim_name.begins_with("stun")
	):
		return
	var speed := 1
	if anim.current_animation != anim_name or not anim.is_playing():
		anim.play(anim_name, -1, speed)
	if weapon:
		_handle_weapon(anim_name)


func _handle_weapon(anim_name: String) -> void:
	if anim_name.begins_with("attack"):
		weapon_sprite.play(_direction_suffix(facing_dir))
	else:
		weapon_sprite.animation = _direction_suffix(facing_dir)
		weapon_sprite.pause()
		weapon_sprite.frame = 0


func _direction_suffix(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("block") or anim_name.begins_with("dodge") or anim_name.begins_with("stun") or anim_name.begins_with("attack"):
		anim.pause()
		anim.seek(anim.current_animation_length, true)  # Stay on last frame
		is_action_playing = false
		return


func recover(type: String) -> void:
	if type == "rest":
		granny_stats.health += 20
		granny_stats.stamina = MAX_STAMINA
	elif type == "post fight":
		granny_stats.health += 10
		granny_stats.stamina = MAX_STAMINA
	_update_health()


func _on_btn_aggression_pressed() -> void:
	_set_training("aggression")


func _on_btn_strength_pressed() -> void:
	_set_training("strength")


func _on_btn_dexterity_pressed() -> void:
	_set_training("dexterity")


func _on_btn_courage_pressed() -> void:
	_set_training("courage")


func _on_btn_hide_pressed() -> void:
	stats.visible = false


func _on_btn_retire_pressed() -> void:
	get_parent().remove_child(self)
	Global.recruited_grannies.erase(self)
	Global.retired_grannies.append(self)


func _on_btn_weapon_pressed() -> void:
	weapon_list.visible = true
	if "spoon" not in Global.weapons:
		weapon_list.get_node("VBoxContainer/BtnSpoon").disabled = true
	else:
		weapon_list.get_node("VBoxContainer/BtnSpoon").disabled = false
	if "cane" not in Global.weapons:
		weapon_list.get_node("VBoxContainer/BtnCane").disabled = true
	else:
		weapon_list.get_node("VBoxContainer/BtnCane").disabled = false
	if "walker" not in Global.weapons:
		weapon_list.get_node("VBoxContainer/BtnWalker").disabled = true
	else:
		weapon_list.get_node("VBoxContainer/BtnWalker").disabled = false


func _remove_weapon() -> void:
	if weapon_node.get_child_count() > 0:
		var current_weapon = weapon_node.get_child(0)
		if current_weapon:
			weapon_node.remove_child(current_weapon)
			current_weapon.queue_free()


func _clear_old_weapon(weap_name) -> void:
	match weap_name:
		"spoon":
			granny_stats.strength -= 10
		"cane":
			granny_stats.strength -= 15
		"walker":
			granny_stats.strength -= 20
	Global.weapons.append(weap_name)
	_remove_weapon()


func _on_btn_none_pressed() -> void:
	if weapon:
		_clear_old_weapon(weapon)
	weapon = ""
	weapon_list.visible = false


func _on_btn_spoon_pressed() -> void:
	if weapon:
		_clear_old_weapon(weapon)
	Global.weapons.erase("spoon")
	var spoon = load("res://assets/weapons/spoon_sprite.tscn").instantiate()
	add_weapon("spoon", spoon)
	weapon_list.visible = false


func _on_btn_cane_pressed() -> void:
	if weapon:
		_clear_old_weapon(weapon)
	Global.weapons.erase("cane")
	var cane = load("res://assets/weapons/cane_sprite.tscn").instantiate()
	add_weapon("cane", cane)
	weapon_list.visible = false


func _on_btn_walker_pressed() -> void:
	if weapon:
		_clear_old_weapon(weapon)
	Global.weapons.erase("walker")
	var walker = load("res://assets/weapons/walker_sprite.tscn")
	add_weapon("walker", walker)
	weapon_list.visible = false
