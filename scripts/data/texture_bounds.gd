class_name TextureBounds
extends RefCounted

static var bounds: Dictionary = {}

static func used(texture: Texture2D) -> Rect2:
	# Atlas regions already describe the complete asset. Avoid GPU readbacks and
	# extracting entire country atlases once per building when entering a city.
	if texture is AtlasTexture:
		return Rect2(Vector2.ZERO, texture.get_size())
	var key := texture.resource_path
	if not bounds.has(key):
		bounds[key] = Rect2(texture.get_image().get_used_rect())
	return bounds[key]
