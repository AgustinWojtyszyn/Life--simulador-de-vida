class_name DistrictBlocks
extends RefCounted

# The original demo occupied only the north-west corner. These axes turn the
# district into a real multi-block neighbourhood while preserving the first
# avenue so existing traffic and saves still have a familiar starting area.
const VERTICAL_SPECS := [
	[852.0, 138.0],
	[1810.0, 120.0],
	[2780.0, 126.0],
	[3760.0, 126.0],
]
const HORIZONTAL_SPECS := [
	[394.0, 170.0],
	[1130.0, 120.0],
	[1900.0, 126.0],
	[2660.0, 126.0],
]

static func vertical_roads(district: DistrictData) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for spec in VERTICAL_SPECS:
		var x: float = district.side_street_x if is_equal_approx(float(spec[0]), 1810.0) else float(spec[0])
		var width: float = district.side_street_width if is_equal_approx(float(spec[0]), 1810.0) else float(spec[1])
		if x < district.world_size.x - 80:
			result.append(Rect2(x, 16, width, district.world_size.y - 32))
	return result

static func horizontal_roads(district: DistrictData) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for spec in HORIZONTAL_SPECS:
		var y := float(spec[0])
		var height := float(spec[1])
		if y < district.world_size.y - 80:
			result.append(Rect2(16, y, district.world_size.x - 32, height))
	return result

static func roads(district: DistrictData) -> Array[Rect2]:
	var result := horizontal_roads(district)
	result.append_array(vertical_roads(district))
	return result

static func vertical_centers(district: DistrictData) -> Array[float]:
	var result: Array[float] = []
	for road in vertical_roads(district):
		result.append(road.get_center().x)
	return result

static func horizontal_centers(district: DistrictData) -> Array[float]:
	var result: Array[float] = []
	for road in horizontal_roads(district):
		result.append(road.get_center().y)
	return result

static func frontage(origin: Vector2, along: Vector2, count: int, spacing: float, normal: Vector2, seed: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var facing := AssetOrientation.from_vector(normal)
	for i in count:
		result.append({
			"position": origin + along.normalized() * spacing * i,
			"kind": "house",
			"mode": "EXTERIOR_ONLY",
			"asset_index": seed + i,
			"facing": facing,
			"street_normal": facing,
		})
	return result

static func starter_slots(district: DistrictData) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var index := 0

	# The player's home stays in the established starting quarter, facing the
	# avenue consistently. Services are placed only on frontage directions for
	# which their authored art actually exists.
	slots.append({"position": district.home_position, "kind": "home", "mode": "ENTERABLE", "asset_index": index, "facing": "south", "street_normal": "south"})
	index += 1
	for service in [
		[Vector2(1510, 1100), "clinic", "INTERACTABLE"],
		[Vector2(2180, 1100), "office", "EXTERIOR_ONLY"],
		[Vector2(3120, 1870), "shop", "ENTERABLE"],
		[Vector2(4100, 2630), "shop", "ENTERABLE"],
		[Vector2(3320, 1100), "office", "EXTERIOR_ONLY"],
	]:
		if service[0].x < district.world_size.x - 120 and service[0].y < district.world_size.y - 120:
			slots.append({"position": service[0], "kind": service[1], "mode": service[2], "asset_index": index, "facing": "south", "street_normal": "south"})
			index += 1

	# South-facing rows use the broadest set of regional architecture. This is
	# where shops and unique façades live, avoiding sideways storefront signs.
	var row_x := [180.0, 430.0, 680.0, 1120.0, 1430.0, 1650.0, 2070.0, 2350.0, 2530.0, 3020.0, 3280.0, 3500.0, 4010.0, 4270.0, 4560.0]
	for road in horizontal_roads(district):
		var y := road.position.y - 26.0
		for column in row_x.size():
			var x := row_x[column]
			if x > district.world_size.x - 100:
				continue
			if y < 500 and x < 1380:
				# The first four authored regional storefronts already occupy it.
				continue
			if x > 1410 and x < 1690 and y < 500:
				# Leave breathing room around the starter home.
				continue
			var kind := "house"
			var mode := "EXTERIOR_ONLY"
			if y > 600 and column % 7 == 3:
				kind = "shop"
				mode = "ENTERABLE"
			elif y > 600 and column % 11 == 7:
				kind = "office"
			slots.append({"position": Vector2(x, y), "kind": kind, "mode": mode, "asset_index": index, "facing": "south", "street_normal": "south"})
			index += 1

	# Opposite sides of the avenues receive real north-facing residential art.
	# The large block between the third and fourth avenues remains open for a
	# country-specific civic/sports landmark instead of being filled blindly.
	var north_row_x := [240.0, 560.0, 1180.0, 1510.0, 2150.0, 2460.0, 3090.0, 3380.0, 4080.0, 4380.0]
	for road in horizontal_roads(district):
		var y := road.end.y + 248.0
		if y > district.world_size.y - 60:
			continue
		for x in north_row_x:
			if x > district.world_size.x - 100:
				continue
			if road.position.y > 1800 and road.position.y < 2100 and x > 1930 and x < 2770:
				continue
			slots.append({"position": Vector2(x, y), "kind": "house", "mode": "EXTERIOR_ONLY", "asset_index": index, "facing": "north", "street_normal": "north"})
			index += 1

	# Side streets no longer rotate arbitrary storefront PNGs. Only the
	# directional residential family is used here, so doors/windows truly face
	# the road rather than looking sideways into another building.
	var side_y := [820.0, 1530.0, 2290.0, 3040.0]
	for road in vertical_roads(district):
		for y in side_y:
			if y > district.world_size.y - 80:
				continue
			var left_x := road.position.x - 122.0
			var right_x := road.end.x + 122.0
			if left_x > 120:
				slots.append({"position": Vector2(left_x, y), "kind": "house", "mode": "EXTERIOR_ONLY", "asset_index": index, "facing": "east", "street_normal": "east"})
				index += 1
			if right_x < district.world_size.x - 120:
				slots.append({"position": Vector2(right_x, y), "kind": "house", "mode": "EXTERIOR_ONLY", "asset_index": index, "facing": "west", "street_normal": "west"})
				index += 1

	return slots
