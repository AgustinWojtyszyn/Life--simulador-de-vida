extends Node2D

var city_objects: Array[Node2D] = []
var solid_rects: Array[Rect2] = []

func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(88, 70, 624, 16), Rect2(88, 386, 624, 16), Rect2(88, 70, 16, 332), Rect2(696, 70, 16, 332), Rect2(303, 86, 10, 148), Rect2(566, 86, 10, 116)]:
		add_solid(rect)
	furniture("bed", Vector2(190, 245), Vector2(100, 100), Rect2(147, 178, 86, 61))
	furniture("sofa", Vector2(430, 280), Vector2(134, 90), Rect2(380, 254, 100, 20))
	furniture("kitchen", Vector2(478, 166), Vector2(144, 96), Rect2(419, 124, 118, 35))
	add_target(Vector2(260, 245), "Descansar en tu cama", "rest", WorldManager.profile.home_id + "_bed")
	add_target(Vector2(390, 362), "Salir al barrio", "exit_home", WorldManager.profile.home_id + "_exit")
	var camera: Camera2D = $Player/Camera2D
	camera.limit_right = 800
	camera.limit_bottom = 450
	camera.position_smoothing_speed = 12
	var layer := CanvasLayer.new()
	var hud := Control.new()
	hud.set_script(preload("res://scripts/city_hud.gd"))
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	add_child(layer)
	var interactions := Node.new()
	interactions.name = "Interactions"
	interactions.set_script(preload("res://scripts/city_interactions.gd"))
	interactions.hud = hud
	add_child(interactions)

func add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	solid_rects.append(rect)

func furniture(asset: String, at: Vector2, size: Vector2, footprint: Rect2) -> void:
	var node := Node2D.new()
	node.position = at
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/interior/%s.png" % asset)
	sprite.centered = false
	sprite.position = Vector2(-size.x / 2, -size.y)
	sprite.scale = size / sprite.texture.get_size()
	node.add_child(sprite)
	add_child(node)
	city_objects.append(node)
	add_solid(footprint)

func add_target(at: Vector2, title: String, action: String, id: String) -> void:
	var target := Node2D.new()
	target.position = at
	target.set_meta("prompt", title)
	target.set_meta("action", action)
	target.set_meta("id", id)
	target.add_to_group("interactables")
	add_child(target)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 800, 450), Color("15292e"))
	draw_rect(Rect2(88, 70, 624, 332), Color("6c756d"))
	draw_rect(Rect2(104, 86, 592, 300), Color("ab8966"))
	for y in range(86, 386, 16):
		for x in range(104, 696, 40):
			draw_rect(Rect2(x, y, 39, 15), Color("bc9c76") if (x + y) % 3 else Color("b0926d"))
	draw_rect(Rect2(112, 87, 184, 38), WorldManager.country.accent)
	draw_rect(Rect2(313, 87, 250, 22), Color("d1c5a3"))
	draw_rect(Rect2(576, 88, 119, 112), Color("b5c6bf"))
	for x in range(576, 694, 16):
		for y in range(88, 198, 16):
			draw_rect(Rect2(x, y, 15, 15), Color("d2dbcb"))
	# Suggested bathroom fixtures, with a separate walkable doorway below.
	draw_rect(Rect2(649, 108, 28, 40), Color("e1e4d6"))
	draw_circle(Vector2(661, 146), 13, Color("f0eddb"))
	draw_circle(Vector2(661, 146), 7, Color("8eaaa7"))
	draw_rect(Rect2(342, 273, 170, 54), Color("547b78"))
	draw_rect(Rect2(347, 278, 160, 44), Color("709a90"), false, 2)
	draw_rect(Rect2(303, 86, 10, 148), Color("ded1b1"))
	draw_rect(Rect2(566, 86, 10, 116), Color("ded1b1"))
	draw_rect(Rect2(363, 375, 54, 15), Color("598381"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(123, 116), "DORMITORIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("354a48"))
	draw_string(font, Vector2(587, 185), "BAÑO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("354a48"))
	draw_string(font, Vector2(340, 365), "SALIDA AL BARRIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f8e5b9"))
