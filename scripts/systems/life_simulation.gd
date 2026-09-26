extends Node

signal changed
var money := 80
var energy := 85.0
var wellbeing := 70.0
var reputation := 0
var inventory: Dictionary = {}
var last_minutes := 480.0

func _ready() -> void:
	GameClock.changed.connect(on_time)

func on_time() -> void:
	var elapsed := maxf(0, GameClock.total_minutes - last_minutes)
	last_minutes = GameClock.total_minutes
	if WorldManager.playing:
		energy = clampf(energy - elapsed * 0.018, 0, 100)
		wellbeing = clampf(wellbeing - elapsed * 0.005, 0, 100)
		changed.emit()

func act(action: String) -> String:
	match action:
		"rest":
			GameClock.advance(480)
			energy = 100
			wellbeing = minf(100, wellbeing + 8)
			WorldManager.basic_state["rested"] = true
			LifeEvents.rested.emit(WorldManager.profile.home_id)
			changed.emit()
			return "Dormiste ocho horas. Empezás con energía renovada."
		"buy_food":
			if money < 12: return "Necesitás $12 para comprar provisiones."
			money -= 12
			inventory["food"] = int(inventory.get("food", 0)) + 1
			changed.emit()
			return "Compraste provisiones por $12. Están en tu inventario."
		"eat", "cook", "fridge":
			if int(inventory.get("food", 0)) < 1: return "Faltan provisiones. Podés comprarlas en el mercado."
			inventory["food"] -= 1
			GameClock.advance(25)
			energy = minf(100, energy + 24)
			wellbeing = minf(100, wellbeing + 8)
		"coffee":
			if money < 5: return "El café cuesta $5."
			money -= 5
			energy = minf(100, energy + 12)
			wellbeing = minf(100, wellbeing + 6)
			GameClock.advance(15)
		"pc":
			if energy < 20: return "Necesitás descansar antes de trabajar."
			GameClock.advance(90)
			energy = maxf(0, energy - 15)
			money += 20
		"tv":
			GameClock.advance(30)
			wellbeing = minf(100, wellbeing + 12)
		"shower":
			GameClock.advance(15)
			wellbeing = minf(100, wellbeing + 10)
	changed.emit()
	return {"eat": "Comiste y recuperaste energía.", "cook": "Cocinaste tus provisiones. ¡Buen provecho!", "fridge": "Preparaste una comida con tus provisiones.", "coffee": "Un café y una pausa. Pagaste $5.", "pc": "Completaste un encargo en la PC. Ganaste $20.", "tv": "Disfrutaste un programa. Te sentís mejor.", "shower": "Una ducha para empezar de nuevo."}.get(action, "")

func to_dict() -> Dictionary:
	return {"money": money, "energy": energy, "wellbeing": wellbeing, "reputation": reputation, "inventory": inventory.duplicate(true)}

func restore(data: Dictionary) -> void:
	money = maxi(0, int(data.get("money", 80)))
	energy = clampf(float(data.get("energy", 85)), 0, 100)
	wellbeing = clampf(float(data.get("wellbeing", 70)), 0, 100)
	reputation = int(data.get("reputation", 0))
	inventory = data.get("inventory", {}).duplicate(true) if data.get("inventory", {}) is Dictionary else {}
	last_minutes = GameClock.total_minutes
	changed.emit()
