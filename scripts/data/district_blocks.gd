class_name DistrictBlocks
extends RefCounted

static func roads(district: DistrictData) -> Array[Rect2]:
	return [Rect2(16, 394, 2368, 170), Rect2(852, 16, 138, 1568), Rect2(16, 1130, 2368, 120), Rect2(district.side_street_x, 16, district.side_street_width, 1568)]

# Reusable frontage: the street normal determines the view; spacing and seed
# determine the order of compatible assets. No RNG or edits to landmark IDs.
static func frontage(origin: Vector2, along: Vector2, count: int, spacing: float, normal: Vector2, seed: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in count:
		result.append({"position": origin + along.normalized() * spacing * i, "kind": "house", "mode": "EXTERIOR_ONLY", "asset_index": seed + i, "facing": AssetOrientation.from_vector(normal), "street_normal": AssetOrientation.from_vector(normal)})
	return result

static func starter_slots(district: DistrictData) -> Array[Dictionary]:
	var east := minf(district.side_street_x + district.side_street_width + 140, 2080)
	var slots: Array[Dictionary] = [
		{"position": district.home_position, "kind": "home", "mode": "ENTERABLE"},
		{"position": Vector2(east, 330), "kind": "shop", "mode": "INTERACTABLE"},
		{"position": Vector2(minf(east + 245, 2270), 335), "kind": "office", "mode": "EXTERIOR_ONLY"},
		{"position": Vector2(1560, 780), "kind": "clinic", "mode": "INTERACTABLE"},
		{"position": Vector2(east, 800), "kind": "shop", "mode": "INTERACTABLE"},
		{"position": Vector2(minf(east + 225, 2270), 800), "kind": "house", "mode": "EXTERIOR_ONLY"},
		{"position": Vector2(230, 1460), "kind": "house", "mode": "EXTERIOR_ONLY"},
		{"position": Vector2(560, 1460), "kind": "shop", "mode": "INTERACTABLE"},
		{"position": Vector2(1160, 1460), "kind": "house", "mode": "EXTERIOR_ONLY"},
		{"position": Vector2(1530, 1460), "kind": "office", "mode": "EXTERIOR_ONLY"},
		{"position": Vector2(east, 1460), "kind": "house", "mode": "EXTERIOR_ONLY"},
	]
	# Existing walkable blocks, with mixed frontages and distinct house silhouettes.
	# Slots leave doors, sidewalks, the plaza and parking circulation clear.
	var row := frontage(Vector2(150, 1060), Vector2.RIGHT, 3, 235, Vector2.DOWN)
	var mixed_positions := [row[0].position, row[1].position, row[2].position,
		Vector2(1160, 1060), Vector2(1370, 1060),
		Vector2(1630, 1060), Vector2(east + 160, 1060),
		Vector2(780, 1460), Vector2(2280, 1460)]
	for i in mixed_positions.size():
		var housing := i % 3 != 1
		slots.append({"position": mixed_positions[i], "kind": "house" if housing else "office", "mode": "EXTERIOR_ONLY", "asset_index": i})
	# Front-only clinics/shops/offices occupy the north side of a street.
	# Houses with directional families take the opposite/side-facing lots.
	slots[3].position = Vector2(1560, 1060)
	slots[16].position = Vector2(1690, 780)
	for pair in [[4, 17], [7, 13], [9, 11]]:
		var previous: Vector2 = slots[pair[0]].position
		slots[pair[0]].position = slots[pair[1]].position
		slots[pair[1]].position = previous
	var street_rects := roads(district)
	for slot in slots:
		slot["facing"] = AssetOrientation.street_facing(slot.position, street_rects)
		slot["street_normal"] = AssetOrientation.street_facing(slot.position, street_rects, false)
	var home_index := 0
	var commercial_index := 2
	for slot in slots:
		if slot.kind in ["home", "house"]:
			slot["asset_index"] = home_index
			home_index += 1
		else:
			slot["asset_index"] = commercial_index
			commercial_index += 1
	return slots
