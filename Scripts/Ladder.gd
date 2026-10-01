@tool
extends Node2D
# Climbable ladder. Drawn from the steel ladder tile in the facility sheet,
# which has two rungs per tile so stacked copies form one continuous ladder.
#
# The player finds this through the "ladders" group and a plain rectangle test
# rather than an Area2D, because Area2D overlap lists lag a physics frame and a
# climb that engages late feels broken.

@export var tiles: int = 5:
	set(v):
		tiles = maxi(v, 1)
		queue_redraw()

const TEX := preload("res://Assets/Spritesheet/facility_tilesheet.png")
const REGION := Rect2(64, 256, 64, 64)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("ladders")

func _draw() -> void:
	for i in tiles:
		draw_texture_rect_region(TEX, Rect2(0, i * 64.0, 64, 64), REGION)

# Wider than the tile and a little taller at both ends, so grabbing it at the
# foot and topping out are both forgiving.
func climb_rect() -> Rect2:
	return Rect2(global_position.x - 14.0, global_position.y - 10.0, 92.0, tiles * 64.0 + 20.0)

func top_y() -> float:
	return global_position.y
