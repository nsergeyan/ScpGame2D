extends Area2D

# You can change these to your likings
@export var amplitude := 4
@export var frequency := 5

var time_passed = 0
var initial_position := Vector2.ZERO
var entry_index: int = -1   # set by Level.gd, indexes ScpArchive.ENTRIES

func _ready():
	add_to_group("documents")
	initial_position = position

func _process(delta):
	coin_hover(delta)

# Coin Hover Animation
func coin_hover(delta):
	time_passed += delta
	position.y = initial_position.y + amplitude * sin(frequency * time_passed)

# Coin collected (a "document" in this game)
func _on_body_entered(body):
	if body.is_in_group("Player"):
		AudioManager.play("coin")
		GameManager.add_score()
		GameManager.collect_entry(entry_index)
		if GameManager.score == 1:   # teach the mechanic the first time it matters
			# typed local: GDScript will not pass a bare array literal into an Array[String] parameter
			var intel: Array[String] = [
				"Classified document recovered.",
				"Every file you carry out is another piece of what this place really is.",
				"The more you take, the more you learn about the Foundation.",
				"Somewhere in these files is the truth about SCP Foundation.",
			]
			GameManager.announce("document_intel", intel)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
		await tween.finished
		queue_free()
