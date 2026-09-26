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

func perform(player: Node2D) -> String:
	match action:
		"enter_home", "exit_home", "enter_shop", "enter_cafe":
			if action in ["enter_shop", "enter_cafe"]:
				WorldManager.return_position = global_position + Vector2(0, 18)
			var destination := "home" if action == "enter_home" else "shop" if action == "enter_shop" else "cafe" if action == "enter_cafe" else "street"
			WorldManager.call_deferred("travel", destination)
			return ""
		"rest", "tv", "pc", "fridge", "eat", "coffee", "cook", "shower", "buy_food":
			var result := LifeSimulation.act(action)
			if not result.begins_with("Necesitás") and not result.begins_with("Faltan"):
				player.perform_activity(action)
			if action == "buy_food": MissionSystem.purchased()
			return result
		"shop": return detail + " · Horario de atención: 9 a 20."
	return ""
