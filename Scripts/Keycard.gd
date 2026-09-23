extends Area2D
# Yellow keycard: required to open the exit gate. Picking it up sets off the alarm.

@export var triggers_alarm: bool = true
var t: float = 0.0
var base_y: float = 0.0
var taken: bool = false

func _ready() -> void:
	base_y = position.y
	add_to_group("resettable")

func _process(delta: float) -> void:
	t += delta
	position.y = base_y + 5.0 * sin(t * 4.0)

func _physics_process(_delta: float) -> void:
	if taken:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("Player"):
			taken = true
			GameManager.has_keycard = true
			AudioManager.play("keycard")
			GameManager.show_message("KEYCARD ACQUIRED! The alarm is blaring - RUN to the exit!", 4.0)
			if triggers_alarm:
				GameManager.alarm_on = true
				AudioManager.start_alarm()
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2.ZERO, 0.15)
			await tw.finished
			hide()
			break

func reset_to_start() -> void:
	pass   # once collected, the keycard stays collected
