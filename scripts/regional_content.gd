extends Node2D

var phase := 0.0
const FIELD := Rect2(70, 58, 580, 320)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	# A real neighbourhood football ground: full-size in game terms, with
	# stands, technical areas, goals and enough room for several residents.
	var outer := Rect2(0, 0, 720, 440)
	draw_rect(outer, Color("c7b58a"))
	draw_rect(Rect2(18, 18, 684, 404), Color("8e7b62"))
	draw_rect(FIELD.grow(10), Color("d7d0b0"))
	draw_rect(FIELD, Color("4f7656"))
	for x in range(int(FIELD.position.x), int(FIELD.end.x), 48):
		draw_rect(Rect2(x, FIELD.position.y, 24, FIELD.size.y), Color("587f5e"))
	draw_rect(FIELD.grow(-7), Color("edf0d8"), false, 3)
	draw_line(Vector2(FIELD.get_center().x, FIELD.position.y + 7), Vector2(FIELD.get_center().x, FIELD.end.y - 7), Color("edf0d8"), 3)
	draw_arc(FIELD.get_center(), 42, 0, TAU, 40, Color("edf0d8"), 3)
	draw_circle(FIELD.get_center(), 4, Color("edf0d8"))
	for x in [FIELD.position.x + 7, FIELD.end.x - 126]:
		draw_rect(Rect2(x, FIELD.position.y + 92, 119, 136), Color("edf0d8"), false, 3)
	for x in [FIELD.position.x + 7, FIELD.end.x - 65]:
		draw_rect(Rect2(x, FIELD.position.y + 132, 58, 56), Color("edf0d8"), false, 2)

	# Goals and low stands.
	for x in [FIELD.position.x - 12, FIELD.end.x + 2]:
		draw_rect(Rect2(x, FIELD.get_center().y - 42, 10, 84), Color("f1e9d1"), false, 3)
	for stand in [
		Rect2(76, 18, 568, 26),
		Rect2(76, 392, 568, 26),
		Rect2(18, 88, 30, 258),
		Rect2(672, 88, 30, 258),
	]:
		draw_rect(stand, Color("3b5050"))
		draw_rect(stand.grow(-5), Color("d6b270"))
		for i in range(0, int(stand.size.x if stand.size.x > stand.size.y else stand.size.y), 18):
			if stand.size.x > stand.size.y:
				draw_line(stand.position + Vector2(i, 4), stand.position + Vector2(i, stand.size.y - 4), Color("5e5550"))
			else:
				draw_line(stand.position + Vector2(4, i), stand.position + Vector2(stand.size.x - 4, i), Color("5e5550"))

	var font := ThemeDB.fallback_font
	draw_rect(Rect2(182, -28, 356, 31), Color("263d40"))
	draw_string(font, Vector2(196, -7), "CANCHA MUNICIPAL · BARRIO DEL SOL", HORIZONTAL_ALIGNMENT_CENTER, 328, 15, Color("f0d5a0"))

	# A moving ball makes the pitch feel active even before a mission starts.
	var ball := Vector2(
		FIELD.position.x + 85 + (sin(phase * 0.72) * 0.5 + 0.5) * (FIELD.size.x - 170),
		FIELD.get_center().y + sin(phase * 1.44) * 92
	)
	draw_circle(ball + Vector2(3, 3), 7, Color(0, 0, 0, 0.22))
	draw_circle(ball, 6, Color("f3edda"))
	draw_rect(Rect2(ball - Vector2(2, 2), Vector2(4, 4)), Color("283b40"))
