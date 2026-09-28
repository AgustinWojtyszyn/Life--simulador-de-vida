class_name CityTrafficSignal
extends Node2D

const GREEN_SECONDS := 7.0
const AMBER_SECONDS := 1.35
const ALL_RED_SECONDS := 0.75
const CYCLE_SECONDS := (GREEN_SECONDS + AMBER_SECONDS + ALL_RED_SECONDS) * 2.0

var horizontal_half := 60.0
var vertical_half := 60.0
var cycle_offset := 0.0
var horizontal_state := "green"
var vertical_state := "red"
var update_clock := 0.0

func _ready() -> void:
	add_to_group("traffic_signals")
	z_index = 14
	# Use one state-driven signal rendering per corner. Previously a decorative
	# sprite and the procedural signal were stacked at the same coordinates.
	refresh_state(true)

func _process(delta: float) -> void:
	update_clock += delta
	if update_clock < 0.12:
		return
	update_clock = 0.0
	refresh_state(false)

func refresh_state(force_redraw: bool) -> void:
	var phase := fposmod(Time.get_ticks_msec() / 1000.0 + cycle_offset, CYCLE_SECONDS)
	var next_h := "red"
	var next_v := "red"
	var cursor := 0.0
	if phase < cursor + GREEN_SECONDS:
		next_h = "green"
	elif phase < cursor + GREEN_SECONDS + AMBER_SECONDS:
		next_h = "amber"
	cursor += GREEN_SECONDS + AMBER_SECONDS + ALL_RED_SECONDS
	if phase >= cursor and phase < cursor + GREEN_SECONDS:
		next_v = "green"
	elif phase >= cursor + GREEN_SECONDS and phase < cursor + GREEN_SECONDS + AMBER_SECONDS:
		next_v = "amber"
	if force_redraw or next_h != horizontal_state or next_v != vertical_state:
		horizontal_state = next_h
		vertical_state = next_v
		queue_redraw()

func state_for(forward: Vector2) -> String:
	return horizontal_state if absf(forward.x) >= absf(forward.y) else vertical_state

func blocking_distance(vehicle_position: Vector2, forward: Vector2, speed: float = 0.0, braking: float = 260.0) -> float:
	if forward.length_squared() < 0.01:
		return INF
	var horizontal := absf(forward.x) >= absf(forward.y)
	var state := horizontal_state if horizontal else vertical_state
	if state == "green":
		return INF
	var stop_point := vehicle_position
	if horizontal:
		if absf(vehicle_position.y - global_position.y) > horizontal_half + 38.0:
			return INF
		stop_point.x = global_position.x - vertical_half - 24.0 if forward.x > 0.0 else global_position.x + vertical_half + 24.0
	else:
		if absf(vehicle_position.x - global_position.x) > vertical_half + 38.0:
			return INF
		stop_point.y = global_position.y - horizontal_half - 24.0 if forward.y > 0.0 else global_position.y + horizontal_half + 24.0
	var ahead := (stop_point - vehicle_position).dot(forward.normalized())
	if ahead < -8.0 or ahead > 260.0:
		return INF
	# Decision logic: if the vehicle can stop before the intersection, it must.
	# If it's too close to stop safely, it should clear the junction.
	if state == "amber":
		if ahead - 14.0 < speed * speed / (2.0 * maxf(braking, 1.0)) + 5.0:
			return INF
	return maxf(0.0, ahead - 14.0)

# One short-lived claim per crossing; no global traffic manager.
var occupant: WeakRef
var entered := false
var claim_position := Vector2.ZERO
var claim_frame := 0

func junction() -> Rect2:
	return Rect2(global_position - Vector2(vertical_half, horizontal_half), Vector2(vertical_half, horizontal_half) * 2)

func owner() -> Node2D:
	var car = occupant.get_ref() if occupant != null else null
	if not is_instance_valid(car) or not car.is_inside_tree() or not car.is_in_group("city_traffic"):
		occupant = null
		return null
	var inside := junction().grow(car.half_width + 8).has_point(car.global_position)
	entered = entered or junction().has_point(car.global_position)
	# Recycle/teleport and an exited rear bumper invalidate a claim immediately.
	if (not entered and not junction().grow(car.half_width + 120).has_point(car.global_position)) or (entered and not inside) or car.global_position.distance_to(claim_position) > 700 or (not entered and Engine.get_physics_frames() - claim_frame > 180):
		occupant = null
		return null
	return car

func clearance_distance(car: Node2D, traffic: Array) -> float:
	var holder := owner()
	if holder == car: return INF # Legal entrant clears even after phase changes.
	var forward: Vector2 = car.forward_vector()
	var relative: Vector2 = global_position - car.global_position
	var horizontal := absf(forward.x) >= absf(forward.y)
	var lateral := horizontal_half if horizontal else vertical_half
	if absf(relative.cross(forward)) > lateral + 12: return INF
	var half_extent := vertical_half if horizontal else horizontal_half
	var ahead := relative.dot(forward)
	if ahead < -half_extent - car.half_width or ahead > 420: return INF
	var stop := maxf(0, ahead - half_extent - car.half_width - 12)
	if holder != null: return stop
	if junction().has_point(car.global_position):
		# Recover an unclaimed entrant (e.g. world spawn) deterministically.
		# Physical obstacle checks still run in the vehicle; this never grants ghosting.
		for other in traffic:
			if is_instance_valid(other) and other != car and junction().has_point(other.global_position) and other.get_instance_id() < car.get_instance_id(): return 0
		occupant = weakref(car)
		entered = true
		claim_position = car.global_position
		claim_frame = Engine.get_physics_frames()
		return INF
	var state := state_for(forward)
	var can_enter: bool = state == "green" or (state == "amber" and stop < car.current_speed * car.current_speed / (2 * maxf(car.braking, 1)) + 5)
	if not can_enter: return stop
	if stop > 100: return INF
	# Trace the actual route through a turn to its exit, not just the entry axis.
	var exit_point: Vector2 = car.global_position
	var exit_forward := forward
	var found_exit := false
	var touched := false
	for distance in range(0, 700, 12):
		exit_point = car.global_position + forward * distance if car.route_points.is_empty() else car.curve.sample_baked(fposmod(car.progress + distance, car.curve.get_baked_length()))
		touched = touched or junction().has_point(exit_point)
		if touched and not junction().grow(car.half_width + 20).has_point(exit_point):
			exit_forward = forward if car.route_points.is_empty() else car.tangent(car.progress + distance)
			found_exit = true
			break
	if not found_exit: return INF # This route does not cross this junction.
	for other in traffic:
		if not is_instance_valid(other) or other == car: continue
		var delta: Vector2 = other.global_position - exit_point
		if junction().grow(8).has_point(other.global_position) or (absf(delta.cross(exit_forward)) < 28 and absf(delta.dot(exit_forward)) < car.half_width + other.half_width + 30):
			return stop
	# Reserve only near the stop line. Atomic physics order breaks ties.
	if stop <= 100:
		occupant = weakref(car)
		entered = junction().has_point(car.global_position)
		claim_position = car.global_position
		claim_frame = Engine.get_physics_frames()
	return INF

func signal_positions() -> Array[Vector2]:
	var margin := 28.0
	# Only 2 signals per intersection: one for each direction
	# This reduces visual clutter while maintaining functionality
	return [
		Vector2(-vertical_half - margin, -horizontal_half - margin),
		Vector2(vertical_half + margin, horizontal_half + margin),
	]

func _draw() -> void:
	var positions := signal_positions()
	draw_head(positions[0], horizontal_state)
	draw_head(positions[1], vertical_state)

func draw_head(at: Vector2, state: String) -> void:
	# Larger, more visible signal head
	draw_line(at + Vector2(0, 10), at + Vector2(0, 36), Color("36454a"), 4.0)
	draw_rect(Rect2(at - Vector2(9, 18), Vector2(18, 34)), Color("172428"))
	var red := Color("e05a52") if state == "red" else Color(0.28, 0.20, 0.19)
	var amber := Color("e6b95e") if state == "amber" else Color(0.28, 0.24, 0.17)
	var green := Color("68b878") if state == "green" else Color(0.18, 0.28, 0.20)
	draw_circle(at + Vector2(0, -12), 4.5, red)
	draw_circle(at + Vector2(0, -2), 4.5, amber)
	draw_circle(at + Vector2(0, 8), 4.5, green)
