extends Node

var touch_vector := Vector2.ZERO
var touch_interaction := false
var touch_enabled := false

func _ready() -> void:
	touch_enabled = OS.has_feature("android") or "--touch-test" in OS.get_cmdline_user_args()
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "interact": [KEY_E], "pause_game": [KEY_ESCAPE]}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for code in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func movement() -> Vector2:
	return (Input.get_vector("move_left", "move_right", "move_up", "move_down") + touch_vector).limit_length()

func interact_pressed() -> bool:
	var pressed := touch_interaction or Input.is_action_just_pressed("interact")
	touch_interaction = false
	return pressed

func reset() -> void:
	touch_vector = Vector2.ZERO
	touch_interaction = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		reset()
