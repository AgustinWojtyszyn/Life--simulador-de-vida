extends Control

var interaction_prompt := ""
var interaction_message := ""

func set_interaction(prompt: String, message: String) -> void:
	if prompt != interaction_prompt or message != interaction_message:
		interaction_prompt = prompt
		interaction_message = message
		queue_redraw()

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	GameClock.changed.connect(queue_redraw)
	WeatherSystem.changed.connect(queue_redraw)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := get_viewport_rect().size.x
	var height := get_viewport_rect().size.y
	draw_style_box(panel(), Rect2(18, 16, 208, 57))
	draw_rect(Rect2(30, 29, 3, 30), Color("dfb575"))
	draw_string(font, Vector2(42, 42), "VIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f5ecd7"))
	draw_string(font, Vector2(104, 39), WorldManager.district.title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d8ccaf"))
	draw_string(font, Vector2(104, 55), ("Tu vivienda · " if WorldManager.location == "home" else "") + WorldManager.country.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("9dafaa"))
	draw_style_box(panel(), Rect2(width - 127, 16, 109, 39))
	draw_circle(Vector2(width - 109, 35), 5, Color("dfb575"))
	draw_string(font, Vector2(width - 96, 39), GameClock.display(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("eee3ca"))
	draw_string(font, Vector2(width - 126, 67), WeatherSystem.title(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("eee3ca"))
	draw_style_box(panel(), Rect2(18, height - 39, 314, 23))
	draw_string(font, Vector2(30, height - 23), ("Arrastrá para caminar · Botón para actuar" if InputManager.touch_enabled else "WASD / Flechas · Caminar      E · Interactuar"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d8d4bf"))

	if not interaction_prompt.is_empty():
		draw_style_box(panel(), Rect2(width / 2 - 120, height - 75, 240, 27))
		draw_string(font, Vector2(width / 2 - 108, height - 57), interaction_prompt.replace("E · ", "") if InputManager.touch_enabled else interaction_prompt, HORIZONTAL_ALIGNMENT_CENTER, 216, 12, Color("f3d799"))
	if not interaction_message.is_empty():
		draw_style_box(panel(), Rect2(width / 2 - 200, 86, 400, 28))
		draw_string(font, Vector2(width / 2 - 188, 105), interaction_message, HORIZONTAL_ALIGNMENT_CENTER, 376, 11, Color("eee3ca"))

func panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.17, 0.19, 0.94)
	style.set_corner_radius_all(4)
	style.border_color = Color("50605e")
	style.set_border_width_all(1)
	return style
