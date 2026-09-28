extends SceneTree

var failures := 0
var manager: Node
var saves: Node
var inputs: Node
var app: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func press_e() -> void:
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	await frames(3)

func run() -> void:
	manager = root.get_node("WorldManager")
	saves = root.get_node("SaveSystem")
	inputs = root.get_node("InputManager")
	saves.save_path = "user://vida_phase1_test.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(saves.save_path + suffix)
	app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	await frames(2)
	check(is_instance_valid(app.menu), "Main menu must appear before gameplay")
	app.menu.create_screen()
	await frames(2)
	app.menu.name_edit.text = ""
	click("Comenzar mi vida")
	check(not app.menu.error_label.text.is_empty(), "Creator must reject an empty name")
	app.menu.name_edit.text = "Alex"
	var options: Array[Node] = app.menu.find_children("*", "OptionButton", true, false)
	var chosen := [1, 2, 1, 1, 2, 1]
	for i in options.size():
		options[i].select(chosen[i])
		options[i].item_selected.emit(chosen[i])
	check(app.menu.preview.sprite.texture.resource_path.contains("female"), "Creator must preview selected gender")
	check(not app.menu.has_method("country_screen"), "New life has no country selector")
	var selected: PlayerProfile = app.menu.draft
	for id in ["ar", "us", "jp", "it", "br"]:
		if id == "ar":
			click("Comenzar mi vida")
		else:
			manager.new_game(PlayerProfile.from_dict(selected.to_dict()), id)
		await frames(3)
		check(manager.location == "home", "New game must start at home: " + id)
		check(app.world.name == "Home", "Home interior must load: " + id)
		var player: CharacterBody2D = app.world.get_node("Player")
		check(player.position == HomeSystem.INTERIOR_SPAWN, "Own home spawn must be stable")
		check(player.visual.profile.gender == "female", "Selected appearance must reach gameplay")
		await press_e()
		check(manager.location == "street", "E must exit through the home door: " + id)
		player = app.world.get_node("Player")
		check(player.position.distance_to(manager.district.home_position + Vector2(0, 34)) < 1, "Street spawn must be outside the correct home")
		for rect in app.world.solid_rects:
			check(not rect.grow(6).has_point(player.position), "Home exit must not intersect a solid")
		var residents := get_nodes_in_group("city_residents")
		var women := 0
		var men := 0
		for npc in residents:
			if npc.profile.gender == "female": women += 1
			else: men += 1
		check(women >= 6 and men >= 6, "District population must contain varied men and women")
		check(get_nodes_in_group("city_traffic").size() >= 6, "District must have traffic")
		check(app.world.city_objects.size() > 70, "District must contain a populated expansion")
		await press_e()
		check(manager.location == "home", "E must re-enter the same home: " + id)
		player = app.world.get_node("Player")
		player.position = Vector2(350, 320)
		Input.action_press("move_right")
		await frames(15)
		check(player.position.x > 365, "PC movement must work")
		check(player.visual.pose == "walk", "Actual displacement must select walk animation")
		Input.action_release("move_right")
		await frames(8)
		check(player.velocity.is_zero_approx() and player.visual.pose == "idle", "Stopping must return to idle without drifting")
		player.position = Vector2(260, 245)
		await frames(2)
		await press_e()
		check(manager.basic_state.rested, "Bed must have a persistent basic interaction")
		check(manager.save_game(), "Save must succeed")
		var saved_position := player.position
		app.show_menu()
		await frames(2)
		check(manager.continue_game(), "Continue must reload a complete save")
		await frames(3)
		check(manager.profile.player_name == "Alex" and manager.profile.gender == "female", "Save must preserve name and gender")
		check(manager.profile.country_id == id and manager.profile.home_id == id + "_home", "Save must preserve country and home identity")
		check(manager.profile.skin == 2 and manager.profile.top == 2 and manager.profile.hair == 1, "Save must preserve customization")
		check(manager.basic_state.rested, "Rested state must survive loading")
		check(app.world.get_node("Player").position == saved_position, "Save must preserve position")
		print("COUNTRY SMOKE: ", id, " PASS")
	# Multitouch: stick and action use different indices and can operate together.
	inputs.touch_enabled = true
	var touch := Control.new()
	touch.set_script(load("res://scripts/ui/touch_controls.gd"))
	app.overlay.add_child(touch)
	await frames(2)
	touch.context_available = true
	var stick := InputEventScreenTouch.new()
	stick.index = 0
	stick.pressed = true
	stick.position = touch.stick_center + Vector2(touch.radius * .85, 0)
	touch._input(stick)
	var action := InputEventScreenTouch.new()
	action.index = 1
	action.pressed = true
	action.position = touch.action_center
	touch._input(action)
	check(inputs.movement().x > 0.6 and inputs.touch_interaction, "Multitouch stick and action must coexist")
	check(touch.stick_finger == 0 and touch.action_finger == 1, "Touch ownership must remain independent")
	stick.pressed = false
	touch._input(stick)
	check(inputs.touch_vector == Vector2.ZERO, "Releasing the joystick must stop movement")
	inputs.reset()
	touch.queue_free()
	inputs.touch_enabled = false
	# Atomic backup recovery and schema rejection, without touching user saves.
	check(manager.save_game(), "Second save must create a complete backup")
	var file := FileAccess.open(saves.save_path, FileAccess.WRITE)
	file.store_string("broken json")
	file.close()
	check(not saves.read_save().is_empty(), "Corrupt current save must recover its backup")
	check(not saves.valid({"version": 999}), "Unsupported schemas must be rejected")
	app.show_menu()
	await frames(2)
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(saves.save_path + suffix)
	print("PHASE 1 TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

func click(text: String) -> void:
	for button in app.menu.find_children("*", "Button", true, false):
		if button.text == text:
			button.pressed.emit()
			return
	check(false, "Missing UI button: " + text)
