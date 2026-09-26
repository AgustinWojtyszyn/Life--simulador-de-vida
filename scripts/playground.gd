extends Node2D

const MAP_SIZE := Vector2(2400, 1600)
const CityProp := preload("res://scripts/city_prop.gd")
const Ground := preload("res://scripts/city_ground.gd")
const Walker := preload("res://scripts/city_walker.gd")
const Vehicle := preload("res://scripts/city_vehicle.gd")
const Interactions := preload("res://scripts/city_interactions.gd")
const Water := preload("res://scripts/fountain_water.gd")
const Hud := preload("res://scripts/city_hud.gd")
const BuildingVariants := preload("res://scripts/data/building_variant.gd")
const CityBuildingScript := preload("res://scripts/building.gd")
# World-space footprints are independent of sprite height; sorting uses the feet.
var solid_rects: Array[Rect2] = []
var city_objects: Array[Node2D] = []
var occluders: Array[Sprite2D] = []
# Two active lanes. Vehicles recycle beyond camera limits; parked cars stay solid.
const TRAFFIC_LANES := [
	{"from": Vector2(-140, 454), "to": Vector2(2540, 454), "direction": Vector2.RIGHT},
	{"from": Vector2(2540, 512), "to": Vector2(-140, 512), "direction": Vector2.LEFT},
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	configure_input()
	$Player/Camera2D.limit_right = int(MAP_SIZE.x)
	$Player/Camera2D.limit_bottom = int(MAP_SIZE.y)
	# Render thousands of static ground marks only once, then reuse one GPU texture.
	var ground_view := SubViewport.new()
	ground_view.name = "GroundCache"
	ground_view.size = Vector2i(MAP_SIZE)
	ground_view.disable_3d = true
	ground_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var ground := Node2D.new()
	ground.set_script(Ground)
	ground_view.add_child(ground)
	add_child(ground_view)
	var ground_sprite := Sprite2D.new()
	ground_sprite.texture = ground_view.get_texture()
	ground_sprite.centered = false
	ground_sprite.z_index = -10
	add_child(ground_sprite)
	for rect in [Rect2(0, 0, 2400, 16), Rect2(0, 1584, 2400, 16),
		Rect2(0, 0, 16, 1600), Rect2(2384, 0, 16, 1600)]:
		add_solid(rect)
	# Northern commercial frontage, a side street, and a second block.
	add_frontage("cafe", Vector2(195, 318), Vector2(230, 268), Rect2(-87, -64, 166, 58), 0)
	add_frontage("market", Vector2(445, 320), Vector2(220, 220), Rect2(-83, -58, 160, 53), 1)
	add_frontage("cafe", Vector2(704, 315), Vector2(230, 268), Rect2(-87, -64, 166, 58), 2)
	add_frontage("market", Vector2(1168, 324), Vector2(264, 264), Rect2(-100, -70, 193, 64), 3)
	var parked_positions := [Vector2(1126, 732), Vector2(1304, 732), Vector2(1126, 876), Vector2(1304, 876)]
	var parked_models := ["car", "van", "coupe", "taxi"]
	for i in parked_positions.size():
		var size := Vector2(98, 70) if parked_models[i] == "van" else Vector2(90, 60)
		add_asset("vehicles/" + parked_models[i], parked_positions[i], size, Rect2(-37, -19, 74, 18))
	for lane_index in TRAFFIC_LANES.size():
		var lane: Dictionary = TRAFFIC_LANES[lane_index]
		for i in 3:
			var vehicle := AnimatableBody2D.new()
			vehicle.set_script(Vehicle)
			vehicle.name = "Traffic_%s_%s" % [lane_index, i]
			vehicle.model = parked_models[(i + lane_index * 2) % parked_models.size()]
			vehicle.position = Vector2(100 + i * 560 + lane_index * 200, lane.from.y)
			vehicle.direction = lane.direction.x
			vehicle.cruise_speed = 62.0 + i * 5.0
			vehicle.player = $Player
			add_child(vehicle)
	# A second circuit turns through both intersections and the southern street.
	# Chamfered waypoints keep vehicles in paved space through each turn.
	var east_lane := WorldManager.district.side_street_x + WorldManager.district.side_street_width * 0.5
	var circuit: Array[Vector2] = [Vector2(920, 1170), Vector2(920, 550), Vector2(940, 508),
		Vector2(1005, 480), Vector2(east_lane - 58, 480), Vector2(east_lane - 16, 500),
		Vector2(east_lane, 550), Vector2(east_lane, 1118), Vector2(east_lane - 18, 1152),
		Vector2(east_lane - 60, 1180), Vector2(1000, 1180), Vector2(948, 1160)]
	for i in 2:
		# A circuit requires genuine directional art; never rotate the legacy PNG.
		if not Vehicle.has_directional_art("taxi" if i == 0 else "van"):
			continue
		var vehicle := AnimatableBody2D.new()
		vehicle.set_script(Vehicle)
		vehicle.name = "Circuit_%s" % i
		vehicle.model = "taxi" if i == 0 else "van"
		vehicle.route_points = circuit
		vehicle.route_index = 1 if i == 0 else 7
		vehicle.position = circuit[0] if i == 0 else circuit[6]
		vehicle.cruise_speed = 47.0 if i == 0 else 38.0
		vehicle.player = $Player
		add_child(vehicle)
	for p in [Vector2(67, 341), Vector2(557, 333), Vector2(800, 338),
		Vector2(1035, 340), Vector2(1360, 354), Vector2(126, 713),
		Vector2(292, 699), Vector2(708, 705), Vector2(122, 906), Vector2(708, 906), Vector2(1390, 932)]:
		add_prop("tree_bed", p + Vector2(0, 3), Rect2())
		add_asset("vegetation/tree", p, Vector2(100, 133), Rect2(-9, -9, 18, 13))
	for p in [Vector2(270, 782), Vector2(621, 782), Vector2(716, 610), Vector2(1045, 601)]:
		add_asset("props/bench", p, Vector2(58, 43), Rect2(-23, -12, 46, 12))
	for p in [Vector2(90, 379), Vector2(510, 379), Vector2(813, 379), Vector2(1018, 379),
		Vector2(1370, 600), Vector2(814, 600), Vector2(66, 600), Vector2(460, 888)]:
		add_asset("props/lamp", p, Vector2(48, 96), Rect2(-4, -4, 8, 8))
	for p in [Vector2(322, 351), Vector2(758, 355), Vector2(1066, 365), Vector2(684, 603)]:
		add_asset("props/planter", p, Vector2(48, 36), Rect2(-18, -10, 36, 12))
	add_asset("props/fountain", Vector2(457, 819), Vector2(144, 108), Rect2(-49, -31, 98, 28))
	add_prop("sign", Vector2(266, 355), Rect2(-7, -5, 14, 6))
	add_prop("sign", Vector2(499, 354), Rect2(-7, -5, 14, 6))
	build_expansion()
	populate()
	var layer := CanvasLayer.new()
	var hud := Control.new()
	hud.set_script(Hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	add_child(layer)
	var interactions := Node.new()
	interactions.name = "Interactions"
	interactions.set_script(Interactions)
	interactions.hud = hud
	add_child(interactions)

func configure_input() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E],
	}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)
	solid_rects.append(rect)

func add_frontage(asset: String, pos: Vector2, size: Vector2, footprint: Rect2, index: int) -> void:
	var building := CityBuildingScript.new()
	building.position = pos
	building.size = size
	building.country_id = WorldManager.country.id
	building.variant = BuildingVariants.make(building.country_id, "shop", index + 13)
	building.access = CityBuilding.Access.ENTERABLE
	building.interior_type = "cafe" if asset == "cafe" else "shop"
	building.title = WorldManager.country.shop_names[1 if asset == "cafe" else 0]
	building.building_id = "%s_front_%d" % [building.country_id, index]
	building.facade = load("res://assets/city/buildings/%s.png" % asset) if building.country_id == "ar" else load(WorldManager.country.facade)
	add_child(building)
	city_objects.append(building)
	occluders.append(building.get_child(0))
	add_solid(Rect2(pos + footprint.position, footprint.size))

func add_asset(asset: String, pos: Vector2, size: Vector2, footprint: Rect2, tint := Color.WHITE) -> void:
	var prop := Node2D.new()
	prop.name = asset.get_file().capitalize()
	prop.position = pos
	var sprite := Sprite2D.new()
	var path := "res://assets/city/%s.png" % asset
	if asset.begins_with("buildings/") and WorldManager.country.id != "ar":
		path = WorldManager.country.facade
	elif asset == "vegetation/tree":
		path = WorldManager.country.greenery
	sprite.texture = load(path)
	sprite.centered = false
	sprite.position = Vector2(-size.x / 2, -size.y)
	sprite.scale = size / sprite.texture.get_size()
	sprite.modulate = tint
	prop.add_child(sprite)
	if asset == "props/fountain":
		prop.set_script(Water)
	if asset == "props/bench":
		prop.add_to_group("city_benches")
	if asset.begins_with("vehicles/"):
		prop.add_to_group("parked_vehicles")
	add_child(prop)
	city_objects.append(prop)
	if asset.begins_with("buildings/"):
		prop.set_meta("building_mode", "EXTERIOR_ONLY")
	if asset.begins_with("buildings/") or asset.begins_with("vegetation/"):
		occluders.append(sprite)
	add_solid(Rect2(pos + footprint.position, footprint.size))

func add_prop(kind: String, pos: Vector2, footprint: Rect2) -> void:
	var prop := Node2D.new()
	prop.set_script(CityProp)
	prop.kind = kind
	prop.position = pos
	if kind == "tree_bed":
		prop.z_index = -1
	add_child(prop)
	city_objects.append(prop)
	if footprint.has_area():
		add_solid(Rect2(pos + footprint.position, footprint.size))

func _process(delta: float) -> void:
	# Keep the controllable resident readable while passing behind a facade/canopy.
	var player: Node2D = $Player
	for sprite in occluders:
		var behind: bool = player.position.y < sprite.get_parent().position.y
		var local_head := sprite.to_local(player.position - Vector2(0, 15))
		var covered: bool = behind and sprite.get_rect().has_point(local_head)
		sprite.modulate.a = move_toward(sprite.modulate.a, 0.45 if covered else 1.0, delta * 4.0)
		if sprite.get_parent().get_script() == CityBuildingScript:
			sprite.get_parent().modulate.a = sprite.modulate.a

func build_expansion() -> void:
	var data: DistrictData = WorldManager.district
	var country: CountryData = WorldManager.country
	var index := 0
	for slot in data.building_slots:
		var building := CityBuildingScript.new()
		building.position = slot.position
		building.building_id = country.id + "_building_" + str(index)
		building.is_home = slot.kind == "home"
		building.interior_type = ("cafe" if index % 2 else "shop") if slot.kind == "shop" else ""
		building.access = CityBuilding.Access.ENTERABLE if slot.mode == "ENTERABLE" else CityBuilding.Access.INTERACTABLE if slot.mode == "INTERACTABLE" else CityBuilding.Access.EXTERIOR_ONLY
		building.title = country.shop_names[2] if slot.kind == "clinic" else country.shop_names[4] if slot.kind == "office" else country.home_kind.to_upper() if slot.kind == "house" else country.shop_names[index % 2]
		building.country_id = country.id
		building.variant = BuildingVariants.make(country.id, slot.kind, index)
		var use_house: bool = slot.kind in ["home", "house"] and country.id not in ["jp", "it"]
		building.facade = load("res://assets/regions/home.png" if use_house else country.facade)
		building.size = Vector2(building.variant.width, building.variant.height)
		add_child(building)
		city_objects.append(building)
		occluders.append(building.get_child(0))
		add_solid(Rect2(building.position + Vector2(-76, -48), Vector2(150, 44)))
		index += 1
	var east := data.side_street_x + data.side_street_width + 140
	add_asset("props/fountain", Vector2(east, 1040), Vector2(100, 75), Rect2(-32, -21, 64, 20))
	add_asset("props/bench", Vector2(east - 80, 1080), Vector2(58, 43), Rect2(-23, -12, 46, 12))
	add_asset("props/planter", Vector2(east + 70, 1044), Vector2(48, 36), Rect2(-18, -10, 36, 12))
	for p in [Vector2(1435, 354), Vector2(1710, 352), Vector2(1990, 580), Vector2(2340, 590), Vector2(1480, 1020), Vector2(1720, 950), Vector2(110, 1280), Vector2(760, 1280), Vector2(1040, 1280), Vector2(1720, 1280), Vector2(2340, 1280)]:
		add_prop("tree_bed", p + Vector2(0, 3), Rect2())
		add_asset("vegetation/tree", p, Vector2(100, 133), Rect2(-9, -9, 18, 13))
	for p in [Vector2(1460, 600), Vector2(1650, 930), Vector2(530, 1285), Vector2(2170, 1030)]:
		add_asset("props/bench", p, Vector2(58, 43), Rect2(-23, -12, 46, 12))
	for p in [Vector2(1460, 380), Vector2(1730, 380), Vector2(2000, 380), Vector2(2340, 1040), Vector2(1630, 1110), Vector2(450, 1110), Vector2(1080, 1110)]:
		add_asset("props/lamp", p, Vector2(48, 96), Rect2(-4, -4, 8, 8))

func populate() -> void:
	var system := Node.new()
	system.name = "PopulationSystem"
	system.set_script(preload("res://scripts/population_system.gd"))
	add_child(system)
	var east := WorldManager.district.side_street_x + WorldManager.district.side_street_width + 140
	var routes := [
		[Vector2(340, 373), Vector2(462, 373), Vector2(462, 355), Vector2(340, 355)],
		[Vector2(200, 608), Vector2(490, 608), Vector2(490, 626), Vector2(200, 626)],
		[Vector2(1120, 370), Vector2(1300, 370), Vector2(1300, 350), Vector2(1120, 350)],
		[Vector2(1490, 362), Vector2(1640, 362), Vector2(1640, 382), Vector2(1490, 382)],
		[Vector2(2050, 364), Vector2(2270, 364), Vector2(2270, 380), Vector2(2050, 380)],
		[Vector2(1550, 816), Vector2(1680, 816), Vector2(1680, 840), Vector2(1550, 840)],
		[Vector2(140, 1500), Vector2(370, 1500), Vector2(370, 1520), Vector2(140, 1520)],
		[Vector2(1130, 1500), Vector2(1420, 1500), Vector2(1420, 1520), Vector2(1130, 1520)],
		[Vector2(270, 784), Vector2(270, 816), Vector2(335, 816), Vector2(335, 797)],
		[Vector2(445, 334), Vector2(445, 363), Vector2(380, 363), Vector2(380, 340)],
		[Vector2(1022, 420), Vector2(1022, 580), Vector2(1007, 580), Vector2(1007, 420)],
		[Vector2(east, 830), Vector2(east + 130, 830), Vector2(east + 130, 856), Vector2(east, 856)],
		[Vector2(east - 50, 1080), Vector2(east + 100, 1080), Vector2(east + 100, 1100), Vector2(east - 50, 1100)],
		[Vector2(358, 630), Vector2(401, 684), Vector2(463, 751), Vector2(500, 813), Vector2(552, 873), Vector2(500, 813), Vector2(463, 751), Vector2(401, 684)],
		[Vector2(1430, 1030), Vector2(1520, 1072), Vector2(1615, 1088), Vector2(1700, 1050), Vector2(1615, 1088), Vector2(1520, 1072)],
	]
	for i in WorldManager.district.population:
		var walker := Node2D.new()
		walker.set_script(Walker)
		walker.route.assign(routes[i % routes.size()])
		walker.position = walker.route[0] + Vector2((i / routes.size()) * 25, 0)
		walker.speed = 22.0 + (i % 4) * 3
		walker.profile = PlayerProfile.new()
		walker.profile.gender = "female" if i % 2 else "male"
		walker.profile.skin = i % 3
		walker.profile.hair = (i / 2) % 3
		walker.profile.hair_color = (i / 3) % 3
		walker.profile.top = (i + 1) % 3
		walker.profile.bottom = (i / 2) % 3
		walker.route_kind = "bench" if i % routes.size() == 8 else "shop" if i % routes.size() == 9 else "crossing" if i % routes.size() == 10 else "walk"
		add_child(walker)
		system.residents.append(walker)
