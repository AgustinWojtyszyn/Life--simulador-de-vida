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
	var poi: Dictionary = get_meta("poi", {})
	var hours: Dictionary = poi.get("opening_hours", {})
	if action.begins_with("enter_") and action != "enter_home":
		if not PoiData.is_open(hours, GameClock.total_minutes):
			return "Cerrado · " + PoiData.hours_text(hours)
		WorldManager.active_poi = poi
	if action == "hospital_floor":
		WorldManager.call_deferred("travel", "hospital" if WorldManager.location == "hospital_ward" else "hospital_ward")
		return ""
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
			return detail + " · " + PoiData.status_text(hours if not poi.is_empty() else WorldManager.active_poi.get("opening_hours", {}), GameClock.total_minutes)

		# ── Nexovial / B2B actions ────────────────────────────────────────────
		"nexovial_hire":
			if EmploymentSystem.employed:
				return "Ya estás empleado en " + EmploymentSystem.company_name() + "."
			# Show the hire dialogue through LifePanel.
			var panel: Node = _life_panel()
			if panel != null:
				panel.show_hire_dialogue("nexovial", "nexovial_sede", "operador")
			return ""

		"nexovial_consult_job":
			var panel: Node = _life_panel()
			if panel != null:
				if EmploymentSystem.employed:
					panel.show_work_status()
				else:
					panel.show_hire_dialogue("nexovial", "nexovial_sede", "operador")
			return ""

		"nexovial_shift_toggle":
			if ShiftSystem.active:
				# End shift — player must be near the entrance.
				var result_dict := ShiftSystem.end_shift()
				var panel: Node = _life_panel()
				if panel != null:
					panel.show_shift_result(result_dict)
				return "Turno finalizado."
			else:
				# Begin shift — player must be employed.
				var err := ShiftSystem.begin_shift()
				if err != "":
					return err
				return "Turno iniciado. " + ShiftSystem.current_objective()

		"nexovial_pickup_docs":
			return _advance_objective(player, "Retiraste el lote de documentos de recepción.")

		"nexovial_register_docs":
			return _advance_objective(player, "Documentos registrados y datos verificados.")

		"nexovial_report_supervisor":
			# This target also works as scenario escalation point.
			if ShiftSystem.active_scenario() != null:
				var res := ShiftSystem.resolve_scenario(true)
				return "Escalaste el problema. Supervisor notificado. +Rep +Exp"
			return _advance_objective(player, "Reporte entregado al supervisor.")

		"nexovial_phone_client":
			if ShiftSystem.active_scenario() != null:
				var res := ShiftSystem.resolve_scenario(true)
				return "Llamaste al cliente. El archivo fue regularizado. +Rep +Exp"
			return "El teléfono está disponible durante situaciones urgentes."

	return ""

func _advance_objective(player: Node2D, success_text: String) -> String:
	if not ShiftSystem.active:
		return "No hay turno activo. Iniciá el turno primero."
	var obj_before := ShiftSystem.current_objective_index
	var new_obj := ShiftSystem.complete_current_objective()
	if ShiftSystem.current_objective_index > obj_before:
		player.perform_activity("pc")
		return success_text + " · " + (new_obj if not new_obj.is_empty() else "Todos los objetivos completados.")
	return "Ya completaste este objetivo."

func _life_panel() -> Node:
	var world := WorldManager.active_world
	if is_instance_valid(world) and world.has_node("LifePanel"):
		return world.get_node("LifePanel")
	return null

