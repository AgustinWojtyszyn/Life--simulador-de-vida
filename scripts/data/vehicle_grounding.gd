class_name VehicleGrounding
extends RefCounted

# Ground-plane centre in the alpha-cropped frame, reviewed against wheel contacts.
# E, SE, S, SW, W, NW, N, NE. PNG padding never enters this coordinate system.
const ANCHORS := {
	"compact": [Vector2(.5,.85), Vector2(.5,.70), Vector2(.5,.65), Vector2(.5,.70), Vector2(.5,.85), Vector2(.5,.70), Vector2(.5,.65), Vector2(.5,.70)],
	"sedan": [Vector2(.5,.84), Vector2(.5,.70), Vector2(.5,.65), Vector2(.5,.70), Vector2(.5,.84), Vector2(.5,.70), Vector2(.5,.65), Vector2(.5,.70)],
	"sports": [Vector2(.5,.83), Vector2(.5,.70), Vector2(.5,.65), Vector2(.5,.70), Vector2(.5,.83), Vector2(.5,.70), Vector2(.5,.65), Vector2(.5,.70)],
	"van": [Vector2(.5,.89), Vector2(.5,.76), Vector2(.5,.69), Vector2(.5,.76), Vector2(.5,.89), Vector2(.5,.76), Vector2(.5,.69), Vector2(.5,.76)],
	"colectivo": [Vector2(.5,.91), Vector2(.5,.79), Vector2(.5,.72), Vector2(.5,.79), Vector2(.5,.91), Vector2(.5,.79), Vector2(.5,.72), Vector2(.5,.79)],
	"hatchback": [Vector2(.5,.88), Vector2(.5,.74), Vector2(.5,.67), Vector2(.5,.74), Vector2(.5,.88), Vector2(.5,.74), Vector2(.5,.67), Vector2(.5,.74)],
	"pickup": [Vector2(.5,.87), Vector2(.5,.72), Vector2(.5,.65), Vector2(.5,.72), Vector2(.5,.87), Vector2(.5,.72), Vector2(.5,.65), Vector2(.5,.72)],
	"suv": [Vector2(.5,.88), Vector2(.5,.74), Vector2(.5,.67), Vector2(.5,.74), Vector2(.5,.88), Vector2(.5,.74), Vector2(.5,.67), Vector2(.5,.74)],
	"taxi": [Vector2(.5,.87), Vector2(.5,.72), Vector2(.5,.65), Vector2(.5,.72), Vector2(.5,.87), Vector2(.5,.72), Vector2(.5,.65), Vector2(.5,.72)],
}

static func art_model(model: String) -> String:
	# Legacy classic frames contain multiple cars / repeated headings; truck is
	# an incomplete atlas. Retain those assets, use complete art for moving bodies.
	return {"classic": "sedan", "truck": "van"}.get(model, model)

static func anchor(model: String, index: int, bounds: Rect2) -> Vector2:
	var family := art_model(model)
	assert(ANCHORS.has(family), "Vehicle needs reviewed ground anchors: " + model)
	var normalized: Vector2 = ANCHORS[family][index]
	assert(normalized.x >= .2 and normalized.x <= .8 and normalized.y >= .5 and normalized.y <= 1.0)
	return normalized * bounds.size

static func apply(sprite: Sprite2D, model: String, index: int, bounds: Rect2, scale_factor: float) -> void:
	sprite.region_enabled = true
	sprite.region_rect = bounds
	sprite.centered = false
	sprite.offset = -anchor(model, index, bounds)
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE * scale_factor

static func shadow_bounds(model: String, index: int, bounds: Rect2, scale_factor: float) -> Rect2:
	var contact := anchor(model, index, bounds)
	var radii := Vector2(bounds.size.x * .42, bounds.size.y - contact.y) * scale_factor
	return Rect2(-radii, radii * 2)
