class_name CityTrafficSignal
extends Node2D

const GREEN_SECONDS := 7.0
const AMBER_SECONDS := 1.35
const ALL_RED_SECONDS := 0.75
const CYCLE_SECONDS := (GREEN_SECONDS + AMBER_SECONDS + ALL_RED_SECONDS) * 2.0

var horizontal_half := 60.0
var vertical_half := 60.0
var cycle_offset := 0.0
var horizontal_state := "green"
var vertical_state := "red"
var update_clock := 0.0

func _ready() -> void:
	add_to_group("traffic_signals")
	z_index = 14
	# Spawn four directional signal sprites using the PixelLab asset
	var sprite_path := "res://assets/city/props/traffic_light.png"
	if ResourceLoader.exists(sprite_path):
		var tex: Texture2D = load(sprite_path)
		# Signals stand on the four sidewalk corners, never inside a traffic lane.
		for pos in signal_positions():
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = true
			s.position = pos
			s.scale = Vector2(0.78, 0.78)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(s)
	refresh_state(true)

func _process(delta: float) -> void:
	update_clock += delta
	if update_clock < 0.12:
		return
	update_clock = 0.0
	refresh_state(false)

func refresh_state(force_redraw: bool) -> void:
	var phase := fposmod(Time.get_ticks_msec() / 1000.0 + cycle_offset, CYCLE_SECONDS)
	var next_h := "red"
	var next_v := "red"
	var cursor := 0.0
	if phase < cursor + GREEN_SECONDS:
		next_h = "green"
	elif phase < cursor + GREEN_SECONDS + AMBER_SECONDS:
		next_h = "amber"
	cursor += GREEN_SECONDS + AMBER_SECONDS + ALL_RED_SECONDS
	if phase >= cursor and phase < cursor + GREEN_SECONDS:
		next_v = "green"
	elif phase >= cursor + GREEN_SECONDS and phase < cursor + GREEN_SECONDS + AMBER_SECONDS:
		next_v = "amber"
	if force_redraw or next_h != horizontal_state or next_v != vertical_state:
		horizontal_state = next_h
		vertical_state = next_v
		queue_redraw()

func state_for(forward: Vector2) -> String:
	return horizontal_state if absf(forward.x) >= absf(forward.y) else vertical_state

func blocking_distance(vehicle_position: Vector2, forward: Vector2) -> float:
	if forward.length_squared() < 0.01:
		return INF
	var horizontal := absf(forward.x) >= absf(forward.y)
	var state := horizontal_state if horizontal else vertical_state
	if state == "green":
		return INF
	var stop_point := vehicle_position
	if horizontal:
		if absf(vehicle_position.y - global_position.y) > horizontal_half + 38.0:
			return INF
		stop_point.x = global_position.x - vertical_half - 20.0 if forward.x > 0.0 else global_position.x + vertical_half + 20.0
	else:
		if absf(vehicle_position.x - global_position.x) > vertical_half + 38.0:
			return INF
		stop_point.y = global_position.y - horizontal_half - 20.0 if forward.y > 0.0 else global_position.y + horizontal_half + 20.0
	var ahead := (stop_point - vehicle_position).dot(forward.normalized())
	if ahead < -8.0 or ahead > 240.0:
		return INF
	# A car already committed to a yellow light should clear the junction rather
	# than panic-brake inside it.
	if state == "amber" and ahead < 58.0:
		return INF
	return maxf(0.0, ahead - 12.0)

func signal_positions() -> Array[Vector2]:
	var margin := 24.0
	return [
		Vector2(-vertical_half - margin, -horizontal_half - margin),
		Vector2(vertical_half + margin, -horizontal_half - margin),
		Vector2(vertical_half + margin, horizontal_half + margin),
		Vector2(-vertical_half - margin, horizontal_half + margin),
	]

func _draw() -> void:
	var positions := signal_positions()
	draw_head(positions[0], horizontal_state)
	draw_head(positions[2], horizontal_state)
	draw_head(positions[1], vertical_state)
	draw_head(positions[3], vertical_state)

func draw_head(at: Vector2, state: String) -> void:
	draw_line(at + Vector2(0, 8), at + Vector2(0, 28), Color("36454a"), 3.0)
	draw_rect(Rect2(at - Vector2(6, 14), Vector2(12, 25)), Color("172428"))
	var red := Color("e05a52") if state == "red" else Color(0.28, 0.20, 0.19)
	var amber := Color("e6b95e") if state == "amber" else Color(0.28, 0.24, 0.17)
	var green := Color("68b878") if state == "green" else Color(0.18, 0.28, 0.20)
	draw_circle(at + Vector2(0, -9), 3.2, red)
	draw_circle(at + Vector2(0, -1), 3.2, amber)
	draw_circle(at + Vector2(0, 7), 3.2, green)
