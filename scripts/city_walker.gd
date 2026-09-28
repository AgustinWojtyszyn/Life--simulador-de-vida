extends CharacterBody2D

enum State { WALK, IDLE, SIT, PHONE, DRINK, EAT, SHOP, CHAT, WAIT_CROSSING, ENTER_BUILDING, EXIT_BUILDING, LOOK_AROUND, REST, OPTIONAL_JOG }
var state := State.WALK
var personality := 0

var start := Vector2.ZERO
var finish := Vector2.ZERO
var route: Array[Vector2] = []
var destination := 1
var speed := 65.0
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
var blocked_time := 0.0
var path := PackedVector2Array()
var path_index := 1
var replan_time := 0.0
var navigation: RefCounted
var progress_position := Vector2.ZERO
var progress_time := 0.0
var failed_paths := 0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	# PLAYER=1, NPC=4, WORLD=8. Traffic yields to pedestrians.
	collision_mask = 1 | 4 | 8
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 8)
	collider.shape = shape
	collider.position = Vector2(0, -4)
	add_child(collider)
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
	call_deferred("setup_navigation")

func _physics_process(delta: float) -> void:
	if indoor_time > 0:
		velocity = Vector2.ZERO
		indoor_time = maxf(0, indoor_time - delta)
		visible = indoor_time == 0
		collision_layer = 4 if visible else 0
		if indoor_time == 0:
			activity = "walk"
			state = State.EXIT_BUILDING
		return
	if greeting_time > 0:
		velocity = Vector2.ZERO
		greeting_time = maxf(0, greeting_time - delta)
		visual.set_art("wave", "south", 0)
		queue_redraw()
		return
	if wait_time > 0:
		# STATIONARY STATE: velocity is ZERO and NO movement is applied.
		# No crowd separation, no nudges, no lateral displacement.
		# The NPC must remain completely still while waiting.
		velocity = Vector2.ZERO
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
	# Wait at the curb for crossing
	if route_kind == "crossing" and not crossing and absf(goal.y - position.y) > 80:
		# Use central registry for traffic check
		var pop_system := get_tree().get_nodes_in_group("population_system")
		var traffic: Array[Node] = pop_system[0].get_traffic_registry() if not pop_system.is_empty() else get_tree().get_nodes_in_group("city_traffic")
		for vehicle in traffic:
			if vehicle.position.distance_to(position) < 170 and Geometry2D.get_closest_point_to_segment(vehicle.position, position, goal).distance_to(vehicle.position) < vehicle.half_width + 18:
				velocity = Vector2.ZERO
				state = State.WAIT_CROSSING
				visual.animate_motion(Vector2.ZERO, 0)
				return
		crossing = true
	if navigation == null:
		return
	replan_time = maxf(0.0, replan_time - delta)
	if path.is_empty():
		if replan_time <= 0.0:
			rebuild_path()
		stop_walking()
		return
	while path_index < path.size() and position.distance_to(path[path_index]) < 3.0:
		path_index += 1
	if path_index >= path.size():
		arrive()
		return
	var target := path[path_index]
	var remaining := position.distance_to(target)
	var pace := speed * (1.15 if WeatherSystem.state == "rain" else 1.0)
	var desired := position.direction_to(target) * minf(pace, remaining / maxf(delta, 0.0001))
	# Plan around actual occupied space, including stationary actors. Keep the
	# chosen side until that path is blocked; no alternating separation nudges.
	var obstructed := false
	for actor in nearby_actors():
		var ahead: Vector2 = actor.position - position
		var forward := desired.normalized()
		if ahead.dot(forward) > 0.0 and ahead.dot(forward) < 46.0 and absf(ahead.cross(forward)) < 20.0:
			obstructed = true
			break
	if obstructed and replan_time <= 0.0:
		rebuild_path()
		stop_walking()
		return
	velocity = velocity.move_toward(desired, 280.0 * delta)
	if velocity.length() * delta > remaining:
		velocity = position.direction_to(target) * remaining / delta
	if not navigation.segment_clear(position, position + velocity * delta):
		velocity = desired if navigation.segment_clear(position, position + desired * delta) else Vector2.ZERO
	var before := position
	move_and_slide()
	var movement := position - before
	visual.animate_motion(movement, movement.length())
	progress_time += delta
	if progress_time >= 0.75:
		blocked_time = blocked_time + progress_time if position.distance_to(progress_position) < 4.0 else 0.0
		progress_position = position
		progress_time = 0.0
		if blocked_time >= 0.75:
			path.clear()
			stop_walking()
			if blocked_time >= 4.0:
				destination = (destination + 1) % route.size()
				blocked_time = 0.0

func setup_navigation() -> void:
	if not "pedestrian_navigation" in get_parent():
		return
	navigation = get_parent().pedestrian_navigation
	for i in route.size():
		var point: Vector2 = navigation.nearest(route[i])
		if point.is_finite():
			route[i] = point
	var spawn: Vector2 = navigation.nearest(position)
	if spawn.is_finite():
		# Resolve spawn overlaps once, before the first walking frame. Movement
		# never teleports an actor out of a crowd.
		var occupied: Array[Vector2] = []
		for other in get_tree().get_nodes_in_group("city_residents"):
			if other != self and other.navigation != null and other.visible:
				occupied.append(other.position)
		var chosen := spawn
		var found := false
		for ring in range(5):
			for direction in 8:
				var candidate := spawn + Vector2.RIGHT.rotated(direction * PI / 4.0) * ring * 24.0
				if not navigation.open(navigation.cell(candidate)):
					continue
				if occupied.any(func(at: Vector2): return at.distance_to(candidate) < 24.0):
					continue
				chosen = candidate
				found = true
				break
			if found:
				break
		position = chosen
	progress_position = position

func nearby_actors() -> Array:
	var actors: Array = []
	var systems := get_tree().get_nodes_in_group("population_system")
	var residents: Array = systems[0].get_nearby_npcs(position, 100.0) if not systems.is_empty() else get_tree().get_nodes_in_group("city_residents")
	for other in residents:
		if other != self and is_instance_valid(other) and other.visible and position.distance_to(other.position) < 100.0:
			actors.append(other)
	var player := get_parent().get_node_or_null("Player") as Node2D
	if is_instance_valid(player) and player.visible and position.distance_to(player.position) < 110.0:
		actors.append(player)
	return actors

func rebuild_path() -> void:
	path = navigation.path(position, route[destination], nearby_actors())
	path_index = 1
	replan_time = 0.6 + personality * 0.09
	if path.is_empty():
		failed_paths += 1
		if failed_paths >= 4:
			destination = (destination + 1) % route.size()
			failed_paths = 0
	else:
		failed_paths = 0

func stop_walking() -> void:
	velocity = Vector2.ZERO
	visual.animate_motion(Vector2.ZERO, 0)

func arrive() -> void:
	stop_walking()
	path.clear()
	crossing = false
	blocked_time = 0.0
	visits += 1
	destination = (destination + 1) % route.size()
	choose_activity()
	if route_kind == "shop" and destination == 1 and visits > 1:
		state = State.ENTER_BUILDING
		indoor_time = 12.0 + personality * 4.0
		visible = false
		collision_layer = 0

func choose_activity() -> void:
	# Activities only happen at specific destinations, never randomly while walking
	if route_kind == "football":
		wait_time = 0.4 + personality * 0.15
		return
	# Only assign activities at valid destinations (bench, shop, crossing)
	if route_kind == "bench" and destination == 1:
		activity = "sit"
		state = State.SIT
	elif route_kind == "shop" and destination == 1:
		activity = "browse"
		state = State.SHOP
	elif route_kind == "crossing":
		activity = "wait"
		state = State.WAIT_CROSSING
	else:
		# Walking NPCs just keep walking - no random activities in the middle of the street
		return
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
	# Draw name labels BEHIND the character (lower y-sort) so they don't
	# block the player when walking under them.
	if has_meta("person_name"):
		draw_string(ThemeDB.fallback_font, Vector2(-28, -55), str(get_meta("person_name")), HORIZONTAL_ALIGNMENT_CENTER, 56, 11, Color("fff0c5"))
	if greeting_time > 0:
		draw_rect(Rect2(-24, -48, 52, 17), Color("243c40"))
		draw_string(ThemeDB.fallback_font, Vector2(-19, -36), "¡Buenas!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f5ecd7"))
