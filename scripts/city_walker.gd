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

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 5 # world (1) + other residents (4)
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

func _physics_process(delta: float) -> void:
	if indoor_time > 0:
		indoor_time = maxf(0, indoor_time - delta)
		visible = indoor_time == 0
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
		velocity = Vector2.ZERO
		apply_crowd_separation(delta)
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
				velocity = Vector2.ZERO
				state = State.WAIT_CROSSING
				visual.animate_motion(Vector2.ZERO, 0)
				return
		crossing = true
	# Check for oncoming walkers and yield deterministically
	for other in get_tree().get_nodes_in_group("city_residents"):
		if other == self or not is_instance_valid(other) or not other.visible:
			continue
		if is_facing_oncoming(other) and should_yield_to(other):
			# Yield: stop briefly and let the other pass
			velocity = Vector2.ZERO
			visual.animate_motion(Vector2.ZERO, 0)
			wait_time = maxf(wait_time, 0.4)
			return
	var remaining := position.distance_to(goal)
	var pace := speed * (1.15 if WeatherSystem.state == "rain" else 1.0)
	var desired_speed := minf(pace, sqrt(2.0 * 180.0 * remaining))
	var desired := position.direction_to(goal) * desired_speed
	var separation := crowd_separation()
	if separation.length_squared() > 0.001:
		desired += separation * minf(48.0, desired_speed * 0.75)
		desired = desired.limit_length(desired_speed)
	velocity = velocity.move_toward(desired, (150.0 + personality * 14.0) * delta)
	var intended := velocity * delta
	if intended.length() > remaining:
		velocity = position.direction_to(goal) * remaining / maxf(delta, 0.0001)
		intended = goal - position
	var candidate := position + intended
	var parent := get_parent()
	if parent.has_method("walker_position_clear") and not bool(parent.call("walker_position_clear", candidate)):
		# Blocked: wait briefly, then try to recalculate
		velocity = Vector2.ZERO
		crossing = false
		blocked_time += delta
		wait_time = maxf(wait_time, 0.3)
		visual.animate_motion(Vector2.ZERO, 0)
		# If blocked for too long, skip to next destination
		if blocked_time > 1.5:
			destination = (destination + 1) % route.size()
			blocked_time = 0.0
			wait_time = 0.35
		return
	blocked_time = maxf(0.0, blocked_time - delta * 2.0)
	var before := position
	move_and_slide()
	var movement := position - before
	visual.animate_motion(movement, movement.length())
	if position.distance_to(goal) < 1:
		velocity = Vector2.ZERO
		crossing = false
		visits += 1
		destination = (destination + 1) % route.size()
		choose_activity()
		if route_kind == "shop" and destination == 1 and visits > 1:
			state = State.ENTER_BUILDING
			indoor_time = 12.0 + personality * 4.0
			visible = false

func crowd_separation() -> Vector2:
	var push := Vector2.ZERO
	const PERSONAL_SPACE := 24.0
	for other in get_tree().get_nodes_in_group("city_residents"):
		if other == self or not is_instance_valid(other) or not other.visible:
			continue
		var away: Vector2 = position - other.position
		var distance_sq := away.length_squared()
		if distance_sq >= PERSONAL_SPACE * PERSONAL_SPACE:
			continue
		if distance_sq < 0.01:
			var side := -1.0 if get_instance_id() < other.get_instance_id() else 1.0
			away = Vector2(side, 0.35)
		var distance := maxf(1.0, away.length())
		# Deterministic priority: lower instance_id yields to higher one.
		# This prevents two NPCs from endlessly trying to dodge each other.
		var priority_factor := 1.0 if get_instance_id() > other.get_instance_id() else 0.3
		push += away / distance * (1.0 - distance / PERSONAL_SPACE) * priority_factor
	return push

func is_facing_oncoming(other: Node2D) -> bool:
	# Check if another walker is approaching head-on
	if not is_instance_valid(other) or not other.visible:
		return false
	var to_other: Vector2 = other.position - position
	if to_other.length_squared() > 90.0 * 90.0:
		return false
	# Both must be moving toward each other
	var my_dir: Vector2 = velocity.normalized() if velocity.length_squared() > 0.01 else Vector2.ZERO
	var other_dir: Vector2 = (other.velocity as Vector2).normalized() if other.velocity.length_squared() > 0.01 else Vector2.ZERO
	if my_dir == Vector2.ZERO or other_dir == Vector2.ZERO:
		return false
	return my_dir.dot(other_dir) < -0.5

func should_yield_to(other: Node2D) -> bool:
	# Deterministic priority: lower instance_id yields
	return get_instance_id() < other.get_instance_id()

func apply_crowd_separation(delta: float) -> void:
	var push := crowd_separation()
	if push.length_squared() < 0.001:
		return
	var nudge := push.normalized() * minf(20.0, push.length() * 28.0)
	var candidate := position + nudge * delta
	var parent := get_parent()
	if not parent.has_method("walker_position_clear") or bool(parent.call("walker_position_clear", candidate)):
		var previous_velocity := velocity
		velocity = nudge
		move_and_slide()
		velocity = previous_velocity

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
