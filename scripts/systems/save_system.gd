extends Node

const VERSION := 1
var save_path := "user://vida_save.json"
var last_error := ""

func write_save(data: Dictionary) -> bool:
	last_error = ""
	var payload := data.duplicate(true)
	payload["version"] = VERSION
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
	return p is Array and p.size() == 2 and (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int) and is_finite(float(p[0])) and is_finite(float(p[1])) and data.get("location") in ["home", "street"]

func has_save() -> bool:
	return not read_save().is_empty()
