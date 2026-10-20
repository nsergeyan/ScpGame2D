extends Area2D
# NEW OBJECT 3a: floor button (external trigger). Stand on it to open every Door
# with the same "channel" letter (A blue, B green, C yellow, D orange).

@export var channel: String = "A"

const TILES := {"A": Vector2i(10, 5), "B": Vector2i(10, 6), "C": Vector2i(12, 5), "D": Vector2i(12, 6)}
const GLOW := {"A": Color(0.25, 0.6, 1.0), "B": Color(0.3, 0.9, 0.4), "C": Color(1.0, 0.82, 0.2), "D": Color(1.0, 0.5, 0.15)}
const UNSHADED := preload("res://Assets/Materials/unshaded.tres")

var pressed: bool = false
var clock: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	material = UNSHADED   # the glow and arrow must read in the dark; the sprite keeps its own shading
	_set_region(0)
	add_to_group("resettable")

func reset_to_start() -> void:
	pressed = false   # re-arm: a relocking door needs pressing again
	_set_region(0)
	queue_redraw()

func _set_region(dx: int) -> void:
	var c: Vector2i = TILES.get(channel, Vector2i(10, 5))
	sprite.region_rect = Rect2((c.x + dx) * 64, c.y * 64, 64, 64)

func _process(delta: float) -> void:
	if pressed:
		return
	clock += delta
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if pressed:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("Player") and not b.dead:
			pressed = true
			_set_region(1)
			queue_redraw()
			AudioManager.play("button")
			get_tree().call_group("door_" + channel, "open")
			break

# Pulsing glow and a bouncing arrow until it is pressed, so the player notices it.
func _draw() -> void:
	if pressed:
		return
	var col: Color = GLOW.get(channel, GLOW["A"])
	var pulse := 0.5 + 0.5 * sin(clock * 4.0)
	var r := 36.0 + 8.0 * pulse
	var dome := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		dome.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(dome, Color(col, 0.15 + 0.15 * pulse))
	var y := -86.0 - 10.0 * absf(sin(clock * 3.0))
	draw_rect(Rect2(-5, y - 20, 10, 20), col)
	draw_colored_polygon(PackedVector2Array([Vector2(-15, y), Vector2(15, y), Vector2(0, y + 18)]), col)
