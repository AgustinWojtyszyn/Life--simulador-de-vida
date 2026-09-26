extends Node

const InteractionTargetScript := preload("res://scripts/interaction_target.gd")

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
	if InputManager.interact_pressed():
		interact()
	elif is_instance_valid(seated_bench) and not player.transitioning and InputManager.movement() != Vector2.ZERO:
		stand_up()
	if is_instance_valid(hud):
		hud.set_interaction(prompt, message)

func refresh_target() -> void:
	target = null
	kind = ""
	prompt = ""
	if is_instance_valid(seated_bench):
		prompt = "" if player.transitioning else "E · Levantarte"
		return
	var nearest := 49.0
	for group in ["interactables", "city_benches", "city_residents", "city_fountain"]:
		for node in get_tree().get_nodes_in_group(group):
			if not node.is_visible_in_tree():
				continue
			if node.get_script() == InteractionTargetScript and not node.can_interact(player):
				continue
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
		"interactables": prompt = "E · " + (target.label if target.get_script() == InteractionTargetScript else str(target.get_meta("prompt", "Interactuar")))
		"city_benches": prompt = "E · Sentarte a descansar"
		"city_residents": prompt = "E · Saludar al vecino"
		"city_fountain": prompt = "E · Pedir un deseo"

func interact() -> void:
	if cooldown > 0 or player.transitioning:
		return
	if is_instance_valid(seated_bench):
		stand_up()
		return
	refresh_target()
	if not is_instance_valid(target):
		return
	LifeEvents.interacted.emit(kind, str(target.get_meta("id", target.name)))
	match kind:
		"interactables":
			if target.get_script() == InteractionTargetScript:
				say(target.perform(player))
			else:
				legacy_interaction()
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

func legacy_interaction() -> void:
	match str(target.get_meta("action", "")):
		"enter_home": WorldManager.call_deferred("travel", "home")
		"exit_home": WorldManager.call_deferred("travel", "street")
		"rest":
			WorldManager.basic_state["rested"] = true
			LifeEvents.rested.emit(WorldManager.profile.home_id)
			say("Descansaste en tu cama. Este es tu hogar.")
		"shop": say(str(target.get_meta("title", "Comercio")) + " · Horario de atención: 9 a 20.")

func stand_up() -> void:
	player.stand(stand_position)
	seated_bench = null
	cooldown = 0.25
	say("A seguir recorriendo el barrio.")

func say(text: String) -> void:
	message = text
	message_time = 3.5
