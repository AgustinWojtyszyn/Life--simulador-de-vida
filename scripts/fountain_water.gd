extends Node2D

var water_time := 0.0
var wish_time := 0.0
var wishes := 0
var water_material: ShaderMaterial

func _ready() -> void:
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://assets/shaders/fountain_water.gdshader")
	get_child(0).material = water_material
	add_to_group("city_fountain")

func _process(delta: float) -> void:
	water_time += delta
	water_material.set_shader_parameter("water_time", water_time)
	if wish_time > 0:
		wish_time = maxf(0, wish_time - delta)
		queue_redraw()

func make_wish() -> void:
	wishes += 1
	wish_time = 2.0
	queue_redraw()

func _draw() -> void:
	if wish_time <= 0:
		return
	var progress := 1.0 - wish_time / 2.0
	draw_set_transform(Vector2(0, -27), 0, Vector2(1, 0.35))
	draw_arc(Vector2.ZERO, 5 + progress * 30, 0, TAU, 24, Color(0.75, 1.0, 0.92, 1.0 - progress), 1.5)
	draw_set_transform(Vector2.ZERO)
	if progress < 0.35:
		var p := Vector2(0, -8).lerp(Vector2(0, -27), progress / 0.35)
		p.y -= sin(progress / 0.35 * PI) * 28
		draw_rect(Rect2(p, Vector2(2, 2)), Color("ffe1a0"))
