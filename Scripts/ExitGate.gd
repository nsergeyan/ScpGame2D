extends Area2D
# The exit. Needs the keycard.

const END_SCENE := "res://Scenes/UI/EndScreen.tscn"
var used: bool = false
var warn_cd: float = 0.0
@onready var top: Sprite2D = $Top
@onready var bottom: Sprite2D = $Bottom

func _ready() -> void:
	GameManager.keycard_changed.connect(_on_keycard)

func _on_keycard(has: bool) -> void:
	# unlocked gate turns into the dark "open" archway
	top.region_rect = Rect2((5 if has else 7) * 64, 5 * 64, 64, 64)
	bottom.region_rect = Rect2((5 if has else 7) * 64, 6 * 64, 64, 64)

func _physics_process(delta: float) -> void:
	warn_cd = maxf(warn_cd - delta, 0.0)
	if used:
		return
	for b in get_overlapping_bodies():
		if not b.is_in_group("Player"):
			continue
		if GameManager.has_keycard:
			used = true
			b.movement_enabled = false
			GameManager.timer_running = false
			AudioManager.stop_alarm()
			AudioManager.play("escape")
			SceneTransition.load_scene(load(END_SCENE))
		elif warn_cd <= 0.0:
			warn_cd = 2.5
			GameManager.show_message("ACCESS DENIED - find the yellow keycard!", 2.5)
