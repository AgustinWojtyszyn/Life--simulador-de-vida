extends Node2D

const MAP_SIZE := Vector2(1440, 960)
const CityProp := preload("res://scripts/city_prop.gd")
const Ground := preload("res://scripts/city_ground.gd")
const Walker := preload("res://scripts/city_walker.gd")
const Vehicle := preload("res://scripts/city_vehicle.gd")
const Interactions := preload("res://scripts/city_interactions.gd")
const Water := preload("res://scripts/fountain_water.gd")
const Hud := preload("res://scripts/city_hud.gd")
# World-space footprints are independent of sprite height; sorting uses the feet.
var solid_rects: Array[Rect2] = []
var city_objects: Array[Node2D] = []
var occluders: Array[Sprite2D] = []
# Two active lanes. Vehicles recycle beyond camera limits; parked cars stay solid.
const TRAFFIC_LANES := [
	{"from": Vector2(-140, 454), "to": Vector2(1580, 454), "direction": Vector2.RIGHT},
	{"from": Vector2(1580, 512), "to": Vector2(-140, 512), "direction": Vector2.LEFT},
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	configure_input()
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
	for rect in [Rect2(0, 0, 1440, 16), Rect2(0, 944, 1440, 16),
		Rect2(0, 0, 16, 960), Rect2(1424, 0, 16, 960)]:
		add_solid(rect)
	# Northern commercial frontage, a side street, and a second block.
	add_asset("buildings/cafe", Vector2(195, 318), Vector2(230, 268), Rect2(-87, -64, 166, 58))
	add_asset("buildings/market", Vector2(445, 320), Vector2(220, 220), Rect2(-83, -58, 160, 53))
	add_asset("buildings/cafe", Vector2(704, 315), Vector2(230, 268), Rect2(-87, -64, 166, 58), Color("e3d3c8"))
	add_asset("buildings/market", Vector2(1168, 324), Vector2(264, 264), Rect2(-100, -70, 193, 64))
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
	for route in [Vector4(340, 373, 462, 373), Vector4(200, 608, 490, 608), Vector4(1120, 370, 1300, 370)]:
		var walker := Node2D.new()
		walker.set_script(Walker)
		walker.start = Vector2(route.x, route.y)
		walker.finish = Vector2(route.z, route.w)
		walker.position = walker.start
		walker.modulate = Color("d6c7ac")
		add_child(walker)
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

func add_asset(asset: String, pos: Vector2, size: Vector2, footprint: Rect2, tint := Color.WHITE) -> void:
	var prop := Node2D.new()
	prop.name = asset.get_file().capitalize()
	prop.position = pos
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/city/%s.png" % asset)
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
