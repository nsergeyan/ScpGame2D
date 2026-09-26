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

const TEX := preload("res://Assets/Spritesheet/platformPack_tilesheet.png")
const COLORS := {
	"A": Vector2i(6, 0), "B": Vector2i(6, 1), "C": Vector2i(7, 0), "D": Vector2i(7, 1), "cell": Vector2i(4, 4),
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
	var c: Vector2i = COLORS.get(channel, Vector2i(6, 0))
	for i in height_tiles:
		draw_texture_rect_region(TEX, Rect2(0, i * 64.0, 64, 64), Rect2(c.x * 64, c.y * 64, 64, 64))
	# hazard stripe so it reads as a door
	draw_rect(Rect2(0, 0, 64, 8), Color(0.1, 0.1, 0.1, 0.5))
	draw_rect(Rect2(28, height_tiles * 32.0 - 20, 8, 40), Color(0, 0, 0, 0.45))

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
