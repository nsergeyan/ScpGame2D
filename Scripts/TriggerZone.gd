extends Area2D
# Invisible zone. When the player enters it can show a hint and/or call a method on a group
# (e.g. wake the statue). Origin = bottom centre of the zone.

@export var size: Vector2 = Vector2(64, 400)
@export_multiline var text: String = ""
@export var text_time: float = 4.0
@export var call_group: String = ""
@export var call_method: String = ""
@export var once: bool = true

var fired: bool = false

func _ready() -> void:
	var s := RectangleShape2D.new()
	s.size = size
	var cs := CollisionShape2D.new()
	cs.shape = s
	cs.position = Vector2(0, -size.y / 2.0)
	add_child(cs)
	if call_group != "":
		add_to_group("resettable")

func reset_to_start() -> void:
	fired = false   # re-arm after the player dies

func _physics_process(_delta: float) -> void:
	if fired and once:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("Player"):
			fired = true
			if text != "":
				GameManager.show_message(text, text_time)
			if call_group != "":
				get_tree().call_group(call_group, call_method)
			break
