extends CharacterBody2D

const SPEED := 140.0
const ACCELERATION := 1100.0
const DECELERATION := 1500.0
const SOUTH := preload("res://assets/characters/resident/south.png")
const NORTH := preload("res://assets/characters/resident/north.png")
const EAST := preload("res://assets/characters/resident/east.png")
const WEST := preload("res://assets/characters/resident/west.png")
var facing := Vector2.DOWN
@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var rate := ACCELERATION if direction != Vector2.ZERO else DECELERATION
	velocity = velocity.move_toward(direction * SPEED, rate * delta)
	if direction != Vector2.ZERO:
		facing = direction
		if absf(facing.x) > absf(facing.y):
			sprite.texture = EAST if facing.x > 0 else WEST
		else:
			sprite.texture = SOUTH if facing.y > 0 else NORTH
	move_and_slide()


func _draw() -> void:
	draw_ellipse_shadow()


func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 9, Color(0.05, 0.1, 0.12, 0.25))
	draw_set_transform(Vector2.ZERO)
