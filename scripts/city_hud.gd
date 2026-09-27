extends Control

var interaction_prompt := ""
var interaction_message := ""

func set_interaction(prompt: String, message: String) -> void:
	if prompt != interaction_prompt or message != interaction_message:
		interaction_prompt = prompt
		interaction_message = message
		queue_redraw()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(queue_redraw)
	GameClock.changed.connect(queue_redraw)
	WeatherSystem.changed.connect(queue_redraw)

func ui_scale() -> float:
	var viewport := get_viewport_rect().size
	var responsive := minf(viewport.x / 800.0, viewport.y / 450.0)
	var base := 1.16 if not InputManager.touch_enabled else 1.28
	return clampf(responsive * base, base, 1.75)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var viewport := get_viewport_rect().size
	var width := viewport.x
	var height := viewport.y
	var s := ui_scale()
	var margin := 16.0 * s

	var identity := Rect2(margin, margin, 224 * s, 64 * s)
	draw_style_box(panel(), identity)
	draw_rect(Rect2(identity.position + Vector2(13, 13) * s, Vector2(4, 36) * s), Color("dfb575"))
	draw_string(font, identity.position + Vector2(27, 31) * s, "VIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * s), Color("f5ecd7"))
	draw_string(font, identity.position + Vector2(92, 27) * s, WorldManager.district.title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * s), Color("d8ccaf"))
	draw_string(font, identity.position + Vector2(92, 47) * s, ("Tu vivienda · " if WorldManager.location == "home" else "") + WorldManager.country.title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * s), Color("9dafaa"))

	var clock_width := 126.0 * s
	var clock_rect := Rect2(width - margin - clock_width, margin, clock_width, 46 * s)
	draw_style_box(panel(), clock_rect)
	draw_circle(clock_rect.position + Vector2(17, 22) * s, 5 * s, Color("dfb575"))
	draw_string(font, clock_rect.position + Vector2(30, 27) * s, GameClock.display(), HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * s), Color("eee3ca"))
	draw_string(font, Vector2(clock_rect.position.x, clock_rect.end.y + 15 * s), WeatherSystem.title(), HORIZONTAL_ALIGNMENT_CENTER, clock_width, int(10 * s), Color("eee3ca"))

	if not InputManager.touch_enabled:
		var hint := Rect2(margin, height - margin - 29 * s, 340 * s, 29 * s)
		draw_style_box(panel(), hint)
		draw_string(font, hint.position + Vector2(13, 20) * s, "WASD / Flechas · Caminar      E · Interactuar", HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * s), Color("d8d4bf"))

	if not interaction_prompt.is_empty():
		var prompt_width := 300.0 * s
		var prompt_y := height - (126 * s if InputManager.touch_enabled else 82 * s)
		var prompt_rect := Rect2(width / 2.0 - prompt_width / 2.0, prompt_y, prompt_width, 34 * s)
		draw_style_box(panel(), prompt_rect)
		var shown := interaction_prompt.replace("E · ", "") if InputManager.touch_enabled else interaction_prompt
		draw_string(font, prompt_rect.position + Vector2(12, 23) * s, shown, HORIZONTAL_ALIGNMENT_CENTER, prompt_width - 24 * s, int(13 * s), Color("f3d799"))

	if not interaction_message.is_empty():
		var message_width := minf(470 * s, width - margin * 2.0)
		var message_rect := Rect2(width / 2.0 - message_width / 2.0, 92 * s, message_width, 38 * s)
		draw_style_box(panel(), message_rect)
		draw_string(font, message_rect.position + Vector2(14, 25) * s, interaction_message, HORIZONTAL_ALIGNMENT_CENTER, message_width - 28 * s, int(12 * s), Color("eee3ca"))

func panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.17, 0.19, 0.93)
	style.set_corner_radius_all(6)
	style.border_color = Color("50605e")
	style.set_border_width_all(1)
	return style
