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
var progress_distance := INF
var progress_goal := Vector2.INF
var detour: Array[Vector2] = []
var detour_side := 1.0
var side_memory := 0.0
var nearby_residents: Array = []
var nearby_traffic: Array = []
var neighbor_clock := 0.0

func refresh_neighbors(delta: float) -> void:
	neighbor_clock -= delta
	if neighbor_clock > 0: return
	neighbor_clock = .2
	var parent := get_parent()
	nearby_residents = parent.nearby_agents("city_residents", global_position, 180) if parent.has_method("nearby_agents") else get_tree().get_nodes_in_group("city_residents")
	nearby_traffic = parent.nearby_agents("city_traffic", global_position, 240) if parent.has_method("nearby_agents") else get_tree().get_nodes_in_group("city_traffic")

func walkable(at: Vector2) -> bool:
	var parent := get_parent()
	if parent.has_method("walker_position_clear") and not parent.walker_position_clear(at): return false
	if route_kind != "crossing" and parent.has_method("roads"):
		for road in parent.roads():
			if road.grow(8).has_point(at): return false
	return true

func agents_clear(at: Vector2) -> bool:
	for other in nearby_residents:
		if not is_instance_valid(other) or other == self or not other.visible: continue
		var clearance := Rect2(other.position - Vector2(12.2, 8.2), Vector2(24.4, 16.4))
		if clearance.has_point(at):
			# Physics safe margins can leave us just inside this conservative
			# planning envelope. Permit escape, never deeper penetration.
			if clearance.has_point(position) and at.distance_squared_to(other.position) > position.distance_squared_to(other.position): continue
			return false
	return true

func segment_agents_clear(from: Vector2, to: Vector2) -> bool:
	var count := maxi(1, ceili(from.distance_to(to) / 4))
	for i in range(1, count + 1):
		if not agents_clear(from.lerp(to, float(i) / count)): return false
	return true

func segment_clear(from: Vector2, to: Vector2) -> bool:
	# Endpoint/sample checks can miss a thin corner, then steering keeps pushing
	# into it. Reject the entire segment against inflated solid rectangles.
	var parent := get_parent()
	if parent.has_method("walker_position_clear"):
		var swept := Rect2(from, Vector2.ZERO).expand(to).grow(.01)
		for solid in parent.solid_rects:
			var rect: Rect2 = solid.grow(8)
			if not swept.intersects(rect): continue
			var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
			for i in 4:
				if Geometry2D.segment_intersects_segment(from, to, corners[i], corners[(i + 1) % 4]) != null: return false
	var count := maxi(1, ceili(from.distance_to(to) / 6))
	for i in range(1, count + 1):
		if not walkable(from.lerp(to, float(i) / count)): return false
	return true

func recover_route(goal: Vector2) -> void:
	var forward := position.direction_to(goal)
	var side := Vector2(-forward.y, forward.x)
	var best: Array[Vector2] = []
	var score := INF
	var selected_side := detour_side
	for sign_value in ([detour_side, -detour_side] if walkable(goal) else []):
		for width in [32.0, 64.0, 96.0, 144.0]:
			var lateral: Vector2 = position + side * width * sign_value
			var onward: Vector2 = lateral + forward * minf(112, position.distance_to(goal))
			if not segment_clear(position, lateral) or not segment_clear(lateral, onward) or not segment_agents_clear(position, lateral) or not segment_agents_clear(lateral, onward): continue
			var occupied := false
			for other in nearby_residents:
				if is_instance_valid(other) and other != self and other.visible and (other.position.distance_to(lateral) < 20 or other.position.distance_to(onward) < 20): occupied = true
			if occupied: continue
			var cost: float = onward.distance_to(goal) + width * .25
			if side_memory > 0 and sign_value != detour_side: cost += 160
			if cost < score and onward.distance_to(goal) < position.distance_to(goal) + 16:
				score = cost
				best.assign([lateral, onward])
				selected_side = sign_value
	if not best.is_empty():
		detour = best
		detour_side = selected_side
		side_memory = 4
	else:
		# Only select reachable, validated waypoints; never jump position.
		var nearest := INF
		for i in route.size():
			var distance := position.distance_to(route[i])
			if distance > 12 and distance < nearest and segment_clear(position, route[i]):
				nearest = distance
				destination = i
		detour.clear()
	blocked_time = 0
	progress_distance = INF
	velocity = Vector2.ZERO

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	# Only collide with world (1) and other residents (4), NOT player (2).
	# This prevents the player from pushing NPCs around.
	collision_mask = 5
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
	refresh_neighbors(delta)
	side_memory = maxf(0, side_memory - delta)
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
	var goal := route[destination] if detour.is_empty() else detour[0]
	if goal != progress_goal:
		progress_goal = goal
		progress_distance = position.distance_to(goal)
		blocked_time = 0
	var distance_now := position.distance_to(goal)
	if distance_now < progress_distance - 4:
		progress_distance = distance_now
		blocked_time = 0
	else:
		blocked_time += delta
	if blocked_time >= 1.4:
		recover_route(route[destination])
		goal = route[destination] if detour.is_empty() else detour[0]
	# Wait at the curb, then finish the crossing; cars also yield to residents.
	if route_kind == "crossing" and not crossing and absf(goal.y - position.y) > 80:
		for vehicle in nearby_traffic:
			if not is_instance_valid(vehicle): continue
			if absf(vehicle.position.x - position.x) < 170 and absf(vehicle.position.y - position.y) < 120 and (vehicle.current_speed > 4 or (absf(vehicle.position.x - position.x) < vehicle.half_width + 12 and absf(vehicle.position.y - position.y) < 24)):
				velocity = Vector2.ZERO
				state = State.WAIT_CROSSING
				visual.animate_motion(Vector2.ZERO, 0)
				return
		crossing = true
	var remaining := position.distance_to(goal)
	var pace := speed * (1.15 if WeatherSystem.state == "rain" else 1.0)
	var desired_speed := minf(pace, sqrt(2.0 * 180.0 * remaining))
	var desired := position.direction_to(goal) * desired_speed
	var separation := crowd_separation()
	if separation.length_squared() > 0.001:
		desired += separation * minf(48.0, desired_speed * 0.75)
	desired = desired.limit_length(desired_speed * 1.2)
	velocity = velocity.move_toward(desired, (150.0 + personality * 14.0) * delta)
	var intended := velocity * delta
	if intended.length() > remaining:
		velocity = position.direction_to(goal) * remaining / maxf(delta, 0.0001)
		intended = goal - position
	var candidate := position + intended
	if not segment_clear(position, candidate) or not agents_clear(candidate):
		velocity = Vector2.ZERO
		visual.animate_motion(Vector2.ZERO, 0)
		return
	var before := position
	move_and_slide()
	var movement := position - before
	visual.animate_motion(movement, movement.length())
	if position.distance_to(goal) < 3:
		if not detour.is_empty():
			detour.pop_front()
			return
		velocity = Vector2.ZERO
		crossing = false
		visits += 1
		for offset in range(1, route.size() + 1):
			var next := (destination + offset) % route.size()
			if walkable(route[next]):
				destination = next
				break
		choose_activity()
		if route_kind == "shop" and destination == 1 and visits > 1:
			state = State.ENTER_BUILDING
			indoor_time = 12.0 + personality * 4.0
			visible = false

func crowd_separation() -> Vector2:
	var push := Vector2.ZERO
	const PERSONAL_SPACE := 24.0
	for other in nearby_residents:
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
		var priority_factor := 1.0 if should_yield_to(other) else 0.3
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
	# Draw name labels BEHIND the character (lower y-sort) so they don't
	# block the player when walking under them.
	if has_meta("person_name"):
		draw_string(ThemeDB.fallback_font, Vector2(-28, -55), str(get_meta("person_name")), HORIZONTAL_ALIGNMENT_CENTER, 56, 11, Color("fff0c5"))
	if greeting_time > 0:
		draw_rect(Rect2(-24, -48, 52, 17), Color("243c40"))
		draw_string(ThemeDB.fallback_font, Vector2(-19, -36), "¡Buenas!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f5ecd7"))
