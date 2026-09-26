extends Area2D
# Yellow keycard: required to open the exit gate. The lockdown is already
# running by the time it can be reached, armed by the SCP-173 breach.

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
			if GameManager.escape_running:
				GameManager.show_message("KEYCARD ACQUIRED! %s to reach the gate!" % GameManager.format_escape(), 4.0, true)
			else:
				GameManager.show_message("KEYCARD ACQUIRED! Get to the exit gate!", 4.0, true)
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2.ZERO, 0.15)
			await tw.finished
			hide()
			break

func reset_to_start() -> void:
	taken = false
	scale = Vector2.ONE
	show()
