@tool
extends StaticBody2D
# NEW OBJECT 3b: sliding door. Opens when a Button with the same "channel" is pressed
# (or when the level calls open() - the cell door uses channel "cell").

@export var channel: String = "A"
# Most doors stay open once opened, so a puzzle is not repeated. A door that
# gates a loop the player must run again has to shut behind them on a death.
@export var relocks: bool = false
@export var height_tiles: int = 6:
	set(v):
		height_tiles = maxi(v, 1)
		if is_node_ready():
			_refresh()

const TEX := preload("res://Assets/Spritesheet/facility_tilesheet.png")
const BODY := Rect2(13 * 64, 1 * 64, 64, 64)      # steel leaf, see Tools/make_facility_tiles.py
const FOOT := Rect2(12 * 64, 2 * 64, 64, 64)      # the same with a hazard band
# Every door is the same grey steel now, so the channel is shown by a status
# light in the colour of the button that opens it.
const LIGHTS := {
	"A": Color(0.25, 0.6, 1.0), "B": Color(0.3, 0.9, 0.4), "C": Color(1.0, 0.82, 0.2), "D": Color(1.0, 0.5, 0.15), "cell": Color(1.0, 0.25, 0.2),
}

var opened: bool = false
var origin: Vector2 = Vector2.ZERO
var slide_tween: Tween
@onready var shape: CollisionShape2D = $Shape

func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	origin = position
	add_to_group("door_" + channel)
	add_to_group("resettable")

func _refresh() -> void:
	var s := RectangleShape2D.new()
	s.size = Vector2(64, height_tiles * 64.0)
	shape.shape = s
	shape.position = s.size / 2.0
	queue_redraw()

func _draw() -> void:
	for i in height_tiles:
		draw_texture_rect_region(TEX, Rect2(0, i * 64.0, 64, 64), FOOT if i == height_tiles - 1 else BODY)
	draw_rect(Rect2(0, 0, 64, 8), Color(0.1, 0.1, 0.1, 0.5))
	var lamp: Color = LIGHTS.get(channel, LIGHTS["A"])
	var y := height_tiles * 32.0 - 12
	draw_rect(Rect2(40, y - 4, 16, 24), Color(0.12, 0.12, 0.13))
	draw_rect(Rect2(44, y, 8, 16), lamp)

func open() -> void:
	if opened:
		return
	opened = true
	AudioManager.play("door", -2.0)
	shape.set_deferred("disabled", true)
	if slide_tween:
		slide_tween.kill()
	slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", origin.y - height_tiles * 64.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func reset_to_start() -> void:
	if not relocks or not opened:
		return
	# A death mid-slide would otherwise leave the tween running, and it would
	# finish opening the door after the reset had already closed it.
	if slide_tween:
		slide_tween.kill()
	opened = false
	position = origin
	shape.set_deferred("disabled", false)
