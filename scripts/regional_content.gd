extends Node2D

var phase := 0.0

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	# A compact neighbourhood five-a-side pitch, on the plaza's open paving.
	draw_rect(Rect2(-5, -5, 225, 95), Color("c7b58a"))
	draw_rect(Rect2(0, 0, 215, 85), Color("53795a"))
	for x in range(0, 210, 30):
		draw_rect(Rect2(x, 0, 15, 85), Color("598160"))
	draw_rect(Rect2(5, 5, 205, 75), Color("e5e6cc"), false, 1)
	draw_line(Vector2(107, 5), Vector2(107, 80), Color("e5e6cc"))
	draw_arc(Vector2(107, 42), 17, 0, TAU, 28, Color("e5e6cc"))
	for x in [5, 180]:
		draw_rect(Rect2(x, 23, 30, 38), Color("e5e6cc"), false, 1)
	for x in [0, 211]:
		draw_rect(Rect2(x, 29, 4, 26), Color("eeeecc"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(46, -9), "CLUB BARRIO DEL SOL", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("263d40"))
	var ball := Vector2(35 + (sin(phase * 1.3) * 0.5 + 0.5) * 145, 43 + sin(phase * 2.6) * 16)
	draw_circle(ball + Vector2(2, 2), 4, Color(0, 0, 0, 0.2))
	draw_circle(ball, 3, Color("f3edda"))
	draw_rect(Rect2(ball - Vector2.ONE, Vector2(2, 2)), Color("283b40"))
