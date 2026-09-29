## Nexovial S.A. — empresa ficticia de gestión documental y servicios operativos.
## Distrito: Centro / Financiero.
## Propósito: demostrar que el motor B2B puede servir para oficinas,
## logística y operaciones sin depender de ningún dato real.
extends RefCounted

static func build() -> CompanyData:
	var company := CompanyData.new()
	company.id = "nexovial"
	company.display_name = "Nexovial S.A."
	company.description = "Empresa de gestión documental y servicios operativos en el Centro."
	company.district_id = "centro"
	company.map_position = Vector2(2560, 1480)
	company.workplaces.append(_build_sede_central())
	return company

static func _build_sede_central() -> WorkplaceData:
	var wp := WorkplaceData.new()
	wp.id = "nexovial_sede"
	wp.display_name = "Sede Central"
	wp.company_id = "nexovial"
	wp.type = "office"
	# Interior scene loaded by ShopInterior variant; reutiliza sistema existente.
	wp.interior_scene = "res://scenes/interiors/nexovial_office.tscn"
	# Entrance position approximately matches the city building footprint.
	wp.entrance_world_position = Vector2(2580, 1540)
	wp.roles.append(_role_operador())
	wp.roles.append(_role_coordinador())
	wp.scenarios.append(_scenario_archivo_urgente())
	return wp

static func _role_operador() -> JobRoleData:
	var r := JobRoleData.new()
	r.id = "operador"
	r.title = "Operador"
	r.workplace_id = "nexovial_sede"
	r.base_salary = 80
	r.shift_duration_minutes = 240.0   # 09:00 – 13:00
	r.objectives.assign([
		"Retirar el lote de documentos de recepción",
		"Llevar los documentos al área de registro y verificar datos",
		"Reportar el estado al supervisor",
	])
	r.scenario_ids.assign(["archivo_urgente"])
	return r

static func _role_coordinador() -> JobRoleData:
	var r := JobRoleData.new()
	r.id = "coordinador"
	r.title = "Coordinador"
	r.workplace_id = "nexovial_sede"
	r.base_salary = 120
	r.shift_duration_minutes = 300.0   # 09:00 – 14:00
	r.objectives.assign([
		"Revisar el estado del turno con recepción",
		"Asignar tareas pendientes en el panel de coordinación",
		"Cerrar el reporte del turno con el supervisor",
	])
	r.scenario_ids.assign(["archivo_urgente"])
	return r

static func _scenario_archivo_urgente() -> ScenarioData:
	var sc := ScenarioData.new()
	sc.id = "archivo_urgente"
	sc.title = "Archivo urgente sin firma"
	sc.context = "El cliente Durante & Cía envió un lote de documentos sin firmar. "\
			+ "La operación no puede continuar sin resolverlo antes del cierre de turno."
	sc.objectives.assign(["Gestionar el archivo urgente de Durante & Cía"])
	sc.trigger = {"type": "objective_index", "value": 2}
	sc.player_actions.assign([
		{"id": "contact_client", "label": "Ir al teléfono y contactar al cliente",
			"outcome": "success", "world_target": "telefono"},
		{"id": "escalate",       "label": "Reportar al supervisor y escalar",
			"outcome": "success", "world_target": "supervisor"},
		{"id": "ignore",         "label": "Archivar igual sin firma",
			"outcome": "failure", "world_target": ""},
	])
	sc.success = {"reputation": 2, "experience": 15, "money": 20}
	sc.failure = {"reputation": -1, "experience": 5,  "money": 0}
	return sc
