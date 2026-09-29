extends Node
## Manages a single work shift: start/stop, objectives, scenario trigger, reward.
## Reads JobRoleData / ScenarioData from the catalog; no hardcoded company logic.

signal started(shift: Dictionary)
signal objective_advanced(index: int, text: String)
signal scenario_triggered(scenario: ScenarioData)
signal scenario_resolved(success: bool, results: Dictionary)
signal ended(result: Dictionary)
signal changed

# ─── shift state ──────────────────────────────────────────────────────────────
var active := false
var start_minute := 0.0
var end_minute := 0.0          # set by role shift_duration_minutes
var current_objective_index := 0
var objectives_done: Array[bool] = []
var scenario_fired := false
var scenario_resolved_ok := false
var _current_scenario: ScenarioData = null
var _result := {}              # filled when shift ends

# ─── catalog helper ───────────────────────────────────────────────────────────
func _catalog() -> Node:
	return get_node_or_null("/root/CompanyCatalog")

# ─── public API ───────────────────────────────────────────────────────────────

## Try to start a shift. Returns "" on success, error string otherwise.
## Caller must verify physical location before calling this.
func begin_shift() -> String:
	if not EmploymentSystem.employed:
		return "No tenés empleo actualmente."
	if active:
		return "Ya estás en turno."
	var role := EmploymentSystem.role()
	if role == null:
		return "No se encontraron datos del puesto."
	active = true
	start_minute = GameClock.total_minutes
	end_minute = start_minute + role.shift_duration_minutes
	current_objective_index = 0
	scenario_fired = false
	scenario_resolved_ok = false
	_current_scenario = null
	_result = {}
	objectives_done.resize(role.objectives.size())
	objectives_done.fill(false)
	changed.emit()
	started.emit({"role": role.title, "start": start_minute, "end": end_minute, "objectives": role.objectives.duplicate()})
	return ""

## Returns the text of the current objective or "" if all done.
func current_objective() -> String:
	var role := EmploymentSystem.role()
	if role == null or not active:
		return ""
	if current_objective_index >= role.objectives.size():
		return "Todos los objetivos completados."
	return role.objectives[current_objective_index]

## Mark the current objective done and advance. Returns new objective text.
func complete_current_objective() -> String:
	if not active:
		return ""
	var role := EmploymentSystem.role()
	if role == null:
		return ""
	if current_objective_index >= role.objectives.size():
		return "Ya completaste todos los objetivos."
	objectives_done[current_objective_index] = true
	current_objective_index += 1
	objective_advanced.emit(current_objective_index, current_objective())
	changed.emit()
	# Check if it's time to fire the scenario (after first objective done).
	_check_scenario_trigger()
	return current_objective()

func all_objectives_done() -> bool:
	return active and current_objective_index >= objectives_done.size()

## Fire the role scenario if not already fired and conditions are met.
func _check_scenario_trigger() -> void:
	if scenario_fired:
		return
	var cat = _catalog()
	if cat == null:
		return
	var role := EmploymentSystem.role()
	if role == null or role.scenario_ids.is_empty():
		return
	# Trigger after the second completed objective (index 1 → done, about to do 2).
	if current_objective_index < 2:
		return
	var scenario_id: String = role.scenario_ids[0]
	var scenario: ScenarioData = cat.find_scenario(scenario_id)
	if scenario == null:
		return
	scenario_fired = true
	_current_scenario = scenario
	scenario_triggered.emit(scenario)
	changed.emit()

func active_scenario() -> ScenarioData:
	return _current_scenario

## Resolve the scenario: action is "success" or "failure".
func resolve_scenario(success: bool) -> Dictionary:
	if _current_scenario == null:
		return {}
	var results: Dictionary = _current_scenario.success if success else _current_scenario.failure
	scenario_resolved_ok = success
	_current_scenario = null
	var rep_delta := int(results.get("reputation", 0))
	var exp_bonus := int(results.get("experience", 0))
	var money_bonus := int(results.get("money", 0))
	EmploymentSystem.modify_work_reputation(rep_delta)
	EmploymentSystem.add_experience(exp_bonus)
	LifeSimulation.money += money_bonus
	LifeSimulation.changed.emit()
	scenario_resolved.emit(success, results)
	changed.emit()
	return results

## End the shift and compute rewards. Returns a result Dictionary.
## Caller must verify physical location and that the player is at the workplace.
func end_shift() -> Dictionary:
	if not active:
		return {}
	active = false
	var role := EmploymentSystem.role()
	var done_count := 0
	for d in objectives_done:
		if d:
			done_count += 1
	var total := objectives_done.size()
	var performance := float(done_count) / float(total) if total > 0 else 0.0
	# Base pay + scenario bonus.
	var base_pay := int(float(EmploymentSystem.salary) * performance)
	var rep_delta := 1 if performance >= 1.0 else (0 if performance >= 0.5 else -1)
	var exp_gain := int(30.0 * performance) + (10 if scenario_resolved_ok else 0)
	LifeSimulation.money += base_pay
	LifeSimulation.reputation += rep_delta
	LifeSimulation.changed.emit()
	EmploymentSystem.add_experience(exp_gain)
	EmploymentSystem.modify_work_reputation(rep_delta)
	GameClock.advance(maxf(0, end_minute - GameClock.total_minutes))
	_result = {
		"pay": base_pay,
		"experience": exp_gain,
		"reputation": rep_delta,
		"performance": performance,
		"objectives_done": done_count,
		"objectives_total": total,
	}
	objectives_done.clear()
	current_objective_index = 0
	scenario_fired = false
	scenario_resolved_ok = false
	changed.emit()
	ended.emit(_result)
	return _result

func last_result() -> Dictionary:
	return _result

# ─── persistence ──────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	var done_ints: Array[int] = []
	for d in objectives_done:
		done_ints.append(1 if d else 0)
	return {
		"active": active,
		"start_minute": start_minute,
		"end_minute": end_minute,
		"current_objective_index": current_objective_index,
		"objectives_done": done_ints,
		"scenario_fired": scenario_fired,
		"scenario_resolved_ok": scenario_resolved_ok,
	}

## Safe restore — missing fields get sane defaults.
func restore(data: Dictionary) -> void:
	active = bool(data.get("active", false))
	start_minute = float(data.get("start_minute", 0.0))
	end_minute = float(data.get("end_minute", 0.0))
	current_objective_index = int(data.get("current_objective_index", 0))
	var raw_done = data.get("objectives_done", [])
	objectives_done.clear()
	if raw_done is Array:
		for v in raw_done:
			objectives_done.append(bool(int(v)))
	scenario_fired = bool(data.get("scenario_fired", false))
	scenario_resolved_ok = bool(data.get("scenario_resolved_ok", false))
	_current_scenario = null
	_result = {}
	changed.emit()
