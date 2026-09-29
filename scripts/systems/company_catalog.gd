extends Node
## Runtime catalog of all registered companies. New companies are registered once
## at startup. Data-driven: no per-company if/switch logic here.

var _companies: Array[CompanyData] = []

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	# Register the Nexovial demo company. Additional companies follow the same pattern.
	var nexovial := preload("res://resources/companies/nexovial.gd").build()
	_companies.append(nexovial)

func find_company(id: String) -> CompanyData:
	for c in _companies:
		if c.id == id:
			return c
	return null

func find_workplace(company_id: String, workplace_id: String) -> WorkplaceData:
	var c := find_company(company_id)
	if c == null:
		return null
	for w in c.workplaces:
		if w.id == workplace_id:
			return w
	return null

func find_role(company_id: String, workplace_id: String, role_id: String) -> JobRoleData:
	var w := find_workplace(company_id, workplace_id)
	if w == null:
		return null
	for r in w.roles:
		if r.id == role_id:
			return r
	return null

func find_scenario(scenario_id: String) -> ScenarioData:
	for c in _companies:
		for w in c.workplaces:
			for r in w.roles:
				for sid in r.scenario_ids:
					if sid == scenario_id:
						# Retrieve the scenario from the workplace's scenario list.
						for sc in w.scenarios:
							if sc.id == scenario_id:
								return sc
	return null

func all_companies() -> Array[CompanyData]:
	return _companies.duplicate()
