extends Node2D

var tint := CanvasModulate.new()
var rain: CPUParticles2D
var lamps: Array[Node2D] = []

func _ready() -> void:
	add_child(tint)
	GameClock.changed.connect(refresh)
	WeatherSystem.changed.connect(refresh)
	if WorldManager.location == "street":
		rain = CPUParticles2D.new()
		rain.amount = 160
		rain.lifetime = 0.65
		rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		rain.emission_rect_extents = Vector2(620, 380)
		rain.direction = Vector2(-0.25, 1)
		rain.spread = 0
		rain.initial_velocity_min = 380
		rain.initial_velocity_max = 430
		rain.gravity = Vector2.ZERO
		rain.color = Color(0.76, 0.86, 0.96, 0.55)
		var image := Image.create(2, 10, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		rain.texture = ImageTexture.create_from_image(image)
		rain.z_index = 100
		add_child(rain)
	refresh()

func refresh() -> void:
	tint.color = GameClock.tint() if WorldManager.location == "street" else Color.WHITE.lerp(GameClock.tint(), 0.22)
	if WorldManager.location == "street" and WeatherSystem.state != "clear":
		tint.color = tint.color * Color("b3bfcc")
	if is_instance_valid(rain):
		rain.emitting = WeatherSystem.state == "rain"
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(rain):
		rain.position = get_parent().get_node("Player").position

func _draw() -> void:
	if WorldManager.location != "street" or GameClock.hour() >= 8 and GameClock.hour() < 18:
		return
	for lamp in get_tree().get_nodes_in_group("street_lamps"):
		var at: Vector2 = lamp.position - Vector2(0, 60)
		for i in range(4, 0, -1):
			draw_circle(at, i * 12, Color(1.0, 0.8, 0.4, 0.035))
		draw_circle(at, 3, Color("ffe4a1"))
