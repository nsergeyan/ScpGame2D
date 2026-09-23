@tool
extends StaticBody2D
# NEW OBJECT 1: crumbling platform. Shakes when the player steps on it, falls, then respawns.
# Change "tiles" (width), "fall_delay" and "respawn_time" in the Inspector.

@export var tiles: int = 2:
	set(v):
		tiles = maxi(v, 1)
		if is_node_ready():
			_refresh()
@export var fall_delay: float = 0.6
@export var respawn_time: float = 3.5
@export var tile_region: Rect2 = Rect2(192, 128, 64, 32)   # yellow "unstable" block (top half)

const TEX := preload("res://Assets/Spritesheet/platformPack_tilesheet.png")
const THICK := 32.0

var origin: Vector2 = Vector2.ZERO
var state: int = 0          # 0 idle, 1 shaking, 2 falling, 3 gone
var timer: float = 0.0
var fall_speed: float = 0.0

@onready var shape: CollisionShape2D = $Shape
@onready var trigger: Area2D = $Trigger
@onready var trigger_shape: CollisionShape2D = $Trigger/TriggerShape

func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	origin = position
	add_to_group("resettable")

func _refresh() -> void:
	var s := RectangleShape2D.new()
	s.size = Vector2(tiles * 64.0, THICK)
	shape.shape = s
	shape.position = s.size / 2.0
	shape.one_way_collision = true
	var t := RectangleShape2D.new()
	t.size = Vector2(tiles * 64.0 - 10.0, 18.0)
	trigger_shape.shape = t
	trigger_shape.position = Vector2(tiles * 32.0, -11.0)
	queue_redraw()

func _draw() -> void:
	for i in tiles:
		draw_texture_rect_region(TEX, Rect2(i * 64.0, 0, 64, THICK), tile_region)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match state:
		0:
			for b in trigger.get_overlapping_bodies():
				if b.is_in_group("Player"):
					state = 1
					timer = fall_delay
					AudioManager.play("crumble", -6.0)
					break
		1:
			timer -= delta
			position.x = origin.x + randf_range(-2.0, 2.0)
			if timer <= 0.0:
				position.x = origin.x
				state = 2
				fall_speed = 0.0
				shape.set_deferred("disabled", true)
		2:
			fall_speed += 1500.0 * delta
			position.y += fall_speed * delta
			modulate.a = maxf(modulate.a - delta * 1.5, 0.0)
			if position.y > origin.y + 400.0:
				state = 3
				timer = respawn_time
				visible = false
		3:
			timer -= delta
			if timer <= 0.0:
				reset_to_start()

func reset_to_start() -> void:
	position = origin
	modulate.a = 1.0
	visible = true
	state = 0
	shape.set_deferred("disabled", false)
