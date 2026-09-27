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
