extends AnimatableBody2D

# Six reusable traffic bodies follow two horizontal lanes. They yield to the
# resident and the car ahead; their collision shapes travel with their sprites.
const ROUTE_LEFT := -140.0
const ROUTE_RIGHT := 2540.0
const ROUTE_LENGTH := ROUTE_RIGHT - ROUTE_LEFT
const BRAKING := 150.0
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

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = false
	add_to_group("city_traffic")
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/city/vehicles/%s.png" % model)
	# Anchor visible wheels, not the padded generation canvas, to the road.
	sprite.region_enabled = true
	sprite.region_rect = sprite.texture.get_image().get_used_rect()
	sprite.position = Vector2(0, -sprite.region_rect.size.y / 2.0)
	sprite.flip_h = direction > 0 or not route_points.is_empty()
	add_child(sprite)
	if model == "van":
		half_width = 43.0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(half_width * 2.0, 20)
	collider.shape = shape
	collider.position.y = -10
	add_child(collider)

func free_distance() -> float:
	var gap := ROUTE_LENGTH
	for other in get_tree().get_nodes_in_group("city_traffic"):
		if other == self or other.direction != direction or not other.route_points.is_empty():
			continue
		var ahead: float = fposmod((other.position.x - position.x) * direction, ROUTE_LENGTH)
		gap = minf(gap, ahead - half_width - other.half_width - 22.0)
	var pedestrians: Array[Node] = get_tree().get_nodes_in_group("city_residents")
	if is_instance_valid(player):
		pedestrians.append(player)
	for pedestrian in pedestrians:
		if not pedestrian.is_visible_in_tree():
			continue
		if absf(pedestrian.position.y - (position.y - 10.0)) < 24.0:
			var ahead: float = (pedestrian.position.x - position.x) * direction
			if ahead >= -half_width - 6.0:
				gap = minf(gap, ahead - half_width - 18.0)
	return maxf(0.0, gap)

func _physics_process(delta: float) -> void:
	if not route_points.is_empty():
		follow_route(delta)
		return
	var gap := free_distance()
	var safe_speed := minf(cruise_speed, sqrt(2.0 * BRAKING * gap))
	current_speed = move_toward(current_speed, safe_speed, (BRAKING if current_speed > safe_speed else 45.0) * delta)
	# Cap each step too, so entering the road suddenly cannot cause a collision.
	position.x += direction * minf(current_speed * delta, gap)
	if gap < 0.01:
		current_speed = 0.0
	if position.x > ROUTE_RIGHT:
		position.x -= ROUTE_LENGTH
	elif position.x < ROUTE_LEFT:
		position.x += ROUTE_LENGTH

func follow_route(delta: float) -> void:
	var goal := route_points[route_index]
	var forward := (goal - position).normalized()
	if forward == Vector2.ZERO:
		route_index = (route_index + 1) % route_points.size()
		return
	var clearance := 500.0
	for other in get_tree().get_nodes_in_group("city_traffic"):
		if other == self or other.route_points.is_empty():
			continue
		var relative: Vector2 = other.position - position
		if relative.dot(forward) > 0 and absf(relative.cross(forward)) < 45:
			clearance = minf(clearance, relative.dot(forward) - half_width - other.half_width - 20)
	for pedestrian in get_tree().get_nodes_in_group("city_residents") + [player]:
		if not is_instance_valid(pedestrian) or not pedestrian.is_visible_in_tree():
			continue
		var relative: Vector2 = pedestrian.position - position
		if relative.dot(forward) > 0 and absf(relative.cross(forward)) < 23:
			clearance = minf(clearance, relative.dot(forward) - half_width - 14)
	clearance = maxf(0, clearance)
	var safe_speed := minf(cruise_speed, sqrt(2.0 * BRAKING * clearance))
	current_speed = move_toward(current_speed, safe_speed, (BRAKING if current_speed > safe_speed else 40.0) * delta)
	position = position.move_toward(goal, minf(current_speed * delta, clearance))
	var desired := forward.angle()
	heading = lerp_angle(heading, desired, minf(1.0, delta * 3.5))
	sprite.rotation = heading
	if position.distance_to(goal) < 2:
		route_index = (route_index + 1) % route_points.size()

func _draw() -> void:
	draw_set_transform(Vector2(1, -6), 0, Vector2(1, 0.24))
	draw_circle(Vector2.ZERO, 37 if model != "van" else 44, Color(0.08, 0.13, 0.18, 0.26))
	draw_set_transform(Vector2.ZERO)
