extends Control
# Shown after the player escapes.

const TITLE := "res://Scenes/UI/Title.tscn"

# points -> letter, and the line shown under the title
const RANKS := [
	[90.0, "S", "Full recovery of site intel. The Foundation is asking questions."],
	[75.0, "A", "Clean exit. Barely a trace left behind."],
	[60.0, "B", "Effective, if messy."],
	[40.0, "C", "You got out. That is the part that counts."],
	[0.0,  "D", "Fitting, for a Class-D."],
]
var started: bool = false
var t: float = 0.0
@onready var stats: Label = $Stats
@onready var rank_label: Label = $Rank
@onready var subtitle: Label = $Subtitle
@onready var prompt: Label = $Prompt

func _ready() -> void:
	AudioManager.stop_alarm()
	AudioManager.play_music("outro", -10.0, false)
	GameManager.alarm_on = false
	stats.text = "Time: %s      Deaths: %d      Documents: %d / %d" % [
		GameManager.format_time(), GameManager.deaths, GameManager.score, GameManager.total_documents]
	var r := _grade()
	rank_label.text = "RANK  %s" % r[0]
	subtitle.text = r[1]

# Graded on intel recovered (50), surviving (30) and speed (20).
func _grade() -> Array:
	var points := 0.0
	if GameManager.total_documents > 0:
		points += 50.0 * float(GameManager.score) / float(GameManager.total_documents)
	points += maxf(30.0 - GameManager.deaths * 5.0, 0.0)
	points += clampf(remap(GameManager.run_time, 180.0, 480.0, 20.0, 0.0), 0.0, 20.0)
	for r in RANKS:
		if points >= r[0]:
			return [r[1], r[2]]
	return ["D", ""]

func _process(delta: float) -> void:
	t += delta
	prompt.modulate.a = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 4.0))
	if not started and t > 0.8 and (Input.is_action_just_pressed("Jump") or Input.is_action_just_pressed("Skip")):
		started = true
		SceneTransition.load_scene(load(TITLE))
