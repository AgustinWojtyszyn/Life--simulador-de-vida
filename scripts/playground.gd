extends Node2D

const MAP_SIZE := Vector2(960, 640)
const GRASS := preload("res://assets/environment/grass.png")
const GROUND := preload("res://assets/environment/ground.png")
const SIDEWALK := preload("res://assets/environment/sidewalk.png")
const OBSTACLE := preload("res://assets/environment/obstacle.png")
const OBSTACLES: Array[Rect2] = [
	Rect2(240, 176, 96, 64),
	Rect2(592, 272, 96, 80),
	Rect2(352, 432, 128, 48),
	Rect2(720, 464, 64, 64),
]


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	configure_input()
	for rect in OBSTACLES:
		add_solid(rect)
	for rect in [Rect2(0, 0, 960, 16), Rect2(0, 624, 960, 16),
		Rect2(0, 0, 16, 640), Rect2(944, 0, 16, 640)]:
		add_solid(rect)


func configure_input() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func add_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)


func _draw() -> void:
	draw_texture_rect(GRASS, Rect2(Vector2.ZERO, MAP_SIZE), true)
	draw_texture_rect(GROUND, Rect2(16, 288, 928, 64), true)
	draw_texture_rect(SIDEWALK, Rect2(448, 16, 64, 608), true)
	# Fine inset edging gives the existing paths depth without widening them.
	for rect in [Rect2(16, 288, 432, 1), Rect2(512, 288, 432, 1),
		Rect2(448, 16, 1, 608)]:
		draw_rect(rect, Color("d1c4a0"))
	for rect in [Rect2(16, 351, 432, 1), Rect2(512, 351, 432, 1),
		Rect2(511, 16, 1, 608)]:
		draw_rect(rect, Color("696d52"))
	for rect in OBSTACLES:
		draw_rect(Rect2(rect.position + Vector2(3, 5), rect.size), Color(0.10, 0.15, 0.17, 0.3))
		draw_texture_rect(OBSTACLE, rect, true)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color("a4b3b5"))
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 5), Vector2(rect.size.x, 5)), Color("414f60"))
	for rect in [Rect2(0, 0, 960, 16), Rect2(0, 624, 960, 16),
		Rect2(0, 16, 16, 608), Rect2(944, 16, 16, 608)]:
		draw_texture_rect(OBSTACLE, rect, true)
