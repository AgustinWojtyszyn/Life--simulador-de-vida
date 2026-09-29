extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func step(id: String, action: String, target: String, required: bool = true, prereqs: Array[String] = []) -> ProcedureStepData:
	var value := ProcedureStepData.new()
	value.id = id
	value.title = id
	value.action_id = action
	value.world_target = target
	value.required = required
	value.prerequisite_step_ids = prereqs
	value.success_feedback = "ok"
	return value

func run() -> void:
	var runner := root.get_node("ProcedureRunner")
	runner.reset()
	var procedure := ProcedureData.new()
	procedure.id = "test_procedure"
	procedure.title = "Test procedure"
	procedure.steps.assign([
		step("prepare", "prepare", "station"),
		step("execute", "execute", "station", true, ["prepare"]),
		step("optional_note", "note", "board", false),
	])
	check(runner.begin(procedure), "procedure starts")
	check(runner.current_step().id == "prepare", "first required step is selected")
	var wrong: Dictionary = runner.perform("execute", "station")
	check(not bool(wrong.get("accepted", true)), "out-of-order required step is rejected")
	check(runner.result.errors.size() == 1, "rejected action is recorded")
	var first: Dictionary = runner.perform("prepare", "station")
	check(bool(first.get("accepted", false)), "first step is accepted")
	var duplicate: Dictionary = runner.perform("prepare", "station")
	check(not bool(duplicate.get("accepted", true)), "duplicate step is rejected")
	var second: Dictionary = runner.perform("execute", "station")
	check(bool(second.get("accepted", false)), "second step is accepted")
	check(not runner.active, "procedure auto-finishes after required steps")
	var result: Dictionary = runner.result.to_dict()
	check(bool(result.get("completed", false)), "result is completed")
	check((result.get("completed_steps", []) as Array).size() == 2, "required completions are recorded")
	check((result.get("events", []) as Array).size() >= 4, "telemetry events are recorded")
	print("PROCEDURE RUNNER: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
