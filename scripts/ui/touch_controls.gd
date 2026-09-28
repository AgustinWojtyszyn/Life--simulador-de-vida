extends Control

var stick_finger := -1
var action_finger := -1
var journal_finger := -1
var stick_center := Vector2.ZERO
var action_center := Vector2.ZERO
var journal_center := Vector2.ZERO
var radius := 72.0
var action_radius := 50.0
var context_available := false
var was_paused := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = InputManager.touch_enabled
	resized.connect(layout_controls)
	layout_controls()

func layout_controls() -> void:
	stick_finger = -1
	action_finger = -1
	journal_finger = -1
	InputManager.reset()
	var logical := size
	var safe := InputManager.gameplay_safe_rect(logical)
	var scale_factor := clampf(minf(logical.x / 800.0, logical.y / 450.0), 1.0, 1.35)
	radius = 72.0 * scale_factor
	action_radius = 50.0 * scale_factor
	var bottom_lift := clampf(safe.size.y * 0.11, 44.0, 72.0)
	stick_center = Vector2(safe.position.x + radius + 34, safe.end.y - radius - bottom_lift)
	action_center = Vector2(safe.end.x - action_radius - 34, safe.end.y - action_radius - bottom_lift)
	journal_center = action_center + Vector2(0, -(action_radius * 2.0 + 28.0))
	queue_redraw()

func _process(_delta: float) -> void:
	if not visible:
		return
	if was_paused != get_tree().paused:
		was_paused = get_tree().paused
		queue_redraw()
	if get_tree().paused:
		stick_finger = -1
		action_finger = -1
		journal_finger = -1
		InputManager.reset()
		return
	var world: Node2D = WorldManager.active_world
	var available := false
	if is_instance_valid(world) and world.has_node("Interactions"):
		available = not world.get_node("Interactions").prompt.is_empty()
	if available != context_available:
		context_available = available
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if stick_finger == -1 and event.position.distance_to(stick_center) < radius * 1.55:
				stick_finger = event.index
				update_stick(event.position)
				get_viewport().set_input_as_handled()
			elif action_finger == -1 and event.position.distance_to(action_center) < action_radius * 1.25:
				action_finger = event.index
				InputManager.touch_interaction = context_available
				get_viewport().set_input_as_handled()
			elif journal_finger == -1 and event.position.distance_to(journal_center) < action_radius:
				journal_finger = event.index
				open_journal()
				get_viewport().set_input_as_handled()
		else:
			if event.index == stick_finger:
				stick_finger = -1
				InputManager.touch_vector = Vector2.ZERO
			if event.index == action_finger:
				action_finger = -1
			if event.index == journal_finger:
				journal_finger = -1
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == stick_finger:
		update_stick(event.position)
		get_viewport().set_input_as_handled()

func update_stick(at: Vector2) -> void:
	var axis := (at - stick_center) / radius
	InputManager.touch_vector = Vector2.ZERO if axis.length() < 0.15 else axis.normalized() * clampf((axis.length() - 0.15) / 0.85, 0.0, 1.0)
	queue_redraw()

func open_journal() -> void:
	var world := WorldManager.active_world
	if not is_instance_valid(world):
		return
	var life_panel := world.get_node_or_null("LifePanel")
	if life_panel != null and not life_panel.opened:
		life_panel.show_journal()

func _draw() -> void:
	if not visible or get_tree().paused:
		return
	var font := ThemeDB.fallback_font
	draw_circle(stick_center, radius, Color(0.06, 0.12, 0.15, 0.42))
	draw_arc(stick_center, radius, 0, TAU, 56, Color(0.93, 0.86, 0.69, 0.58), 3)
	draw_circle(stick_center + InputManager.touch_vector * radius * 0.68, radius * 0.34, Color(0.79, 0.82, 0.75, 0.68))
	var action_color := Color(0.12, 0.22, 0.25, 0.88) if context_available else Color(0.12, 0.18, 0.20, 0.38)
	draw_circle(action_center, action_radius, action_color)
	draw_arc(action_center, action_radius, 0, TAU, 40, Color("d3b17b") if context_available else Color(0.65, 0.64, 0.57, 0.42), 3)
	draw_string(font, action_center + Vector2(-44, 6), "ACTUAR", HORIZONTAL_ALIGNMENT_CENTER, 88, 15, Color("f2ddaa") if context_available else Color(0.72, 0.71, 0.66, 0.62))
	draw_circle(journal_center, action_radius * 0.78, Color(0.08, 0.16, 0.18, 0.78))
	draw_arc(journal_center, action_radius * 0.78, 0, TAU, 36, Color(0.83, 0.74, 0.56, 0.62), 2)
	draw_string(font, journal_center + Vector2(-34, 5), "VIDA", HORIZONTAL_ALIGNMENT_CENTER, 68, 14, Color("eee3ca"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		stick_finger = -1
		action_finger = -1
		journal_finger = -1
		InputManager.reset()

func _exit_tree() -> void:
	InputManager.reset()
