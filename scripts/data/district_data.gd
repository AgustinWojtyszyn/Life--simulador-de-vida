class_name DistrictData
extends Resource

@export var id := "centro"
@export var title := "Distrito inicial"
@export var world_size := Vector2(4800, 3200)
@export var home_position := Vector2(1550, 325)
@export var side_street_x := 1810.0
@export var side_street_width := 120.0
@export var population := 38
@export var building_slots: Array[Dictionary] = []

@export var available := false
@export var district_style_weights: Dictionary = {}

func asset_pool_at(point: Vector2) -> String:
	# Stable block-sized clusters keep neighbouring facades coherent.
	var total := 0
	for weight in district_style_weights.values():
		total += maxi(0, int(weight))
	if total == 0: return "ar"
	var pick := posmod(int(floor(point.x / 900)) * 37 + int(floor(point.y / 760)) * 61, total)
	for pool in district_style_weights:
		pick -= maxi(0, int(district_style_weights[pool]))
		if pick < 0: return pool
	return "ar"
