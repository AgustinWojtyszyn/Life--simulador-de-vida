extends CanvasLayer

var panel: PanelContainer
var body: VBoxContainer
var opened := false
var journal_button: Button

func _ready() -> void:
	layer = 24
	var button := Button.new()
	journal_button = button
	button.text = "Mi vida"
	button.position = Vector2(18, 80)
	button.custom_minimum_size = Vector2(92, 48)
	button.pressed.connect(show_journal)
	add_child(button)
	panel = PanelContainer.new()
	panel.add_theme_font_size_override("font_size", 16)
	panel.add_theme_stylebox_override("panel", panel_style())
	add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	get_viewport().size_changed.connect(layout_panel)
	layout_panel()
	panel.hide()

func clear_panel() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	panel.show()
	opened = true
	get_tree().paused = true
	InputManager.reset()

func text_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)

func action(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(callback)
	body.add_child(button)

func close() -> void:
	panel.hide()
	opened = false
	get_tree().paused = false
	InputManager.reset()

func show_journal() -> void:
	clear_panel()
	text_line("%s · %s · %s" % [WorldManager.profile.player_name, GameClock.display(), GameClock.period()])
	text_line("$%d   Energía %d/100   Bienestar %d/100   Reputación %d" % [LifeSimulation.money, LifeSimulation.energy, LifeSimulation.wellbeing, LifeSimulation.reputation])
	text_line("Inventario: %d provisiones" % int(LifeSimulation.inventory.get("food", 0)))
	text_line(MissionSystem.INTRO.title + "\n" + MissionSystem.objective())
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

func layout_panel() -> void:
	var safe := InputManager.safe_rect(get_viewport().get_visible_rect().size)
	journal_button.position = safe.position + Vector2(18, 80)
	panel.size = Vector2(minf(540, safe.size.x - 40), minf(320, safe.size.y - 40))
	panel.position = safe.get_center() - panel.size / 2

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
