extends Node2D

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")

var city_objects: Array[Node2D] = []
var solid_rects: Array[Rect2] = []

func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(88, 70, 624, 16), Rect2(88, 386, 624, 16), Rect2(88, 70, 16, 332), Rect2(696, 70, 16, 332), Rect2(303, 86, 10, 148), Rect2(566, 86, 10, 116)]:
		add_solid(rect)
	# Furniture now alternates authored diagonal views instead of every object
	# leaning from the same upper-right to lower-left axis.
	furniture("bed_front", Vector2(190, 245), Vector2(100, 100), Rect2(147, 178, 86, 61), "south")
	furniture("sofa_front", Vector2(430, 275), Vector2(134, 80), Rect2(380, 253, 100, 22), "south")
	furniture("kitchen", Vector2(478, 166), Vector2(160, 100), Rect2(419, 124, 118, 35), "south-west")
	furniture("wardrobe", Vector2(267, 171), Vector2(56, 82), Rect2(243, 148, 48, 18), "south-east")
	furniture("shelf", Vector2(141, 153), Vector2(50, 68), Rect2(119, 137, 44, 14), "south-west")
	furniture("tv_back", Vector2(430, 331), Vector2(83, 56), Rect2(395, 315, 70, 16), "north")
	furniture("desk", Vector2(537, 248), Vector2(64, 68), Rect2(511, 228, 50, 14), "south-east")
	furniture("dining", Vector2(600, 331), Vector2(74, 59), Rect2(572, 306, 56, 19), "south-west")
	furniture("bathroom", Vector2(636, 185), Vector2(106, 89), Rect2(589, 110, 92, 42), "south-east")
	add_target(Vector2(635, 219), "Ducharte", "shower", "shower")
	add_target(Vector2(417, 202), "Cocinar", "cook", "stove")
	add_target(Vector2(260, 245), "Descansar en tu cama", "rest", WorldManager.profile.home_id + "_bed")
	add_target(Vector2(430, 295), "Mirar televisión", "tv", "tv")
	add_target(Vector2(535, 266), "Usar la computadora", "pc", "pc")
	add_target(Vector2(478, 207), "Abrir la heladera", "fridge", "fridge")
	add_target(Vector2(590, 350), "Comer en la mesa", "eat", "table")
	add_target(Vector2(440, 305), "Descansar en el sofá", "rest", "sofa")
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

# Collision layers: PLAYER=1, TRAFFIC=2, NPC=4, WORLD=8
const LAYER_WORLD := 8

func add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	solid_rects.append(rect)

func furniture(asset: String, at: Vector2, size: Vector2, footprint: Rect2, facing := "south-east") -> void:
	var node := Node2D.new()
	node.position = at
	node.set_meta("orientation", facing)
	node.set_meta("interior_asset", asset)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/interior/%s.png" % asset)
	sprite.region_enabled = true
	sprite.region_rect = sprite.texture.get_image().get_used_rect()
	sprite.position = Vector2(0, -size.y / 2)
	sprite.scale = size / sprite.region_rect.size
	# Interior props contain no signage, so a horizontal authored mirror is a
	# safe second isometric view. We never rotate the sprite upside-down.
	sprite.flip_h = facing in ["south-west", "west", "north-west"]
	node.add_child(sprite)
	add_child(node)
	city_objects.append(node)
	add_solid(footprint)

func add_target(at: Vector2, title: String, action: String, id: String) -> void:
	var target := InteractionTargetScript.new()
	target.position = at
	target.label = title
	target.action = action
	target.target_id = id
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
	draw_rect(Rect2(342, 273, 170, 54), Color("547b78"))
	draw_rect(Rect2(347, 278, 160, 44), Color("709a90"), false, 2)
	# Smaller material changes and wall details keep the home from reading as
	# one repeated diagonal asset sheet.
	draw_rect(Rect2(124, 128, 146, 5), Color("d9c7a6"))
	draw_rect(Rect2(330, 126, 204, 5), Color("d9c7a6"))
	draw_rect(Rect2(603, 100, 66, 8), Color("7fa0a1"))
	draw_circle(Vector2(380, 180), 12, Color(0.95, 0.82, 0.55, 0.18))
	draw_circle(Vector2(514, 317), 11, Color(0.95, 0.82, 0.55, 0.14))
	draw_rect(Rect2(303, 86, 10, 148), Color("ded1b1"))
	draw_rect(Rect2(566, 86, 10, 116), Color("ded1b1"))
	draw_rect(Rect2(363, 375, 54, 15), Color("598381"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(123, 116), "DORMITORIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("354a48"))
	draw_string(font, Vector2(587, 185), "BAÑO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("354a48"))
	draw_string(font, Vector2(340, 365), "SALIDA AL BARRIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f8e5b9"))
