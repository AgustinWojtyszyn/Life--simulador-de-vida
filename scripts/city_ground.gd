extends Node2D

# Static drawing is cached by Godot; no per-frame tile generation.
func _draw() -> void:
	draw_rect(Rect2(0, 0, 2400, 1600), Color("b5ae95"))
	paving(Rect2(20, 24, 2360, 366))
	paving(Rect2(20, 574, 2360, 1006))
	# Two intersecting streets, with a darker gutter and a raised stone curb.
	for road in [Rect2(16, 394, 2368, 170), Rect2(852, 16, 138, 1568), Rect2(16, 1130, 2368, 120), Rect2(WorldManager.district.side_street_x, 16, WorldManager.district.side_street_width, 1568)]:
		draw_rect(road.grow(9), Color("787d79"))
		draw_rect(road.grow(5), Color("e3d7b7"))
		draw_rect(road.grow(1), Color("575f65"))
		draw_rect(road, Color("424e59"))
	# Open the shared intersection: no curb may cut across an active road.
	draw_rect(Rect2(842, 384, 158, 190), Color("424e59"))
	var sx := WorldManager.district.side_street_x
	var sw := WorldManager.district.side_street_width
	for at in [Vector2(842, 1120), Vector2(sx - 10, 384), Vector2(sx - 10, 1120)]:
		draw_rect(Rect2(at, Vector2(158 if at.x == 842 else sw + 20, 190 if at.y == 384 else 140)), Color("424e59"))
	for x in range(32, 2370, 44):
		if not (x > 820 and x < 1010) and not (x > sx - 30 and x < sx + sw + 30):
			draw_rect(Rect2(x, 1189, 22, 2), Color("c9b783"))
	for y in range(24, 1580, 44):
		if not (y > 370 and y < 590) and not (y > 1100 and y < 1280):
			draw_rect(Rect2(sx + sw / 2, y, 2, 22), Color("c9b783"))
	for y in range(1140, 1240, 18):
		for x in [807, 1009, int(sx - 40), int(sx + sw + 20)]:
			draw_rect(Rect2(x, y, 26, 9), Color("dcd8c2"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 519
	for i in 14000:
		var p := Vector2(rng.randi_range(18, 2380), rng.randi_range(18, 1580))
		if (p.y > 396 and p.y < 562) or (p.x > 854 and p.x < 988):
			draw_rect(Rect2(p, Vector2(1 + i % 2, 1)), Color("495560") if i % 3 else Color("3d4954"))
	for x in range(32, 2380, 44):
		if (x < 816 or x > 1010) and not (x > sx - 30 and x < sx + sw + 30):
			draw_rect(Rect2(x, 478, 22, 2), Color("c9b783"))
	for y in range(24, 1580, 44):
		if (y < 370 or y > 590) and not (y > 1100 and y < 1280):
			draw_rect(Rect2(920, y, 2, 22), Color("c9b783"))
	# Crosswalks at the intersection, on all four approaches.
	for y in range(405, 555, 18):
		for x in [807, 1009, int(sx - 40), int(sx + sw + 20)]:
			draw_rect(Rect2(x, y, 26, 9), Color("dcd8c2"))
	for x in range(861, 984, 18):
		for y in [355, 580]:
			draw_rect(Rect2(x, y, 9, 26), Color("dcd8c2"))
	# Dedicated off-street parking, with four numbered bays and a clear access aisle.
	draw_rect(Rect2(1030, 631, 370, 280), Color("e3d7b7"))
	draw_rect(Rect2(1034, 635, 362, 272), Color("4b5860"))
	draw_rect(Rect2(990, 760, 44, 42), Color("4b5860"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(1050, 656), "P  ·  ESTACIONAMIENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e9d69f"))
	var bays := [Rect2(1050, 669, 152, 70), Rect2(1228, 669, 152, 70), Rect2(1050, 813, 152, 70), Rect2(1228, 813, 152, 70)]
	for i in bays.size():
		draw_rect(bays[i], Color("d3cda9"), false, 2)
		draw_string(font, bays[i].position + Vector2(5, 16), "%02d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e9d69f"))
	for x in range(1065, 1360, 68):
		draw_line(Vector2(x, 781), Vector2(x + 22, 781), Color("c8c49b"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(1020, 772), Vector2(1033, 781), Vector2(1020, 790)]), Color("e9d69f"))
	# The plaza has raised garden beds, paths, edging and dense low vegetation.
	for bed in [Rect2(87, 642, 258, 86), Rect2(564, 642, 202, 86),
		Rect2(87, 839, 258, 88), Rect2(564, 839, 202, 88)]:
		draw_rect(bed.grow(4), Color("777f67"))
		draw_rect(bed.grow(2), Color("e0d6b6"))
		draw_rect(bed, Color("748568"))
		for i in 550:
			var p: Vector2 = bed.position + Vector2(rng.randf_range(2, bed.size.x - 3), rng.randf_range(2, bed.size.y - 3))
			draw_line(p, p + Vector2(2, -1), Color("8d9b72") if i % 2 else Color("627c62"))
		for i in 24:
			var p: Vector2 = bed.position + Vector2(rng.randf_range(6, bed.size.x - 6), rng.randf_range(5, bed.size.y - 5))
			draw_rect(Rect2(p, Vector2(2, 2)), Color("d0b67a"))
	for x in [98, 524, 774, 1040, 1330]:
		draw_rect(Rect2(x, 387, 20, 4), Color("333f47"))
		for dx in range(2, 20, 4):
			draw_line(Vector2(x + dx, 387), Vector2(x + dx, 391), Color("7b8986"))
	# Long afternoon cast shadows, painted on the ground behind sorted objects.
	for p in [Vector2(195, 318), Vector2(445, 320), Vector2(704, 315), Vector2(1168, 324)]:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-87, -50), p + Vector2(80, -50), p + Vector2(128, 15), p + Vector2(-40, 15)]), Color(0.17, 0.22, 0.29, 0.19))

func paving(rect: Rect2) -> void:
	draw_rect(rect, Color("bcb8a3"))
	for y in range(int(rect.position.y), int(rect.end.y), 16):
		for x in range(int(rect.position.x), int(rect.end.x), 32):
			var offset := 16 if (y / 16) % 2 else 0
			var tile := Rect2(x + offset, y, 31, 15).intersection(rect)
			if tile.has_area():
				draw_rect(tile, Color("c8c4af") if (x + y) % 5 else Color("c1bda8"))
				draw_line(tile.position, tile.position + Vector2(tile.size.x, 0), Color("d0cbb7"))
