class_name ProcedureData
extends Resource

@export var id: String = ""
@export var industry_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var role_ids: Array[String] = []
@export var steps: Array[ProcedureStepData] = []
@export var equipment: Array[EquipmentData] = []
@export var rule_references: Array[RuleReferenceData] = []
@export var allow_out_of_order_optional_steps: bool = true

func find_step(step_id: String) -> ProcedureStepData:
	for step in steps:
		if step.id == step_id:
			return step
	return null

func find_equipment(equipment_id: String) -> EquipmentData:
	for item in equipment:
		if item.id == equipment_id:
			return item
	return null

func find_rule(rule_id: String) -> RuleReferenceData:
	for rule in rule_references:
		if rule.id == rule_id:
			return rule
	return null
