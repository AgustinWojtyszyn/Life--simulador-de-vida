class_name TrainingResultData
extends RefCounted

var procedure_id: String = ""
var started_at_ms: int = 0
var ended_at_ms: int = 0
var completed: bool = false
var completed_steps: Array[String] = []
var omitted_required_steps: Array[String] = []
var errors: Array[Dictionary] = []
var events: Array[Dictionary] = []

func duration_ms() -> int:
	if started_at_ms <= 0:
		return 0
	var end_time := ended_at_ms if ended_at_ms > 0 else Time.get_ticks_msec()
	return maxi(0, end_time - started_at_ms)

func to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"procedure_id": procedure_id,
		"started_at_ms": started_at_ms,
		"ended_at_ms": ended_at_ms,
		"duration_ms": duration_ms(),
		"completed": completed,
		"completed_steps": completed_steps.duplicate(),
		"omitted_required_steps": omitted_required_steps.duplicate(),
		"errors": errors.duplicate(true),
		"events": events.duplicate(true),
	}
