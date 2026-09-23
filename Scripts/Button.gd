extends Area2D
# NEW OBJECT 3a: floor button (external trigger). Stand on it to open every Door
# with the same "channel" letter (A blue, B green, C yellow, D orange).

@export var channel: String = "A"

const TILES := {"A": Vector2i(10, 5), "B": Vector2i(10, 6), "C": Vector2i(12, 5), "D": Vector2i(12, 6)}

var pressed: bool = false
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_set_region(0)

func _set_region(dx: int) -> void:
	var c: Vector2i = TILES.get(channel, Vector2i(10, 5))
	sprite.region_rect = Rect2((c.x + dx) * 64, c.y * 64, 64, 64)

func _physics_process(_delta: float) -> void:
	if pressed:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("Player"):
			pressed = true
			_set_region(1)
			AudioManager.play("button")
			get_tree().call_group("door_" + channel, "open")
			break
