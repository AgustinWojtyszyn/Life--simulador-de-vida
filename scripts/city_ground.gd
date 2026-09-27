extends Node2D

# Ground is drawn once by Godot's CanvasItem cache. Keeping it as vector draw
# commands avoids allocating one enormous 4800x3200 render texture on Android.
func _draw() -> void:
	var district: DistrictData = WorldManager.district
	var world := district.world_size
	var pavement := WorldManager.country.pavement
	draw_rect(Rect2(Vector2.ZERO, world), pavement.darkened(0.12))
	paving(Rect2(18, 18, world.x - 36, world.y - 36), pavement)

	var horizontal := DistrictBlocks.horizontal_roads(district)
	var vertical := DistrictBlocks.vertical_roads(district)
	var all_roads := DistrictBlocks.roads(district)

	for road in all_roads:
		draw_rect(road.grow(9), Color("777d79"))
		draw_rect(road.grow(5), Color("e0d5b8"))
		draw_rect(road.grow(1), Color("596167"))
		draw_rect(road, Color("424e59"))

	# Clear every crossing after curbs are painted so streets read as a
	# continuous network instead of disconnected demo rectangles.
	for h in horizontal:
		for v in vertical:
			draw_rect(Rect2(v.position.x, h.position.y, v.size.x, h.size.y), Color("424e59"))

	# Centre lines and restrained road wear.
	for h in horizontal:
		var y := h.get_center().y
		for x in range(34, int(world.x) - 34, 54):
			if not inside_vertical_crossing(Vector2(x, y), vertical):
				draw_rect(Rect2(x, y - 1, 27, 2), Color("c9b783"))
	for v in vertical:
		var x := v.get_center().x
		for y in range(30, int(world.y) - 30, 54):
			if not inside_horizontal_crossing(Vector2(x, y), horizontal):
				draw_rect(Rect2(x - 1, y, 2, 27), Color("c9b783"))

	# Zebra crossings at each intersection. The visual scale remains legible
	# from the default camera without turning the streets into UI decoration.
	for h in horizontal:
		for v in vertical:
			var center := Vector2(v.get_center().x, h.get_center().y)
			for offset in range(-46, 47, 16):
				draw_rect(Rect2(center.x - v.size.x / 2 - 30, center.y + offset - 4, 24, 8), Color("ded9c3"))
				draw_rect(Rect2(center.x + v.size.x / 2 + 6, center.y + offset - 4, 24, 8), Color("ded9c3"))

	# Starter-quarter parking remains useful, but it is no longer the edge of
	# the world: roads and blocks continue far beyond it.
	draw_parking(Rect2(1030, 631, 370, 280))
	draw_plaza(Rect2(72, 620, 720, 330))

	# Secondary green pockets distribute visual identity through the district
	# instead of concentrating every memorable object in the first plaza.
	draw_park(Rect2(2980, 650, 520, 360), 41)
	draw_park(Rect2(4040, 1370, 500, 350), 73)
	draw_park(Rect2(350, 2820, 560, 300), 99)

	# Fine, deterministic wear breaks up large expanses without creating a
	# giant source texture. This is intentionally sparse for mobile GPUs.
	var rng := RandomNumberGenerator.new()
	rng.seed = 519 + WorldManager.country.id.hash()
	for i in 6500:
		var p := Vector2(rng.randf_range(22, world.x - 22), rng.randf_range(22, world.y - 22))
		var on_road := false
		for road in all_roads:
			if road.has_point(p):
				on_road = true
				break
		if on_road:
			draw_rect(Rect2(p, Vector2(1 + i % 2, 1)), Color(0.23, 0.28, 0.31, 0.32))

func inside_vertical_crossing(point: Vector2, roads: Array[Rect2]) -> bool:
	for road in roads:
		if absf(point.x - road.get_center().x) < road.size.x * 0.7:
			return true
	return false

func inside_horizontal_crossing(point: Vector2, roads: Array[Rect2]) -> bool:
	for road in roads:
		if absf(point.y - road.get_center().y) < road.size.y * 0.7:
			return true
	return false

func paving(rect: Rect2, base: Color) -> void:
	draw_rect(rect, base)
	var light := base.lightened(0.055)
	var dark := base.darkened(0.035)
	for y in range(int(rect.position.y), int(rect.end.y), 24):
		for x in range(int(rect.position.x), int(rect.end.x), 48):
			var offset := 24 if (y / 24) as int % 2 else 0
			var tile := Rect2(x + offset, y, 47, 23).intersection(rect)
			if tile.has_area():
				draw_rect(tile, light if (x / 48 + y / 24) as int % 5 else dark)
				draw_line(tile.position, tile.position + Vector2(tile.size.x, 0), base.lightened(0.09))

func draw_parking(area: Rect2) -> void:
	draw_rect(area, Color("e3d7b7"))
	draw_rect(area.grow(-4), Color("4b5860"))
	var font := ThemeDB.fallback_font
	draw_string(font, area.position + Vector2(20, 25), "P  ·  ESTACIONAMIENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e9d69f"))
	var bay_w := 152.0
	var bays := [
		Rect2(area.position + Vector2(20, 38), Vector2(bay_w, 70)),
		Rect2(area.position + Vector2(198, 38), Vector2(bay_w, 70)),
		Rect2(area.position + Vector2(20, 182), Vector2(bay_w, 70)),
		Rect2(area.position + Vector2(198, 182), Vector2(bay_w, 70)),
	]
	for i in bays.size():
		draw_rect(bays[i], Color("d3cda9"), false, 2)
		draw_string(font, bays[i].position + Vector2(5, 16), "%02d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e9d69f"))

func draw_plaza(area: Rect2) -> void:
	draw_rect(area.grow(5), Color("ded4b6"))
	draw_rect(area, Color("b9b49f"))
	var beds := [
		Rect2(area.position + Vector2(16, 18), Vector2(250, 92)),
		Rect2(area.position + Vector2(445, 18), Vector2(250, 92)),
		Rect2(area.position + Vector2(16, 218), Vector2(250, 92)),
		Rect2(area.position + Vector2(445, 218), Vector2(250, 92)),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 331
	for bed in beds:
		draw_rect(bed.grow(3), Color("ddd3b4"))
		draw_rect(bed, Color("748568"))
		for i in 160:
			var p := bed.position + Vector2(rng.randf_range(3, bed.size.x - 3), rng.randf_range(3, bed.size.y - 3))
			draw_line(p, p + Vector2(2, -1), Color("8d9b72") if i % 2 else Color("627c62"))
	var path := PackedVector2Array([
		area.position + Vector2(280, 8),
		area.position + Vector2(336, 82),
		area.position + Vector2(365, 165),
		area.position + Vector2(430, 245),
		area.position + Vector2(450, 322),
	])
	draw_polyline(path, Color("e1d6b6"), 26, true)
	draw_polyline(path, Color("aaa58e"), 2, true)

func draw_park(area: Rect2, seed: int) -> void:
	draw_rect(area.grow(4), Color("dfd4b7"))
	draw_rect(area, Color("78886b"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 520:
		var p := area.position + Vector2(rng.randf_range(3, area.size.x - 3), rng.randf_range(3, area.size.y - 3))
		draw_line(p, p + Vector2(2, -1), Color("8fa076") if i % 3 else Color("667b62"))
	var mid := area.get_center()
	draw_rect(Rect2(area.position.x + 14, mid.y - 8, area.size.x - 28, 16), Color("d8cdae"))
	draw_rect(Rect2(mid.x - 8, area.position.y + 14, 16, area.size.y - 28), Color("d8cdae"))
