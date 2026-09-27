extends Node2D

var kind := "sign"

func _draw() -> void:
	match kind:
		"transport_stop":
			draw_line(Vector2.ZERO, Vector2(0, -64), Color("546a72"), 4)
			draw_rect(Rect2(-22, -70, 44, 28), Color("e9e0bc"))
			draw_rect(Rect2(-22, -70, 44, 11), Color("469fc0"))
			draw_string(ThemeDB.fallback_font, Vector2(-19, -61), "PARADA", HORIZONTAL_ALIGNMENT_CENTER, 38, 8, Color.WHITE)
			draw_string(ThemeDB.fallback_font, Vector2(-17, -47), "60 · 152", HORIZONTAL_ALIGNMENT_CENTER, 34, 9, Color("263d40"))
		"tree_bed":
			paint_ellipse(Vector2(14, 0), Vector2(47, 14), Color(0.18, 0.25, 0.25, 0.16))
			draw_rect(Rect2(-15, -8, 30, 13), Color("858574"))
			draw_rect(Rect2(-13, -8, 26, 10), Color("615f4c"))
		"sign":
			draw_line(Vector2(-8, 0), Vector2(-5, -24), Color("795c43"), 3)
			draw_line(Vector2(9, 0), Vector2(5, -24), Color("795c43"), 3)
			draw_rect(Rect2(-7, -24, 14, 19), Color("b59b71"))
			draw_rect(Rect2(-5, -22, 10, 14), Color("354f51"))
			draw_line(Vector2(-3, -18), Vector2(3, -18), Color("e6d7b3"))
			draw_line(Vector2(-3, -14), Vector2(2, -14), Color("e6d7b3"))

func paint_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_set_transform(center, 0, radii)
	draw_circle(Vector2.ZERO, 1, color)
	draw_set_transform(Vector2.ZERO)
