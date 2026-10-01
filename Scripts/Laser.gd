@tool
extends Area2D
# NEW OBJECT 4: timed laser barrier. OFF -> WARNING (flickers) -> ON (deadly) -> OFF ...
# Walk through while it is off. "start_delay" shifts the rhythm between lasers.

@export var height_tiles: int = 6:
	set(v):
		height_tiles = maxi(v, 1)
		if is_node_ready():
			_refresh()
@export var on_time: float = 1.3
@export var off_time: float = 1.9
@export var warn_time: float = 0.45
@export var start_delay: float = 0.0

const UNSHADED := preload("res://Assets/Materials/unshaded.tres")

var mode: int = 0   # 0 off, 1 warning, 2 on
var clock: float = 0.0
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	material = UNSHADED   # a beam is a light source, it should not sink into the dark
	_refresh()

func _refresh() -> void:
	var h := height_tiles * 64.0
	var s := RectangleShape2D.new()
	s.size = Vector2(12, h - 24)
	shape.shape = s
	shape.position = Vector2(0, h / 2.0)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	clock += delta
	var cycle := on_time + off_time + warn_time
	var c := fposmod(clock + start_delay, cycle)
	var new_mode := 0
	if c >= off_time + warn_time:
		new_mode = 2
	elif c >= off_time:
		new_mode = 1
	if new_mode != mode:
		if new_mode == 2 and is_instance_valid(GameManager.player) \
				and absf(GameManager.player.global_position.x - global_position.x) < 700.0:
			AudioManager.play("zap", -8.0)
		mode = new_mode
	queue_redraw()
	if mode == 2:
		for b in get_overlapping_bodies():
			if b.is_in_group("Player"):
				b.die()

func _draw() -> void:
	var h := height_tiles * 64.0
	var flick := Engine.is_editor_hint() or (mode == 1 and int(clock * 14.0) % 2 == 0)
	if mode == 2 or Engine.is_editor_hint():
		draw_rect(Rect2(-9, 12, 18, h - 24), Color(1, 0.1, 0.1, 0.25))
		draw_rect(Rect2(-4, 12, 8, h - 24), Color(1, 0.25, 0.25, 0.95))
		draw_rect(Rect2(-1.5, 12, 3, h - 24), Color(1, 0.9, 0.9, 1))
	elif mode == 1 and flick:
		draw_rect(Rect2(-2, 12, 4, h - 24), Color(1, 0.3, 0.3, 0.55))
	else:
		draw_dashed_line(Vector2(0, 12), Vector2(0, h - 12), Color(1, 0.3, 0.3, 0.18), 2.0, 10.0)
	# emitters
	draw_rect(Rect2(-16, 0, 32, 14), Color(0.25, 0.27, 0.33))
	draw_rect(Rect2(-16, h - 14, 32, 14), Color(0.25, 0.27, 0.33))
	var led := Color(1, 0.2, 0.2) if mode == 2 else (Color(1, 0.8, 0.2) if mode == 1 else Color(0.2, 0.9, 0.3))
	draw_rect(Rect2(-4, 4, 8, 6), led)
	draw_rect(Rect2(-4, h - 10, 8, 6), led)
