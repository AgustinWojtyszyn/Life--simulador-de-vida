extends Node
## Tracks the player's current employment state. Data-driven: reads CompanyData /
## WorkplaceData / JobRoleData resources from the catalog; no hardcoded company logic.

signal changed

# ─── runtime state ────────────────────────────────────────────────────────────
var employed := false
var company_id := ""
var workplace_id := ""
var role_id := ""
var salary := 0          # pay per completed shift
var work_reputation := 0 # reputation specific to work performance
var work_experience := 0 # total experience points accumulated
# ─── resolved references (populated when employment changes) ──────────────────
var _company: CompanyData = null
var _workplace: WorkplaceData = null
var _role: JobRoleData = null

# ─── public API ───────────────────────────────────────────────────────────────

## Returns the catalog singleton. Loaded lazily to avoid circular autoload issues.
func _catalog() -> Node:
	return get_node_or_null("/root/CompanyCatalog")

func hire(c_id: String, w_id: String, r_id: String) -> bool:
	var cat = _catalog()
	if cat == null:
		return false
	var company: CompanyData = cat.find_company(c_id)
	if company == null:
		return false
	var workplace: WorkplaceData = cat.find_workplace(c_id, w_id)
	if workplace == null:
		return false
	var role: JobRoleData = cat.find_role(c_id, w_id, r_id)
	if role == null:
		return false
	employed = true
	company_id = c_id
	workplace_id = w_id
	role_id = r_id
	salary = role.base_salary
	_company = company
	_workplace = workplace
	_role = role
	changed.emit()
	return true

func resign() -> void:
	employed = false
	company_id = ""
	workplace_id = ""
	role_id = ""
	salary = 0
	_company = null
	_workplace = null
	_role = null
	changed.emit()

func add_experience(amount: int) -> void:
	work_experience += amount
	changed.emit()

func modify_work_reputation(delta: int) -> void:
	work_reputation = clampi(work_reputation + delta, -100, 100)
	changed.emit()

## Resolve cached references after a load (catalog may not be ready at restore time).
func resolve_references() -> void:
	if not employed:
		return
	var cat = _catalog()
	if cat == null:
		return
	_company = cat.find_company(company_id)
	_workplace = cat.find_workplace(company_id, workplace_id)
	_role = cat.find_role(company_id, workplace_id, role_id)

func company() -> CompanyData:
	if _company == null:
		resolve_references()
	return _company

func workplace() -> WorkplaceData:
	if _workplace == null:
		resolve_references()
	return _workplace

func role() -> JobRoleData:
	if _role == null:
		resolve_references()
	return _role

func role_title() -> String:
	var r := role()
	return r.title if r != null else ""

func company_name() -> String:
	var c := company()
	return c.display_name if c != null else ""

# ─── persistence ──────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"employed": employed,
		"company_id": company_id,
		"workplace_id": workplace_id,
		"role_id": role_id,
		"salary": salary,
		"work_reputation": work_reputation,
		"work_experience": work_experience,
	}

## Safe restore — fields missing in legacy saves get sane defaults.
func restore(data: Dictionary) -> void:
	employed = bool(data.get("employed", false))
	company_id = str(data.get("company_id", ""))
	workplace_id = str(data.get("workplace_id", ""))
	role_id = str(data.get("role_id", ""))
	salary = int(data.get("salary", 0))
	work_reputation = int(data.get("work_reputation", 0))
	work_experience = int(data.get("work_experience", 0))
	_company = null
	_workplace = null
	_role = null
	if employed:
		resolve_references()
	changed.emit()
