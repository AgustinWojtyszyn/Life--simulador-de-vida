extends CharacterBody2D

const SPEED := 140.0
const ACCELERATION := 1100.0
const DECELERATION := 1500.0
const SOUTH := preload("res://assets/characters/resident/south.png")
const NORTH := preload("res://assets/characters/resident/north.png")
const EAST := preload("res://assets/characters/resident/east.png")
const WEST := preload("res://assets/characters/resident/west.png")
const SEATED := preload("res://assets/characters/resident/seated.png")
const WAVE := preload("res://assets/characters/resident/wave.png")
var seated := false
var wave_time := 0.0
var facing := Vector2.DOWN
@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	if seated:
		velocity = Vector2.ZERO
		return
	wave_time = maxf(0, wave_time - delta)
	if wave_time > 0:
		sprite.texture = WAVE
	else:
		sprite.texture = (EAST if facing.x > 0 else WEST) if absf(facing.x) > absf(facing.y) else (SOUTH if facing.y >= 0 else NORTH)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var rate := ACCELERATION if direction != Vector2.ZERO else DECELERATION
	velocity = velocity.move_toward(direction * SPEED, rate * delta)
	if direction != Vector2.ZERO:
		facing = direction
		if absf(facing.x) > absf(facing.y):
			sprite.texture = EAST if facing.x > 0 else WEST
		else:
			sprite.texture = SOUTH if facing.y > 0 else NORTH
	if wave_time > 0:
		sprite.texture = WAVE
	move_and_slide()


func _draw() -> void:
	draw_ellipse_shadow()


func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 9, Color(0.05, 0.1, 0.12, 0.25))
	draw_set_transform(Vector2.ZERO)

func sit(at: Vector2) -> void:
	seated = true
	wave_time = 0
	velocity = Vector2.ZERO
	global_position = at
	collision_layer = 0
	collision_mask = 0
	sprite.texture = SEATED
	sprite.position.y = -22

func stand(at: Vector2) -> void:
	global_position = at
	seated = false
	collision_layer = 1
	collision_mask = 3
	facing = Vector2.DOWN
	sprite.texture = SOUTH
	sprite.position.y = -14

func wave() -> void:
	wave_time = 1.5
	sprite.texture = WAVE
