class_name TrafficVehicle
extends AnimatableBody2D

var route_left := -140.0
var route_right := 2540.0
const BRAKING := 260.0
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
var model := "compact"
var art_bounds: Array[Rect2] = []
var driver_acceleration := 80.0
var direction := 1.0
var cruise_speed := 190.0
var current_speed := 0.0
var half_width := 35.0
var player: CharacterBody2D
var sprite: Sprite2D
var route_points: Array[Vector2] = []
var route_index := 1
var heading := 0.0
var curve := Curve2D.new()
var progress := 0.0
var directional_art: Array[Texture2D] = []
var collider := CollisionShape2D.new()
var facing_index := -1
var motion_vector := Vector2.ZERO
var body_height := 14.0
var visual_scale := 1.0
var braking := BRAKING
var braking_sound_active := false
var horn_cooldown := 0.0
var blocked_time := 0.0
var proximity_clock := 0.0
var cached_gap := 99999.0
## Lane offset: lateral displacement from route centreline (negative = left, positive = right)
var lane_offset := 0.0

const CATEGORIES := {
	"colectivo": {"speed": 158.0, "acceleration": 36.0, "braking": 155.0, "half_length": 55.0, "turn_radius": 32.0},
	"van": {"speed": 174.0, "acceleration": 58.0, "braking": 220.0, "half_length": 43.0, "turn_radius": 26.0},
	"pickup": {"speed": 188.0, "acceleration": 68.0, "braking": 240.0, "half_length": 38.0, "turn_radius": 24.0},
	"sports_v2": {"speed": 260.0, "acceleration": 140.0, "braking": 340.0, "half_length": 34.0, "turn_radius": 20.0},
	"classic": {"speed": 148.0, "acceleration": 45.0, "braking": 180.0, "half_length": 38.0, "turn_radius": 24.0},
	"truck": {"speed": 140.0, "acceleration": 38.0, "braking": 160.0, "half_length": 48.0, "turn_radius": 30.0},
}

static func profile_for(vehicle_model: String) -> Dictionary:
	return CATEGORIES.get(vehicle_model, {"speed": 198.0, "acceleration": 82.0, "braking": 260.0, "half_length": 35.0})

static func display_width_for(vehicle_model: String) -> float:
	# Visual footprint follows the physical family, not each PNG canvas.
	return float(profile_for(vehicle_model).half_length) * 2.0

static func source_direction(vehicle_model: String, facing: String) -> String:
	# Reviewed corrections for mislabeled legacy source files; never mirror text.
	if vehicle_model == "compact" and facing in ["east", "west"]:
		return "west" if facing == "east" else "east"
	return facing

static func art_family(vehicle_model: String) -> String:
	# sports_v2 contains near-duplicate diagonal front views, not eight angles.
	# The original yellow coupe has a clean, complete directional family.
	# Taxi/classic sources also contain mixed models and duplicate views; use
	# the coherent sedan geometry with their own paint and driving profiles.
	return {"sports_v2": "sports", "classic": "sedan", "taxi": "sedan"}.get(vehicle_model, vehicle_model)

static func apply_paint(target: Sprite2D, vehicle_model: String) -> void:
	if vehicle_model not in ["taxi", "classic"]:
		return
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://assets/shaders/vehicle_paint.gdshader")
	paint.set_shader_parameter("paint", Color("f4c432") if vehicle_model == "taxi" else Color("b86c39"))
	target.material = paint

static func has_directional_art(vehicle_model: String) -> bool:
	for facing in DIRECTIONS:
		if not ResourceLoader.exists("res://assets/vehicles/%s/%s.png" % [art_family(vehicle_model), facing]):
			return false
	return true

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = false
	add_to_group("city_traffic")
	sprite = Sprite2D.new()
	add_child(sprite)
	apply_paint(sprite, model)
	if has_directional_art(model):
		for facing in DIRECTIONS:
			var source := source_direction(model, facing)
			var texture: Texture2D = load("res://assets/vehicles/%s/%s.png" % [art_family(model), source])
			directional_art.append(texture)
			art_bounds.append(texture.get_image().get_used_rect())
	var driving := profile_for(model)
	driver_acceleration = driving.acceleration + float(get_index() % 3) * 3.0
	braking = driving.braking
	half_width = driving.half_length
	cruise_speed = minf(cruise_speed, driving.speed)
	if not art_bounds.is_empty():
		var reference_width := 1.0
		for bounds in art_bounds:
			reference_width = maxf(reference_width, bounds.size.x)
		visual_scale = display_width_for(model) / reference_width
	var shape := RectangleShape2D.new()
	shape.size = Vector2(half_width * 2.0, 20)
	collider.shape = shape
	collider.position.y = -10
	add_child(collider)
	heading = 0.0 if direction > 0 else PI
	if not route_points.is_empty():
		build_curve()
		progress = curve.get_closest_offset(position)
		position = curve.sample_baked(progress)
		heading = tangent(progress).angle()
	update_art()

func build_curve() -> void:
	curve.clear_points()
	curve.bake_interval = 2.0
	# Turn radius based on vehicle profile (colectivo needs wider turns)
	var profile := profile_for(model)
	var base_radius: float = float(profile.get("turn_radius", 28.0))
	# Trim each waypoint into a tangent-continuous cubic corner. Handles never
	# exceed adjacent segment lengths, so even narrow streets stay in bounds.
	for i in route_points.size():
		var corner := route_points[i]
		var incoming := corner - route_points[posmod(i - 1, route_points.size())]
		var outgoing := route_points[(i + 1) % route_points.size()] - corner
		var radius := minf(base_radius, minf(incoming.length(), outgoing.length()) * 0.40)
		var before := corner - incoming.normalized() * radius
		var after := corner + outgoing.normalized() * radius
		curve.add_point(before, Vector2.ZERO, incoming.normalized() * radius * 0.5523)
		curve.add_point(after, -outgoing.normalized() * radius * 0.5523, Vector2.ZERO)
	if curve.point_count > 0:
		curve.add_point(curve.get_point_position(0), Vector2.ZERO, curve.get_point_out(0))

func tangent(at: float) -> Vector2:
	var length := curve.get_baked_length()
	return (curve.sample_baked(fposmod(at + 2.0, length)) - curve.sample_baked(fposmod(at, length))).normalized()

func route_length() -> float:
	return maxf(1.0, route_right - route_left)

func forward_vector() -> Vector2:
	return Vector2(direction, 0) if route_points.is_empty() else tangent(progress)

func free_distance() -> float:
	var gap := route_length()
	var forward := forward_vector()
	# Use central registry instead of global scan
	var pop_system := get_tree().get_nodes_in_group("population_system")
	var traffic: Array[Node] = pop_system[0].get_traffic_registry() if not pop_system.is_empty() else get_tree().get_nodes_in_group("city_traffic")
	for other in traffic:
		if other == self:
			continue
		var relative: Vector2 = other.position - position
		var ahead := relative.dot(forward)
		# When both vehicles have route_points, use direct distance calculation
		# to avoid incorrect fposmod wrapping on curves
		if route_points.is_empty() and other.route_points.is_empty() and other.direction == direction:
			ahead = fposmod(ahead, route_length())
		elif not route_points.is_empty() and not other.route_points.is_empty():
			# Both on curves: ensure ahead is always positive if other is ahead
			# by checking if other is in front along the curve direction
			var to_other: Vector2 = other.position - position
			if to_other.dot(forward) > 0:
				ahead = to_other.length()
			else:
				ahead = -1.0
		# Only consider vehicles in the same lane (narrower cross threshold)
		if ahead > 0 and absf(relative.cross(forward)) < 15.0:
			# Increased minimum gap for better separation and progressive braking
			var speed_factor: float = 1.0 + (current_speed / maxf(cruise_speed, 1.0)) * 0.5
			var min_gap: float = (half_width + other.half_width + 30.0) * speed_factor
			gap = minf(gap, ahead - min_gap)

	var pedestrians: Array[Node] = get_tree().get_nodes_in_group("city_residents")
	if is_instance_valid(player):
		pedestrians.append(player)
	for pedestrian in pedestrians:
		if not pedestrian.is_visible_in_tree():
			continue
		var relative: Vector2 = pedestrian.position - (position - Vector2(0, 10))
		var ahead := relative.dot(forward)
		if ahead >= -half_width - 6.0 and absf(relative.cross(forward)) < 24.0:
			gap = minf(gap, ahead - half_width - 20.0)
	# Signals participate in the same cached proximity pass as cars and
	# pedestrians, so red lights do not add per-frame work.
	var signals: Array[Node] = pop_system[0].get_signal_registry() if not pop_system.is_empty() else get_tree().get_nodes_in_group("traffic_signals")
	for traffic_signal in signals:
		if not traffic_signal.has_method("blocking_distance"):
			continue
		var signal_gap: float = traffic_signal.blocking_distance(position, forward)
		if is_finite(signal_gap):
			gap = minf(gap, signal_gap)
	return maxf(0.0, gap)

func has_honk_target() -> bool:
	var forward := forward_vector()
	for other in get_tree().get_nodes_in_group("city_traffic"):
		if other == self or not is_instance_valid(other):
			continue
		var relative: Vector2 = other.position - position
		var ahead := relative.dot(forward)
		if ahead > 0.0 and ahead < 90.0 and absf(relative.cross(forward)) < 28.0:
			return true
	for pedestrian in get_tree().get_nodes_in_group("city_residents"):
		if not is_instance_valid(pedestrian) or not pedestrian.visible:
			continue
		var relative: Vector2 = pedestrian.position - position
		var ahead := relative.dot(forward)
		if ahead > 0.0 and ahead < 72.0 and absf(relative.cross(forward)) < 25.0:
			return true
	return false

func _physics_process(delta: float) -> void:
	horn_cooldown = maxf(0.0, horn_cooldown - delta)
	# Proximity scans are the expensive part of traffic AI: each vehicle checks
	# every other vehicle and resident. Reuse the result for a few physics ticks,
	# especially when the car is far from the player.
	proximity_clock -= delta
	if proximity_clock <= 0.0:
		cached_gap = free_distance()
		var near_player := is_instance_valid(player) and position.distance_squared_to(player.position) < 900.0 * 900.0
		proximity_clock = 0.05 if near_player else 0.16
	var gap := cached_gap
	if gap < 46.0 and current_speed < 18.0 and has_honk_target():
		blocked_time += delta
		if blocked_time >= 2.0 and horn_cooldown <= 0.0:
			AudioSystem.play_sfx("horn", position)
			horn_cooldown = 6.0 + float(get_index() % 4)
			blocked_time = 0.0
	else:
		blocked_time = maxf(0.0, blocked_time - delta * 2.0)
	var desired := cruise_speed * (0.8 if WeatherSystem.state == "rain" else 1.0)
	if not route_points.is_empty():
		# Brake before the arc instead of rotating the artwork after a hard turn.
		var turn := absf(forward_vector().angle_to(tangent(progress + 48.0)))
		desired *= lerpf(1.0, 0.42, clampf(turn / (PI / 2.0), 0, 1))
	# Progressive braking: account for vehicle speed to avoid sudden stops
	var speed_ratio := current_speed / maxf(cruise_speed, 1.0)
	var effective_braking := braking * (0.7 + 0.6 * speed_ratio)
	var safe_speed := minf(desired, sqrt(2.0 * effective_braking * gap))
	# Smooth approach for close distances: linear deceleration near target
	if gap < 30.0:
		safe_speed = minf(safe_speed, gap * 2.0)
	# Full stop when very close to a stopped vehicle ahead
	if gap < 20.0 and current_speed < 30.0:
		safe_speed = 0.0
	var braking_now := safe_speed < current_speed - 24.0 and current_speed > 55.0
	if braking_now and not braking_sound_active:
		AudioSystem.play_sfx("brake", position)
	braking_sound_active = braking_now
	current_speed = move_toward(current_speed, safe_speed, (effective_braking if current_speed > safe_speed else driver_acceleration) * delta)
	# Waiting at a red light or behind a pedestrian is valid. Never teleport
	# through a queue after a timeout: the same rules apply to every model.
	var step := minf(current_speed * delta, gap)
	cached_gap = maxf(0.0, cached_gap - step)
	var previous := position
	if route_points.is_empty():
		var new_x := route_left + fposmod(position.x + direction * step - route_left, route_length())
		position = Vector2(new_x, position.y)  # lane_offset is baked into y at spawn
	else:
		progress = fposmod(progress + step, curve.get_baked_length())
		position = curve.sample_baked(progress)
	# Use actual displacement through the curve, not its next waypoint or a
	# stale heading. Recycling is excluded from the movement vector.
	motion_vector = Vector2(direction * step, 0) if route_points.is_empty() else position - previous
	if motion_vector.length_squared() > 0.000001:
		heading = motion_vector.angle()
	collider.rotation = heading
	update_art()
	queue_redraw()

func update_art() -> void:
	# Correct facing index calculation for all angles including negative
	# Map heading [-π, π] to index [0, 7] correctly
	var angle_deg := rad_to_deg(heading)
	# Normalize to [0, 360)
	if angle_deg < 0.0:
		angle_deg += 360.0
	# Each direction covers 45 degrees, centered on the cardinal direction
	# East=0°, SE=45°, S=90°, SW=135°, W=180°, NW=225°, N=270°, NE=315°
	var index := posmod(roundi(angle_deg / 45.0), 8)
	if index == facing_index:
		return
	facing_index = index
	# Directional textures stay upright; only the collision footprint follows the road.
	if directional_art.size() != 8:
		push_error("Missing directional vehicle family: " + model)
		set_physics_process(false)
		return
	sprite.texture = directional_art[index]
	sprite.flip_h = model == "suv" and DIRECTIONS[index] == "west"
	sprite.region_enabled = true
	sprite.region_rect = art_bounds[index]
	sprite.scale = Vector2.ONE * visual_scale
	# With region_enabled, Sprite2D centers the REGION, not the source PNG.
	# Half its height puts the visible bottom at the shared ground pivot.
	sprite.offset = Vector2(0, -art_bounds[index].size.y * 0.5)
	sprite.position = Vector2.ZERO

func _draw() -> void:
	# Shadow disabled: the procedural shadow was displaced and made vehicles
	# appear to float. A contact shadow below the car is preferable to a
	# floating one, but the current implementation hurts more than it helps.
	pass
