extends Node

var player: CharacterBody2D
var hud: Control
var target: Node2D
var kind := ""
var prompt := ""
var message := ""
var message_time := 0.0
var cooldown := 0.0
var seated_bench: Node2D
var stand_position := Vector2.ZERO

func _ready() -> void:
	player = get_parent().get_node("Player")

func _process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	message_time = maxf(0, message_time - delta)
	if message_time == 0:
		message = ""
	refresh_target()
	if Input.is_action_just_pressed("interact"):
		interact()
	elif is_instance_valid(seated_bench) and Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO:
		stand_up()
	if is_instance_valid(hud):
		hud.set_interaction(prompt, message)

func refresh_target() -> void:
	target = null
	kind = ""
	prompt = ""
	if is_instance_valid(seated_bench):
		prompt = "E · Levantarte"
		return
	var nearest := 49.0
	for group in ["city_benches", "city_residents", "city_fountain"]:
		for node in get_tree().get_nodes_in_group(group):
			var anchor: Vector2 = node.global_position
			if group == "city_benches":
				anchor += Vector2(0, 16)
			elif group == "city_fountain":
				anchor += Vector2(0, 18)
			var distance := player.global_position.distance_to(anchor)
			if distance < nearest:
				nearest = distance
				target = node
				kind = group
	match kind:
		"city_benches": prompt = "E · Sentarte a descansar"
		"city_residents": prompt = "E · Saludar al vecino"
		"city_fountain": prompt = "E · Pedir un deseo"

func interact() -> void:
	if cooldown > 0:
		return
	if is_instance_valid(seated_bench):
		stand_up()
		return
	refresh_target()
	if not is_instance_valid(target):
		return
	match kind:
		"city_benches":
			# Always stand back on the approach side, outside the bench footprint.
			stand_position = target.global_position + Vector2(0, 18)
			seated_bench = target
			player.sit(target.global_position + Vector2(0, 2))
			say("Un descanso a la sombra. E o movete para levantarte.")
		"city_residents":
			player.wave()
			target.greet()
			say("Vecino: ¡Buenas! Linda tarde para pasear.")
		"city_fountain":
			player.wave()
			target.make_wish()
			say("Pediste un deseo. Las ondas se alejan por el agua.")
	cooldown = 0.4

func stand_up() -> void:
	player.stand(stand_position)
	seated_bench = null
	cooldown = 0.25
	say("A seguir recorriendo el barrio.")

func say(text: String) -> void:
	message = text
	message_time = 3.5
