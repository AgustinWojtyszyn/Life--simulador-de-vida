extends Node2D

const MAP_SIZE := Vector2(2400, 1600)
const Regional := preload("res://scripts/data/regional_assets.gd")
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
var building_bounds: Array[Rect2] = []
var protected_content: Array[Rect2] = []
var placed_prop_bounds: Array[Rect2] = []
var city_objects: Array[Node2D] = []
var occluders: Array[Sprite2D] = []
# Two active lanes. Vehicles recycle beyond camera limits; parked cars stay solid.
const TRAFFIC_LANES := [
	{"from": Vector2(-140, 512), "to": Vector2(2540, 512), "direction": Vector2.RIGHT},
	{"from": Vector2(2540, 454), "to": Vector2(-140, 454), "direction": Vector2.LEFT},
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
	var frontages: Array = Regional.FRONTAGES[WorldManager.country.id]
	for i in frontages.size():
		add_frontage(frontages[i], [Vector2(195, 318), Vector2(445, 320), Vector2(704, 315), Vector2(1168, 324)][i], i)
	build_expansion()
	if WorldManager.country.id == "ar":
		integrate_argentina()
	var parked_positions := [Vector2(1126, 732), Vector2(1304, 732), Vector2(1126, 876), Vector2(1304, 876)]
	var parked_models := ["car", "van", "coupe", "taxi"]
	for i in parked_positions.size():
		var size := Vector2(98, 70) if parked_models[i] == "van" else Vector2(90, 60)
		add_asset("vehicles/" + parked_models[i], parked_positions[i], size, Rect2(-37, -19, 74, 18))
	var regional_models: Array = {"ar": ["compact", "taxi", "van", "sedan"], "jp": ["hatchback", "compact", "van", "sedan"], "us": ["pickup", "suv", "sedan", "van"], "it": ["compact", "hatchback", "sedan", "van"], "br": ["compact", "pickup", "sedan", "suv"]}[WorldManager.country.id]
	for lane_index in TRAFFIC_LANES.size():
		var lane: Dictionary = TRAFFIC_LANES[lane_index]
		for i in 3:
			var vehicle := AnimatableBody2D.new()
			vehicle.set_script(Vehicle)
			vehicle.name = "Traffic_%s_%s" % [lane_index, i]
			vehicle.model = regional_models[(i + lane_index * 2) % regional_models.size()]
			vehicle.position = Vector2(100 + i * 560 + lane_index * 200, lane.from.y)
			vehicle.direction = lane.direction.x
			vehicle.cruise_speed = 185.0 + i * 8.0
			vehicle.player = $Player
			add_child(vehicle)
	# A second circuit turns through both intersections and the southern street.
	# Chamfered waypoints keep vehicles in paved space through each turn.
	var east_lane := WorldManager.district.side_street_x + WorldManager.district.side_street_width * 0.25
	var circuit: Array[Vector2] = [Vector2(958, 1160), Vector2(958, 512), Vector2(east_lane, 512), Vector2(east_lane, 1160)]
	for i in 2:
		# A circuit requires genuine directional art; never rotate the legacy PNG.
		if not Vehicle.has_directional_art(regional_models[i]):
			continue
		var vehicle := AnimatableBody2D.new()
		vehicle.set_script(Vehicle)
		vehicle.name = "Circuit_%s" % i
		vehicle.model = regional_models[i]
		vehicle.route_points = circuit
		vehicle.route_index = 1 if i == 0 else 7
		vehicle.position = Vector2(958, 680) if i == 0 else Vector2(east_lane, 950)
		vehicle.cruise_speed = 170.0 if i == 0 else 160.0
		vehicle.player = $Player
		add_child(vehicle)
	for p in [Vector2(67, 341), Vector2(557, 333), Vector2(800, 338),
		Vector2(1035, 340), Vector2(1360, 354), Vector2(126, 713),
		Vector2(292, 699), Vector2(708, 705), Vector2(122, 906), Vector2(708, 906), Vector2(1390, 932)]:
		add_asset("vegetation/tree", p, Vector2(100, 133), Rect2(-9, -9, 18, 13))
	for p in [Vector2(365, 880), Vector2(621, 782), Vector2(716, 610), Vector2(1045, 601)]:
		add_asset("props/bench", p, Vector2(58, 43), Rect2(-23, -12, 46, 12))
	for p in [Vector2(90, 379), Vector2(510, 379), Vector2(813, 379), Vector2(1018, 379),
		Vector2(1370, 600), Vector2(814, 600), Vector2(66, 600), Vector2(460, 888)]:
		add_asset("props/lamp", p, Vector2(48, 96), Rect2(-4, -4, 8, 8))
	for p in [Vector2(322, 351), Vector2(758, 355), Vector2(1066, 365), Vector2(684, 603)]:
		add_asset("props/planter", p, Vector2(48, 36), Rect2(-18, -10, 36, 12))
	add_asset("props/fountain", Vector2(457, 819), Vector2(144, 108), Rect2(-49, -31, 98, 28))
	add_prop("sign", Vector2(266, 355), Rect2(-7, -5, 14, 6))
	add_prop("sign", Vector2(499, 354), Rect2(-7, -5, 14, 6))
	decorate_expansion()
	integrate_regional_props()
	populate()
	add_neighbor("mara", "Mara", WorldManager.district.home_position + Vector2(80, 42))
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

func add_frontage(asset: String, pos: Vector2, index: int) -> void:
	var building := CityBuildingScript.new()
	building.position = pos
	building.country_id = WorldManager.country.id
	building.variant = BuildingVariants.make(building.country_id, "shop", index + 13)
	var spec := Regional.descriptor(building.country_id, asset, index)
	building.building_type = spec.type
	building.title = spec.title
	building.access = CityBuilding.Access.EXTERIOR_ONLY if spec.type == "office" else CityBuilding.Access.ENTERABLE
	building.interior_type = "" if spec.type == "office" else "cafe" if spec.type in ["cafe", "diner", "pizzeria", "bakery", "trattoria"] else "shop"
	building.building_id = "%s_front_%d" % [building.country_id, index]
	building.facade = load(spec.path)
	fit_building(building)
	add_child(building)
	city_objects.append(building)
	occluders.append(building.get_child(0))
	add_building_solid(building)

func add_asset(asset: String, pos: Vector2, size: Vector2, footprint: Rect2, tint := Color.WHITE) -> void:
	pos = valid_prop_position(pos, size, asset.begins_with("vehicles/"))
	if not pos.is_finite(): return
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
	sprite.region_enabled = true
	sprite.region_rect = sprite.texture.get_image().get_used_rect()
	sprite.position = Vector2(0, -size.y / 2)
	sprite.scale = size / sprite.region_rect.size
	sprite.modulate = tint
	prop.add_child(sprite)
	if asset == "vegetation/tree":
		add_prop("tree_bed", pos + Vector2(0, 3), Rect2())
	if asset == "props/fountain":
		prop.set_script(Water)
	if asset == "props/bench":
		prop.add_to_group("city_benches")
	if asset.begins_with("vehicles/"):
		prop.add_to_group("parked_vehicles")
	if asset == "props/lamp":
		prop.add_to_group("street_lamps")
	prop.set_meta("placement_bounds", Rect2(pos - Vector2(size.x / 2, size.y), size))
	add_child(prop)
	city_objects.append(prop)
	if asset.begins_with("buildings/"):
		prop.set_meta("building_mode", "EXTERIOR_ONLY")
	if asset.begins_with("buildings/") or asset.begins_with("vegetation/"):
		occluders.append(sprite)
	add_solid(Rect2(pos + footprint.position, footprint.size))

func add_prop(kind: String, pos: Vector2, footprint: Rect2) -> void:
	if kind != "tree_bed":
		pos = valid_prop_position(pos, Vector2(22, 28))
		if not pos.is_finite(): return
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
		var nearby := player.position.distance_squared_to(sprite.get_parent().position) < 1050.0 * 1050.0
		sprite.get_parent().visible = nearby
		if not nearby: continue
		var behind: bool = player.position.y < sprite.get_parent().position.y
		var local_head := sprite.to_local(player.position - Vector2(0, 15))
		var covered: bool = behind and sprite.get_rect().has_point(local_head)
		sprite.modulate.a = move_toward(sprite.modulate.a, 0.45 if covered else 1.0, delta * 4.0)
		if sprite.get_parent().get_script() == CityBuildingScript:
			sprite.get_parent().modulate.a = 1.0

func build_expansion() -> void:
	var data: DistrictData = WorldManager.district
	var country: CountryData = WorldManager.country
	var index := 0
	for slot in data.building_slots:
		var building := CityBuildingScript.new()
		building.position = slot.position
		building.building_id = country.id + "_building_" + str(index)
		building.is_home = slot.kind == "home"
		var spec := Regional.descriptor(country.id, slot.kind, int(slot.get("asset_index", index)))
		building.building_type = spec.type
		building.title = spec.title
		building.country_id = country.id
		building.variant = BuildingVariants.make(country.id, slot.kind, index)
		building.interior_type = ("cafe" if spec.type in ["cafe", "bakery", "pizzeria", "diner"] else "shop") if slot.kind == "shop" else ""
		building.access = CityBuilding.Access.ENTERABLE if slot.mode == "ENTERABLE" else CityBuilding.Access.INTERACTABLE if slot.mode == "INTERACTABLE" else CityBuilding.Access.EXTERIOR_ONLY
		building.facade = load(spec.path)
		fit_building(building)
		add_child(building)
		city_objects.append(building)
		occluders.append(building.get_child(0))
		add_building_solid(building)
		index += 1
func decorate_expansion() -> void:
	var data: DistrictData = WorldManager.district
	var east := data.side_street_x + data.side_street_width + 140
	add_asset("props/fountain", Vector2(east, 1040), Vector2(100, 75), Rect2(-32, -21, 64, 20))
	add_asset("props/bench", Vector2(east - 80, 1080), Vector2(58, 43), Rect2(-23, -12, 46, 12))
	add_asset("props/planter", Vector2(east + 70, 1044), Vector2(48, 36), Rect2(-18, -10, 36, 12))
	for p in [Vector2(1435, 354), Vector2(1710, 352), Vector2(1990, 580), Vector2(2340, 590), Vector2(1480, 1020), Vector2(1720, 950), Vector2(110, 1280), Vector2(760, 1280), Vector2(1040, 1280), Vector2(1720, 1280), Vector2(2340, 1280)]:
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
	var benches := get_tree().get_nodes_in_group("city_benches")
	if not benches.is_empty():
		var seat: Vector2 = benches[0].position + Vector2(0, 2)
		routes[8] = [seat, seat + Vector2(0, 26), seat + Vector2(65, 26), seat + Vector2(0, 26)]
	for i in WorldManager.district.population:
		var walker := Node2D.new()
		walker.set_script(Walker)
		walker.route.assign(routes[i % routes.size()])
		walker.position = walker.route[0] + Vector2((i / routes.size()) * 25, 0)
		walker.speed = 60.0 + (i % 5) * 6
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

func add_neighbor(id: String, title: String, at: Vector2) -> void:
	var walker := Walker.new()
	walker.position = at
	walker.route.assign([at, at + Vector2(32, 0), at + Vector2(32, 18), at + Vector2(0, 18)])
	walker.profile = PlayerProfile.new()
	walker.profile.gender = "female" if id == "mara" else "male"
	walker.set_meta("person_id", id)
	walker.set_meta("person_name", title)
	add_child(walker)

func fit_building(building: CityBuilding) -> void:
	var used := building.facade.get_image().get_used_rect().size
	var max_width := 190.0
	var max_height := 238.0
	for road in roads():
		if road.size.x > 1000 and road.end.y < building.position.y:
			max_height = minf(max_height, building.position.y - road.end.y - 24)
		if road.size.y > 1000:
			var clearance := road.position.x - building.position.x if building.position.x < road.position.x else building.position.x - road.end.x
			max_width = minf(max_width, (clearance - 14) * 2)
	# The southern parking bays remain unobstructed by the next frontage.
	if building.position.x > 1030 and building.position.x < 1400 and building.position.y == 1060:
		max_height = minf(max_height, 130)
	var factor := minf(max_width / used.x, max_height / used.y)
	building.size = building.facade.get_size() * factor
	building_bounds.append(Rect2(building.position - Vector2(used.x * factor / 2, used.y * factor), Vector2(used) * factor))

func add_building_solid(building: CityBuilding) -> void:
	var bounds: Rect2 = building_bounds.back()
	var depth := minf(64.0, bounds.size.y * 0.32)
	add_solid(Rect2(building.position + Vector2(-bounds.size.x * 0.46, -depth), Vector2(bounds.size.x * 0.92, depth - 4)))

func roads() -> Array[Rect2]:
	return [Rect2(16, 394, 2368, 170), Rect2(852, 16, 138, 1568), Rect2(16, 1130, 2368, 120), Rect2(WorldManager.district.side_street_x, 16, WorldManager.district.side_street_width, 1568)]

func valid_prop_position(at: Vector2, size: Vector2, parked: bool = false) -> Vector2:
	# Reserve the entire facade envelope, not just its collision strip. This
	# prevents short props from appearing pasted onto a tall building's front.
	var offsets := [Vector2.ZERO]
	if not parked:
		for distance in [32, 64, 96, 128]:
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
				offsets.append(direction * distance)
	for offset in offsets:
		var candidate: Vector2 = at + offset
		var visual := Rect2(candidate - Vector2(size.x / 2, size.y), size)
		var base := Rect2(candidate - Vector2(size.x / 2, 16), Vector2(size.x, 20))
		if not Rect2(20, 20, 2360, 1560).encloses(visual): continue
		var valid := true
		for bounds in building_bounds:
			if visual.intersects(bounds.grow(8)): valid = false
		for road in roads():
			if base.intersects(road.grow(8)): valid = false
		for bounds in protected_content:
			if visual.intersects(bounds): valid = false
		for bounds in placed_prop_bounds:
			if base.intersects(bounds.grow(5)): valid = false
		if valid:
			placed_prop_bounds.append(base)
			return candidate
	return Vector2(INF, INF)

func integrate_argentina() -> void:
	add_asset("props/ar/choripan_stand", Vector2(150, 802), Vector2(84, 78), Rect2(-32, -18, 64, 18))
	add_asset("props/ar/parrilla", Vector2(723, 811), Vector2(84, 78), Rect2(-32, -18, 64, 18))
	var stop := Node2D.new()
	stop.set_script(CityProp)
	stop.kind = "transport_stop"
	stop.position = Vector2(360, 600)
	stop.set_meta("building_type", "transport_stop")
	add_child(stop)
	add_solid(Rect2(357, 592, 6, 8))
	var pitch := Node2D.new()
	pitch.set_script(preload("res://scripts/regional_content.gd"))
	pitch.position = Vector2(215, 735)
	pitch.z_index = -2
	pitch.set_meta("building_type", "sports")
	add_child(pitch)
	protected_content.append(Rect2(210, 715, 225, 115))
	for food_name in ["Choripan Stand", "Parrilla"]:
		var stand := get_node(NodePath(food_name)) as Node2D
		protected_content.append(stand.get_meta("placement_bounds"))
		var target := preload("res://scripts/interaction_target.gd").new()
		target.position = Vector2(0, 18)
		target.label = "Comprar choripán" if food_name == "Choripan Stand" else "Comer en la parrilla"
		target.action = "buy_food"
		stand.add_child(target)
	# Existing east art is used only on the eastbound avenue; no invented turns.
	var bus := Vehicle.new()
	bus.name = "Colectivo"
	bus.model = "colectivo"
	bus.position = Vector2(1900, 512)
	bus.direction = 1.0
	bus.cruise_speed = 180.0
	bus.player = $Player
	add_child(bus)
	add_local_resident("Tito", Vector2(150, 830), "eat")
	add_local_resident("Luli", Vector2(395, 601), "phone")
	for i in 2:
		var walker := Walker.new()
		walker.route.assign([Vector2(240 + i * 135, 760), Vector2(265 + i * 130, 800)])
		walker.position = walker.route[0]
		walker.speed = 48 + i * 7
		walker.route_kind = "football"
		walker.profile = PlayerProfile.new()
		walker.profile.top = i
		add_child(walker)

func add_local_resident(title: String, at: Vector2, activity: String) -> void:
	var walker := Walker.new()
	walker.position = at
	walker.route.assign([at, at + Vector2(25, 0)])
	walker.activity = activity
	walker.set_meta("person_name", title)
	add_child(walker)
	walker.wait_time = 12.0

func integrate_regional_props() -> void:
	match WorldManager.country.id:
		"br":
			add_asset("props/br/moto", Vector2(615, 376), Vector2(42, 36), Rect2(-16, -10, 32, 10))
		"it":
			add_asset("props/it/scooter", Vector2(615, 376), Vector2(42, 36), Rect2(-16, -10, 32, 10))
		"jp":
			add_asset("props/jp/vending_machine", Vector2(772, 378), Vector2(30, 49), Rect2(-13, -12, 26, 12))
			add_asset("props/jp/bicycle", Vector2(630, 376), Vector2(42, 30), Rect2(-16, -8, 32, 8))
