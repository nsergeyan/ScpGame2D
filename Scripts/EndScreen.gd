extends Control
# Shown after the player escapes.

const TITLE := "res://Scenes/UI/Title.tscn"
var started: bool = false
var t: float = 0.0
@onready var stats: Label = $Stats
@onready var prompt: Label = $Prompt

func _ready() -> void:
	AudioManager.stop_music()
	AudioManager.stop_alarm()
	GameManager.alarm_on = false
	stats.text = "Time: %s      Deaths: %d      Documents: %d" % [GameManager.format_time(), GameManager.deaths, GameManager.score]

func _process(delta: float) -> void:
	t += delta
	prompt.modulate.a = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 4.0))
	if not started and t > 0.8 and (Input.is_action_just_pressed("Jump") or Input.is_action_just_pressed("Skip")):
		started = true
		SceneTransition.load_scene(load(TITLE))
