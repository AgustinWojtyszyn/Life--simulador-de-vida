class_name AssetOrientation
extends RefCounted

# Screen compass: x grows right, y grows down. These are authored views,
# never transformations of an image. Text/signage is consequently never mirrored.
const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
const VECTORS := [Vector2.RIGHT, Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1), Vector2.UP, Vector2(1, -1)]

static func vector(facing: String) -> Vector2:
	var index := DIRECTIONS.find(facing)
	return VECTORS[index].normalized() if index >= 0 else Vector2.DOWN

static func from_vector(movement: Vector2) -> String:
	return DIRECTIONS[posmod(roundi(movement.angle() / (PI / 4.0)), 8)]

static func street_facing(at: Vector2, roads: Array[Rect2], corners: bool = true) -> String:
	var approaches: Array[Dictionary] = []
	for road in roads:
		var nearest := at.clamp(road.position, road.end)
		var toward := nearest - at
		if toward.length_squared() > 0:
			approaches.append({"distance": toward.length(), "vector": toward.normalized()})
	approaches.sort_custom(func(a: Dictionary, b: Dictionary): return a.distance < b.distance)
	if approaches.is_empty(): return "south"
	# Use the closest road's direction as the primary facing
	var normal: Vector2 = approaches[0].vector
	# Only combine with a second road if the building is actually at a corner
	# (both roads are very close, within 1.5x of each other)
	if corners and approaches.size() > 1:
		var second: Dictionary = approaches[1]
		if second.distance < approaches[0].distance * 1.5:
			normal += second.vector
	return from_vector(normal)

static func family_path(folder: String, facing: String) -> String:
	var path := folder.path_join(facing + ".png")
	return path if ResourceLoader.exists(path) else ""
