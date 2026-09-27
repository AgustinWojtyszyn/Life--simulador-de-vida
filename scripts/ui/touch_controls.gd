extends Control

var stick_finger := -1
var action_finger := -1
var stick_center := Vector2.ZERO
var action_center := Vector2.ZERO
var radius := 54.0
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
	InputManager.reset()
	var safe := InputManager.safe_rect(size)
	stick_center = Vector2(safe.position.x + radius + 24, safe.end.y - radius - 24)
	action_center = Vector2(safe.end.x - 66, safe.end.y - 78)
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
			if stick_finger == -1 and event.position.distance_to(stick_center) < radius * 1.6:
				stick_finger = event.index
				update_stick(event.position)
				get_viewport().set_input_as_handled()
			elif action_finger == -1 and event.position.distance_to(action_center) < 45:
				action_finger = event.index
				InputManager.touch_interaction = context_available
				get_viewport().set_input_as_handled()
		else:
			if event.index == stick_finger:
				stick_finger = -1
				InputManager.touch_vector = Vector2.ZERO
			if event.index == action_finger:
				action_finger = -1
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == stick_finger:
		update_stick(event.position)
		get_viewport().set_input_as_handled()

func update_stick(at: Vector2) -> void:
	var axis := (at - stick_center) / radius
	InputManager.touch_vector = Vector2.ZERO if axis.length() < 0.15 else axis.normalized() * clampf((axis.length() - 0.15) / 0.85, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	if not visible or get_tree().paused:
		return
	draw_circle(stick_center, radius, Color(0.1, 0.2, 0.23, 0.32))
	draw_arc(stick_center, radius, 0, TAU, 48, Color(0.9, 0.85, 0.7, 0.42), 2)
	draw_circle(stick_center + InputManager.touch_vector * radius * 0.7, 22, Color(0.8, 0.82, 0.74, 0.5))
	draw_circle(action_center, 38, Color(0.12, 0.22, 0.25, 0.78))
	draw_arc(action_center, 38, 0, TAU, 32, Color("d3b17b") if context_available else Color("637476"), 2)
	draw_string(ThemeDB.fallback_font, action_center + Vector2(-29, 5), "ACTUAR" if context_available else "ACERCATE", HORIZONTAL_ALIGNMENT_CENTER, 58, 12, Color("f2ddaa"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		stick_finger = -1
		action_finger = -1
		InputManager.reset()

func _exit_tree() -> void:
	InputManager.reset()
