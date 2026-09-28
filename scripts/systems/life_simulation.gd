extends Node

signal changed
var money := 80
var energy := 85.0
var wellbeing := 70.0
var reputation := 0
var inventory: Dictionary = {}
var last_minutes := 480.0
var daily_actions: Dictionary = {}

func _ready() -> void:
	GameClock.changed.connect(on_time)

func on_time() -> void:
	var elapsed := maxf(0, GameClock.total_minutes - last_minutes)
	last_minutes = GameClock.total_minutes
	if WorldManager.playing:
		energy = clampf(energy - elapsed * 0.018, 0, 100)
		wellbeing = clampf(wellbeing - elapsed * 0.005, 0, 100)
		changed.emit()

func action_count_today(action: String) -> int:
	var key := "%d:%s" % [GameClock.day(), action]
	return int(daily_actions.get(key, 0))

func mark_action(action: String) -> void:
	var key := "%d:%s" % [GameClock.day(), action]
	daily_actions[key] = action_count_today(action) + 1
	prune_daily_actions()

func prune_daily_actions() -> void:
	# Keep only recent counters. Long-running saves should not grow forever.
	var oldest_day := maxi(1, GameClock.day() - 2)
	for key in daily_actions.keys():
		var day_text := str(key).get_slice(":", 0)
		if day_text.is_valid_int() and int(day_text) < oldest_day:
			daily_actions.erase(key)

func act(action: String) -> String:
	match action:
		"sleep":
			GameClock.advance(480)
			energy = 100
			wellbeing = minf(100, wellbeing + 8)
			WorldManager.basic_state["rested"] = true
			LifeEvents.rested.emit(WorldManager.profile.home_id)
			changed.emit()
			return "Dormiste ocho horas. Empezás con energía renovada."
		"rest":
			GameClock.advance(30)
			var first_rest := action_count_today("rest") == 0
			energy = minf(100, energy + (12 if first_rest else 4))
			wellbeing = minf(100, wellbeing + (5 if first_rest else 1))
			mark_action("rest")
			changed.emit()
			return "Descansaste un rato. Recuperaste algo de energía."
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
			if energy < 8: return "Necesitás descansar antes de usar la computadora."
			GameClock.advance(30)
			energy = maxf(0, energy - 3)
			var pc_gain := 4.0 if action_count_today("pc") == 0 else 1.0
			wellbeing = minf(100, wellbeing + pc_gain)
			mark_action("pc")
		"browse":
			GameClock.advance(10)
			var browse_gain := 3.0 if action_count_today("browse") == 0 else 1.0
			wellbeing = minf(100, wellbeing + browse_gain)
			mark_action("browse")
		"tv":
			GameClock.advance(30)
			var tv_gain := 8.0 if action_count_today("tv") == 0 else 2.0
			wellbeing = minf(100, wellbeing + tv_gain)
			mark_action("tv")
		"shower":
			GameClock.advance(15)
			var shower_gain := 6.0 if action_count_today("shower") == 0 else 1.0
			wellbeing = minf(100, wellbeing + shower_gain)
			mark_action("shower")
		"exercise":
			if energy < 12: return "Necesitás un poco más de energía para entrenar."
			GameClock.advance(45)
			energy = maxf(0, energy - 10)
			wellbeing = minf(100, wellbeing + (10 if action_count_today("exercise") == 0 else 3))
			mark_action("exercise")
		"play_football":
			if energy < 8: return "Necesitás un poco más de energía para jugar."
			GameClock.advance(35)
			energy = maxf(0, energy - 8)
			var first_match := action_count_today("play_football") == 0
			wellbeing = minf(100, wellbeing + (14 if first_match else 4))
			if first_match:
				reputation += 1
			mark_action("play_football")
	changed.emit()
	return {"eat": "Comiste y recuperaste energía.", "cook": "Cocinaste tus provisiones. ¡Buen provecho!", "fridge": "Preparaste una comida con tus provisiones.", "coffee": "Un café y una pausa. Pagaste $5.", "pc": "Usaste la computadora un rato.", "browse": "Recorriste las estanterías y encontraste algo interesante.", "tv": "Disfrutaste un programa. Te sentís mejor.", "shower": "Una ducha para empezar de nuevo.", "exercise": "Entrenaste un rato. Bajó tu energía y subió tu bienestar.", "play_football": "Jugaste un rato en la cancha. Subieron tu bienestar y tu reputación."}.get(action, "")

func to_dict() -> Dictionary:
	return {"money": money, "energy": energy, "wellbeing": wellbeing, "reputation": reputation, "inventory": inventory.duplicate(true), "daily_actions": daily_actions.duplicate(true)}

func restore(data: Dictionary) -> void:
	money = maxi(0, int(data.get("money", 80)))
	energy = clampf(float(data.get("energy", 85)), 0, 100)
	wellbeing = clampf(float(data.get("wellbeing", 70)), 0, 100)
	reputation = int(data.get("reputation", 0))
	inventory = data.get("inventory", {}).duplicate(true) if data.get("inventory", {}) is Dictionary else {}
	daily_actions = data.get("daily_actions", {}).duplicate(true) if data.get("daily_actions", {}) is Dictionary else {}
	prune_daily_actions()
	last_minutes = GameClock.total_minutes
	changed.emit()
