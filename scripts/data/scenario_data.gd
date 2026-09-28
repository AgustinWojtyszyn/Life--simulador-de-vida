class_name ScenarioData
extends Resource

@export var id := ""
@export var title := ""
@export var objectives: Array[String] = []
@export var context := ""
@export var trigger: Dictionary = {}
@export var success: Dictionary = {}
@export var failure: Dictionary = {}
@export var results: Dictionary = {}
