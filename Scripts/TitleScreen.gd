extends Control
# Title screen. SPACE / ENTER starts a new run.

const LEVEL := "res://Scenes/Levels/Level_ClassD.tscn"
var started: bool = false
var t: float = 0.0
@onready var prompt: Label = $Prompt

func _ready() -> void:
	AudioManager.stop_alarm()
	AudioManager.play_music("menu", -10.0)

func _process(delta: float) -> void:
	t += delta
	prompt.modulate.a = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 4.0))
	if not started and (Input.is_action_just_pressed("Jump") or Input.is_action_just_pressed("Skip")):
		started = true
		GameManager.reset_run()
		AudioManager.play("checkpoint", -4.0)
		SceneTransition.load_scene(load(LEVEL))
