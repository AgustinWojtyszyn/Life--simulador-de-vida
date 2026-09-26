extends Node2D

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

func _ready() -> void:
	add_to_group("city_residents")
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
		return
	if greeting_time > 0:
		greeting_time = maxf(0, greeting_time - delta)
		visual.set_art("wave", "south", 0)
		queue_redraw()
		return
	if wait_time > 0:
		wait_time = maxf(0, wait_time - delta)
		visual.set_art("seated" if route_kind == "bench" and destination == 1 else "idle", "south", 0)
		return
	var goal := route[destination]
	# Wait at the curb, then finish the crossing; cars also yield to residents.
	if route_kind == "crossing" and not crossing and absf(goal.y - position.y) > 80:
		for vehicle in get_tree().get_nodes_in_group("city_traffic"):
			if absf(vehicle.position.x - position.x) < 170:
				visual.animate_motion(Vector2.ZERO, 0)
				return
		crossing = true
	var step := position.move_toward(goal, speed * delta)
	var movement := step - position
	position = step
	visual.animate_motion(movement, movement.length())
	if position.distance_to(goal) < 1:
		crossing = false
		visits += 1
		destination = (destination + 1) % route.size()
		wait_time = 1.0 + (visits % 3)
		if route_kind == "shop" and destination == 1 and visits > 1:
			indoor_time = 4.0
			visible = false

func greet() -> void:
	greeting_time = 2.5
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 7, Color(0.1, 0.16, 0.2, 0.22))
	draw_set_transform(Vector2.ZERO)
	if greeting_time > 0:
		draw_rect(Rect2(-24, -48, 52, 17), Color("243c40"))
		draw_string(ThemeDB.fallback_font, Vector2(-19, -36), "¡Buenas!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f5ecd7"))
