extends SceneTree

var failures := 0
var app: Node
var wm: Node
var sim: Node
var mission: Node
var clock: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame

func interact_at(at: Vector2) -> void:
	app.world.get_node("Player").position = at
	await frames(3)
	var interactions: Node = app.world.get_node("Interactions")
	interactions.cooldown = 0
	interactions.interact()
	await frames(3)

func run() -> void:
	wm = root.get_node("WorldManager")
	sim = root.get_node("LifeSimulation")
	mission = root.get_node("MissionSystem")
	clock = root.get_node("GameClock")
	var saves := root.get_node("SaveSystem")
	saves.save_path = "user://vida_iteration_test.json"
	app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	wm.new_game(PlayerProfile.new(), "ar")
	await frames(4)
	check(wm.location == "home", "New life starts in equipped home")
	var p: CharacterBody2D = app.world.get_node("Player")
	p.position = Vector2(350, 320)
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	check(p.position.x > 360, "Player walks inside home")
	await interact_at(Vector2(535, 266))
	check(sim.money == 100, "Computer work earns actual money")
	await interact_at(Vector2(260, 245))
	check(sim.energy > 99, "Sleeping restores energy")
	check(clock.hour() >= 17, "Activities advance world time")
	await interact_at(Vector2(390, 362))
	check(wm.location == "street", "Home door exits")
	await interact_at(wm.district.home_position + Vector2(80, 42))
	var panel: Node = app.world.get_node("LifePanel")
	check(panel.opened, "Mara opens a real choice dialogue")
	mission.choose("accept")
	panel.close()
	wm.travel("cafe")
	await frames(4)
	await interact_at(Vector2(656, 265))
	panel = app.world.get_node("LifePanel")
	check(panel.opened, "Nico is reachable at cafe")
	mission.choose("paid")
	panel.close()
	await interact_at(Vector2(390, 359))
	check(wm.location == "street", "Cafe exit works")
	wm.travel("shop")
	await frames(4)
	await interact_at(Vector2(228, 278))
	check(sim.money == 88 and mission.stage == 3, "Market purchase pays money and advances quest")
	await interact_at(Vector2(390, 359))
	await interact_at(wm.district.home_position + Vector2(80, 42))
	panel = app.world.get_node("LifePanel")
	check(panel.opened, "Return to Mara is playable")
	mission.choose("deliver")
	panel.close()
	check(mission.stage == 4 and sim.money == 106 and sim.reputation == 1, "Paid branch delivers once and pays reward")
	mission.choose("deliver")
	check(sim.money == 106, "Cannot duplicate quest rewards")
	check(wm.save_game(), "Save complete life")
	var saved_time: float = clock.total_minutes
	app.show_menu()
	await frames(3)
	check(wm.continue_game(), "Reload life")
	await frames(3)
	check(mission.stage == 4 and sim.money == 106, "Mission and money survive loading")
	check(absf(clock.total_minutes - saved_time) < 1, "World time survives loading")
	# Verify the other decision with an independent new life.
	wm.new_game(PlayerProfile.new(), "ar")
	mission.choose("accept")
	mission.choose("gift")
	sim.act("buy_food")
	mission.purchased()
	mission.choose("deliver")
	check(sim.money == 68 and sim.reputation == 3, "Gift branch has distinct money/reputation consequence")
	var before: float = clock.total_minutes
	paused = true
	await process_frame
	check(clock.total_minutes == before, "Pausing stops world time")
	paused = false
	app.show_menu()
	await frames(2)
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(saves.save_path + suffix)
	print("LIFE ITERATION: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
