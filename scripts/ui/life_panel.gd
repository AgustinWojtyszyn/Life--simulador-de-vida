extends CanvasLayer

var panel: PanelContainer
var body: VBoxContainer
var opened := false

func _ready() -> void:
	layer = 24
	var button := Button.new()
	button.text = "Mi vida"
	button.position = Vector2(18, 80)
	button.custom_minimum_size = Vector2(92, 36)
	button.pressed.connect(show_journal)
	add_child(button)
	panel = PanelContainer.new()
	panel.position = Vector2(130, 118)
	panel.custom_minimum_size = Vector2(540, 180)
	add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
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
	label.custom_minimum_size.x = 500
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)

func action(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
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
