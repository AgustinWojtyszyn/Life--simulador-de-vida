## Interior de la Sede Central de Nexovial S.A.
## Reutiliza todos los helpers de ShopInterior (furniture, add_solid, add_resident, etc.)
## pero controla qué interacciones tienen sentido en contexto laboral.
## NOTA: Se accede como WorldManager.location == "office" usando el sistema existente.
extends Node2D

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")
const ShopScript := preload("res://scripts/shop_interior.gd")

# Apunta a los interaction targets clave del escenario.
var _telefono_target: Node2D = null
var _supervisor_target: Node2D = null
var _scenario_banner_visible := false

func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Player/Camera2D.limit_right = 800
	$Player/Camera2D.limit_bottom = 450

	# ── Walls ────────────────────────────────────────────────────────────────
	for wall in [
		Rect2(86, 64, 628, 16), Rect2(86, 388, 628, 16),
		Rect2(86, 64, 16, 340), Rect2(698, 64, 16, 340),
	]:
		_add_solid(wall)

	# ── Recepción ────────────────────────────────────────────────────────────
	_furniture("reception", Vector2(240, 170), Vector2(200, 72),
			Rect2(148, 141, 184, 26), "south")
	add_target(Vector2(246, 210), "Retirar documentos (Obj. 1)", "nexovial_pickup_docs", "recepcion")
	_add_resident("reception", "Recepción", Vector2(242, 126), true)

	# ── Área de registro ─────────────────────────────────────────────────────
	_furniture("desk", Vector2(420, 240), Vector2(90, 92),
			Rect2(384, 205, 72, 26), "south-east")
	_furniture("desk", Vector2(555, 240), Vector2(90, 92),
			Rect2(519, 205, 72, 26), "south-west")
	add_target(Vector2(420, 275), "Registrar y verificar datos (Obj. 2)", "nexovial_register_docs", "registro")
	_add_resident("coworker", "Compañero", Vector2(555, 200), false)

	# ── Supervisor ───────────────────────────────────────────────────────────
	_furniture("desk", Vector2(620, 300), Vector2(100, 92),
			Rect2(578, 265, 84, 26), "south-west")
	_supervisor_target = add_target(Vector2(620, 335), "Reportar al supervisor (Obj. 3)", "nexovial_report_supervisor", "supervisor")
	_add_resident("supervisor", "Supervisor", Vector2(622, 250), true)

	# ── Teléfono (para resolver el escenario) ────────────────────────────────
	_furniture("shelf", Vector2(660, 160), Vector2(62, 62),
			Rect2(634, 140, 52, 18), "south-west")
	_telefono_target = add_target(Vector2(650, 195), "Llamar al cliente", "nexovial_phone_client", "telefono")

	# ── Sofá / sala de espera ────────────────────────────────────────────────
	_furniture("sofa_front", Vector2(200, 330), Vector2(120, 70),
			Rect2(148, 307, 104, 20), "south-east")

	# ── Salida ───────────────────────────────────────────────────────────────
	add_target(Vector2(390, 359), "Salir al barrio", "exit_interior", "exit")

	# ── Turno / inicio de turno ──────────────────────────────────────────────
	# El jugador debe estar cerca de la entrada para iniciar o finalizar turno.
	add_target(Vector2(390, 375), _shift_label(), "nexovial_shift_toggle", "entrada")

	# ── HUD & Interactions ───────────────────────────────────────────────────
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

	# Observe shift changes to update labels.
	ShiftSystem.changed.connect(_on_shift_changed)

func _shift_label() -> String:
	if ShiftSystem.active:
		return "Finalizar turno"
	return "Iniciar turno"

func _on_shift_changed() -> void:
	# Refresh the shift toggle target label.
	for child in get_children():
		if child is InteractionTarget and child.target_id == "entrada":
			child.label = _shift_label()
			break
	queue_redraw()

func add_target(at: Vector2, label_text: String, action_id: String, id: String) -> Node2D:
	var point := InteractionTargetScript.new()
	point.position = at
	point.label = label_text
	point.action = action_id
	point.target_id = id
	point.detail = "Nexovial S.A."
	add_child(point)
	return point

func _add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _furniture(asset: String, at: Vector2, size: Vector2, footprint: Rect2, facing := "south-east") -> void:
	var node := Node2D.new()
	node.position = at
	node.set_meta("orientation", facing)
	node.set_meta("interior_asset", asset)
	var sprite := Sprite2D.new()
	var tex_path := "res://assets/interior/%s.png" % asset
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.region_enabled = true
		sprite.region_rect = sprite.texture.get_image().get_used_rect()
		sprite.scale = size / sprite.region_rect.size
		sprite.position.y = -sprite.region_rect.size.y * sprite.scale.y / 2
		sprite.flip_h = facing in ["south-west", "west", "north-west"]
	node.add_child(sprite)
	add_child(node)
	_add_solid(footprint)

func _add_resident(id: String, title: String, at: Vector2, employee: bool) -> void:
	var walker := preload("res://scripts/city_walker.gd").new()
	walker.position = at
	walker.route.assign([at, at + Vector2(16, 0), at + Vector2(16, 8), at + Vector2(0, 8)])
	walker.profile = PlayerProfile.new()
	walker.profile.gender = "male" if employee else "female"
	walker.speed = 10
	walker.set_meta("person_id", id)
	walker.set_meta("person_name", title)
	add_child(walker)

func _draw() -> void:
	var accent := Color("2d6a8a")   # Nexovial brand: steel blue
	draw_rect(Rect2(0, 0, 800, 450), Color("172d31"))
	draw_rect(Rect2(86, 64, 628, 340), Color("d5c3a5"))
	draw_rect(Rect2(102, 80, 596, 308), Color("8d7762"))
	# Floor tiles
	for y in range(80, 388, 24):
		for x in range(102, 698, 36):
			draw_rect(
				Rect2(x + (12 if y % 48 else 0), y, 35, 23)
					.intersection(Rect2(102, 80, 596, 308)),
				Color("9b9b8a") if x % 3 else Color("a0a090")
			)
	# Header bar
	draw_rect(Rect2(109, 82, 582, 29), accent)
	draw_string(ThemeDB.fallback_font, Vector2(230, 103), "NEXOVIAL S.A. · SEDE CENTRAL",
			HORIZONTAL_ALIGNMENT_CENTER, 340, 17, Color("f0ece0"))
	# Divider between reception and work area
	draw_rect(Rect2(330, 82, 2, 308), Color("607070", 0.6))
	# Zone labels
	draw_string(ThemeDB.fallback_font, Vector2(110, 125), "RECEPCIÓN",
			HORIZONTAL_ALIGNMENT_LEFT, 200, 10, Color("38596c"))
	draw_string(ThemeDB.fallback_font, Vector2(360, 125), "ÁREA DE REGISTRO",
			HORIZONTAL_ALIGNMENT_LEFT, 200, 10, Color("38596c"))
	draw_string(ThemeDB.fallback_font, Vector2(540, 125), "SUPERVISIÓN",
			HORIZONTAL_ALIGNMENT_LEFT, 150, 10, Color("38596c"))
	# Exit sign
	draw_rect(Rect2(365, 381, 50, 12), Color("d6ba8b"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 378), "SALIDA",
			HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color("f1e2c5"))
	# Shift status banner (HUD supplement)
	if ShiftSystem.active:
		var obj := ShiftSystem.current_objective()
		var banner := Rect2(102, 398, 596, 28)
		draw_rect(banner, Color("1a3a30", 0.92))
		draw_string(ThemeDB.fallback_font, banner.position + Vector2(8, 19),
				"TURNO ACTIVO · " + obj, HORIZONTAL_ALIGNMENT_LEFT,
				580, 11, Color("90d4a0"))
	# Scenario alert
	if ShiftSystem.active_scenario() != null:
		var sc: ScenarioData = ShiftSystem.active_scenario()
		var alert := Rect2(102, 82, 596, 32)
		draw_rect(alert, Color("7a2020", 0.95))
		draw_string(ThemeDB.fallback_font, alert.position + Vector2(8, 22),
				"⚠ SITUACIÓN: " + sc.title, HORIZONTAL_ALIGNMENT_LEFT,
				580, 13, Color("ffd0a0"))
