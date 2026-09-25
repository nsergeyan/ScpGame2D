extends CanvasLayer
# Autoload: the blink gauge and the eyelids.
#
# Only runs while an SCP-173 is awake. Everywhere else the player never blinks,
# so ordinary platforming is never interrupted, and the gauge appearing is itself
# the warning that something is in the room with you.
#
# eyes_shut is what SCP-173 reads. While it is true the statue ignores where the
# player is looking and lunges.

const INTERVAL := 6.5      # seconds of held gaze before a blink is forced
const CLOSE := 0.13        # lids coming down: the player's warning frame
const SHUT := 0.34         # blind, and the statue is free
const OPEN := 0.18
const MIN_HOLD := 0.8      # a voluntary blink cannot be spammed
const DROOP_FROM := 0.35   # fraction of the gauge where the lids start sagging
const DROOP_MAX := 0.13
const NEAR := 900.0        # distance at which the gauge starts warning
const GAINED_SHAKE := 70.0 # ground lost in a blink before the camera jolts

const CALM := Color(0.45, 0.75, 0.5)
const WARN := Color(0.93, 0.72, 0.25)
const DANGER := Color(0.93, 0.26, 0.2)

# The gauge is an eye that closes as the blink approaches, so it reads without
# being parsed. Drawn rather than drawn-from-a-texture so it can recolour.
class EyeGauge extends Control:
	var closure: float = 0.0
	var tint: Color = Color(0.45, 0.75, 0.5)
	var alarm: float = 0.0       # 0..1, how close SCP-173 is

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cy := h * 0.5
		var panel := Color(0.03, 0.035, 0.045, 0.82 + 0.12 * alarm)
		draw_rect(Rect2(Vector2.ZERO, size), panel)
		if alarm > 0.02:                     # border glows as it closes in
			draw_rect(Rect2(Vector2.ZERO, size), Color(DANGER.r, DANGER.g, DANGER.b, 0.7 * alarm), false, 2.0)

		var pts := PackedVector2Array()
		var steps := 26
		for i in steps + 1:                  # upper lid line
			var t := float(i) / steps
			pts.append(Vector2(lerpf(10.0, w - 10.0, t), cy - sin(t * PI) * (h * 0.30)))
		for i in steps + 1:                  # lower lid line
			var t := 1.0 - float(i) / steps
			pts.append(Vector2(lerpf(10.0, w - 10.0, t), cy + sin(t * PI) * (h * 0.30)))
		draw_colored_polygon(pts, Color(0.08, 0.09, 0.11))
		draw_polyline(pts, tint, 2.0)
		draw_circle(Vector2(w * 0.5, cy), h * 0.15, tint)

		var lid := closure * (h * 0.5)       # eyelids sweep in over the eye
		if lid > 0.0:
			draw_rect(Rect2(0, 0, w, lid), panel)
			draw_rect(Rect2(0, h - lid, w, lid), panel)

var eyes_shut: bool = false
var timer: float = INTERVAL
var phase: int = 0         # 0 watching, 1 closing, 2 shut, 3 opening
var phase_t: float = 0.0
var armed: bool = false
var dist_at_close: float = 0.0

var lid_top: ColorRect
var lid_low: ColorRect
var gauge: EyeGauge
var label: Label

func _ready() -> void:
	layer = 90
	_build()

func _build() -> void:
	lid_top = ColorRect.new()
	lid_top.color = Color(0, 0, 0, 1)
	lid_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lid_top.anchor_right = 1.0
	add_child(lid_top)

	lid_low = ColorRect.new()
	lid_low.color = Color(0, 0, 0, 1)
	lid_low.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lid_low.anchor_right = 1.0
	lid_low.anchor_top = 1.0
	lid_low.anchor_bottom = 1.0
	add_child(lid_low)

	gauge = EyeGauge.new()
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.anchor_left = 0.5
	gauge.anchor_right = 0.5
	gauge.anchor_top = 1.0
	gauge.anchor_bottom = 1.0
	gauge.offset_left = -70.0
	gauge.offset_right = 70.0
	gauge.offset_top = -74.0
	gauge.offset_bottom = -30.0
	add_child(gauge)

	label = Label.new()
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.66, 0.68, 0.70))
	label.add_theme_constant_override("outline_size", 0)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = -110.0
	label.offset_right = 110.0
	label.offset_top = -28.0
	label.offset_bottom = -8.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	_set_lids(0.0)
	_show(false)

func _show(v: bool) -> void:
	gauge.visible = v
	label.visible = v

# 0 = open, 1 = fully shut. Anchors rather than pixels so it scales with the window.
func _set_lids(p: float) -> void:
	lid_top.anchor_bottom = 0.52 * p
	lid_low.anchor_top = 1.0 - 0.52 * p

func _statue_awake() -> bool:
	for s in get_tree().get_nodes_in_group("SCP"):
		if s.get("active") and not s.get("gone"):
			return true
	return false

func _statue_distance() -> float:
	var p = GameManager.player
	if not is_instance_valid(p):
		return INF
	var best := INF
	for s in get_tree().get_nodes_in_group("SCP"):
		if s.get("gone"):
			continue
		best = minf(best, absf(s.global_position.x - p.global_position.x))
	return best

func reset() -> void:
	timer = INTERVAL
	phase = 0
	phase_t = 0.0
	eyes_shut = false
	_set_lids(0.0)

func blink() -> void:
	if phase != 0 or timer > INTERVAL - MIN_HOLD:
		return          # already blinking, or blinked a moment ago
	phase = 1
	phase_t = 0.0

func _process(delta: float) -> void:
	armed = _statue_awake()
	_show(armed)
	if not armed:
		if phase != 0:
			reset()
		return
	var player = GameManager.player
	if not is_instance_valid(player) or player.dead:
		reset()
		return

	match phase:
		0:
			timer -= delta
			var left0 := clampf(timer / INTERVAL, 0.0, 1.0)
			# eyes getting heavy: the lids sag before the blink is forced
			_set_lids(0.0 if left0 > DROOP_FROM else (DROOP_FROM - left0) / DROOP_FROM * DROOP_MAX)
			if Input.is_action_just_pressed("Blink") or timer <= 0.0:
				blink()
		1:
			phase_t += delta
			_set_lids(minf(phase_t / CLOSE, 1.0))
			if phase_t >= CLOSE:
				phase = 2
				phase_t = 0.0
				eyes_shut = true
				dist_at_close = _statue_distance()
		2:
			phase_t += delta
			if phase_t >= SHUT:
				phase = 3
				phase_t = 0.0
				eyes_shut = false
				# opening on a statue that has closed in should hit you in the chair
				var gained := dist_at_close - _statue_distance()
				if gained > GAINED_SHAKE:
					player.shake = maxf(player.shake, clampf(gained / 18.0, 4.0, 14.0))
		3:
			phase_t += delta
			_set_lids(1.0 - minf(phase_t / OPEN, 1.0))
			if phase_t >= OPEN:
				reset()

	var left := clampf(timer / INTERVAL, 0.0, 1.0)
	var d := _statue_distance()
	gauge.alarm = 0.0 if d == INF else clampf(1.0 - d / NEAR, 0.0, 1.0)
	gauge.closure = 1.0 if phase == 2 else (
		minf(phase_t / CLOSE, 1.0) if phase == 1 else (
		1.0 - minf(phase_t / OPEN, 1.0) if phase == 3 else
		clampf((DROOP_FROM - left) / DROOP_FROM, 0.0, 1.0) * 0.75))
	gauge.tint = DANGER if left < 0.22 else (WARN if left < DROOP_FROM else CALM)
	gauge.queue_redraw()
	if left < 0.22:
		label.text = "BLINKING" if int(Time.get_ticks_msec() / 200.0) % 2 == 0 else ""
	else:
		label.text = "E  to blink       %.1f" % maxf(timer, 0.0)
