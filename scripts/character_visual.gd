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
		facing = ("east" if direction.x > 0 else "west") if absf(direction.x) > absf(direction.y) else ("south" if direction.y > 0 else "north")
	if traveled > 0.02:
		distance_phase += traveled
		set_art("walk", facing, int(distance_phase / 7.0) % 4)
	else:
		distance_phase = 0
		set_art("idle", facing, 0)

func set_art(state: String, direction: String, frame: int) -> void:
	pose = state
	var path := "res://assets/characters/%s/%s.png" % [profile.gender, direction]
	if state == "walk":
		path = "res://assets/characters/%s/walk/%s_%d.png" % [profile.gender, direction, frame]
	elif state in ["seated", "wave"]:
		var folder := "resident" if profile.gender == "male" else "female"
		path = "res://assets/characters/%s/%s.png" % [folder, state]
	if not ResourceLoader.exists(path):
		path = "res://assets/characters/resident/%s.png" % direction
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
	sprite.scale = Vector2.ONE * (36.0 / maxf(1, rect.size.y))
	sprite.position = Vector2((texture.get_width() * 0.5 - rect.get_center().x) * sprite.scale.x, (texture.get_height() * 0.5 - rect.end.y) * sprite.scale.y)
	if state == "seated":
		sprite.scale.y *= 0.82
		sprite.position.y -= 6
	palette.set_shader_parameter("bounds", Vector4(rect.position.x / texture.get_width(), rect.position.y / texture.get_height(), rect.size.x / texture.get_width(), rect.size.y / texture.get_height()))
