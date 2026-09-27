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
	draw_string(font, Vector2(10, 16), "MAPA · " + WorldManager.district.title.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 10, Color("e8dcc2"))
	var inner := Rect2(8, 23, size.x - 16, size.y - 31)
	draw_rect(inner, Color(0.08, 0.13, 0.14, 0.96))
	var world_rect := Rect2(Vector2.ZERO, WorldManager.district.world_size)
	var mapped_world := rect_to_map(world_rect, inner)
	draw_rect(mapped_world, Color("9fa89a"))  # slightly warmer ground
	# Roads
	for road in DistrictBlocks.roads(WorldManager.district):
		draw_rect(rect_to_map(road, inner), Color("34404a"))
	# Buildings with color-coded types
	for object in world.city_objects:
		if not object.has_meta("building_type"):
			continue
		var p := world_to_map(object.position, inner)
		var kind := str(object.get_meta("building_type"))
		var col: Color
		var poi_label := ""
		if kind.contains("cafe") or kind.contains("coffee"):
			col = Color("d9995a")
			poi_label = "CAFÉ"
		elif kind.contains("market") or kind.contains("shop") or kind.contains("mercado"):
			col = Color("5aaed9")
			poi_label = "ALMACÉN" if kind.contains("market") else "TIENDA"
		elif kind.contains("clinic") or kind.contains("hospital"):
			col = Color("e05050")
			poi_label = "CLÍNICA"
		elif kind.contains("bakery") or kind.contains("panaderia"):
			col = Color("e0a040")
			poi_label = "PANADERÍA"
		elif kind.contains("office"):
			col = Color("708090")
		elif kind.begins_with("residential"):
			col = Color("c9b27c")
		else:
			col = Color("9d8a6e")
		var dot_size := 2.0 if not expanded else 3.0
		draw_rect(Rect2(p - Vector2(dot_size, dot_size), Vector2(dot_size * 2, dot_size * 2)), col)
		# Show POI labels only when expanded and near player
		if expanded and poi_label != "" and is_instance_valid(world.get_node_or_null("Player")):
			var player_node_for_poi := world.get_node("Player") as Node2D
			var player_p: Vector2 = player_node_for_poi.global_position
			if object.position.distance_to(player_p) < 600:
				draw_string(font, p + Vector2(4, 4), poi_label, HORIZONTAL_ALIGNMENT_LEFT, 60, 7, col)
	# Traffic signals
	for traffic_light in get_tree().get_nodes_in_group("traffic_signals"):
		if not is_instance_valid(traffic_light):
			continue
		var p := world_to_map(traffic_light.global_position, inner)
		var tl_col := Color("72bd79") if traffic_light.horizontal_state == "green" else \
			(Color("e8c840") if traffic_light.horizontal_state == "amber" else Color("dc6b60"))
		draw_circle(p, 1.8 if not expanded else 2.5, tl_col)
	# Vehicles
	for vehicle in get_tree().get_nodes_in_group("city_traffic"):
		if not is_instance_valid(vehicle):
			continue
		var p := world_to_map(vehicle.global_position, inner)
		draw_circle(p, 1.2 if not expanded else 1.8, Color("e7c36e"))
	# NPC walkers (expanded only)
	if expanded:
		for walker in get_tree().get_nodes_in_group("city_residents"):
			if not is_instance_valid(walker):
				continue
			var p := world_to_map(walker.global_position, inner)
			draw_circle(p, 1.0, Color("b0c8a0", 0.7))
	# Home marker
	var home := world_to_map(WorldManager.district.home_position, inner)
	draw_circle(home, 2.6 if not expanded else 3.8, Color("df9d70"))
	draw_string(font, home + Vector2(4, 4), "🏠", HORIZONTAL_ALIGNMENT_LEFT, 16, 8, Color("df9d70"))
	# Player dot — directional arrow
	var player_node := world.get_node_or_null("Player") as Node2D
	if is_instance_valid(player_node):
		var p := world_to_map(player_node.global_position, inner)
		draw_circle(p, 3.2 if not expanded else 5.0, Color("8ad4d0"))
		draw_arc(p, 5.5 if not expanded else 8.0, 0, TAU, 20, Color(0.9, 1.0, 0.96, 0.8), 1.2)
	# Legend (expanded)
	if expanded:
		var ly := inner.end.y - 28
		var lx := inner.position.x + 4
		var legend_items := [
			[Color("8ad4d0"), "Jugador"],
			[Color("df9d70"), "Casa"],
			[Color("d9995a"), "Café"],
			[Color("5aaed9"), "Tienda"],
			[Color("e05050"), "Clínica"],
		]
		for item in legend_items:
			draw_circle(Vector2(lx + 3, ly + 3), 2.5, item[0])
			draw_string(font, Vector2(lx + 9, ly + 6), str(item[1]), HORIZONTAL_ALIGNMENT_LEFT, 55, 7, Color("c8c0b0"))
			lx += 68

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.10, 0.12, 0.95)
	style.border_color = Color("4a5a52")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
