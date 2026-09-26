class_name CityBuilding
extends Node2D

enum Access { EXTERIOR_ONLY, INTERACTABLE, ENTERABLE }
var access := Access.EXTERIOR_ONLY
var building_id := ""
var title := ""
var facade: Texture2D
var size := Vector2(208, 236)
var is_home := false

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = facade
	sprite.region_enabled = true
	sprite.region_rect = facade.get_image().get_used_rect()
	sprite.scale = size / facade.get_size()
	sprite.position = Vector2(0, -sprite.region_rect.size.y * sprite.scale.y / 2)
	add_child(sprite)
	set_meta("building_mode", Access.keys()[access])
	if access != Access.EXTERIOR_ONLY:
		var door := Node2D.new()
		door.position = Vector2(0, 16)
		door.set_meta("prompt", "Entrar a tu vivienda" if is_home else "Consultar " + title)
		door.set_meta("action", "enter_home" if is_home else "shop")
		door.set_meta("id", building_id)
		door.set_meta("title", title)
		door.add_to_group("interactables")
		add_child(door)

func _draw() -> void:
	var width := 108 if is_home else 104
	draw_rect(Rect2(-width / 2, -7, width, 15), Color("263d40"))
	draw_string(ThemeDB.fallback_font, Vector2(-width / 2 + 3, 4), "TU HOGAR" if is_home else title, HORIZONTAL_ALIGNMENT_CENTER, width - 6, 9, Color("f0d5a0"))
	if is_home:
		draw_colored_polygon(PackedVector2Array([Vector2(-6, 10), Vector2(6, 10), Vector2(0, 15)]), Color("efce8a"))
