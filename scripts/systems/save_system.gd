extends Node

const VERSION := 1
var save_path := "user://vida_save.json"
var last_error := ""

func write_save(data: Dictionary) -> bool:
	last_error = ""
	var payload := data.duplicate(true)
	payload["version"] = VERSION
	payload["modified_at"] = Time.get_datetime_string_from_system()
	if not payload.has("slot_name"):
		var prior := read_save()
		payload["slot_name"] = prior.get("slot_name", str(payload.get("profile", {}).get("player_name", "Mi vida")))
	last_error = ""
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "No se pudo abrir el archivo de guardado."
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	# Keep the previous complete save until its replacement is safely written.
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path + ".bak")
		if DirAccess.rename_absolute(save_path, save_path + ".bak") != OK:
			last_error = "No se pudo respaldar la partida."
			return false
	if DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		DirAccess.rename_absolute(save_path + ".bak", save_path)
		last_error = "No se pudo completar el guardado."
		return false
	return true

func read_save() -> Dictionary:
	last_error = ""
	for path in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			continue
		var parsed = json.data
		if parsed is Dictionary and valid(parsed):
			return parsed
	last_error = "No hay una partida válida para continuar."
	return {}

func valid(data: Dictionary) -> bool:
	if data.get("version") != VERSION or not data.get("profile") is Dictionary:
		return false
	var country: String = str(data.profile.get("country_id", ""))
	if country not in ["ar", "us", "jp", "it", "br"]:
		return false
	var p = data.get("position")
	return p is Array and p.size() == 2 and (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int) and is_finite(float(p[0])) and is_finite(float(p[1])) and WorldManager.is_valid_location(str(data.get("location", "")))

func has_save() -> bool:
	return not read_save().is_empty()

const SLOT_DIR := "user://lives"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SLOT_DIR)
	# Copy once. The legacy file and its backup remain available for recovery.
	var legacy := read_save()
	if not legacy.is_empty() and not FileAccess.file_exists(SLOT_DIR + "/.legacy_migrated"):
		var previous := save_path
		save_path = SLOT_DIR + "/legacy.json"
		if write_save(legacy):
			var marker := FileAccess.open(SLOT_DIR + "/.legacy_migrated", FileAccess.WRITE)
			if marker: marker.store_string("1")
		save_path = previous
	var slots := list_slots()
	if not slots.is_empty():
		save_path = slots[0].path

func new_slot() -> void:
	# Explicit test paths remain isolated from real player saves.
	if save_path != "user://vida_save.json" and not save_path.begins_with(SLOT_DIR + "/"):
		return
	save_path = SLOT_DIR + "/life_%d_%d.json" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

func list_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directory := DirAccess.open(SLOT_DIR)
	if directory == null: return result
	var selected := save_path
	for filename in directory.get_files():
		if not filename.ends_with(".json"): continue
		save_path = SLOT_DIR + "/" + filename
		var data := read_save()
		if data.is_empty(): continue
		result.append({"path": save_path, "data": data, "modified": FileAccess.get_modified_time(save_path)})
	save_path = selected
	result.sort_custom(func(a: Dictionary, b: Dictionary): return a.modified > b.modified)
	return result

func select_slot(path: String) -> bool:
	for slot in list_slots():
		if slot.path == path:
			save_path = path
			return true
	return false

func rename_slot(path: String, title: String) -> bool:
	var previous := save_path
	if not select_slot(path): return false
	var data := read_save()
	data["slot_name"] = title.strip_edges().left(40)
	var ok := write_save(data)
	save_path = previous
	return ok

func delete_slot(path: String) -> bool:
	if not list_slots().any(func(slot: Dictionary): return slot.path == path): return false
	if DirAccess.remove_absolute(path) != OK: return false
	for suffix in [".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	var remaining := list_slots()
	if save_path == path:
		save_path = remaining[0].path if not remaining.is_empty() else SLOT_DIR + "/new.json"
	return true
