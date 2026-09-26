extends Node

signal changed
# One real second advances one world minute; pauses and menus stop the clock.
var minutes_per_second := 1.0
var total_minutes := 8.0 * 60.0
var played_seconds := 0.0
var last_minute := -1

func _process(delta: float) -> void:
	if not WorldManager.playing:
		return
	played_seconds += delta
	advance(delta * minutes_per_second)

func advance(minutes: float) -> void:
	total_minutes = maxf(0, total_minutes + minutes)
	if int(total_minutes) != last_minute:
		last_minute = int(total_minutes)
		changed.emit()

func day() -> int:
	return int(total_minutes / 1440.0) + 1

func hour() -> int:
	return int(total_minutes / 60.0) % 24

func period() -> String:
	var h := hour()
	return "AMANECER" if h >= 5 and h < 8 else "DÍA" if h >= 8 and h < 17 else "ATARDECER" if h >= 17 and h < 20 else "NOCHE"

func display() -> String:
	return "D%d · %02d:%02d" % [day(), hour(), int(total_minutes) % 60]

func tint() -> Color:
	var h := fposmod(total_minutes, 1440.0) / 60.0
	var stops := [0.0, 5.0, 8.0, 17.0, 20.0, 24.0]
	var colors := [Color("677fa8"), Color("8696ae"), Color.WHITE, Color("ffe6bc"), Color("677fa8"), Color("677fa8")]
	for i in 5:
		if h <= stops[i + 1]:
			return colors[i].lerp(colors[i + 1], inverse_lerp(stops[i], stops[i + 1], h))
	return colors[0]

func to_dict() -> Dictionary:
	return {"minutes": total_minutes, "played_seconds": played_seconds, "speed": minutes_per_second}

func restore(data: Dictionary) -> void:
	total_minutes = maxf(0, float(data.get("minutes", 480)))
	played_seconds = maxf(0, float(data.get("played_seconds", 0)))
	minutes_per_second = clampf(float(data.get("speed", minutes_per_second)), 0.25, 4.0)
	last_minute = -1
	advance(0)
