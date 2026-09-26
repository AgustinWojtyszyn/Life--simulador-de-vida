class_name TrafficVehicle
extends AnimatableBody2D

const ROUTE_LEFT := -140.0
const ROUTE_RIGHT := 2540.0
const ROUTE_LENGTH := ROUTE_RIGHT - ROUTE_LEFT
const BRAKING := 150.0
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
var model := "car"
var direction := 1.0
var cruise_speed := 66.0
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
			directional_art.append(load("res://assets/vehicles/%s/%s.png" % [model, facing]))
	if model == "van":
		half_width = 43.0
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
		var radius := minf(38.0, minf(incoming.length(), outgoing.length()) * 0.28)
		var before := corner - incoming.normalized() * radius
		var after := corner + outgoing.normalized() * radius
		curve.add_point(before, Vector2.ZERO, incoming.normalized() * radius * 0.5523)
		curve.add_point(after, -outgoing.normalized() * radius * 0.5523, Vector2.ZERO)
	if curve.point_count > 0:
		curve.add_point(curve.get_point_position(0), Vector2.ZERO, curve.get_point_out(0))

func tangent(at: float) -> Vector2:
	var length := curve.get_baked_length()
	return (curve.sample_baked(fposmod(at + 2.0, length)) - curve.sample_baked(fposmod(at, length))).normalized()

func forward_vector() -> Vector2:
	return Vector2(direction, 0) if route_points.is_empty() else tangent(progress)

func free_distance() -> float:
	var gap := ROUTE_LENGTH
	var forward := forward_vector()
	for other in get_tree().get_nodes_in_group("city_traffic"):
		if other == self:
			continue
		var relative: Vector2 = other.position - position
		var ahead := relative.dot(forward)
		if route_points.is_empty() and other.route_points.is_empty() and other.direction == direction:
			ahead = fposmod(ahead, ROUTE_LENGTH)
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
	return maxf(0.0, gap)

func _physics_process(delta: float) -> void:
	var gap := free_distance()
	var desired := cruise_speed
	if not route_points.is_empty():
		# Brake before the arc instead of rotating the artwork after a hard turn.
		var turn := absf(forward_vector().angle_to(tangent(progress + 48.0)))
		desired *= lerpf(1.0, 0.42, clampf(turn / (PI / 2.0), 0, 1))
	var safe_speed := minf(desired, sqrt(2.0 * BRAKING * gap))
	current_speed = move_toward(current_speed, safe_speed, (BRAKING if current_speed > safe_speed else 40.0) * delta)
	var step := minf(current_speed * delta, gap)
	if route_points.is_empty():
		position.x = ROUTE_LEFT + fposmod(position.x + direction * step - ROUTE_LEFT, ROUTE_LENGTH)
	else:
		progress = fposmod(progress + step, curve.get_baked_length())
		position = curve.sample_baked(progress)
		heading = tangent(progress).angle()
		collider.rotation = heading
	update_art()

func update_art() -> void:
	var index := posmod(roundi(heading / (PI / 4.0)), 8)
	if index == facing_index:
		return
	facing_index = index
	# Legacy images remain usable on horizontal lanes only. Never rotate a PNG.
	sprite.texture = directional_art[index] if directional_art.size() == 8 else load("res://assets/city/vehicles/%s.png" % model)
	sprite.flip_h = directional_art.is_empty() and direction > 0
	sprite.region_enabled = true
	sprite.region_rect = sprite.texture.get_image().get_used_rect()
	sprite.position = Vector2(0, -sprite.region_rect.size.y / 2.0)

func _draw() -> void:
	draw_set_transform(Vector2(1, -6), 0, Vector2(1, 0.24))
	draw_circle(Vector2.ZERO, half_width, Color(0.08, 0.13, 0.18, 0.26))
	draw_set_transform(Vector2.ZERO)
