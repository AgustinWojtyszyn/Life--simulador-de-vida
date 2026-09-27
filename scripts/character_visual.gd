class_name CharacterVisual
extends Node2D

const SKINS := [Color("d6a078"), Color("ac7658"), Color("754c39")]
const HAIRS := [Color("493020"), Color("b88b48"), Color("25232b")]
const TOPS := [Color("378f8a"), Color("a54f56"), Color("6884ad")]
const BOTTOMS := [Color("38414f"), Color("6e6253"), Color("4f6377")]
var profile: PlayerProfile
var sprite := Sprite2D.new()
var palette := ShaderMaterial.new()
var facing := "south"
var distance_phase := 0.0
var textures := {}
var bounds_cache := {}
var last_art := ""
var pose := "idle"
var activity_phase := 0.0
var base_sprite_position := Vector2.ZERO
var base_sprite_scale := Vector2.ONE
const WALK_CYCLE_DISTANCE := 56.0
var walk_cycles := {}

func walk_cycle(direction: String) -> Array[Texture2D]:
	var key := profile.gender + "/" + direction
	if not walk_cycles.has(key):
		var frames: Array[Texture2D] = []
		var index := 0
		while ResourceLoader.exists("res://assets/characters/%s/walk/%s_%d.png" % [profile.gender, direction, index]):
			frames.append(load("res://assets/characters/%s/walk/%s_%d.png" % [profile.gender, direction, index]))
			index += 1
		walk_cycles[key] = frames
	return walk_cycles[key]

func _ready() -> void:
	if profile == null:
		profile = WorldManager.profile
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	palette.shader = preload("res://assets/shaders/character_palette.gdshader")
	sprite.material = palette
	apply_profile(profile)

func apply_profile(value: PlayerProfile) -> void:
	profile = value
	last_art = ""
	palette.set_shader_parameter("skin_color", SKINS[profile.skin])
	palette.set_shader_parameter("hair_color", HAIRS[profile.hair_color])
	palette.set_shader_parameter("top_color", TOPS[profile.top])
	palette.set_shader_parameter("bottom_color", BOTTOMS[profile.bottom])
	palette.set_shader_parameter("hair_style", profile.hair)
	set_art("idle", facing, 0)

func animate_motion(direction: Vector2, traveled: float) -> void:
	if direction.length_squared() > 0.001:
		var names := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
		var requested: String = names[posmod(roundi(direction.angle() / (PI / 4)), 8)]
		facing = requested if ResourceLoader.exists("res://assets/characters/%s/%s.png" % [profile.gender, requested]) else (("east" if direction.x > 0 else "west") if absf(direction.x) > absf(direction.y) else ("south" if direction.y > 0 else "north"))
	if traveled > 0.02:
		distance_phase += traveled
		var count := walk_cycle(facing).size()
		set_art("walk", facing, int(distance_phase / WALK_CYCLE_DISTANCE * max(1, count)) % max(1, count))
	else:
		distance_phase = 0
		reset_pose_transform()
		if facing == "south" and ResourceLoader.exists("res://assets/characters/%s/idle_live/south_0.png" % profile.gender):
			animate_activity("idle_live", get_process_delta_time())
		else:
			set_art("idle", facing, 0)

func set_art(state: String, direction: String, frame: int) -> void:
	pose = state
	var path := "res://assets/characters/%s/%s.png" % [profile.gender, direction]
	if state == "walk":
		path = "res://assets/characters/%s/walk/%s_%d.png" % [profile.gender, direction, frame]
	elif state in ["phone", "drink", "idle_live", "eat", "look", "chat", "browse", "pickup", "pc", "tv", "stand", "sit"]:
		path = "res://assets/characters/%s/%s/south_%d.png" % [profile.gender, state, frame % 9]
	elif state in ["seated", "wave"]:
		var folder := "resident" if profile.gender == "male" else "female"
		path = "res://assets/characters/%s/%s.png" % [folder, state]
	if not ResourceLoader.exists(path):
		path = "res://assets/characters/%s/%s.png" % [profile.gender, direction]
		if not ResourceLoader.exists(path):
			path = "res://assets/characters/%s/south.png" % profile.gender
	if not textures.has(path):
		var art: Texture2D = load(path)
		textures[path] = art
		bounds_cache[path] = art.get_image().get_used_rect()
	var art_key := path + state
	if last_art == art_key:
		return
	last_art = art_key
	var texture: Texture2D = textures[path]
	var rect: Rect2 = bounds_cache[path]
	sprite.texture = texture
	# Feet, not transparent canvas padding, define the ground contact.
	var reference_path := "res://assets/characters/%s/south.png" % profile.gender
	if not bounds_cache.has(reference_path):
		bounds_cache[reference_path] = load(reference_path).get_image().get_used_rect()
	var standing: Rect2 = bounds_cache[reference_path]
	sprite.scale = Vector2.ONE * (52.0 / maxf(1, standing.size.y))
	sprite.position = Vector2((texture.get_width() * 0.5 - rect.get_center().x) * sprite.scale.x, (texture.get_height() * 0.5 - rect.end.y) * sprite.scale.y)
	if state == "walk":
		# A cycle shares a pivot. Recentring every silhouette cancels the authored
		# hip/foot motion, especially on vertical steps, and makes feet skate.
		var cycle_key := profile.gender + "/walk/" + direction
		if not bounds_cache.has(cycle_key):
			var cycle_bounds := Rect2()
			for art in walk_cycle(direction):
				var used := Rect2(art.get_image().get_used_rect())
				used.position -= art.get_size() * 0.5
				cycle_bounds = used if not cycle_bounds.has_area() else cycle_bounds.merge(used)
			bounds_cache[cycle_key] = cycle_bounds
		var cycle_bounds: Rect2 = bounds_cache[cycle_key]
		sprite.position = -Vector2(cycle_bounds.get_center().x, cycle_bounds.end.y) * sprite.scale
	sprite.rotation = 0.0
	if state == "seated":
		sprite.scale.y *= 0.82
		sprite.position.y -= 6
	base_sprite_position = sprite.position
	base_sprite_scale = sprite.scale
	palette.set_shader_parameter("bounds", Vector4(rect.position.x / texture.get_width(), rect.position.y / texture.get_height(), rect.size.x / texture.get_width(), rect.size.y / texture.get_height()))

func animate_activity(state: String, delta: float) -> void:
	activity_phase += delta
	var authored := "res://assets/characters/%s/%s/south_0.png" % [profile.gender, state]
	if ResourceLoader.exists(authored):
		set_art(state, "south", int(activity_phase * 7.0) % 9)
		return

	# Procedural fallback for actions whose full sprite sheet has not been
	# authored yet. This keeps cooking, TV, shopping, showering and football
	# visibly active instead of freezing the character in place.
	set_art("idle", "south", 0)
	var bob: float = sin(activity_phase * 7.0)
	var lean: float = sin(activity_phase * 4.2)
	sprite.position = base_sprite_position + Vector2(lean * 1.4, -absf(bob) * 2.2)
	sprite.rotation = lean * (0.06 if state in ["kick", "eat", "browse"] else 0.035)
	if state == "kick":
		sprite.scale = base_sprite_scale * (Vector2.ONE + Vector2(absf(bob) * 0.05, -absf(bob) * 0.03))
	elif state in ["pc", "tv", "browse"]:
		sprite.scale = base_sprite_scale * Vector2(1.0 + lean * 0.015, 1.0)
	pose = state

func reset_pose_transform() -> void:
	sprite.position = base_sprite_position
	sprite.scale = base_sprite_scale
	sprite.rotation = 0.0
