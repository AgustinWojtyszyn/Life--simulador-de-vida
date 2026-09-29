class_name ProcedureStepData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var instruction: String = ""
@export var action_id: String = ""
@export var world_target: String = ""
@export var required: bool = true
@export var prerequisite_step_ids: Array[String] = []
@export var equipment_ids: Array[String] = []
@export var rule_reference_ids: Array[String] = []
@export_multiline var success_feedback: String = ""
@export_multiline var error_feedback: String = ""
