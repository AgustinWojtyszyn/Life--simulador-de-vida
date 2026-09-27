class_name InteractionTarget
extends Node2D

@export var label := "Interactuar"
@export var action := ""
@export var target_id := ""
@export var detail := ""

func _ready() -> void:
	add_to_group("interactables")

func can_interact(player: Node2D) -> bool:
	var reach := 68.0 if InputManager.touch_enabled else 52.0
	return is_visible_in_tree() and player.global_position.distance_to(global_position) < reach and not player.transitioning

func perform(player: Node2D) -> String:
	if action == "enter_home":
		WorldManager.call_deferred("travel", "home")
		return ""
	if action in ["exit_home", "exit_interior"]:
		WorldManager.call_deferred("travel", "street")
		return ""
	if action.begins_with("enter_"):
		var destination := action.trim_prefix("enter_")
		if destination in WorldManager.PUBLIC_INTERIORS:
			WorldManager.return_position = global_position + Vector2(0, 18)
			WorldManager.call_deferred("travel", destination)
		return ""

	match action:
		"rest", "tv", "pc", "fridge", "eat", "coffee", "cook", "shower", "buy_food", "play_football":
			var result := LifeSimulation.act(action)
			if not result.begins_with("Necesitás") and not result.begins_with("Faltan"):
				player.perform_activity(action)
			if action == "buy_food":
				MissionSystem.purchased()
			if action == "play_football":
				AudioSystem.play_sfx("kick", player.global_position)
			return result
		"shop":
			return detail + " · Horario de atención: 9 a 20."
	return ""
