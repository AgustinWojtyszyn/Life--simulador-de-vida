extends Node

var residents: Array[Node2D] = []
var timer := 0.0

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0:
		return
	timer = 0.4
	var player: Node2D = get_parent().get_node("Player")
	for npc in residents:
		var close := npc.position.distance_squared_to(player.position) < 850.0 * 850.0
		npc.set_process(close)
		npc.visible = close and npc.indoor_time <= 0
