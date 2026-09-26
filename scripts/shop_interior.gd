extends Node2D

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")

func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Player/Camera2D.limit_right = 800
	$Player/Camera2D.limit_bottom = 450
	for wall in [Rect2(86, 64, 628, 16), Rect2(86, 388, 628, 16), Rect2(86, 64, 16, 340), Rect2(698, 64, 16, 340), Rect2(501, 161, 136, 46)]:
		var body := StaticBody2D.new()
		body.position = wall.get_center()
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = wall.size
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
	for entry in [
		[Vector2(390, 359), "Salir al barrio", "exit_home", "exit"],
		[Vector2(228, 278), "Comprar provisiones · $12", "buy_food", "shelf"],
		[Vector2(550, 250), "Tomar algo", "coffee", "counter"],
	]:
		if entry[2] == "buy_food" and WorldManager.location == "cafe": continue
		if entry[2] == "coffee" and WorldManager.location != "cafe": continue
		var point := InteractionTargetScript.new()
		point.position = entry[0]
		point.label = entry[1]
		point.action = entry[2]
		point.target_id = entry[3]
		point.detail = "el local"
		add_child(point)
	var cafe := WorldManager.location == "cafe"
	if cafe:
		furniture("cafe_bar", Vector2(560, 220), Vector2(160, 102), Rect2(495, 170, 132, 43))
		for at in [Vector2(184, 206), Vector2(343, 206), Vector2(182, 327), Vector2(343, 327)]:
			furniture("cafe_table", at, Vector2(90, 80), Rect2(at - Vector2(32, 31), Vector2(64, 25)))
	else:
		for at in [Vector2(176, 245), Vector2(318, 245), Vector2(458, 245)]:
			furniture("market_shelf", at, Vector2(76, 110), Rect2(at - Vector2(32, 30), Vector2(64, 24)))
		furniture("market_fridge", Vector2(645, 164), Vector2(76, 82), Rect2(620, 141, 50, 18))
		furniture("checkout", Vector2(566, 228), Vector2(130, 91), Rect2(505, 180, 122, 32))
	add_resident("nico" if cafe else "clerk", "Nico" if cafe else "Almacenero", Vector2(567, 146), true)
	add_resident("customer", "Cliente", Vector2(292, 293), false)
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

func _draw() -> void:
	var cafe := WorldManager.location == "cafe"
	var accent: Color = WorldManager.country.accent
	draw_rect(Rect2(0, 0, 800, 450), Color("172d31"))
	draw_rect(Rect2(86, 64, 628, 340), Color("d5c3a5"))
	draw_rect(Rect2(102, 80, 596, 308), Color("8d7762"))
	for y in range(80, 388, 24):
		for x in range(102, 698, 36):
			draw_rect(Rect2(x + (12 if y % 48 else 0), y, 35, 23).intersection(Rect2(102, 80, 596, 308)), Color("9b856b") if x % 3 else Color("a48d73"))
	draw_rect(Rect2(109, 82, 582, 29), accent)
	draw_string(ThemeDB.fallback_font, Vector2(280, 103), "CAFETERÍA" if cafe else "MERCADO", HORIZONTAL_ALIGNMENT_CENTER, 240, 17, Color("293b3c"))
	draw_rect(Rect2(365, 381, 50, 12), Color("d6ba8b"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 378), "SALIDA", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color("f1e2c5"))

func furniture(asset: String, at: Vector2, size: Vector2, footprint: Rect2) -> void:
	var node := Node2D.new()
	node.position = at
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/interior/%s.png" % asset)
	sprite.region_enabled = true
	sprite.region_rect = sprite.texture.get_image().get_used_rect()
	sprite.scale = size / sprite.texture.get_size()
	sprite.position.y = -sprite.region_rect.size.y * sprite.scale.y / 2
	node.add_child(sprite)
	add_child(node)
	var body := StaticBody2D.new()
	body.position = footprint.get_center()
	var shape := RectangleShape2D.new()
	shape.size = footprint.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func add_resident(id: String, title: String, at: Vector2, employee: bool) -> void:
	var walker := preload("res://scripts/city_walker.gd").new()
	walker.position = at
	walker.route.assign([at, at + Vector2(18, 0), at + Vector2(18, 10), at + Vector2(0, 10)])
	walker.profile = PlayerProfile.new()
	walker.profile.gender = "male" if employee else "female"
	walker.speed = 10
	walker.set_meta("person_id", id)
	walker.set_meta("person_name", title)
	if id == "nico":
		# A counter conversation anchor keeps Nico reachable from the customer side.
		walker.position = Vector2(656, 255)
		walker.route.assign([walker.position, walker.position + Vector2(0, 12)])
	add_child(walker)
