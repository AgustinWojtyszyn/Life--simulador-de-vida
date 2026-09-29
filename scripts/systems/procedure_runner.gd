extends Node

signal started(procedure: ProcedureData)
signal step_completed(step: ProcedureStepData)
signal action_rejected(action_id: String, target_id: String, reason: String)
signal finished(result: Dictionary)
signal changed

var active: bool = false
var procedure: ProcedureData = null
var result: TrainingResultData = null

func begin(next_procedure: ProcedureData) -> bool:
	if next_procedure == null or next_procedure.steps.is_empty():
		return false
	procedure = next_procedure
	result = TrainingResultData.new()
	result.procedure_id = procedure.id
	result.started_at_ms = Time.get_ticks_msec()
	active = true
	_record("procedure_started", {"procedure_id": procedure.id})
	started.emit(procedure)
	changed.emit()
	return true

func current_step() -> ProcedureStepData:
	if not active or procedure == null:
		return null
	for step in procedure.steps:
		if step.required and step.id not in result.completed_steps:
			return step
	for step in procedure.steps:
		if step.id not in result.completed_steps:
			return step
	return null

func perform(action_id: String, target_id: String = "") -> Dictionary:
	if not active or procedure == null or result == null:
		return {"accepted": false, "reason": "no_active_procedure"}
	var candidate := _matching_step(action_id, target_id)
	if candidate == null:
		return _reject(action_id, target_id, "unexpected_action")
	if candidate.id in result.completed_steps:
		return _reject(action_id, target_id, "step_already_completed")
	for prerequisite in candidate.prerequisite_step_ids:
		if prerequisite not in result.completed_steps:
			return _reject(action_id, target_id, "missing_prerequisite:" + prerequisite)
	if candidate.required:
		var expected := current_step()
		if expected != null and expected.required and expected.id != candidate.id:
			return _reject(action_id, target_id, "wrong_order")
	result.completed_steps.append(candidate.id)
	_record("step_completed", {"step_id": candidate.id, "action_id": action_id, "target_id": target_id})
	step_completed.emit(candidate)
	changed.emit()
	if _all_required_steps_done():
		complete()
	return {"accepted": true, "step_id": candidate.id, "feedback": candidate.success_feedback}

func complete() -> Dictionary:
	if not active or procedure == null or result == null:
		return {}
	result.omitted_required_steps.clear()
	for step in procedure.steps:
		if step.required and step.id not in result.completed_steps:
			result.omitted_required_steps.append(step.id)
	result.completed = result.omitted_required_steps.is_empty()
	result.ended_at_ms = Time.get_ticks_msec()
	_record("procedure_finished", {"completed": result.completed})
	active = false
	var payload := result.to_dict()
	finished.emit(payload)
	changed.emit()
	return payload

func cancel() -> Dictionary:
	if not active:
		return {}
	return complete()

func reset() -> void:
	active = false
	procedure = null
	result = null
	changed.emit()

func _matching_step(action_id: String, target_id: String) -> ProcedureStepData:
	for step in procedure.steps:
		if step.action_id != action_id:
			continue
		if not step.world_target.is_empty() and step.world_target != target_id:
			continue
		return step
	return null

func _all_required_steps_done() -> bool:
	for step in procedure.steps:
		if step.required and step.id not in result.completed_steps:
			return false
	return true

func _reject(action_id: String, target_id: String, reason: String) -> Dictionary:
	var error := {"at_ms": Time.get_ticks_msec(), "action_id": action_id, "target_id": target_id, "reason": reason}
	result.errors.append(error)
	_record("action_rejected", error)
	action_rejected.emit(action_id, target_id, reason)
	changed.emit()
	return {"accepted": false, "reason": reason}

func _record(kind: String, data: Dictionary) -> void:
	if result == null:
		return
	var event := data.duplicate(true)
	event["type"] = kind
	event["at_ms"] = Time.get_ticks_msec()
	result.events.append(event)
