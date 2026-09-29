class_name JobRoleData
extends Resource

@export var id := ""
@export var title := ""
@export var workplace_id := ""
@export var base_salary := 80          # pay for a full successful shift
@export var shift_duration_minutes := 240.0   # default 4h shift
@export var objectives: Array[String] = []
@export var procedure_ids: Array[String] = []
@export var scenario_ids: Array[String] = []
