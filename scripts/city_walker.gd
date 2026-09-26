extends Node2D

# Ambient pedestrians follow short, clear sidewalk segments, never the roadway.
var greeting_time := 0.0
var start := Vector2.ZERO
var finish := Vector2.ZERO
var speed := 18.0
var progress := 0.0
var forward := true
var sprite: Sprite2D
var east := preload("res://assets/characters/resident/east.png")
var west := preload("res://assets/characters/resident/west.png")

func _ready() -> void:
	add_to_group("city_residents")
	sprite = Sprite2D.new()
	sprite.texture = east
	sprite.position.y = -14
	add_child(sprite)

func _process(delta: float) -> void:
	if greeting_time > 0:
		greeting_time = maxf(0, greeting_time - delta)
		sprite.texture = preload("res://assets/characters/resident/wave.png")
		queue_redraw()
		return
	progress = move_toward(progress, 1.0 if forward else 0.0, speed * delta / start.distance_to(finish))
	position = start.lerp(finish, progress)
	if progress == 1.0 or progress == 0.0:
		forward = not forward
	sprite.texture = east if forward else west
	sprite.position.y = -14 + roundf(sin(progress * start.distance_to(finish) * 0.5) * 0.6)

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 8, Color(0.1, 0.16, 0.2, 0.22))
	draw_set_transform(Vector2.ZERO)
	if greeting_time > 0:
		draw_style_box(bubble(), Rect2(-22, -47, 49, 17))
		draw_string(ThemeDB.fallback_font, Vector2(-17, -35), "¡Buenas!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f5ecd7"))

func bubble() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("243c40")
	box.set_corner_radius_all(3)
	return box

func greet() -> void:
	greeting_time = 2.5
	queue_redraw()
