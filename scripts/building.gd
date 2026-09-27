class_name CityBuilding
extends Node2D

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")
const TextureBoundsScript := preload("res://scripts/data/texture_bounds.gd")

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
	sprite.region_rect = TextureBoundsScript.used(facade)
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
	if not (building_type.begins_with("residential") and not is_home):
		add_destination_label()
	set_meta("building_mode", Access.keys()[access])
	set_meta("building_type", building_type)
	set_meta("building_title", "TU HOGAR" if is_home else title)
	set_meta("orientation", orientation)
	var poi := PoiData.make(building_id, "home" if is_home else building_type, "TU HOGAR" if is_home else title,
		global_position, global_position + door_offset, country_id, WorldManager.profile.city_id, WorldManager.district.id)
	poi["interior_type"] = interior_type
	set_meta("poi", poi)
	add_to_group("map_pois")
	if access != Access.EXTERIOR_ONLY:
		var door := InteractionTargetScript.new()
		door.position = door_offset
		door.label = "Entrar a tu vivienda" if is_home else "Entrar a " + title if interior_type != "" else "Consultar " + title
		door.action = "enter_home" if is_home else "enter_" + interior_type if interior_type != "" else "shop"
		door.detail = title
		door.target_id = building_id
		door.set_meta("poi", poi)
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

func add_destination_label() -> void:
	# Labels must NEVER cover characters. A dedicated CanvasLayer with
	# negative layer renders below the world (and its characters) while
	# keeping the plate visible as decoration on the facade.
	var width: float = 118.0 if is_home else 112.0
	var plate := Label.new()
	plate.text = "TU HOGAR" if is_home else title
	if access == Access.ENTERABLE and not is_home:
		plate.text += "  •"
	plate.position = Vector2(-width * 0.5, -10)
	plate.size = Vector2(width, 18)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_theme_font_size_override("font_size", 9)
	plate.add_theme_color_override("font_color", Color("f0d5a0"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263d40")
	style.set_corner_radius_all(2)
	style.content_margin_left = 3
	style.content_margin_right = 3
	plate.add_theme_stylebox_override("normal", style)
	# Move label to a CanvasLayer below the world so it never covers characters
	var label_layer := CanvasLayer.new()
	label_layer.name = "LabelLayer"
	label_layer.layer = -1
	add_child(label_layer)
	label_layer.add_child(plate)
