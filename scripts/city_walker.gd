extends Node2D

enum State { WALK, IDLE, SIT, PHONE, DRINK, EAT, SHOP, CHAT, WAIT_CROSSING, ENTER_BUILDING, EXIT_BUILDING, LOOK_AROUND, REST, OPTIONAL_JOG }
var state := State.WALK
var personality := 0

var start := Vector2.ZERO
var finish := Vector2.ZERO
var route: Array[Vector2] = []
var destination := 1
var speed := 25.0
var greeting_time := 0.0
var wait_time := 0.0
var indoor_time := 0.0
var visits := 0
var crossing := false
var profile: PlayerProfile
var visual: CharacterVisual
var sprite: Sprite2D
var route_kind := "walk"
var activity := "walk"
var activity_time := 0.0

func _ready() -> void:
	add_to_group("city_residents")
	personality = get_index() % 5
	wait_time = float(personality) * 0.73
	if route.is_empty():
		route.assign([start, finish, finish + Vector2(0, 14), start + Vector2(0, 14)])
	if profile == null:
		profile = PlayerProfile.new()
	visual = CharacterVisual.new()
	visual.profile = profile
	add_child(visual)
	sprite = visual.sprite

func _process(delta: float) -> void:
	if indoor_time > 0:
		indoor_time = maxf(0, indoor_time - delta)
		visible = indoor_time == 0
		if indoor_time == 0:
			activity = "walk"
			state = State.EXIT_BUILDING
		return
	if greeting_time > 0:
		greeting_time = maxf(0, greeting_time - delta)
		visual.set_art("wave", "south", 0)
		queue_redraw()
		return
	if wait_time > 0:
		wait_time = maxf(0, wait_time - delta)
		activity_time += delta
		if activity in ["phone", "drink", "eat", "look", "chat", "browse"]:
			visual.animate_activity(activity, delta)
		else:
			visual.set_art("seated" if activity == "sit" else "wave" if activity == "chat" else "idle", "south", 0)
		if wait_time == 0:
			queue_redraw()
		return
	activity = "walk"
	state = State.WALK
	var goal := route[destination]
	# Wait at the curb, then finish the crossing; cars also yield to residents.
	if route_kind == "crossing" and not crossing and absf(goal.y - position.y) > 80:
		for vehicle in get_tree().get_nodes_in_group("city_traffic"):
			if absf(vehicle.position.x - position.x) < 170:
				state = State.WAIT_CROSSING
				visual.animate_motion(Vector2.ZERO, 0)
				return
		crossing = true
	var step := position.move_toward(goal, speed * (1.3 if WeatherSystem.state == "rain" else 1.0) * delta)
	var movement := step - position
	position = step
	visual.animate_motion(movement, movement.length())
	if position.distance_to(goal) < 1:
		crossing = false
		visits += 1
		destination = (destination + 1) % route.size()
		choose_activity()
		if route_kind == "shop" and destination == 1 and visits > 1:
			state = State.ENTER_BUILDING
			indoor_time = 12.0 + personality * 4.0
			visible = false

func choose_activity() -> void:
	if route_kind == "football":
		wait_time = 0.4 + personality * 0.15
		return
	var options := ["phone", "drink", "look", "rest", "chat", "eat"]
	activity = "sit" if route_kind == "bench" and destination == 1 else "browse" if route_kind == "shop" and destination == 1 else "wait" if route_kind == "crossing" else options[(visits + profile.skin + profile.top) % options.size()]
	state = {"sit": State.SIT, "phone": State.PHONE, "drink": State.DRINK, "eat": State.EAT, "look": State.LOOK_AROUND, "rest": State.REST, "chat": State.CHAT, "browse": State.SHOP, "wait": State.WAIT_CROSSING}.get(activity, State.IDLE)
	wait_time = 3.0 + float((visits + personality) % 6)
	if WeatherSystem.state == "rain": wait_time *= 0.4
	activity_time = 0.0
	queue_redraw()

func greet() -> void:
	greeting_time = 2.5
	activity = "chat"
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 7, Color(0.1, 0.16, 0.2, 0.22))
	draw_set_transform(Vector2.ZERO)
	if greeting_time > 0:
		draw_rect(Rect2(-24, -48, 52, 17), Color("243c40"))
		draw_string(ThemeDB.fallback_font, Vector2(-19, -36), "¡Buenas!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f5ecd7"))
	if has_meta("person_name"):
		draw_string(ThemeDB.fallback_font, Vector2(-28, -55), str(get_meta("person_name")), HORIZONTAL_ALIGNMENT_CENTER, 56, 11, Color("fff0c5"))
