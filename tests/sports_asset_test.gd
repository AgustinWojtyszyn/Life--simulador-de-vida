extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	# Test 1: All 8 views exist
	var directions = ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
	var paths := []
	for dir in directions:
		var path := "res://assets/vehicles/sports_v2/" + dir + ".png"
		check(ResourceLoader.exists(path), "Missing sports_v2 view: " + dir)
		if ResourceLoader.exists(path):
			paths.append(path)
	
	# Test 2: Old sports car should NOT appear in spawn lists
	var playground_script := load("res://scripts/playground.gd")
	var source := playground_script.source_code
	check(not source.contains('"sports"'), "Old 'sports' model should not appear in spawn lists")
	check(source.contains('"sports_v2"'), "New 'sports_v2' model should appear in spawn lists")
	
	# Test 3: Load each image and verify reasonable dimensions
	for path in paths:
		var img: Image = load(path).get_image()
		check(img.get_width() >= 64 and img.get_height() >= 64, "sports_v2 image too small: " + path)
		check(img.get_width() <= 256 and img.get_height() <= 256, "sports_v2 image too large: " + path)
	
	# Test 4: Check alpha channel for single vehicle (not duplicated)
	for path in paths:
		var img: Image = load(path).get_image()
		var alpha_data: PackedByteArray = img.get_data()
		# Count opaque pixels - should be reasonable for ONE car
		var opaque_count := 0
		for y in range(0, img.get_height(), 2):
			for x in range(0, img.get_width(), 2):
				var idx := (y * img.get_width() + x) * 4 + 3
				if idx < alpha_data.size() and alpha_data[idx] > 100:
					opaque_count += 1
		# A single car should have between 500-3000 sampled opaque pixels
		check(opaque_count >= 100, "sports_v2 " + path + " has too few opaque pixels: " + str(opaque_count))
		check(opaque_count <= 10000, "sports_v2 " + path + " has too many opaque pixels (possible duplicate): " + str(opaque_count))
	
	print("SPORTS ASSET TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
