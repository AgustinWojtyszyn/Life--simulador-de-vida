extends Node

signal changed
const CLIMATES := {"ar": 24, "us": 23, "jp": 38, "it": 18, "br": 42}
var state := "clear"
var next_change := 840.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	GameClock.changed.connect(update_weather)

func update_weather() -> void:
	if GameClock.total_minutes < next_change:
		return
	var rain_chance: int = CLIMATES.get(WorldManager.profile.country_id, 25)
	var roll := rng.randi_range(0, 99)
	state = "rain" if roll < rain_chance else "cloudy" if roll < rain_chance + 25 else "clear"
	next_change = GameClock.total_minutes + rng.randf_range(240, 600)
	changed.emit()

func title() -> String:
	return "Lluvia" if state == "rain" else "Nublado" if state == "cloudy" else "Despejado"

func to_dict() -> Dictionary:
	return {"state": state, "next_change": next_change}

func restore(data: Dictionary) -> void:
	state = str(data.get("state", "clear"))
	if state not in ["clear", "cloudy", "rain"]:
		state = "clear"
	next_change = maxf(GameClock.total_minutes + 1, float(data.get("next_change", 840)))
	changed.emit()
