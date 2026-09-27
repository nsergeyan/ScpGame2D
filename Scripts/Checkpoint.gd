extends Area2D
# Checkpoint terminal: red = inactive, green = active. Dying respawns you at the last active one.

# Reaching a terminal finishes the section behind it. Set this false on a
# checkpoint that sits INSIDE an encounter, like the one in the SCP-173 wing,
# where the loop-back deliberately sends the player back past it.
@export var retires_previous: bool = true

var active: bool = false
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.region_rect = Rect2(5 * 64, 2 * 64, 64, 64)

func _physics_process(_delta: float) -> void:
	if active:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("Player"):
			active = true
			b.spawn_position = global_position
			b.heal_full()
			sprite.region_rect = Rect2(5 * 64, 3 * 64, 64, 64)
			AudioManager.play("checkpoint", -4.0)
			if retires_previous:
				_retire_behind()
			break

# Dropping a finished section out of the group stops a later death from
# re-arming it: the statue coming back with its blink meter, the door
# relocking, the keycard reappearing on its ledge.
func _retire_behind() -> void:
	for n in get_tree().get_nodes_in_group("resettable"):
		if n is Node2D and n.global_position.x < global_position.x:
			n.remove_from_group("resettable")
