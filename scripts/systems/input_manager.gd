extends Node

var touch_vector := Vector2.ZERO
var touch_interaction := false
var touch_enabled := false
var portrait_warning := false

func _ready() -> void:
	refresh_device_mode()
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E],
		"pause_game": [KEY_ESCAPE],
	}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for code in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func refresh_device_mode() -> void:
	# Android exported builds and Android/iOS browsers must both receive the
	# touch HUD. OS.has_feature("android") alone misses the web build.
	touch_enabled = (
		OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("mobile")
		or DisplayServer.is_touchscreen_available()
		or "--touch-test" in OS.get_cmdline_user_args()
	)

func is_landscape(canvas_size: Vector2) -> bool:
	return canvas_size.x >= canvas_size.y

func gameplay_safe_rect(canvas_size: Vector2) -> Rect2:
	var safe := safe_rect(canvas_size)
	if not touch_enabled:
		return safe
	# Some Android/WebView builds report an empty/full safe area even though the
	# gesture/navigation edges still consume touches. Keep a conservative inset.
	var side_guard := clampf(canvas_size.x * 0.018, 12.0, 28.0)
	var bottom_guard := clampf(canvas_size.y * 0.035, 14.0, 26.0)
	return safe.grow_individual(-side_guard, -8.0, -side_guard, -bottom_guard)

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

# Canvas-space safe area shared by every mobile surface, including menus.
func safe_rect(canvas_size: Vector2) -> Rect2:
	var screen := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if not touch_enabled or screen.x <= 0 or screen.y <= 0 or not safe.has_area():
		return Rect2(Vector2.ZERO, canvas_size)
	var ratio := canvas_size / screen
	return Rect2(safe.position * ratio, safe.size * ratio).intersection(Rect2(Vector2.ZERO, canvas_size))
