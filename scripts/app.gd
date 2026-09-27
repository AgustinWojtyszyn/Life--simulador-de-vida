extends Node

var world: Node2D
var menu: Control
var overlay: CanvasLayer
var pause_panel: PanelContainer
var changing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	WorldManager.travel_requested.connect(switch_world)
	show_menu()

func show_menu() -> void:
	get_tree().paused = false
	InputManager.reset()
	WorldManager.playing = false
	AudioSystem.stop_world()
	if is_instance_valid(world):
		world.queue_free()
		world = null
	WorldManager.active_world = null
	if is_instance_valid(overlay):
		overlay.queue_free()
	menu = Control.new()
	menu.set_script(preload("res://scripts/ui/main_menu.gd"))
	add_child(menu)

func switch_world() -> void:
	if changing:
		return
	changing = true
	InputManager.reset()
	InputManager.refresh_device_mode()
	WorldManager.settings["touch_controls"] = InputManager.touch_enabled
	AudioSystem.set_enabled(bool(WorldManager.settings.get("audio_enabled", true)))
	AudioSystem.set_music_volume(float(WorldManager.settings.get("music_volume", 0.65)))
	if is_instance_valid(menu):
		menu.queue_free()
		menu = null
	if is_instance_valid(overlay):
		overlay.queue_free()
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	get_tree().paused = false
	var scene := HomeSystem.INTERIOR_SCENE if WorldManager.location == "home" else "res://scenes/shop.tscn" if WorldManager.location != "street" else "res://scenes/playground.tscn"
	world = load(scene).instantiate()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	WorldManager.active_world = world
	var player: CharacterBody2D = world.get_node("Player")
	player.position = WorldManager.spawn_position
	player.get_node("Camera2D").reset_smoothing()
	var environment := preload("res://scripts/world_environment.gd").new()
	world.add_child(environment)
	setup_overlay()
	AudioSystem.start_world(WorldManager.country.id)
	changing = false

func setup_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 30
	var life_panel := preload("res://scripts/ui/life_panel.gd").new()
	life_panel.name = "LifePanel"
	life_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(life_panel)
	add_child(overlay)
	var controls := Control.new()
	controls.set_script(preload("res://scripts/ui/touch_controls.gd"))
	overlay.add_child(controls)
	var root_control := Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(root_control)
	var pause_button := Button.new()
	pause_button.text = "Menú"
	pause_button.add_theme_font_size_override("font_size", 17 if InputManager.touch_enabled else 14)
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-118, 76) if InputManager.touch_enabled else Vector2(-94, 72)
	pause_button.size = Vector2(98, 52) if InputManager.touch_enabled else Vector2(76, 44)
	pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_button.pressed.connect(func():
		AudioSystem.play_ui()
		toggle_pause())
	root_control.add_child(pause_button)
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var panel_size := Vector2(380, 280) if InputManager.touch_enabled else Vector2(330, 235)
	pause_panel.position = -panel_size / 2.0
	pause_panel.custom_minimum_size = panel_size
	root_control.add_child(pause_panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	pause_panel.add_child(list)
	var info := Label.new()
	info.text = "VIDA · Tu partida"
	info.add_theme_font_size_override("font_size", 21 if InputManager.touch_enabled else 17)
	list.add_child(info)
	for entry in [["Seguir jugando", func(): toggle_pause()], ["Guardar partida", func(): info.text = "Partida guardada" if WorldManager.save_game() else SaveSystem.last_error], ["Guardar y volver al menú", func():
		if WorldManager.save_game(): show_menu()
		else: info.text = SaveSystem.last_error]]:
		var b := Button.new()
		b.text = entry[0]
		b.custom_minimum_size.y = 54 if InputManager.touch_enabled else 44
		b.add_theme_font_size_override("font_size", 18 if InputManager.touch_enabled else 15)
		var callback: Callable = entry[1]
		b.pressed.connect(func():
			AudioSystem.play_ui()
			callback.call())
		list.add_child(b)
	pause_panel.hide()
	var fade := ColorRect.new()
	fade.color = Color("112329")
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.35)
	tween.tween_callback(fade.queue_free)

func toggle_pause() -> void:
	var life_panel := world.get_node_or_null("LifePanel")
	if life_panel != null and life_panel.opened:
		life_panel.close()
		return
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused
	InputManager.reset()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and is_instance_valid(world):
		toggle_pause()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if WorldManager.playing:
			WorldManager.save_game()
		get_tree().quit()
