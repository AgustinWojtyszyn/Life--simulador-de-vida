## Tests B2B verticales — verifican el loop completo de empleo jugable.
## Ejecutar con: godot --headless --script tests/b2b_vertical_test.gd
extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	var status := "  PASS" if ok else "  FAIL"
	print(status + " · " + label)
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func frames(count: int) -> void:
	for _i in count:
		await process_frame
		await physics_frame

func run() -> void:
	# ── Bootstrap autoloads ────────────────────────────────────────────────
	var wm   = root.get_node("WorldManager")
	var emp  = root.get_node("EmploymentSystem")
	var shift = root.get_node("ShiftSystem")
	var sim  = root.get_node("LifeSimulation")
	var saves = root.get_node("SaveSystem")
	var cat  = root.get_node("CompanyCatalog")
	saves.save_path = "user://b2b_vertical_test.json"

	# Limpieza de estado antes de comenzar.
	emp.restore({})
	shift.restore({})

	# ── A. CompanyData carga correctamente ────────────────────────────────
	var nexovial = cat.find_company("nexovial")
	check(nexovial != null, "A: CompanyData nexovial carga correctamente")
	check(nexovial != null and nexovial.display_name == "Nexovial S.A.", "A: display_name correcto")
	check(nexovial != null and nexovial.district_id == "centro", "A: district_id = centro")
	check(nexovial != null and nexovial.workplaces.size() > 0, "A: tiene al menos 1 workplace")
	var wp = cat.find_workplace("nexovial", "nexovial_sede")
	check(wp != null, "A: WorkplaceData nexovial_sede encontrado")
	var role = cat.find_role("nexovial", "nexovial_sede", "operador")
	check(role != null, "A: JobRoleData operador encontrado")
	check(role != null and role.base_salary == 80, "A: salario operador = 80")
	check(role != null and role.objectives.size() == 3, "A: operador tiene 3 objetivos")
	var scenario = cat.find_scenario("archivo_urgente")
	check(scenario != null, "A: ScenarioData archivo_urgente encontrado")

	# ── B. El jugador puede aceptar el empleo ─────────────────────────────
	check(not emp.employed, "B: pre-condición: no empleado")
	var hired = emp.hire("nexovial", "nexovial_sede", "operador")
	check(hired, "B: hire() retorna true")
	check(emp.employed, "B: empleado después de hire()")
	check(emp.company_id == "nexovial", "B: company_id = nexovial")
	check(emp.role_id == "operador", "B: role_id = operador")
	check(emp.salary == 80, "B: salario = 80")

	# ── C. El empleo persiste después de save/load ────────────────────────
	var app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	wm.new_game(PlayerProfile.new(), "ar")
	await frames(3)
	var hired2 = emp.hire("nexovial", "nexovial_sede", "operador")
	check(hired2, "C: hire() exitoso en partida nueva")
	check(wm.save_game(), "C: save_game() completa sin errores")
	app.show_menu()
	await frames(2)
	emp.restore({})
	check(not emp.employed, "C: estado borrado antes de reload")
	check(wm.continue_game(), "C: continue_game() retorna true")
	await frames(3)
	check(emp.employed, "C: employment persiste tras save/load")
	check(emp.company_id == "nexovial", "C: company_id correcto tras load")
	check(emp.salary == 80, "C: salario correcto tras load")

	# ── D. No se puede iniciar turno sin empleo ───────────────────────────
	emp.restore({})   # sin empleo
	var err = shift.begin_shift()
	check(err != "", "D: begin_shift() falla sin empleo activo")
	check(not shift.active, "D: turno no activo sin empleo")

	# ── E. Se puede iniciar turno con empleo ──────────────────────────────
	emp.restore({})
	emp.hire("nexovial", "nexovial_sede", "operador")
	shift.restore({})
	var begin_err = shift.begin_shift()
	check(begin_err == "", "E: begin_shift() OK con empleo")
	check(shift.active, "E: turno activo tras begin_shift()")
	check(not shift.current_objective().is_empty(), "E: hay objetivo activo")

	# ── F. Los objetivos progresan en orden ───────────────────────────────
	var obj0 = shift.current_objective()
	shift.complete_current_objective()
	var obj1 = shift.current_objective()
	check(obj0 != obj1, "F: objetivo cambió tras completar el primero")
	var idx_before = shift.current_objective_index
	shift.complete_current_objective()
	check(shift.current_objective_index == idx_before + 1, "F: índice avanza en orden")

	# ── G. ScenarioData dispara la situación ─────────────────────────────
	# El escenario se dispara al completar el objetivo índice 2 (tercero).
	shift.complete_current_objective()  # completa el tercero → debería triggear
	await frames(1)
	check(shift.scenario_fired, "G: escenario disparado después del segundo objetivo completado")
	check(shift.active_scenario() != null, "G: escenario activo no nulo")

	# ── H. Completar turno entrega recompensa exactamente una vez ─────────
	var money_before = sim.money
	shift.resolve_scenario(true)
	var result = shift.end_shift()
	check(not result.is_empty(), "H: end_shift() retorna resultado")
	check(result.get("pay", 0) > 0, "H: pay > 0 con performance completa")
	var money_after = sim.money
	check(money_after > money_before, "H: dinero aumentó al finalizar turno")
	# Intentar finalizar turno de nuevo no debe dar recompensa adicional.
	var money_locked = sim.money
	shift.end_shift()
	check(sim.money == money_locked, "H: end_shift() segunda vez no da recompensa")

	# ── I. Save legacy sin campos B2B continúa cargando ──────────────────
	var legacy_profile := PlayerProfile.new()
	var legacy_data := {
		"version": 1,
		"profile": legacy_profile.to_dict(),
		"location": "home",
		"position": [350.0, 280.0],
		"return_position": [0.0, 0.0],
		"state": {"rested": false},
		"clock": {},
		"weather": {},
		"life": {},
		"mission": {},
		# Sin 'employment' ni 'shift' intencionalmente — prueba compatibilidad legacy.
	}
	var legacy_path := "user://b2b_legacy_test.json"
	var f := FileAccess.open(legacy_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy_data))
	f.close()
	var prev_path = saves.save_path
	saves.save_path = legacy_path
	var loaded = wm.continue_game()
	saves.save_path = prev_path
	await frames(2)
	check(loaded, "I: legacy save sin B2B carga correctamente")
	check(not emp.employed, "I: empleo = false en legacy save")
	check(not shift.active, "I: turno = false en legacy save")
	DirAccess.remove_absolute(legacy_path)

	# ── J. Nueva partida continúa funcionando ────────────────────────────
	app.show_menu()
	await frames(2)
	wm.new_game(PlayerProfile.new(), "ar")
	await frames(4)
	check(wm.location == "home", "J: nueva partida empieza en home")
	check(not emp.employed, "J: empleo limpio en nueva partida")
	check(not shift.active, "J: turno limpio en nueva partida")
	var player = app.world.get_node_or_null("Player")
	check(is_instance_valid(player), "J: Player existe en nueva partida")

	# ── Limpieza ─────────────────────────────────────────────────────────
	app.show_menu()
	await frames(2)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(saves.save_path + suffix):
			DirAccess.remove_absolute(saves.save_path + suffix)

	print("")
	print("B2B VERTICAL: " + ("PASS" if failures == 0 else "FAIL") + " (" + str(failures) + " failures)")
	quit(0 if failures == 0 else 1)
