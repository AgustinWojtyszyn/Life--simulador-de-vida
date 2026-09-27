class_name CityBuilding
extends Node2D

static var facade_bounds_cache: Dictionary = {}

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")

enum Access { EXTERIOR_ONLY, INTERACTABLE, ENTERABLE }
var access := Access.EXTERIOR_ONLY
var building_id := ""
var title := ""
var building_type := "residential_house"
var facade: Texture2D
var size := Vector2(208, 236)
var is_home := false
var variant: Dictionary = {}
var country_id := "ar"
var interior_type := ""
var orientation := "south"
var door_offset := Vector2(0, 16)
var footprint := Rect2()

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = facade
	sprite.region_enabled = true
	var cache_key := facade.resource_path
	if not facade_bounds_cache.has(cache_key):
		facade_bounds_cache[cache_key] = facade.get_image().get_used_rect()
	sprite.region_rect = facade_bounds_cache[cache_key]
	sprite.scale = size / facade.get_size()
	sprite.position = Vector2(0, -sprite.region_rect.size.y * sprite.scale.y / 2)
	# Stable per-building variation breaks the repeated-stamp effect without
	# rotating or mirroring signage. Variation stays deliberately subtle so the
	# authored pixel art remains crisp.
	var seed := int(variant.get("seed", 0))
	var width_variation := 0.94 + float(posmod(seed * 7, 13)) / 100.0
	var height_variation := 0.96 + float(posmod(seed * 11, 11)) / 100.0
	if building_type.begins_with("residential"):
		sprite.scale *= Vector2(width_variation, height_variation)
		var warmth := float(posmod(seed * 5, 9)) / 100.0
		sprite.modulate = Color(1.0, 0.98 + warmth * 0.25, 0.95 + warmth * 0.35)
	add_child(sprite)
	set_meta("building_mode", Access.keys()[access])
	set_meta("building_type", building_type)
	set_meta("orientation", orientation)
	if access != Access.EXTERIOR_ONLY:
		var door := InteractionTargetScript.new()
		door.position = door_offset
		door.label = "Entrar a tu vivienda" if is_home else "Entrar a " + title if interior_type != "" else "Consultar " + title
		door.action = "enter_home" if is_home else "enter_" + interior_type if interior_type != "" else "shop"
		door.detail = title
		door.target_id = building_id
		door.set_meta("prompt", "Entrar a tu vivienda" if is_home else "Consultar " + title)
		door.set_meta("action", "enter_home" if is_home else "shop")
		door.set_meta("id", building_id)
		door.set_meta("title", title)
		door.set_meta("interaction", "door" if is_home else "shop")
		door.add_to_group("interactables")
		add_child(door)

func _draw() -> void:
	# One soft ground-contact shadow integrates each facade into the pavement.
	# It is based on the footprint rather than the PNG canvas, so tall assets do
	# not look like stickers floating over the street.
	var shadow_radius: float = clampf(footprint.size.x * 0.42, 34.0, 92.0)
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, shadow_radius, Color(0.08, 0.12, 0.15, 0.18))
	draw_set_transform(Vector2.ZERO)

	# Ordinary residences no longer carry a debug-like VIVIENDA/MORADIA label.
	# Keep labels for the player's home and actual destinations only.
	if building_type.begins_with("residential") and not is_home:
		return
	var width: float = 112.0 if is_home else 106.0
	draw_rect(Rect2(-width / 2.0, -7, width, 15), Color("263d40"))
	draw_string(ThemeDB.fallback_font, Vector2(-width / 2.0 + 3, 4), "TU HOGAR" if is_home else title, HORIZONTAL_ALIGNMENT_CENTER, width - 6, 9, Color("f0d5a0"))
	if access == Access.ENTERABLE and not is_home:
		draw_circle(Vector2(width / 2.0 - 7, 0), 2.5, Color("efce8a"))
	if is_home:
		draw_colored_polygon(PackedVector2Array([Vector2(-6, 10), Vector2(6, 10), Vector2(0, 15)]), Color("efce8a"))
