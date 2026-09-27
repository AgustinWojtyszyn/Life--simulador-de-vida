extends CanvasLayer

var panel: PanelContainer
var body: VBoxContainer
var opened := false
var journal_button: Button

func _ready() -> void:
	layer = 24
	journal_button = Button.new()
	journal_button.text = "Mi vida"
	journal_button.position = Vector2(20, 96)
	journal_button.custom_minimum_size = Vector2(118, 48) if InputManager.touch_enabled else Vector2(104, 40)
	journal_button.add_theme_font_size_override("font_size", 18 if InputManager.touch_enabled else 15)
	journal_button.pressed.connect(func():
		AudioSystem.play_ui()
		show_journal())
	add_child(journal_button)

	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	panel.add_child(body)
	panel.hide()
	get_viewport().size_changed.connect(layout_panel)
	layout_panel()

func layout_panel() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var width := minf(640.0, viewport.x - 48.0)
	var height := minf(330.0, viewport.y - 72.0)
	if InputManager.touch_enabled:
		width = minf(690.0, viewport.x - 36.0)
		height = minf(360.0, viewport.y - 56.0)
	panel.custom_minimum_size = Vector2(maxf(300, width), maxf(190, height))
	panel.position = -panel.custom_minimum_size / 2.0
	journal_button.visible = not InputManager.touch_enabled

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
	label.custom_minimum_size.x = maxf(280, panel.custom_minimum_size.x - 36)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18 if InputManager.touch_enabled else 16)
	body.add_child(label)

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
