extends Node

var residents: Array[Node2D] = []
var timer := 0.0
# Spatial grid for efficient neighbor queries
var spatial_grid: Dictionary = {}  # Vector2i(cell) -> Array[Node2D]
const CELL_SIZE := 128.0

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0:
		return
	timer = 0.4
	var player: Node2D = get_parent().get_node("Player")
	_update_spatial_grid()
	for npc in residents:
		var close := npc.position.distance_squared_to(player.position) < 850.0 * 850.0
		var awake := (GameClock.hour() >= 6 and GameClock.hour() < 22) or npc.get_index() % 4 == 0 or npc.has_meta("person_id")
		npc.set_physics_process((close and awake) or npc.indoor_time > 0)
		npc.visible = close and awake and npc.indoor_time <= 0

func _update_spatial_grid() -> void:
	spatial_grid.clear()
	for npc in residents:
		if not is_instance_valid(npc) or not npc.visible:
			continue
		var cell := Vector2i(npc.position / CELL_SIZE)
		if not spatial_grid.has(cell):
			spatial_grid[cell] = []
		spatial_grid[cell].append(npc)

func get_nearby_npcs(position: Vector2, radius: float) -> Array[Node2D]:
	# Efficient neighbor query using spatial grid
	var result: Array[Node2D] = []
	var cell_radius := int(radius / CELL_SIZE) + 1
	var center_cell := Vector2i(position / CELL_SIZE)
	for x in range(-cell_radius, cell_radius + 1):
		for y in range(-cell_radius, cell_radius + 1):
			var cell := center_cell + Vector2i(x, y)
			if spatial_grid.has(cell):
				for npc in spatial_grid[cell]:
					if npc.position.distance_squared_to(position) < radius * radius:
						result.append(npc)
	return result
