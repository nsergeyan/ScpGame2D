@tool
extends AnimatableBody2D
# NEW OBJECT 2: moving platform for timed jumps. It glides between its start
# position and start + travel, pausing at each end. Edit "travel" in the Inspector.

@export var tiles: int = 2:
	set(v):
		tiles = maxi(v, 1)
		if is_node_ready():
			_refresh()
@export var travel: Vector2 = Vector2(128, 0)   # offset to the far end (pixels)
@export var move_time: float = 1.6              # seconds for one direction
@export var pause_time: float = 0.35
@export var start_delay: float = 0.0            # shift the phase between platforms
@export var tile_region: Rect2 = Rect2(384, 0, 64, 32)   # blue metal block (top half)

const TEX := preload("res://Assets/Spritesheet/platformPack_tilesheet.png")
const THICK := 32.0

var origin: Vector2 = Vector2.ZERO
var tw: Tween

@onready var shape: CollisionShape2D = $Shape

func _ready() -> void:
	sync_to_physics = true
	_refresh()
	if Engine.is_editor_hint():
		return
	origin = position
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout
	_start()

func _refresh() -> void:
	var s := RectangleShape2D.new()
	s.size = Vector2(tiles * 64.0, THICK)
	shape.shape = s
	shape.position = s.size / 2.0
	shape.one_way_collision = true
	queue_redraw()

func _draw() -> void:
	for i in tiles:
		draw_texture_rect_region(TEX, Rect2(i * 64.0, 0, 64, THICK), tile_region)
	if Engine.is_editor_hint():   # show the path in the editor
		draw_line(Vector2(tiles * 32.0, 16), Vector2(tiles * 32.0, 16) + travel, Color(1, 1, 0, 0.7), 2.0)

func _start() -> void:
	tw = create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.set_loops()
	tw.tween_property(self, "position", origin + travel, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(pause_time)
	tw.tween_property(self, "position", origin, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(pause_time)
