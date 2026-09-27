extends Node2D

var map_size := Vector2.ZERO
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
const CountryCatalogScript := preload("res://scripts/data/country_catalog.gd")
const TextureBoundsScript := preload("res://scripts/data/texture_bounds.gd")
const TrafficSignalScript := preload("res://scripts/traffic_signal.gd")
# World-space footprints are independent of sprite height; sorting uses the feet.
var solid_rects: Array[Rect2] = []
var building_bounds: Array[Rect2] = []
var protected_content: Array[Rect2] = []
var entrance_clearance: Array[Rect2] = []
var placed_prop_bounds: Array[Rect2] = []
var city_objects: Array[Node2D] = []
var occluders: Array[Sprite2D] = []
var texture_used_cache: Dictionary = {}
var road_cache: Array[Rect2] = []
var occlusion_clock := 0.0
# Two active lanes. Vehicles recycle beyond camera limits; parked cars stay solid.
const TRAFFIC_LANES := [
	{"from": Vector2(-140, 512), "to": Vector2(2540, 512), "direction": Vector2.RIGHT},
	{"from": Vector2(2540, 454), "to": Vector2(-140, 454), "direction": Vector2.LEFT},
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	configure_input()
	map_size = WorldManager.district.world_size
	road_cache = DistrictBlocks.roads(WorldManager.district)
	$Player/Camera2D.limit_right = int(map_size.x)
	$Player/Camera2D.limit_bottom = int(map_size.y)
	# Static CanvasItem drawing is cached without allocating a 4800x3200
	# viewport texture, which is substantially cheaper on Android/WebGL.
	var ground := Node2D.new()
	ground.name = "CityGround"
	ground.set_script(Ground)
	ground.z_index = -10
	add_child(ground)
	for rect in [
		Rect2(0, 0, map_size.x, 16),
		Rect2(0, map_size.y - 16, map_size.x, 16),
		Rect2(0, 0, 16, map_size.y),
		Rect2(map_size.x - 16, 0, 16, map_size.y),
	]:
		add_solid(rect)
	add_traffic_signals()
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
		add_asset("vehicles/" + parked_models[i], parked_positions[i], size, Rect2(-37, -19, 74, 18), Color.WHITE, "east" if i % 2 else "west")
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
			vehicle.cruise_speed = Vehicle.profile_for(vehicle.model).speed - i * 3.0
			vehicle.route_right = map_size.x + 140.0
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
		vehicle.cruise_speed = Vehicle.profile_for(vehicle.model).speed - 12.0
		vehicle.player = $Player
		add_child(vehicle)
	add_expansion_traffic(regional_models)
	add_grid_traffic(regional_models)
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
	# Perpendicular benches face the open plaza. Existing south-facing seats
	# retain their interactions and authored seated character poses.
	add_asset("props/bench", Vector2(360, 670), Vector2(58, 43), Rect2(-12, -18, 24, 18), Color.WHITE, "east")
	add_asset("props/bench", Vector2(600, 870), Vector2(58, 43), Rect2(-12, -18, 24, 18), Color.WHITE, "west")
	populate()
	add_neighbor("mara", "Mara", WorldManager.district.home_position + Vector2(80, 42))
	var layer := CanvasLayer.new()
	var hud := Control.new()
	hud.set_script(Hud)
	hud.world = self
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	add_child(layer)
	var interactions := Node.new()
	interactions.name = "Interactions"
	interactions.set_script(Interactions)
	interactions.hud = hud
	add_child(interactions)

func add_traffic_signals() -> void:
	var horizontal := DistrictBlocks.horizontal_roads(WorldManager.district)
	var vertical := DistrictBlocks.vertical_roads(WorldManager.district)
	for row in horizontal.size():
		var h: Rect2 = horizontal[row]
		for column in vertical.size():
			var v: Rect2 = vertical[column]
			var signal := Node2D.new()
			signal.set_script(TrafficSignalScript)
			signal.name = "Signal_%d_%d" % [row, column]
			signal.position = Vector2(v.get_center().x, h.get_center().y)
			signal.horizontal_half = h.size.y * 0.5
			signal.vertical_half = v.size.x * 0.5
			# A small row offset creates a green-wave feel instead of every
			# intersection changing at the exact same instant.
			signal.cycle_offset = float(row) * 1.8 + float(column) * 0.35
			add_child(signal)

func add_grid_traffic(regional_models: Array) -> void:
	# The expanded city must not feel like traffic exists only around spawn.
	# Two lightweight vehicles circulate on each additional avenue lane.
	var roads_h := DistrictBlocks.horizontal_roads(WorldManager.district)
	for road_index in range(1, roads_h.size()):
		var road: Rect2 = roads_h[road_index]
		for lane_index in 2:
			var vehicle := AnimatableBody2D.new()
			vehicle.set_script(Vehicle)
			vehicle.name = "GridTraffic_%s_%s" % [road_index, lane_index]
			vehicle.model = regional_models[(road_index + lane_index) % regional_models.size()]
			vehicle.direction = 1.0 if lane_index == 0 else -1.0
			vehicle.position = Vector2(
				280.0 + road_index * 610.0 + lane_index * 920.0,
				road.get_center().y + (-24.0 if lane_index == 0 else 24.0)
			)
			vehicle.route_right = map_size.x + 140.0
			vehicle.cruise_speed = Vehicle.profile_for(vehicle.model).speed - 7.0 - road_index * 2.0
			vehicle.player = $Player
			add_child(vehicle)

func add_expansion_traffic(regional_models: Array) -> void:
	var circuit: Array[Vector2] = [
		Vector2(2842, 1190),
		Vector2(2842, 1962),
		Vector2(3822, 1962),
		Vector2(3822, 1190),
	]
	for i in 2:
		var model: String = regional_models[(i + 2) % regional_models.size()]
		if not Vehicle.has_directional_art(model):
			continue
		var vehicle := AnimatableBody2D.new()
		vehicle.set_script(Vehicle)
		vehicle.name = "EastCircuit_%s" % i
		vehicle.model = model
		vehicle.route_points = circuit
		vehicle.position = Vector2(2842, 1330 + i * 320)
		vehicle.cruise_speed = Vehicle.profile_for(model).speed - 18.0
		vehicle.player = $Player
		add_child(vehicle)

func configure_input() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E],
		"toggle_minimap": [KEY_M],
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
	var spec := Regional.descriptor(building.country_id, asset, index, AssetOrientation.street_facing(pos, roads(), false))
	building.orientation = spec.facing
	building.building_type = spec.type
	building.title = spec.title
	building.access = CityBuilding.Access.ENTERABLE if spec.type in WorldManager.PUBLIC_INTERIORS else CityBuilding.Access.EXTERIOR_ONLY
	building.interior_type = spec.type if spec.type in WorldManager.PUBLIC_INTERIORS else ""
	building.building_id = "%s_front_%d" % [building.country_id, index]
	building.facade = load(spec.path)
	fit_building(building)
	building_bounds.append(building.get_meta("visual_bounds"))
	add_child(building)
	city_objects.append(building)
	occluders.append(building.get_child(0))
	add_building_solid(building)

func add_asset(asset: String, pos: Vector2, size: Vector2, footprint: Rect2, tint := Color.WHITE, facing: String = "south") -> void:
	var prop := Node2D.new()
	prop.name = asset.get_file().capitalize()
	var sprite := Sprite2D.new()
	var path := "res://assets/city/%s.png" % asset
	if asset.begins_with("buildings/") and WorldManager.country.id != "ar":
		path = WorldManager.country.facade
	elif asset == "vegetation/tree":
		path = WorldManager.country.greenery
	if asset == "props/bench":
		path = AssetOrientation.family_path("res://assets/oriented/props/bench", facing)
	if asset.begins_with("vehicles/"):
		var model: String = {"car": "compact", "coupe": "sedan"}.get(asset.get_file(), asset.get_file())
		path = "res://assets/vehicles/%s/%s.png" % [model, Vehicle.source_direction(model, facing)]
	var texture: Texture2D = load(path)
	var used := Vector2(TextureBoundsScript.used(texture).size)
	size = used * minf(size.x / used.x, size.y / used.y)
	pos = valid_prop_position(pos, size, asset.begins_with("vehicles/"), asset == "props/bench")
	if not pos.is_finite():
		prop.free()
		sprite.free()
		return
	prop.position = pos
	prop.set_meta("orientation", facing)
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = TextureBoundsScript.used(sprite.texture)
	sprite.position = Vector2(0, -size.y / 2)
	sprite.scale = size / sprite.region_rect.size
	sprite.modulate = tint
	prop.add_child(sprite)
	if asset == "vegetation/tree":
		add_prop("tree_bed", pos + Vector2(0, 3), Rect2())
	if asset == "props/fountain":
		prop.set_script(Water)
	if asset == "props/bench":
		prop.add_to_group("public_benches")
	if asset == "props/bench" and facing == "south":
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
	# Visibility/occlusion does not need a 60 Hz scan over every facade and tree.
	# Updating at 10 Hz keeps the same visual behaviour while removing hundreds
	# of transforms and rect checks per rendered frame in the expanded district.
	occlusion_clock += delta
	if occlusion_clock < 0.10:
		return
	var elapsed := occlusion_clock
	occlusion_clock = 0.0
	var player: Node2D = $Player
	for sprite in occluders:
		var parent := sprite.get_parent() as Node2D
		var nearby := player.position.distance_squared_to(parent.position) < 1050.0 * 1050.0
		parent.visible = nearby
		if not nearby:
			continue
		var behind: bool = player.position.y < parent.position.y
		var local_head := sprite.to_local(player.position - Vector2(0, 15))
		var covered: bool = behind and sprite.get_rect().has_point(local_head)
		sprite.modulate.a = move_toward(sprite.modulate.a, 0.45 if covered else 1.0, elapsed * 4.0)
		if parent.get_script() == CityBuildingScript:
			parent.modulate.a = 1.0

func build_expansion() -> void:
	var data: DistrictData = WorldManager.district
	var country: CountryData = WorldManager.country
	var index := 0
	for slot in data.building_slots:
		var building := CityBuildingScript.new()
		building.position = slot.position
		building.building_id = country.id + "_building_" + str(index)
		building.is_home = slot.kind == "home"
		var spec: Dictionary
		if slot.has("catalog_index"):
			spec = CountryCatalogScript.descriptor(country.id, int(slot.get("catalog_index", 0)))
		else:
			spec = Regional.descriptor(country.id, slot.kind, int(slot.get("asset_index", index)), slot.facing)
		building.orientation = spec.facing
		building.building_type = spec.type
		building.title = spec.title
		building.country_id = country.id
		building.variant = BuildingVariants.make(country.id, slot.kind, index)
		if spec.has("family"):
			building.variant["family"] = spec.family
			building.variant["height"] = spec.height
		building.interior_type = ""
		if slot.mode == "ENTERABLE":
			if spec.type in WorldManager.PUBLIC_INTERIORS:
				building.interior_type = spec.type
			elif spec.type in ["store", "supermarket"]:
				building.interior_type = "shop"
			elif spec.type in ["bakery", "restaurant", "cafe"]:
				building.interior_type = "cafe"
		building.access = CityBuilding.Access.ENTERABLE if slot.mode == "ENTERABLE" and not building.interior_type.is_empty() else CityBuilding.Access.INTERACTABLE if slot.mode in ["ENTERABLE", "INTERACTABLE"] else CityBuilding.Access.EXTERIOR_ONLY
		building.facade = load(spec.path)
		fit_building(building)
		if not building_visual_valid(building):
			building.free()
			index += 1
			continue
		building_bounds.append(building.get_meta("visual_bounds"))
		add_child(building)
		city_objects.append(building)
		occluders.append(building.get_child(0))
		add_building_solid(building)
		index += 1
func decorate_expansion() -> void:
	var data: DistrictData = WorldManager.district
	var east := data.side_street_x + data.side_street_width + 140
	add_asset("props/fountain", Vector2(east, 1040), Vector2(100, 75), Rect2(-32, -21, 64, 20))
	for p in [
		Vector2(1435, 354), Vector2(1710, 352), Vector2(1990, 650),
		Vector2(2340, 930), Vector2(1480, 1020), Vector2(1720, 950),
		Vector2(110, 1280), Vector2(760, 1280), Vector2(1040, 1280),
		Vector2(3020, 820), Vector2(3420, 940), Vector2(4140, 1520),
		Vector2(4520, 1640), Vector2(3140, 2940), Vector2(760, 3010),
		Vector2(1270, 2260), Vector2(4380, 2310),
	]:
		add_asset("vegetation/tree", p, Vector2(100, 133), Rect2(-9, -9, 18, 13))
	for p in [
		Vector2(east - 80, 1080), Vector2(1650, 930), Vector2(530, 1285),
		Vector2(3060, 910), Vector2(4200, 1590), Vector2(520, 2960),
	]:
		add_asset("props/bench", p, Vector2(58, 43), Rect2(-23, -12, 46, 12))
	for p in [
		Vector2(1460, 380), Vector2(1730, 380), Vector2(2000, 380),
		Vector2(2340, 1040), Vector2(1630, 1110), Vector2(450, 1110),
		Vector2(1080, 1110), Vector2(2710, 1090), Vector2(2910, 1090),
		Vector2(3650, 1870), Vector2(3950, 1870), Vector2(3520, 2630),
		Vector2(4020, 2630), Vector2(1780, 2600),
	]:
		add_asset("props/lamp", p, Vector2(48, 96), Rect2(-4, -4, 8, 8))
	for p in [Vector2(east + 70, 1044), Vector2(3030, 980), Vector2(4440, 1700), Vector2(820, 3050)]:
		add_asset("props/planter", p, Vector2(48, 36), Rect2(-18, -10, 36, 12))

func populate() -> void:
	var system := Node.new()
	system.name = "PopulationSystem"
	system.set_script(preload("res://scripts/population_system.gd"))
	add_child(system)
	var routes: Array = [
		[Vector2(340, 373), Vector2(462, 373), Vector2(462, 355), Vector2(340, 355)],
		[Vector2(200, 608), Vector2(490, 608), Vector2(490, 626), Vector2(200, 626)],
		[Vector2(1120, 370), Vector2(1300, 370), Vector2(1300, 350), Vector2(1120, 350)],
		[Vector2(1490, 362), Vector2(1640, 362), Vector2(1640, 382), Vector2(1490, 382)],
		[Vector2(358, 630), Vector2(401, 684), Vector2(463, 751), Vector2(500, 813), Vector2(552, 873), Vector2(500, 813), Vector2(463, 751), Vector2(401, 684)],
	]
	# Populate every quarter of the expanded city. Routes are deliberately
	# short local loops so residents look like they belong to a block instead
	# of marching across the whole map in straight lines.
	var block_x := [300.0, 1320.0, 2260.0, 3260.0, 4260.0]
	var block_y := [300.0, 830.0, 1530.0, 2290.0, 3010.0]
	for y in block_y:
		if y > map_size.y - 120:
			continue
		for x in block_x:
			if x > map_size.x - 180:
				continue
			routes.append([
				Vector2(x, y),
				Vector2(x + 150, y),
				Vector2(x + 150, y + 58),
				Vector2(x + 24, y + 58),
			])
	var benches := get_tree().get_nodes_in_group("city_benches")
	if not benches.is_empty():
		var seat: Vector2 = benches[0].position + Vector2(0, 2)
		routes.append([seat, seat + Vector2(0, 28), seat + Vector2(70, 28), seat + Vector2(0, 28)])
	for i in WorldManager.district.population:
		var walker := Node2D.new()
		walker.set_script(Walker)
		walker.route.assign(routes[i % routes.size()])
		walker.position = walker.route[0] + Vector2(int(i / routes.size()) * 18, 0)
		walker.speed = 58.0 + (i % 6) * 6
		walker.profile = PlayerProfile.new()
		walker.profile.gender = "female" if i % 2 else "male"
		walker.profile.skin = i % 3
		walker.profile.hair = int(i / 2) % 3
		walker.profile.hair_color = int(i / 3) % 3
		walker.profile.top = (i + 1) % 3
		walker.profile.bottom = int(i / 2) % 3
		walker.route_kind = "bench" if i == WorldManager.district.population - 1 else "shop" if i % 9 == 0 else "crossing" if i % 11 == 0 else "walk"
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
	var used := TextureBoundsScript.used(building.facade).size
	var catalog := building.variant.has("family")
	var max_width := 170.0 if catalog else 190.0
	var max_height := float(building.variant.get("height", 238.0)) if catalog else 238.0
	if building.building_type == "kiosk":
		max_width = 132.0
		max_height = 170.0
	for road in roads():
		if road.size.x > 1000 and road.end.y < building.position.y:
			max_height = minf(max_height, building.position.y - road.end.y - 24)
		if road.size.y > 1000:
			var clearance := road.position.x - building.position.x if building.position.x < road.position.x else building.position.x - road.end.x
			max_width = minf(max_width, (clearance - 14) * 2)
	if building.position.x > 1030 and building.position.x < 1400 and building.position.y == 1060:
		max_height = minf(max_height, 130)
	var factor: float = minf(max_width / used.x, max_height / used.y)
	if building.building_type == "kiosk":
		factor = minf(factor, 128.0 / building.facade.get_size().x)
	building.size = building.facade.get_size() * factor
	var normal := AssetOrientation.vector(building.orientation)
	var width := used.x * factor
	var depth := minf(64.0, used.y * factor * 0.32)
	building.footprint = Rect2(Vector2(-width * 0.46, -depth), Vector2(width * 0.92, depth - 4))
	if normal.y > 0.3:
		building.door_offset = Vector2(normal.x * width * 0.22, 16)
	elif normal.y < -0.3:
		building.door_offset = Vector2(normal.x * width * 0.22, -depth - 16)
	else:
		building.door_offset = Vector2(normal.x * (width * 0.46 + 16), -depth * 0.5)
	building.set_meta("visual_bounds", Rect2(building.position - Vector2(used.x * factor / 2, used.y * factor), Vector2(used) * factor))

func building_visual_valid(building: CityBuilding) -> bool:
	var bounds: Rect2 = building.get_meta("visual_bounds")
	if not Rect2(Vector2(18, 18), map_size - Vector2(36, 36)).encloses(bounds):
		return false
	for existing in building_bounds:
		if bounds.intersects(existing.grow(5)):
			return false
	for road in roads():
		if bounds.intersects(road.grow(2)):
			return false
	return true

func texture_used_rect(texture: Texture2D) -> Rect2:
	return TextureBoundsScript.used(texture)

func add_building_solid(building: CityBuilding) -> void:
	if building.access != CityBuilding.Access.EXTERIOR_ONLY:
		entrance_clearance.append(Rect2(building.position + building.door_offset - Vector2(24, 18), Vector2(48, 40)))
	add_solid(Rect2(building.position + building.footprint.position, building.footprint.size))

func roads() -> Array[Rect2]:
	return road_cache

func valid_prop_position(at: Vector2, size: Vector2, parked: bool = false, bench: bool = false) -> Vector2:
	# Benches are public-space furniture: never nudge them beside a facade just
	# to force placement. Invalid authored seats are omitted instead.
	var offsets := [Vector2.ZERO]
	if not parked and not bench:
		for distance in [32, 64, 96, 128]:
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
				offsets.append(direction * distance)
	for offset in offsets:
		var candidate: Vector2 = at + offset
		var visual := Rect2(candidate - Vector2(size.x / 2, size.y), size)
		var base := Rect2(candidate - Vector2(size.x / 2, 16), Vector2(size.x, 20))
		if not Rect2(Vector2(20, 20), map_size - Vector2(40, 40)).encloses(visual):
			continue
		if bench and not bench_zone().any(func(zone: Rect2): return zone.encloses(base.grow(12))):
			continue
		var valid := true
		if not parked:
			for bounds in entrance_clearance:
				if base.grow(12).intersects(bounds):
					valid = false
		for bounds in building_bounds:
			if visual.intersects(bounds.grow(8)):
				valid = false
		for road in roads():
			if base.intersects(road.grow(8)):
				valid = false
		for bounds in protected_content:
			if visual.intersects(bounds):
				valid = false
		for bounds in placed_prop_bounds:
			if base.intersects(bounds.grow(5)):
				valid = false
		if valid:
			placed_prop_bounds.append(base)
			return candidate
	return Vector2(INF, INF)

func bench_zone() -> Array[Rect2]:
	return [
		Rect2(72, 620, 720, 330),
		Rect2(2980, 650, 520, 360),
		Rect2(4040, 1370, 500, 350),
		Rect2(350, 2820, 560, 300),
	]

func integrate_argentina() -> void:
	# Argentine identity is distributed across the district instead of being
	# compressed into one plaza.
	add_asset("props/ar/choripan_stand", Vector2(3270, 1710), Vector2(84, 78), Rect2(-32, -18, 64, 18))
	add_asset("props/ar/parrilla", Vector2(4240, 1030), Vector2(92, 84), Rect2(-34, -20, 68, 20))

	var stop := Node2D.new()
	stop.set_script(CityProp)
	stop.kind = "transport_stop"
	stop.position = Vector2(1420, 600)
	stop.set_meta("building_type", "transport_stop")
	stop.set_meta("orientation", "south")
	add_child(stop)
	add_solid(Rect2(stop.position + Vector2(-3, -8), Vector2(6, 8)))

	# Full neighbourhood football ground. It fills the large civic block
	# between two avenues and is no longer a miniature decoration.
	var pitch := Node2D.new()
	pitch.name = "Cancha Municipal"
	pitch.set_script(preload("res://scripts/regional_content.gd"))
	pitch.position = Vector2(1945, 2050)
	pitch.z_index = -2
	pitch.set_meta("building_type", "sports")
	add_child(pitch)
	protected_content.append(Rect2(1935, 2038, 820, 600))
	var football_target := preload("res://scripts/interaction_target.gd").new()
	football_target.position = Vector2(400, 548)
	football_target.label = "Jugar un rato a la pelota"
	football_target.action = "play_football"
	football_target.target_id = "cancha_barrio_del_sol"
	pitch.add_child(football_target)

	for food_name in ["Choripan Stand", "Parrilla"]:
		var stand := get_node(NodePath(food_name)) as Node2D
		protected_content.append(stand.get_meta("placement_bounds"))
		var target := preload("res://scripts/interaction_target.gd").new()
		target.position = Vector2(0, 18)
		target.label = "Comprar choripán" if food_name == "Choripan Stand" else "Comer en la parrilla"
		target.action = "buy_food"
		stand.add_child(target)

	# Keep the bus behaviour that already feels right, but let the second line
	# serve the expanded eastern neighbourhood.
	for i in 2:
		var bus := Vehicle.new()
		bus.name = "Colectivo" if i == 0 else "Colectivo2"
		bus.model = "colectivo"
		if i == 0:
			var east_lane := WorldManager.district.side_street_x + WorldManager.district.side_street_width * 0.25
			bus.route_points.assign([Vector2(958, 1160), Vector2(958, 512), Vector2(east_lane, 512), Vector2(east_lane, 1160)])
			bus.position = Vector2(1450, 512)
		else:
			bus.route_points.assign([Vector2(2842, 1190), Vector2(2842, 1962), Vector2(3822, 1962), Vector2(3822, 1190)])
			bus.position = Vector2(2842, 1510)
		bus.direction = 1.0
		bus.cruise_speed = Vehicle.profile_for("colectivo").speed
		bus.player = $Player
		add_child(bus)

	add_local_resident("Tito", Vector2(3310, 1740), "eat")
	add_local_resident("Luli", Vector2(1460, 610), "phone")
	for i in 4:
		var walker := Walker.new()
		walker.route.assign([
			Vector2(2060 + i * 135, 2290),
			Vector2(2210 + i * 110, 2440),
			Vector2(2130 + i * 120, 2550),
		])
		walker.position = walker.route[0]
		walker.speed = 50 + i * 5
		walker.route_kind = "football"
		walker.profile = PlayerProfile.new()
		walker.profile.gender = "female" if i % 2 else "male"
		walker.profile.top = i % 3
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
	# Regional identity is distributed through several neighbourhoods instead of
	# living only beside the starting plaza.
	match WorldManager.country.id:
		"br":
			for p in [Vector2(615, 376), Vector2(3180, 1090), Vector2(4210, 1875)]:
				add_asset("props/br/moto", p, Vector2(42, 36), Rect2(-16, -10, 32, 10))
		"it":
			for p in [Vector2(615, 376), Vector2(2450, 1880), Vector2(4140, 2650)]:
				add_asset("props/it/scooter", p, Vector2(42, 36), Rect2(-16, -10, 32, 10))
		"jp":
			for p in [Vector2(772, 378), Vector2(3130, 1100), Vector2(4070, 1880)]:
				add_asset("props/jp/vending_machine", p, Vector2(30, 49), Rect2(-13, -12, 26, 12))
			for p in [Vector2(630, 376), Vector2(3330, 1100), Vector2(4320, 2650)]:
				add_asset("props/jp/bicycle", p, Vector2(42, 30), Rect2(-16, -8, 32, 8))
		"us":
			for p in [Vector2(3180, 1840), Vector2(4290, 2600)]:
				add_asset("vehicles/pickup", p, Vector2(104, 67), Rect2(-40, -18, 80, 18), Color.WHITE, "east")
