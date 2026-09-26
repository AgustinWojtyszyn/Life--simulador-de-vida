extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(128, 96)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(view)
	var sprite := Sprite2D.new()
	var source: Texture2D = load("res://assets/city/props/fountain.png")
	sprite.texture = source
	sprite.centered = false
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/fountain_water.gdshader")
	sprite.material = material
	view.add_child(sprite)
	material.set_shader_parameter("water_time", 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var first := view.get_texture().get_image()
	material.set_shader_parameter("water_time", 0.8)
	await process_frame
	await RenderingServer.frame_post_draw
	var second := view.get_texture().get_image()
	first.save_png("res://build/water-before.png")
	second.save_png("res://build/water-after.png")
	var original := source.get_image()
	var changed_water := 0
	var changed_stone := 0
	for y in 96:
		for x in 128:
			var color := original.get_pixel(x, y)
			if color.a < 0.95 or first.get_pixel(x, y).is_equal_approx(second.get_pixel(x, y)):
				continue
			if color.g - color.r >= 0.04 and color.b - color.r >= 0.04 and color.g >= 0.24:
				changed_water += 1
			else:
				changed_stone += 1
	var passed := changed_water > 20 and changed_stone == 0
	print("WATER RENDER TEST: ", "PASS" if passed else "FAIL", "; animated water pixels=", changed_water, "; changed stone pixels=", changed_stone)
	quit(0 if passed else 1)
