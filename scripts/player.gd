extends CharacterBody2D

const SPEED := 140.0
const ACCELERATION := 900.0
const DECELERATION := 1800.0
const SOUTH := preload("res://assets/characters/resident/south.png")
const NORTH := preload("res://assets/characters/resident/north.png")
const EAST := preload("res://assets/characters/resident/east.png")
const WEST := preload("res://assets/characters/resident/west.png")
const SEATED := preload("res://assets/characters/resident/seated.png")
const WAVE := preload("res://assets/characters/resident/wave.png")
var action_time := 0.0
var action_pose := "idle"
var seated := false
var transitioning := false
var wave_time := 0.0
var facing := Vector2.DOWN
@onready var sprite: Sprite2D = $Sprite2D
var visual: CharacterVisual

func _ready() -> void:
	# Top-down movement: treat every collision as a wall, not as a floor/slope.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 7 # world + traffic + residents
	visual = CharacterVisual.new()
	visual.profile = WorldManager.profile
	add_child(visual)
	sprite.hide() # Retained for old scene references; visible body uses directional walk frames.
	$Camera2D.position_smoothing_speed = 12.0
	# Mobile keeps the resident legible without changing desktop framing.
	$Camera2D.zoom = Vector2.ONE * (1.12 if InputManager.touch_enabled else 1.0)


func _physics_process(delta: float) -> void:
	if action_time > 0:
		action_time = maxf(0, action_time - delta)
		velocity = Vector2.ZERO
		visual.animate_activity(action_pose, delta)
		return
	if seated or transitioning:
		velocity = Vector2.ZERO
		return
	wave_time = maxf(0, wave_time - delta)
	var raw_direction := InputManager.movement()
	# IMPORTANT: normalize so diagonal is not √2 faster than cardinal
	var direction := raw_direction.normalized() if raw_direction.length_squared() > 0.01 else Vector2.ZERO
	var target_speed := SPEED
	if InputManager.touch_enabled:
		# Touch joystick gives analogue magnitude — preserve it
		target_speed = SPEED * clampf(raw_direction.length(), 0.0, 1.0)
	var rate := ACCELERATION if direction != Vector2.ZERO else DECELERATION
	if direction.dot(velocity.normalized()) < -0.2:
		rate = 1600.0  # direction changes should feel deliberate, not icy
	velocity = velocity.move_toward(direction * target_speed, rate * delta)
	if direction == Vector2.ZERO and velocity.length_squared() < 4.0:
		velocity = Vector2.ZERO
	if direction != Vector2.ZERO:
		facing = direction
	var before := position
	move_and_slide()
	var moved := position - before
	if wave_time > 0:
		visual.set_art("wave", "south", 0)
	else:
		visual.animate_motion(moved, moved.length())


func _draw() -> void:
	draw_ellipse_shadow()


func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 9, Color(0.05, 0.1, 0.12, 0.25))
	draw_set_transform(Vector2.ZERO)

func sit(at: Vector2) -> void:
	if transitioning or seated:
		return
	transitioning = true
	wave_time = 0
	velocity = Vector2.ZERO
	# Approach the seat on foot, face it, then lower into the seated pose.
	var approach := at + Vector2(0, 17)
	var walk := create_tween()
	walk.tween_property(self, "global_position", approach, global_position.distance_to(approach) / 85.0)
	await walk.finished
	if not is_inside_tree():
		return
	facing = Vector2.UP
	visual.set_art("idle", "north", 0)
	var lower := create_tween()
	lower.tween_property(self, "global_position", at, 0.28).set_trans(Tween.TRANS_SINE)
	await lower.finished
	if not is_inside_tree():
		return
	collision_layer = 0
	collision_mask = 0
	sprite.texture = SEATED
	sprite.position.y = -22
	visual.set_art("seated", "south", 0)
	seated = true
	transitioning = false

func stand(at: Vector2) -> void:
	if transitioning or not seated:
		return
	transitioning = true
	seated = false
	visual.set_art("idle", "south", 0)
	var rise := create_tween()
	rise.tween_property(self, "global_position", at, 0.3).set_trans(Tween.TRANS_SINE)
	await rise.finished
	if not is_inside_tree():
		return
	collision_layer = 1
	collision_mask = 7
	facing = Vector2.DOWN
	sprite.texture = SOUTH
	sprite.position.y = -14
	transitioning = false

func wave() -> void:
	wave_time = 1.5
	sprite.texture = WAVE

func perform_activity(action: String) -> void:
	action_pose = {
		"coffee": "drink",
		"fridge": "eat",
		"cook": "eat",
		"buy_food": "browse",
		"rest": "idle_live",
		"play_football": "kick",
	}.get(action, action)
	# Missing bespoke frames no longer make an interaction visually inert.
	# CharacterVisual supplies a lightweight procedural fallback until a full
	# authored animation family exists for that activity.
	action_time = 2.6
	visual.activity_phase = 0.0
