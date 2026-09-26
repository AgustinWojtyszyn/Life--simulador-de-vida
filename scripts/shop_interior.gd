extends Node2D

func _ready() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Player/Camera2D.limit_right = 800
	$Player/Camera2D.limit_bottom = 450
	for entry in [
		[Vector2(390, 359), "Salir al barrio", "exit_home", "exit"],
		[Vector2(228, 245), "Comprar provisiones", "shop", "shelf"],
		[Vector2(550, 250), "Tomar algo", "coffee", "counter"],
	]:
		var point := InteractionTarget.new()
		point.position = entry[0]
		point.label = entry[1]
		point.action = entry[2]
		point.target_id = entry[3]
		point.detail = "el local"
		add_child(point)
	var layer := CanvasLayer.new()
	var hud := Control.new()
	hud.set_script(preload("res://scripts/city_hud.gd"))
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	add_child(layer)
	var interactions := Node.new()
	interactions.name = "Interactions"
	interactions.set_script(preload("res://scripts/city_interactions.gd"))
	interactions.hud = hud
	add_child(interactions)

func _draw() -> void:
	var cafe := WorldManager.location == "cafe"
	var accent: Color = WorldManager.country.accent
	draw_rect(Rect2(0, 0, 800, 450), Color("172d31"))
	draw_rect(Rect2(86, 64, 628, 340), Color("d5c3a5"))
	draw_rect(Rect2(102, 80, 596, 308), Color("8d7762"))
	for y in range(80, 388, 24):
		for x in range(102, 698, 36):
			draw_rect(Rect2(x + (12 if y % 48 else 0), y, 35, 23), Color("9b856b") if x % 3 else Color("a48d73"))
	draw_rect(Rect2(109, 82, 582, 29), accent)
	draw_string(ThemeDB.fallback_font, Vector2(280, 103), "CAFETERÍA" if cafe else "MERCADO", HORIZONTAL_ALIGNMENT_CENTER, 240, 17, Color("293b3c"))
	for i in 4:
		var x := 133 + i * 92
		draw_rect(Rect2(x, 151, 58, 94), Color("584f46"))
		for row in 3:
			draw_rect(Rect2(x + 5, 158 + row * 28, 48, 21), Color("c5ad7b") if cafe else Color("8ca996"))
			draw_rect(Rect2(x + 4, 178 + row * 28, 50, 3), Color("463e39"))
	draw_rect(Rect2(501, 161, 136, 47), Color("554438"))
	draw_rect(Rect2(497, 178, 144, 49), Color("956b4f"))
	draw_rect(Rect2(506, 182, 126, 19), Color("bd9672"))
	if cafe:
		for x in [526, 561, 596]:
			draw_circle(Vector2(x, 170), 9, Color("e4d4ad"))
	else:
		draw_rect(Rect2(533, 155, 56, 25), Color("354e50"))
		draw_rect(Rect2(536, 158, 50, 18), Color("91aca6"))
	draw_rect(Rect2(365, 381, 50, 12), Color("d6ba8b"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 378), "SALIDA", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color("f1e2c5"))
