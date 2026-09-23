extends Area2D
# Checkpoint terminal: red = inactive, green = active. Dying respawns you at the last active one.

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
			GameManager.show_message("CHECKPOINT REACHED", 2.0)
			break
