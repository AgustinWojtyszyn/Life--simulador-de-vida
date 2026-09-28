extends Node

var residents: Array[Node2D] = []
var timer := 0.0
# Spatial grid for efficient neighbor queries
var spatial_grid: Dictionary = {}  # Vector2i(cell) -> Array[Node2D]
const CELL_SIZE := 128.0
# Central registry for traffic and signals to avoid repeated global scans
var traffic_registry: Array[Node] = []
var signal_registry: Array[Node] = []
var registry_timer := 0.0

func _ready() -> void:
	add_to_group("population_system")

func _physics_process(delta: float) -> void:
	_update_spatial_grid()
	timer -= delta
	if timer > 0:
		return
	timer = 0.4
	registry_timer -= 0.4
	if registry_timer <= 0.0:
		registry_timer = 0.5
		_update_registries()
	var player: Node2D = get_parent().get_node("Player")
	for npc in residents:
		var close := npc.position.distance_squared_to(player.position) < 850.0 * 850.0
		var awake := (GameClock.hour() >= 6 and GameClock.hour() < 22) or npc.get_index() % 4 == 0 or npc.has_meta("person_id")
		npc.set_physics_process((close and awake) or npc.indoor_time > 0)
		npc.visible = close and awake and npc.indoor_time <= 0
		npc.collision_layer = 4 if npc.visible else 0

func _update_registries() -> void:
	# Update central registries every 0.5s to avoid repeated global scans
	traffic_registry.clear()
	for node in get_tree().get_nodes_in_group("city_traffic"):
		if is_instance_valid(node):
			traffic_registry.append(node)
	signal_registry.clear()
	for node in get_tree().get_nodes_in_group("traffic_signals"):
		if is_instance_valid(node):
			signal_registry.append(node)

func get_traffic_registry() -> Array[Node]:
	if traffic_registry.is_empty():
		_update_registries()
	return traffic_registry

func get_signal_registry() -> Array[Node]:
	if signal_registry.is_empty():
		_update_registries()
	return signal_registry

func _update_spatial_grid() -> void:
	spatial_grid.clear()
	for npc in get_tree().get_nodes_in_group("city_residents"):
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
