extends Control

signal granny_recruited(granny: CharacterBody2D)
signal granny_skirmish
signal granny_selected(granny)
signal skip_skirmish
signal final_granny_selected(granny)
signal change_time_speed(time_speed: String)
signal buy_item(item: String)
signal hire_staff(staff)

@onready var countdown = $PanelTop/TopMenu/LblCountdown
@onready var granny_count = $PanelTop/TopMenu/HBoxGranCount/LblGrannyCount
@onready var gold_count = $PanelTop/TopMenu/LblMoney
@onready var menu_panel = $PanelMenu
@onready var granny_panel = $PanelGranny
@onready var granny_list = $PanelGranny/Margins/ScrollGranny/GrannyList
@onready var shop_panel = $PanelShop
@onready var money_panel = $PanelTop/TopMenu/LblMoney/PanelCosts
@onready var skirmish_popup = $PanelSkirmish
@onready var select_panel = $PanelSelectGranny
@onready var warning_panel = $PanelWarning	

var selected_granny
var final: bool = false

func _ready() -> void:
	granny_panel.visible = false
	shop_panel.visible = false
	skirmish_popup.visible = false
	menu_panel.visible = false
	money_panel.visible = false
	select_panel.visible = false
	warning_panel.visible = false


func show_warning():
	warning_panel.visible = true
	await get_tree().create_timer(2.0).timeout
	warning_panel.visible = false


func set_granny(granny) -> void:
	selected_granny = granny


func display_skirmish_select() -> void:
	selected_granny = null
	select_panel.visible = true
	var list = select_panel.get_node("VBoxContainer/ScrollContainer/GrannyList")
	if list.get_children():
		for child in list.get_children():
			child.queue_free()
	for gran in Global.recruited_grannies:
		var btn_granny = Button.new()
		btn_granny.flat = true
		btn_granny.text = gran.granny_stats.name
		btn_granny.pressed.connect(set_granny.bind(gran))
		list.add_child(btn_granny)


func _on_btn_confirm_pressed() -> void:
	if not selected_granny:
		return
	selected_granny.get_parent().remove_child(selected_granny)
	if final:
		final_granny_selected.emit(selected_granny)
	else:
		granny_selected.emit(selected_granny)
	select_panel.visible = false


func display_final_select() -> void:
	final = true
	select_panel.get_node("VBoxContainer/LblSelect").text = "Select your champion for the final fight"
	var skip_button = select_panel.get_node("BtnSkip")
	select_panel.remove_child(skip_button)
	display_skirmish_select()


func update_week_display(weeks_remaining: String) -> void:
	countdown.text = weeks_remaining


func update_granny_display(num_grans: String) -> void:
	granny_count.text = "x " + num_grans


func update_gold_display(gold: String) -> void:
	gold_count.text = "G: " + gold


func update_shop_display() -> void:
	pass


func _on_btn_grannies_pressed() -> void:
	granny_panel.visible = false if granny_panel.visible else true
	if granny_panel.visible:
		_create_granny_list()


func _on_btn_shop_pressed() -> void:
	shop_panel.visible = false if shop_panel.visible else true


func _create_granny_list() -> void:
	for granny in Global.all_grannies:
		if granny.get_parent():
			granny.get_parent().remove_child(granny)
	for gran in granny_list.get_children():
		gran.queue_free()
	var num_grannies
	Global.all_grannies.shuffle()
	if Global.all_grannies.size() < 5:
		num_grannies = Global.all_grannies.size()
	else:
		num_grannies = 5
	while num_grannies > 0:
		var gran = Global.all_grannies[num_grannies - 1]
		_create_granny_item(gran)
		num_grannies -= 1


func _create_granny_item(granny) -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxGranny"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox_top = BoxContainer.new()
	hbox_top.name = "HBoxTop"
	var subviewport_container = SubViewportContainer.new()
	subviewport_container.custom_minimum_size = Vector2(32, 32)
	var subviewport = SubViewport.new()
	subviewport.size = Vector2(32, 32)
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.add_child(granny)
	granny.position = Vector2(16, 16)
	granny.facing_dir = Vector2.RIGHT
	subviewport_container.add_child(subviewport)
	hbox_top.add_child(subviewport_container)
	var btn_recruit = Button.new()
	btn_recruit.name = "BtnRecruit"
	btn_recruit.text = "Recruit"
	btn_recruit.add_theme_font_size_override("font_size", 12)
	btn_recruit.pressed.connect(_recruit_granny.bind(granny))
	if Global.recruited_grannies.size() >= Global.MAX_GRANNIES:
		btn_recruit.disabled = true
	hbox_top.add_child(btn_recruit)
	var vbox_bottom = VBoxContainer.new()
	vbox_bottom.name = "VBoxGranStats"
	vbox_bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl_name = Label.new()
	lbl_name.name = "LblName"
	lbl_name.text = granny.granny_stats.name
	lbl_name.add_theme_font_size_override("font_size", 20)
	vbox_bottom.add_child(lbl_name)
	var hbox_stats = HBoxContainer.new()
	hbox_stats.name = "HBoxStats"
	hbox_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	var lbl_wins = Label.new()
	lbl_wins.name = "LblWins"
	lbl_wins.add_theme_font_size_override("font_size", 16)
	lbl_wins.text = "W: " + str(granny.granny_stats.wins)
	var lbl_losses = Label.new()
	lbl_losses.name = "LblLosses"
	lbl_losses.add_theme_font_size_override("font_size", 16)
	lbl_losses.text = "L: " + str(granny.granny_stats.losses)
	var lbl_fame = Label.new()
	lbl_fame.name = "LblFame"
	lbl_fame.add_theme_font_size_override("font_size", 16)
	lbl_fame.text = granny.granny_stats.fame_string
	hbox_stats.add_child(lbl_fame)
	hbox_stats.add_child(lbl_wins)
	hbox_stats.add_child(lbl_losses)
	vbox_bottom.add_child(hbox_stats)
	vbox.add_child(hbox_top)
	vbox.add_child(vbox_bottom)
	granny_list.add_child(vbox)


func _recruit_granny(granny) -> void:
	if granny.get_parent():
		granny.get_parent().remove_child(granny)
	granny_panel.visible = false
	Global.all_grannies.erase(granny)
	emit_signal("granny_recruited", granny)


func _on_btn_test_skirmish_pressed() -> void:
	emit_signal("granny_skirmish")


func _on_btn_menu_pressed() -> void:
	menu_panel.visible = true


func _on_btn_save_game_pressed() -> void:
	SaveManager.save_game(SaveManager.get_next_available_slot())


func _on_btn_quit_pressed() -> void:
	get_tree().quit()


func _on_btn_close_pressed() -> void:
	menu_panel.visible = false


func _on_btn_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")


func _on_lbl_money_mouse_entered() -> void:
	money_panel.get_node("Margins/Column/LblGrannyCosts").text = "Granny Costs: 50G x " + str(Global.recruited_grannies.size()) 
	money_panel.get_node("Margins/Column/LblStaffCosts").text = "Staff Costs: 50G x " + str(Global.staff.size())
	money_panel.visible = true


func _on_lbl_money_mouse_exited() -> void:
	money_panel.visible = false


func _on_btn_norm_speed_pressed() -> void:
	change_time_speed.emit("normal")


func _on_btn_med_speed_pressed() -> void:
	change_time_speed.emit("medium")


func _on_btn_fast_speed_pressed() -> void:
	change_time_speed.emit("fast")


func _on_btn_skip_pressed() -> void:
	select_panel.visible = false
	emit_signal("skip_skirmish")


func _on_btn_buy_spoon_pressed() -> void:
	if Global.gold >= 20:
		buy_item.emit("spoon")
	else:
		show_warning()


func _on_btn_buy_cane_pressed() -> void:
	if Global.gold >= 50:
		buy_item.emit("cane")
	else:
		show_warning()


func _on_btn_buy_walker_pressed() -> void:
	if Global.gold >= 100:
		buy_item.emit("walker")
	else:
		show_warning()


func _on_btn_hire_doctor_pressed() -> void:
	if Global.gold >= 200:
		var doctor = shop_panel.get_node("ScrollShop/MarginContainer/ShopList/DoctorContainer/RowTopStaff/SubViewportContainer/SubViewport/staff")
		doctor.get_parent().remove_child(doctor)
		hire_staff.emit(doctor)
		shop_panel.get_node("ScrollShop/MarginContainer/ShopList/DoctorContainer").queue_free()
	else:
		show_warning()


func _on_btn_hire_trainer_pressed() -> void:
	if Global.gold >= 250:
		var trainer = shop_panel.get_node("ScrollShop/MarginContainer/ShopList/TrainerContainer/RowTopStaff/SubViewportContainer/SubViewport/staff")
		trainer.get_parent().remove_child(trainer)
		hire_staff.emit(trainer)
		shop_panel.get_node("ScrollShop/MarginContainer/ShopList/TrainerContainer").queue_free()
	else:
		show_warning()


func _on_btn_hire_physio_pressed() -> void:
	if Global.gold >= 300:
		var physio = shop_panel.get_node("ScrollShop/MarginContainer/ShopList/PhysioContainer/RowTopStaff/SubViewportContainer/SubViewport/staff")
		physio.get_parent().remove_child(physio)
		hire_staff.emit(physio)
		shop_panel.get_node("ScrollShop/MarginContainer/ShopList/PhysioContainer").queue_free()
	else:
		show_warning()


func _on_btn_hire_wellness_pressed() -> void:
	if Global.gold >= 400:
		var wellness = shop_panel.get_node("ScrollShop/MarginContainer/ShopList/WellnessContainer/RowTopStaff/SubViewportContainer/SubViewport/staff")
		wellness.get_parent().remove_child(wellness)
		hire_staff.emit(wellness)
		shop_panel.get_node("ScrollShop/MarginContainer/ShopList/WellnessContainer").queue_free()
	else:
		show_warning()
