class_name ScenarioData
extends Resource

@export var id := ""
@export var title := ""
@export var context := ""
@export var objectives: Array[String] = []
## trigger["type"] = "objective_index" | "time_minutes"; trigger["value"] = threshold
@export var trigger: Dictionary = {}
## Actions the player can take: array of {id, label, outcome: "success"|"failure"}
@export var player_actions: Array[Dictionary] = []
## Results when the scenario ends in success.
## Keys: "reputation", "experience", "money"
@export var success: Dictionary = {}
## Results when the scenario ends in failure.
@export var failure: Dictionary = {}
## Legacy field (keep for save compat).
@export var results: Dictionary = {}
