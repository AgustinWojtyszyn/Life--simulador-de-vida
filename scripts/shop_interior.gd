extends Node2D

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")
const Regional := preload("res://scripts/data/regional_assets.gd")

var interior_kind := "shop"

func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	interior_kind = WorldManager.location
	$Player/Camera2D.limit_right = 800
	$Player/Camera2D.limit_bottom = 450
	for wall in [
		Rect2(86, 64, 628, 16), Rect2(86, 388, 628, 16),
		Rect2(86, 64, 16, 340), Rect2(698, 64, 16, 340),
	]:
		add_solid(wall)

	add_target(Vector2(390, 359), "Salir al barrio", "exit_interior", "exit")

	match interior_kind:
		"cafe":
			setup_cafe_like()
		"bakery":
			setup_bakery()
		"restaurant", "pizzeria", "trattoria":
			setup_restaurant()
		"clinic":
			setup_clinic()
		"office":
			setup_office()
		"workshop":
			setup_workshop()
		_:
			setup_market_like()

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

func setup_cafe_like() -> void:
	furniture("cafe_bar", Vector2(560, 220), Vector2(160, 102), Rect2(495, 170, 132, 43), "south-west")
	for entry in [
		[Vector2(184, 206), "south-east"],
		[Vector2(343, 206), "south-west"],
		[Vector2(182, 327), "south-west"],
		[Vector2(343, 327), "south-east"],
	]:
		var at: Vector2 = entry[0]
		furniture("cafe_table", at, Vector2(90, 80), Rect2(at - Vector2(32, 31), Vector2(64, 25)), entry[1])
	add_target(Vector2(550, 250), "Pedir algo", "coffee", "counter")
	add_resident("nico", "Nico", Vector2(656, 255), true)
	add_resident("customer", "Cliente", Vector2(292, 293), false)

func setup_bakery() -> void:
	furniture("cafe_bar", Vector2(574, 205), Vector2(176, 105), Rect2(505, 160, 138, 40), "south-west")
	furniture("market_shelf", Vector2(184, 212), Vector2(76, 110), Rect2(152, 182, 64, 24), "south-east")
	furniture("market_shelf", Vector2(302, 212), Vector2(76, 110), Rect2(270, 182, 64, 24), "south-west")
	furniture("checkout", Vector2(566, 300), Vector2(126, 88), Rect2(511, 266, 110, 26), "south-east")
	add_target(Vector2(540, 328), "Comprar pan y provisiones · $12", "buy_food", "bakery_counter")
	add_resident("baker", "Panadero", Vector2(620, 162), true)
	add_resident("customer", "Cliente", Vector2(350, 305), false)

func setup_restaurant() -> void:
	for entry in [
		[Vector2(190, 220), "south-east"],
		[Vector2(345, 220), "south-west"],
		[Vector2(230, 330), "south-west"],
		[Vector2(405, 330), "south-east"],
	]:
		var at: Vector2 = entry[0]
		furniture("dining", at, Vector2(88, 70), Rect2(at - Vector2(33, 26), Vector2(66, 22)), entry[1])
	furniture("checkout", Vector2(590, 215), Vector2(132, 92), Rect2(533, 178, 114, 28), "south-west")
	add_target(Vector2(560, 248), "Pedir comida", "buy_food", "restaurant_counter")
	add_resident("host", "Encargado", Vector2(625, 176), true)
	add_resident("customer", "Cliente", Vector2(430, 300), false)

func setup_market_like() -> void:
	for entry in [
		[Vector2(176, 245), "south-east"],
		[Vector2(318, 245), "south-west"],
		[Vector2(458, 245), "south-east"],
	]:
		var at: Vector2 = entry[0]
		furniture("market_shelf", at, Vector2(76, 110), Rect2(at - Vector2(32, 30), Vector2(64, 24)), entry[1])
	furniture("market_fridge", Vector2(645, 164), Vector2(76, 82), Rect2(620, 141, 50, 18), "south-west")
	furniture("checkout", Vector2(566, 228), Vector2(130, 91), Rect2(505, 180, 122, 32), "south-east")
	add_target(Vector2(228, 278), "Comprar provisiones · $12", "buy_food", "shelf")
	add_resident("clerk", shopkeeper_name(), Vector2(567, 146), true)
	add_resident("customer", "Cliente", Vector2(292, 293), false)

func setup_clinic() -> void:
	furniture("desk", Vector2(575, 205), Vector2(90, 92), Rect2(535, 171, 78, 24), "south-west")
	furniture("sofa", Vector2(228, 265), Vector2(142, 94), Rect2(174, 238, 108, 23), "south-east")
	furniture("sofa", Vector2(376, 265), Vector2(142, 94), Rect2(322, 238, 108, 23), "south-west")
	furniture("shelf", Vector2(650, 156), Vector2(62, 82), Rect2(624, 137, 52, 18), "south-east")
	add_target(Vector2(545, 238), "Hablar en recepción", "shop", "clinic_desk")
	add_resident("reception", "Recepción", Vector2(605, 172), true)
	add_resident("patient", "Paciente", Vector2(305, 310), false)

func setup_office() -> void:
	furniture("desk", Vector2(235, 220), Vector2(86, 92), Rect2(198, 185, 74, 24), "south-east")
	furniture("desk", Vector2(430, 220), Vector2(86, 92), Rect2(393, 185, 74, 24), "south-west")
	furniture("desk", Vector2(590, 287), Vector2(86, 92), Rect2(553, 252, 74, 24), "south-east")
	furniture("shelf", Vector2(654, 154), Vector2(62, 82), Rect2(628, 135, 52, 18), "south-west")
	furniture("sofa", Vector2(260, 340), Vector2(138, 90), Rect2(208, 315, 104, 22), "south-west")
	add_target(Vector2(420, 250), "Usar una computadora", "pc", "office_pc")
	add_resident("coworker", "Compañero", Vector2(510, 300), true)

func setup_workshop() -> void:
	furniture("shelf", Vector2(170, 180), Vector2(72, 92), Rect2(140, 154, 60, 22), "south-east")
	furniture("shelf", Vector2(270, 180), Vector2(72, 92), Rect2(240, 154, 60, 22), "south-west")
	furniture("desk", Vector2(565, 235), Vector2(104, 96), Rect2(520, 199, 90, 26), "south-east")
	furniture("checkout", Vector2(420, 320), Vector2(126, 88), Rect2(365, 286, 110, 26), "south-west")
	add_target(Vector2(530, 265), "Consultar el taller", "shop", "workshop_counter")
	add_resident("mechanic", "Encargado", Vector2(610, 205), true)

func shopkeeper_name() -> String:
	return {
		"ar": "Almacenero",
		"br": "Atendente",
		"jp": "Encargado",
		"it": "Negoziante",
		"us": "Clerk",
	}.get(WorldManager.country.id, "Encargado")

func add_target(at: Vector2, title: String, action: String, id: String) -> void:
	var point := InteractionTargetScript.new()
	point.position = at
	point.label = title
	point.action = action
	point.target_id = id
	point.detail = interior_title()
	add_child(point)

func add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _draw() -> void:
	var accent: Color = WorldManager.country.accent
	draw_rect(Rect2(0, 0, 800, 450), Color("172d31"))
	draw_rect(Rect2(86, 64, 628, 340), Color("d5c3a5"))
	draw_rect(Rect2(102, 80, 596, 308), Color("8d7762"))
	for y in range(80, 388, 24):
		for x in range(102, 698, 36):
			draw_rect(Rect2(x + (12 if y % 48 else 0), y, 35, 23).intersection(Rect2(102, 80, 596, 308)), Color("9b856b") if x % 3 else Color("a48d73"))
	draw_rect(Rect2(109, 82, 582, 29), accent)
	draw_string(ThemeDB.fallback_font, Vector2(230, 103), interior_title().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 340, 17, Color("293b3c"))
	draw_rect(Rect2(365, 381, 50, 12), Color("d6ba8b"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 378), "SALIDA", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color("f1e2c5"))

func interior_title() -> String:
	var labels: Dictionary = Regional.LABELS.get(WorldManager.country.id, {})
	var normalized := "market" if interior_kind in ["shop", "kiosk"] else interior_kind
	return str(labels.get(normalized, normalized.replace("_", " ").capitalize()))

func furniture(asset: String, at: Vector2, size: Vector2, footprint: Rect2, facing := "south-east") -> void:
	var node := Node2D.new()
	node.position = at
	node.set_meta("orientation", facing)
	node.set_meta("interior_asset", asset)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/interior/%s.png" % asset)
	sprite.region_enabled = true
	sprite.region_rect = sprite.texture.get_image().get_used_rect()
	sprite.scale = size / sprite.texture.get_size()
	sprite.position.y = -sprite.region_rect.size.y * sprite.scale.y / 2
	sprite.flip_h = facing in ["south-west", "west", "north-west"]
	node.add_child(sprite)
	add_child(node)
	add_solid(footprint)

func add_resident(id: String, title: String, at: Vector2, employee: bool) -> void:
	var walker := preload("res://scripts/city_walker.gd").new()
	walker.position = at
	walker.route.assign([at, at + Vector2(18, 0), at + Vector2(18, 10), at + Vector2(0, 10)])
	walker.profile = PlayerProfile.new()
	walker.profile.gender = "male" if employee else "female"
	walker.speed = 10
	walker.set_meta("person_id", id)
	walker.set_meta("person_name", title)
	add_child(walker)
