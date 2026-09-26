extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var saves := root.get_node("SaveSystem")
	# Unique paths; never delete or overwrite an existing life.
	var original: String = saves.save_path
	var id := str(Time.get_ticks_usec())
	var first: String = saves.SLOT_DIR + "/test_a_" + id + ".json"
	var second: String = saves.SLOT_DIR + "/test_b_" + id + ".json"
	var data := {"profile": PlayerProfile.new().to_dict(), "position": [390, 350], "location": "home"}
	saves.save_path = first
	check(saves.write_save(data), "First slot writes")
	saves.save_path = second
	data.profile.player_name = "Otra vida"
	check(saves.write_save(data), "Second slot writes")
	check(saves.select_slot(first), "First life remains selectable")
	check(saves.read_save().profile.player_name == "Alex", "New life preserves previous profile")
	check(saves.rename_slot(first, "Mi historia"), "Rename works")
	check(saves.read_save().slot_name == "Mi historia", "Rename persists")
	check(saves.write_save(data), "Ordinary save works after rename")
	check(saves.read_save().slot_name == "Mi historia", "Ordinary save retains slot name")
	var broken := FileAccess.open(first, FileAccess.WRITE)
	broken.store_string("broken")
	broken.close()
	check(not saves.read_save().is_empty(), "Slot backup recovers corruption")
	check(saves.delete_slot(first), "Confirmed deletion removes only selected slot")
	check(saves.select_slot(second), "Other life survives deletion")
	check(saves.delete_slot(second), "Clean isolated second slot")
	saves.save_path = original
	print("SAVE SLOTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
