extends Node

signal changed
# Stable IDs persist across scene changes and countries.
const INTRO := {"id": "welcome_meal", "title": "Una mesa compartida", "giver": "mara", "contact": "nico", "price": 12, "reward": 18}
var stage := 0
var choice := ""

func objective() -> String:
	return ["Hablá con Mara junto a tu casa", "Preguntale a Nico en el café", "Conseguí provisiones en el mercado", "Llevá las provisiones a Mara", "Compartiste tu primera mesa en el barrio"][clampi(stage, 0, 4)]

func dialogue(person: String) -> Dictionary:
	if person == "mara":
		if stage == 0: return {"text": "Mara: ¡Bienvenido! Preparo una comida para el barrio. ¿Me ayudás? Nico, en el café, sabe qué falta.", "options": [["Contá conmigo", "accept"], ["Quizás más tarde", "close"]]}
		if stage == 3: return {"text": "Mara: ¡Llegaste! ¿Pudiste conseguir algo para compartir?", "options": [["Entregar provisiones", "deliver"], ["Todavía no", "close"]]}
		if stage == 4: return {"text": "Mara: " + ("Gracias por invitar. Todos recuerdan tu generosidad." if choice == "gift" else "Gracias por tu ayuda. Tu trabajo merece una recompensa."), "options": [["¡Hasta pronto!", "close"]]}
	if person == "nico" and stage == 1:
		return {"text": "Nico: Faltan provisiones. Cuestan $12 en el mercado. Mara puede pagarte $18, o podés invitar vos.", "options": [["Acepto el encargo ($18 al entregar)", "paid"], ["Yo invito (+3 reputación)", "gift"]]}
	return {"text": "Mara: " + objective() if person == "mara" else "Nico: El mercado está junto al café. Yo atiendo acá.", "options": [["Nos vemos", "close"]]}

func choose(action: String) -> String:
	match action:
		"accept":
			if stage == 0: stage = 1
		"paid", "gift":
			if stage == 1:
				choice = action
				stage = 2
		"deliver":
			if stage != 3 or int(LifeSimulation.inventory.get("food", 0)) < 1:
				return "Necesitás una provisión para entregar."
			LifeSimulation.inventory["food"] -= 1
			LifeSimulation.money += INTRO.reward if choice == "paid" else 0
			LifeSimulation.reputation += 3 if choice == "gift" else 1
			LifeSimulation.wellbeing = minf(100, LifeSimulation.wellbeing + 15)
			stage = 4
			LifeSimulation.changed.emit()
	changed.emit()
	return objective()

func purchased() -> void:
	if stage == 2 and int(LifeSimulation.inventory.get("food", 0)) > 0:
		stage = 3
		changed.emit()

func to_dict() -> Dictionary:
	return {"stage": stage, "choice": choice}

func restore(data: Dictionary) -> void:
	stage = clampi(int(data.get("stage", 0)), 0, 4)
	choice = str(data.get("choice", ""))
	changed.emit()
