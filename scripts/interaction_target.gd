class_name InteractionTarget
extends Node2D

@export var label := "Interactuar"
@export var action := ""
@export var target_id := ""
@export var detail := ""

func _ready() -> void:
	add_to_group("interactables")

func can_interact(player: Node2D) -> bool:
	return is_visible_in_tree() and player.global_position.distance_to(global_position) < 50.0 and not player.transitioning

func perform(_player: Node2D) -> String:
	match action:
		"enter_home", "exit_home", "enter_shop", "enter_cafe":
			if action in ["enter_shop", "enter_cafe"]:
				WorldManager.return_position = global_position + Vector2(0, 18)
			var destination := "home" if action == "enter_home" else "shop" if action == "enter_shop" else "cafe" if action == "enter_cafe" else "street"
			WorldManager.call_deferred("travel", destination)
			return ""
		"rest":
			WorldManager.basic_state["rested"] = true
			LifeEvents.rested.emit(WorldManager.profile.home_id)
			return "Descansaste en tu cama."
		"shop": return detail + " · Horario de atención: 9 a 20."
		"tv": return "Encendiste la televisión. Un programa acompaña la tarde."
		"pc": return "Revisaste mensajes y trabajaste un rato."
		"fridge": return "Abriste la heladera y preparaste algo fresco."
		"eat": return "Te sentaste a comer y recuperaste energía."
		"coffee": return "Tomaste algo en " + detail + "."
	return ""
