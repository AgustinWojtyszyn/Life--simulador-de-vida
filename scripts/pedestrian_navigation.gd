extends RefCounted

# One clearance grid per district. Temporary actor footprints are applied only
# during a query, so moving crowds never corrupt the static city graph.
const CELL := 12.0
const MARGIN := 10.0
var grid := AStarGrid2D.new()
var world: Node2D

func setup(city: Node2D) -> void:
	world = city
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(ceil(city.map_size.x / CELL), ceil(city.map_size.y / CELL)))
	grid.cell_size = Vector2.ONE * CELL
	grid.offset = Vector2.ONE * CELL * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for rect in city.solid_rects:
		if not rect.has_area():
			continue
		var padded: Rect2 = rect.grow(MARGIN)
		var first := cell(padded.position)
		var last := cell(padded.end)
		grid.fill_solid_region(Rect2i(first, last - first + Vector2i.ONE))
	# Roads remain traversable, but a route along the pavement costs less.
	for road in city.roads():
		var first := cell(road.position)
		var last := cell(road.end)
		grid.fill_weight_scale_region(Rect2i(first, last - first + Vector2i.ONE), 8.0)

func cell(at: Vector2) -> Vector2i:
	return Vector2i(floor(at.x / CELL), floor(at.y / CELL)).clamp(grid.region.position, grid.region.end - Vector2i.ONE)

func open(id: Vector2i) -> bool:
	return grid.is_in_boundsv(id) and not grid.is_point_solid(id)

func nearest(at: Vector2) -> Vector2:
	var origin := cell(at)
	if open(origin):
		return at
	var best := Vector2.INF
	var distance := INF
	for radius in range(1, 32):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if absi(x) != radius and absi(y) != radius:
					continue
				var id := origin + Vector2i(x, y)
				if open(id):
					var point := grid.get_point_position(id)
					if point.distance_squared_to(at) < distance:
						best = point
						distance = point.distance_squared_to(at)
		if best.is_finite():
			return best
	return best

func segment_clear(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / (CELL * 0.25)))
	for i in range(steps + 1):
		if not open(cell(a.lerp(b, float(i) / steps))):
			return false
	return true

func path(from: Vector2, to: Vector2, actors: Array = []) -> PackedVector2Array:
	var start := cell(from)
	var goal := cell(to)
	var changed: Array[Vector2i] = []
	for actor in actors:
		if not is_instance_valid(actor) or not actor.is_visible_in_tree():
			continue
		var center: Vector2 = actor.position
		var origin := cell(center)
		for y in range(-2, 3):
			for x in range(-2, 3):
				var id := origin + Vector2i(x, y)
				if id == start or not open(id):
					continue
				if grid.get_point_position(id).distance_to(center) < 22.0:
					grid.set_point_solid(id)
					changed.append(id)
	var result := PackedVector2Array()
	if open(start) and open(goal):
		var raw := grid.get_point_path(start, goal)
		if not raw.is_empty():
			raw[0] = from
			raw[raw.size() - 1] = to
			# Simplify only short segments: preserve the road cost chosen by A*.
			var anchor := 0
			result.append(from)
			while anchor < raw.size() - 1:
				var next := anchor + 1
				for candidate in range(anchor + 2, mini(raw.size(), anchor + 7)):
					if not segment_clear(raw[anchor], raw[candidate]):
						break
					next = candidate
				result.append(raw[next])
				anchor = next
	for id in changed:
		grid.set_point_solid(id, false)
	return result
