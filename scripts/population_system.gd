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
		var awake := (GameClock.hour() >= 6 and GameClock.hour() < 22) or npc.get_index() % 4 == 0 or npc.has_meta("person_id")
		npc.set_process((close and awake) or npc.indoor_time > 0)
		npc.visible = close and awake and npc.indoor_time <= 0
