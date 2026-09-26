class_name CityBuilding
extends Node2D

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")

enum Access { EXTERIOR_ONLY, INTERACTABLE, ENTERABLE }
var access := Access.EXTERIOR_ONLY
var building_id := ""
var title := ""
var facade: Texture2D
var size := Vector2(208, 236)
var is_home := false
var variant: Dictionary = {}
var country_id := "ar"
var interior_type := ""

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = facade
	sprite.region_enabled = true
	sprite.region_rect = facade.get_image().get_used_rect()
	sprite.scale = size / facade.get_size()
	sprite.position = Vector2(0, -sprite.region_rect.size.y * sprite.scale.y / 2)
	sprite.z_index = -1
	add_child(sprite)
	set_meta("building_mode", Access.keys()[access])
	if access != Access.EXTERIOR_ONLY:
		var door := InteractionTargetScript.new()
		door.position = Vector2(0, 16)
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
	if not variant.is_empty():
		# Retain the illustrated facade, then give each building its own silhouette,
		# shopfront, window rhythm and materials instead of tinting one image.
		var w: float = variant.width
		var h: float = variant.height
		var colors := {
			"ar": [Color("d0bc9e"), Color("566b72")],
			"jp": [Color("b6b8aa"), Color("596765")],
			"us": [Color("b6a495"), Color("465b68")],
			"it": [Color("d9c39f"), Color("797168")],
			"br": [Color("c7b49e"), Color("577777")],
		}
		var material: Array = colors.get(country_id, colors["ar"])
		var left := -w * 0.5
		var top := -h
		var wall: Color = material[0].darkened(0.08)
		wall.a = 0.38
		draw_rect(Rect2(left, top, w, h - 19), wall)
		draw_rect(Rect2(left - 4, top - 7, w + 8, 9), material[1])
		if variant.roof == 1:
			draw_colored_polygon(PackedVector2Array([Vector2(left - 7, top), Vector2(0, top - 26), Vector2(-left + 7, top)]), material[1].darkened(0.16))
		elif variant.roof == 2:
			draw_rect(Rect2(left + 8, top - 17, w - 16, 17), material[1].darkened(0.12))
		for floor_index in range(variant.floors):
			for column in range(variant.windows):
				var gap: float = w / (variant.windows + 1)
				var x: float = left + gap * (column + 1) - 10
				var y: float = top + 24 + floor_index * 32
				draw_rect(Rect2(x - 2, y - 3, 24, 24), material[1])
				draw_rect(Rect2(x, y, 20, 17), Color("77969b") if column % 2 else Color("bdba9c"))
				draw_line(Vector2(x + 10, y), Vector2(x + 10, y + 17), material[1], 2)
				if variant.balcony and floor_index % 2 == 0:
					draw_rect(Rect2(x - 5, y + 17, 30, 5), material[1])
					draw_line(Vector2(x - 4, y + 12), Vector2(x + 24, y + 12), material[1], 2)
		if variant.shopfront:
			draw_rect(Rect2(left + 8, -43, w - 16, 27), material[1])
			draw_rect(Rect2(left + 12, -39, w - 24, 19), Color("6a9893"))
			draw_rect(Rect2(left + 6, -48, w - 12, 7), WorldManager.country.accent)
		else:
			draw_rect(Rect2(-13, -44, 26, 28), material[1].darkened(0.25))
			draw_circle(Vector2(7, -27), 2, Color("e9d9ad"))
	var width := 108 if is_home else 104
	draw_rect(Rect2(-width / 2, -7, width, 15), Color("263d40"))
	draw_string(ThemeDB.fallback_font, Vector2(-width / 2 + 3, 4), "TU HOGAR" if is_home else title, HORIZONTAL_ALIGNMENT_CENTER, width - 6, 9, Color("f0d5a0"))
	if is_home:
		draw_colored_polygon(PackedVector2Array([Vector2(-6, 10), Vector2(6, 10), Vector2(0, 15)]), Color("efce8a"))
