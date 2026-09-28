extends CanvasLayer

var panel: PanelContainer
var body: VBoxContainer
var opened := false
var journal_button: Button

func _ready() -> void:
	layer = 24
	journal_button = Button.new()
	journal_button.text = "Mi vida"
	journal_button.custom_minimum_size = Vector2(118, 48) if InputManager.touch_enabled else Vector2(104, 40)
	journal_button.add_theme_font_size_override("font_size", 18 if InputManager.touch_enabled else 15)
	journal_button.pressed.connect(func():
		AudioSystem.play_ui()
		show_journal())
	add_child(journal_button)

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style())
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	panel.hide()
	get_viewport().size_changed.connect(layout_panel)
	layout_panel()

func layout_panel() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var safe := InputManager.safe_rect(viewport)
	var width := minf(640.0, safe.size.x - 40.0)
	var height := minf(330.0, safe.size.y - 56.0)
	if InputManager.touch_enabled:
		width = minf(690.0, safe.size.x - 32.0)
		height = minf(360.0, safe.size.y - 40.0)
	panel.custom_minimum_size = Vector2(maxf(280.0, width), maxf(190.0, height))
	panel.size = panel.custom_minimum_size
	panel.position = safe.get_center() - panel.size / 2.0
	journal_button.position = safe.position + Vector2(20, 96)
	journal_button.visible = not InputManager.touch_enabled

func clear_panel() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	panel.show()
	opened = true
	get_tree().paused = true
	InputManager.reset()

func text_line(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = maxf(240.0, panel.size.x - 48.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18 if InputManager.touch_enabled else 16)
	body.add_child(label)
	return label

func action(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 54 if InputManager.touch_enabled else 42
	button.add_theme_font_size_override("font_size", 18 if InputManager.touch_enabled else 15)
	button.pressed.connect(func():
		AudioSystem.play_ui()
		callback.call())
	body.add_child(button)

func close() -> void:
	panel.hide()
	opened = false
	get_tree().paused = false
	InputManager.reset()

func show_journal() -> void:
	if opened:
		close()
		return
	clear_panel()
	text_line("%s · %s · %s" % [WorldManager.profile.player_name, GameClock.display(), GameClock.period()])
	text_line("$%d   Energía %d/100   Bienestar %d/100   Reputación %d" % [LifeSimulation.money, LifeSimulation.energy, LifeSimulation.wellbeing, LifeSimulation.reputation])
	text_line("Inventario: %d provisiones" % int(LifeSimulation.inventory.get("food", 0)))
	text_line(MissionSystem.INTRO.title + "\n" + MissionSystem.objective())
	# ── Estado laboral (compacto) ─────────────────────────────────────────
	if EmploymentSystem.employed:
		var work_line := "TRABAJO · " + EmploymentSystem.role_title() + " — " + EmploymentSystem.company_name()
		if ShiftSystem.active:
			work_line += "\nTurno activo · Obj: " + ShiftSystem.current_objective()
		text_line(work_line)
	# ─────────────────────────────────────────────────────────────────────
	var music_label := text_line("Banda sonora · ♫ " + AudioSystem.track_name())
	action("♫ Canción anterior", func():
		AudioSystem.previous_track()
		music_label.text = "Banda sonora · ♫ " + AudioSystem.track_name())
	action("♫ Siguiente canción", func():
		AudioSystem.next_track()
		music_label.text = "Banda sonora · ♫ " + AudioSystem.track_name())
	action("Volver al barrio", close)

func talk(person: String) -> void:
	clear_panel()
	var dialogue := MissionSystem.dialogue(person)
	text_line(dialogue.text)
	for option in dialogue.options:
		action(option[0], func():
			if option[1] != "close":
				var message := MissionSystem.choose(option[1])
				WorldManager.active_world.get_node("Interactions").say(message)
			close())




static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("192e34")
	style.border_color = Color("a48b62")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

# ── B2B: empleo ──────────────────────────────────────────────────────────────

## Muestra diálogo para aceptar el primer empleo.
func show_hire_dialogue(company_id: String, workplace_id: String, role_id: String) -> void:
	clear_panel()
	var cat: Node = get_node_or_null("/root/CompanyCatalog")
	var company_name := company_id
	var role_title := role_id
	if cat != null:
		var company := cat.find_company(company_id)
		var role := cat.find_role(company_id, workplace_id, role_id)
		if company != null:
			company_name = company.display_name
		if role != null:
			role_title = role.title
	text_line("NEXOVIAL S.A. · Consulta de empleo")
	text_line("Puesto disponible: " + role_title)
	text_line("Sueldo por turno: $" + str(cat.find_role(company_id, workplace_id, role_id).base_salary if cat != null and cat.find_role(company_id, workplace_id, role_id) != null else "?"))
	text_line("Turno: 09:00 – 13:00 · Sede Central, Centro")
	action("Aceptar empleo", func():
		var ok := EmploymentSystem.hire(company_id, workplace_id, role_id)
		close()
		if is_instance_valid(WorldManager.active_world):
			var interactions: Node = WorldManager.active_world.get_node_or_null("Interactions")
			if interactions != null:
				interactions.say("¡Bienvenido a " + company_name + "! Iniciá tu turno en la entrada." if ok else "No se pudo procesar el empleo.")
	)
	action("Ahora no", close)

## Muestra el estado laboral actual.
func show_work_status() -> void:
	clear_panel()
	if not EmploymentSystem.employed:
		text_line("No tenés empleo actualmente.")
		action("Cerrar", close)
		return
	text_line("TRABAJO")
	text_line(EmploymentSystem.role_title() + " — " + EmploymentSystem.company_name())
	if ShiftSystem.active:
		text_line("Turno activo")
		text_line("Objetivo: " + ShiftSystem.current_objective())
	else:
		text_line("Sin turno activo · Iniciá el turno en la entrada")
	text_line("Experiencia: " + str(EmploymentSystem.work_experience) + " · Reputación laboral: " + str(EmploymentSystem.work_reputation))
	action("Cerrar", close)

## Muestra el resultado del turno finalizado.
func show_shift_result(result: Dictionary) -> void:
	if result.is_empty():
		return
	clear_panel()
	text_line("TURNO COMPLETADO")
	text_line("Pago: $" + str(result.get("pay", 0)))
	text_line("Experiencia: +" + str(result.get("experience", 0)))
	var rep: int = result.get("reputation", 0)
	text_line("Reputación: " + ("+" if rep >= 0 else "") + str(rep))
	var done: int = result.get("objectives_done", 0)
	var total: int = result.get("objectives_total", 1)
	text_line("Objetivos: %d / %d" % [done, total])
	action("Cerrar", close)

