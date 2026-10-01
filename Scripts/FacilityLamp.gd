extends Node2D
# One ceiling fluorescent: the fixture is drawn here, the light it casts is a
# PointLight2D child. FacilityLighting places these along the level.
#
# The fixture uses the unshaded material, so the darkness does not dim the
# tube itself: a lamp should look lit even where nothing else is.

const UNSHADED := preload("res://Assets/Materials/unshaded.tres")
const WHITE := Color(1.0, 0.96, 0.86)       # warm, slightly green-grey fluorescent
const ALARM := Color(1.0, 0.18, 0.12)

var flickers: bool = false
var energy: float = 1.0
var light: PointLight2D
var rng := RandomNumberGenerator.new()
var dim_left: float = 0.0       # seconds the tube stays dropped out during a flicker
var tube: float = 1.0           # how bright the tube is drawn, 0..1

func setup(light_texture: Texture2D, seed_value: int, flicker: bool) -> void:
	rng.seed = seed_value
	flickers = flicker
	material = UNSHADED
	light = PointLight2D.new()
	light.texture = light_texture
	light.texture_scale = 3.4     # ~435px reach: pools of light with dimmer gaps between
	light.color = WHITE
	light.energy = energy
	light.position = Vector2(0, 120)   # aimed down into the room, not into the ceiling
	add_child(light)
	GameManager.alarm_changed.connect(_on_alarm)
	_on_alarm(GameManager.alarm_on)

func _on_alarm(on: bool) -> void:
	light.color = ALARM if on else WHITE
	queue_redraw()

func _process(delta: float) -> void:
	var level := 1.0
	if GameManager.alarm_on:
		# emergency lighting: a slow red pulse, all lamps in step
		level = 0.55 + 0.45 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 3.2))
	if flickers:
		if dim_left > 0.0:
			dim_left -= delta
			level *= 0.12
		elif rng.randf() < delta * 0.9:    # roughly one stutter a second
			dim_left = rng.randf_range(0.04, 0.22)
	light.energy = energy * level
	if not is_equal_approx(tube, level):
		tube = level
		queue_redraw()

func _draw() -> void:
	var glow := (ALARM if GameManager.alarm_on else WHITE)
	draw_rect(Rect2(-28, 0, 56, 10), Color(0.16, 0.16, 0.17))                      # housing
	draw_rect(Rect2(-24, 6, 48, 6), glow.darkened(0.75 - 0.75 * tube))              # tube
	draw_rect(Rect2(-20, 12, 40, 3), Color(glow.r, glow.g, glow.b, 0.35 * tube))    # bloom lip
