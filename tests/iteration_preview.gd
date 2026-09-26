extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame

func capture(path: String) -> void:
	await frames(30)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/previews")
	root.get_node("SaveSystem").save_path = "user://vida_preview_only.json"
	var app: Node = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	await frames(3)
	var wm := root.get_node("WorldManager")
	wm.new_game(PlayerProfile.new(), "ar")
	await capture("res://build/previews/home.png")
	wm.travel("street")
	await frames(3)
	app.world.get_node("Player").position = Vector2(1000, 530)
	app.world.get_node("Player/Camera2D").reset_smoothing()
	await capture("res://build/previews/intersection.png")
	await frames(150)
	await capture("res://build/previews/traffic_later.png")
	wm.travel("cafe")
	await capture("res://build/previews/cafe.png")
	wm.travel("shop")
	await capture("res://build/previews/market.png")
	wm.travel("street")
	await frames(3)
	root.get_node("GameClock").advance(720)
	app.world.get_node("Player").position = Vector2(430, 560)
	app.world.get_node("Player/Camera2D").reset_smoothing()
	await capture("res://build/previews/night.png")
	print("VISUAL PREVIEW COMPLETE")
	quit()
