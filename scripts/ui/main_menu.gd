extends Control

signal play_requested
var draft := PlayerProfile.new()
var chosen := "ar"
var panel: VBoxContainer
var preview: CharacterVisual
var country_preview: TextureRect
var name_edit: LineEdit
var error_label: Label
var busy := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme_resource := Theme.new()
	theme_resource.default_font_size = 16
	for type in ["Button", "OptionButton", "LineEdit"]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("253d42")
		normal.set_corner_radius_all(6)
		normal.content_margin_left = 16
		normal.content_margin_right = 16
		normal.content_margin_top = 10
		normal.content_margin_bottom = 10
		theme_resource.set_stylebox("normal", type, normal)
		var focus := normal.duplicate()
		focus.border_color = Color("d9b47c")
		focus.set_border_width_all(2)
		theme_resource.set_stylebox("focus", type, focus)
		theme_resource.set_stylebox("hover", type, focus)
		theme_resource.set_color("font_color", type, Color("eee5d2"))
	theme = theme_resource
	main_screen()

func shell(title: String, subtitle: String) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("112329")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := TextureRect.new()
	art.texture = load("res://assets/city/buildings/cafe.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	art.anchor_left = 0.58
	art.modulate = Color(0.8, 0.8, 0.7, 0.2)
	add_child(art)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	scroll.add_child(panel)
	label(title, 30, Color("f0dfbe"))
	label(subtitle, 14, Color("a5b7b3"))

func label(text: String, font_size := 16, color := Color("eee5d2")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	panel.add_child(node)
	return node

func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 44
	node.pressed.connect(action)
	panel.add_child(node)
	return node

func main_screen() -> void:
	shell("VIDA", "Tu vida. Tu ciudad. Tus decisiones.")
	button("Nueva partida", create_screen)
	var resume := button("Continuar", resume_game)
	resume.disabled = not SaveSystem.has_save()
	label("Un hogar. Cinco destinos. Una vida por empezar.", 14)
	error_label = label("")

func resume_game() -> void:
	if busy:
		return
	busy = true
	if not WorldManager.continue_game():
		busy = false
		error_label.text = SaveSystem.last_error

func create_screen() -> void:
	shell("CREAR PERSONAJE", "Elegí cómo empieza tu historia.")
	var row := HBoxContainer.new()
	panel.add_child(row)
	var preview_box := Control.new()
	preview_box.custom_minimum_size = Vector2(105, 106)
	row.add_child(preview_box)
	preview = CharacterVisual.new()
	preview.profile = draft
	preview.position = Vector2(52, 100)
	preview.scale = Vector2.ONE * 3
	preview_box.add_child(preview)
	var fields := VBoxContainer.new()
	fields.custom_minimum_size.x = 160
	row.add_child(fields)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Tu nombre"
	name_edit.max_length = 24
	name_edit.text = draft.player_name
	name_edit.custom_minimum_size.y = 44
	fields.add_child(name_edit)
	var gender := OptionButton.new()
	gender.add_item("Hombre")
	gender.add_item("Mujer")
	gender.selected = 1 if draft.gender == "female" else 0
	gender.custom_minimum_size.y = 44
	gender.item_selected.connect(func(i: int): draft.gender = "female" if i == 1 else "male"; preview.apply_profile(draft))
	fields.add_child(gender)
	var grid := GridContainer.new()
	grid.columns = 2
	row.add_child(grid)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in [["skin", "Piel", ["Clara", "Media", "Oscura"]], ["hair", "Cabello", ["Natural", "Flequillo", "Lateral"]], ["hair_color", "Color de cabello", ["Castaño", "Rubio", "Negro"]], ["top", "Prenda superior", ["Turquesa", "Bordó", "Azul"]], ["bottom", "Pantalón", ["Gris", "Arena", "Denim"]]]:
		var title := Label.new()
		title.text = entry[1]
		grid.add_child(title)
		var choice := OptionButton.new()
		choice.custom_minimum_size.y = 38
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for option in entry[2]:
			choice.add_item(option)
		choice.selected = draft.get(entry[0])
		choice.item_selected.connect(func(i: int): draft.set(entry[0], i); preview.apply_profile(draft))
		grid.add_child(choice)
	error_label = label("", 12)
	button("Continuar → Elegir país", func():
		if name_edit.text.strip_edges().is_empty():
			error_label.text = "Ingresá un nombre para continuar."
			return
		draft.player_name = name_edit.text.strip_edges()
		country_screen())
	button("Volver", main_screen)

func country_screen() -> void:
	shell("ELEGÍ DÓNDE EMPEZAR", "Una vivienda propia te espera en cada destino.")
	var selection := OptionButton.new()
	selection.custom_minimum_size.y = 46
	panel.add_child(selection)
	country_preview = TextureRect.new()
	country_preview.custom_minimum_size = Vector2(180, 140)
	country_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	country_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(country_preview)
	var info := label("", 15)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for country in WorldManager.countries:
		selection.add_item(country.title)
	selection.item_selected.connect(func(i: int):
		var country: CountryData = WorldManager.countries[i]
		chosen = country.id
		country_preview.texture = load(country.facade)
		info.text = country.cities[0].title + " · " + country.description)
	selection.select(["ar", "us", "jp", "it", "br"].find(chosen))
	selection.item_selected.emit(selection.selected)
	button("Comenzar mi vida", func():
		if busy:
			return
		busy = true
		WorldManager.new_game(draft, chosen))
	button("Volver al personaje", create_screen)
