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
var proximity_clock := 0.0
var cached_gap := 99999.0

const CATEGORIES := {
	"colectivo": {"speed": 158.0, "acceleration": 36.0, "braking": 155.0, "half_length": 55.0},
	"van": {"speed": 174.0, "acceleration": 58.0, "braking": 220.0, "half_length": 43.0},
	"pickup": {"speed": 188.0, "acceleration": 68.0, "braking": 240.0, "half_length": 38.0},
}

static func profile_for(vehicle_model: String) -> Dictionary:
	return CATEGORIES.get(vehicle_model, {"speed": 198.0, "acceleration": 82.0, "braking": 260.0, "half_length": 35.0})

static func source_direction(vehicle_model: String, facing: String) -> String:
	# Reviewed corrections for mislabeled legacy source files; never mirror text.
	if vehicle_model == "compact" and facing in ["east", "west"]:
		return "west" if facing == "east" else "east"
	if vehicle_model == "taxi" and facing in ["south-east", "south-west", "north-east", "north-west"]:
		return facing.replace("east", "TEMP").replace("west", "east").replace("TEMP", "west")
	return facing

static func has_directional_art(vehicle_model: String) -> bool:
	for facing in DIRECTIONS:
		if not ResourceLoader.exists("res://assets/vehicles/%s/%s.png" % [vehicle_model, facing]):
			return false
	return true

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = false
	add_to_group("city_traffic")
	sprite = Sprite2D.new()
	add_child(sprite)
	if has_directional_art(model):
		for facing in DIRECTIONS:
			var source := source_direction(model, facing)
			var texture: Texture2D = load("res://assets/vehicles/%s/%s.png" % [model, source])
			directional_art.append(texture)
			art_bounds.append(texture.get_image().get_used_rect())
	var driving := profile_for(model)
	driver_acceleration = driving.acceleration + float(get_index() % 3) * 3.0
	braking = driving.braking
	half_width = driving.half_length
	cruise_speed = minf(cruise_speed, driving.speed)
	if model == "colectivo" and not art_bounds.is_empty():
		visual_scale = 120.0 / art_bounds[0].size.x
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
	# Trim each waypoint into a tangent-continuous cubic corner. Handles never
	# exceed adjacent segment lengths, so even narrow streets stay in bounds.
	for i in route_points.size():
		var corner := route_points[i]
		var incoming := corner - route_points[posmod(i - 1, route_points.size())]
		var outgoing := route_points[(i + 1) % route_points.size()] - corner
		var radius := minf(52.0, minf(incoming.length(), outgoing.length()) * 0.28)
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
	for other in get_tree().get_nodes_in_group("city_traffic"):
		if other == self:
			continue
		var relative: Vector2 = other.position - position
		var ahead := relative.dot(forward)
		if route_points.is_empty() and other.route_points.is_empty() and other.direction == direction:
			ahead = fposmod(ahead, route_length())
		if ahead > 0 and absf(relative.cross(forward)) < 27.0:
			gap = minf(gap, ahead - half_width - other.half_width - 22.0)
	var pedestrians: Array[Node] = get_tree().get_nodes_in_group("city_residents")
	if is_instance_valid(player):
		pedestrians.append(player)
	for pedestrian in pedestrians:
		if not pedestrian.is_visible_in_tree():
			continue
		var relative: Vector2 = pedestrian.position - (position - Vector2(0, 10))
		var ahead := relative.dot(forward)
		if ahead >= -half_width - 6.0 and absf(relative.cross(forward)) < 24.0:
			gap = minf(gap, ahead - half_width - 18.0)
	# Signals participate in the same cached proximity pass as cars and
	# pedestrians, so red lights do not add per-frame work.
	for traffic_signal in get_tree().get_nodes_in_group("traffic_signals"):
		if not traffic_signal.has_method("blocking_distance"):
			continue
		var signal_gap: float = traffic_signal.blocking_distance(position, forward)
		if is_finite(signal_gap):
			gap = minf(gap, signal_gap)
	return maxf(0.0, gap)

func _physics_process(delta: float) -> void:
	# Proximity scans are the expensive part of traffic AI: each vehicle checks
	# every other vehicle and resident. Reuse the result for a few physics ticks,
	# especially when the car is far from the player.
	proximity_clock -= delta
	if proximity_clock <= 0.0:
		cached_gap = free_distance()
		var near_player := is_instance_valid(player) and position.distance_squared_to(player.position) < 900.0 * 900.0
		proximity_clock = 0.05 if near_player else 0.16
	var gap := cached_gap
	var desired := cruise_speed * (0.8 if WeatherSystem.state == "rain" else 1.0)
	if not route_points.is_empty():
		# Brake before the arc instead of rotating the artwork after a hard turn.
		var turn := absf(forward_vector().angle_to(tangent(progress + 48.0)))
		desired *= lerpf(1.0, 0.42, clampf(turn / (PI / 2.0), 0, 1))
	var safe_speed := minf(desired, sqrt(2.0 * braking * gap))
	var braking_now := safe_speed < current_speed - 24.0 and current_speed > 55.0
	if braking_now and not braking_sound_active:
		AudioSystem.play_sfx("brake", position)
	braking_sound_active = braking_now
	# Do not spawn periodic per-car engine clips. A cluster of nearby vehicles
	# used to create a machine-gun-like audio pattern and unnecessary audio nodes.
	current_speed = move_toward(current_speed, safe_speed, (braking if current_speed > safe_speed else driver_acceleration) * delta)
	var step := minf(current_speed * delta, gap)
	var previous := position
	if route_points.is_empty():
		position.x = route_left + fposmod(position.x + direction * step - route_left, route_length())
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
	var index := posmod(roundi(heading / (PI / 4.0)), 8)
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
	# One projected ground-centre for every view: turning does not shift the
	# vehicle by half a sprite's changing height.
	sprite.position = Vector2(0, -body_height)

func _draw() -> void:
	var forward := forward_vector()
	draw_set_transform(Vector2(1, -6), 0, Vector2(lerpf(0.42, 1.0, absf(forward.x)), lerpf(0.66, 0.24, absf(forward.x))))
	draw_circle(Vector2.ZERO, half_width, Color(0.08, 0.13, 0.18, 0.26))
	draw_set_transform(Vector2.ZERO)
