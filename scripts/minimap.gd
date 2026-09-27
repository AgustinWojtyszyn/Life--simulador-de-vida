extends Control

var world: Node2D
var expanded := false
var refresh_clock := 0.0

func _ready() -> void:
	add_to_group("city_minimap")
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	gui_input.connect(_on_gui_input)
	get_viewport().size_changed.connect(layout)
	layout()
	queue_redraw()

func layout() -> void:
	var viewport := get_viewport_rect().size
	var safe := InputManager.safe_rect(viewport)
	var scale_factor := clampf(minf(viewport.x / 800.0, viewport.y / 450.0), 1.0, 1.35)
	var compact := Vector2(176, 120) * scale_factor
	var large := Vector2(350, 230) * scale_factor
	size = large if expanded else compact
	var margin := 18.0 * scale_factor
	position = Vector2(safe.end.x - size.x - margin, safe.position.y + 78.0 * scale_factor)
	queue_redraw()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.12:
		return
	refresh_clock = 0.0
	if is_instance_valid(world):
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_minimap"):
		toggle_size()
		get_viewport().set_input_as_handled()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_size()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		toggle_size()
		accept_event()

func toggle_size() -> void:
	expanded = not expanded
	layout()

func world_to_map(point: Vector2, inner: Rect2) -> Vector2:
	var map_size: Vector2 = WorldManager.district.world_size
	var scale := minf(inner.size.x / map_size.x, inner.size.y / map_size.y)
	var drawn := map_size * scale
	var origin := inner.position + (inner.size - drawn) * 0.5
	return origin + point * scale

func rect_to_map(rect: Rect2, inner: Rect2) -> Rect2:
	var a := world_to_map(rect.position, inner)
	var b := world_to_map(rect.end, inner)
	return Rect2(a, b - a)

func _draw() -> void:
	if not is_instance_valid(world):
		return
	var font := ThemeDB.fallback_font
	var panel := Rect2(Vector2.ZERO, size)
	draw_style_box(panel_style(), panel)
	draw_string(font, Vector2(10, 16), "MAPA · " + WorldManager.district.title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 10, Color("e8dcc2"))
	var inner := Rect2(8, 23, size.x - 16, size.y - 31)
	draw_rect(inner, Color(0.08, 0.13, 0.14, 0.96))
	var world_rect := Rect2(Vector2.ZERO, WorldManager.district.world_size)
	var mapped_world := rect_to_map(world_rect, inner)
	draw_rect(mapped_world, Color("b8b39e"))
	for road in DistrictBlocks.roads(WorldManager.district):
		draw_rect(rect_to_map(road, inner), Color("43505a"))
	for object in world.city_objects:
		if not object.has_meta("building_type"):
			continue
		var p := world_to_map(object.position, inner)
		var kind := str(object.get_meta("building_type"))
		var color := Color("c9b27c") if kind.begins_with("residential") else Color("ddb573")
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), color)
	for traffic_light in get_tree().get_nodes_in_group("traffic_signals"):
		if not is_instance_valid(traffic_light):
			continue
		var p := world_to_map(traffic_light.global_position, inner)
		var color := Color("72bd79") if traffic_light.horizontal_state == "green" else Color("dc6b60")
		draw_circle(p, 1.7 if not expanded else 2.2, color)
	for vehicle in get_tree().get_nodes_in_group("city_traffic"):
		if not is_instance_valid(vehicle):
			continue
		var p := world_to_map(vehicle.global_position, inner)
		draw_circle(p, 1.4 if not expanded else 2.0, Color("e7c36e"))
	var home := world_to_map(WorldManager.district.home_position, inner)
	draw_circle(home, 2.4 if not expanded else 3.4, Color("df9d70"))
	var player := world.get_node_or_null("Player") as Node2D
	if is_instance_valid(player):
		var p := world_to_map(player.global_position, inner)
		draw_circle(p, 3.0 if not expanded else 4.4, Color("8ad4d0"))
		draw_arc(p, 5.0 if not expanded else 7.0, 0, TAU, 18, Color(0.9, 1.0, 0.96, 0.75), 1.0)

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.12, 0.14, 0.94)
	style.border_color = Color("6b756f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style
