extends Node2D
# Level controller: camera limits, ambient music, and the opening announcement.
#
# ELEVENLABS VOICE: put your exported file at  res://Assets/Sound/Voice/announcement.mp3
# (or .ogg / .wav). While it plays, the subtitles below are shown and the cell door stays
# locked. When it ends the cell door opens. No file? The subtitles alone play, timed by
# "seconds_per_line".  Edit the subtitle lines in the Inspector (they are split by length).

@export var level_width: int = 12160
@export var level_height: int = 768
@export var play_announcement: bool = true
@export var seconds_per_line: float = 4.5
@export var announcement_lines: Array[String] = [
	"ATTENTION. Site-19 is in full containment breach.",
	"Class-D subject D-9341: your cell lock has failed.",
	"Move with A and D, or the arrow keys. Jump with SPACE. Press SPACE again in mid-air to double jump.",
	"Press F to punch guards, or jump on their heads to stomp them.",
	"Beware SCP-173. It only moves when you are NOT looking at it. Keep it in sight!",
	"Find the yellow keycard, reach the exit gate, and escape. Good luck, D-9341.",
]

const VOICE_PATHS := [
	"res://Assets/Sound/Voice/announcement.mp3",
	"res://Assets/Sound/Voice/announcement.ogg",
	"res://Assets/Sound/Voice/announcement.wav",
]

var skipped: bool = false
var voice: AudioStreamPlayer

@onready var player = $Player

func _ready() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = level_width
	cam.limit_bottom = level_height
	voice = AudioStreamPlayer.new()
	add_child(voice)
	GameManager.timer_running = true
	AudioManager.play_music("ambient", -9.0)
	if play_announcement:
		_run_announcement()
	else:
		_open_cell()

func _find_voice() -> AudioStream:
	for p in VOICE_PATHS:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _process(_delta: float) -> void:
	if GameManager.announcing and Input.is_action_just_pressed("Skip"):
		skipped = true

func _run_announcement() -> void:
	GameManager.announcing = true
	AudioManager.play("pa_chime", -4.0)
	await get_tree().create_timer(1.6).timeout
	var stream := _find_voice()
	var total := announcement_lines.size() * seconds_per_line
	if stream:
		voice.stream = stream
		voice.play()
		total = stream.get_length()
	var chars := 0
	for l in announcement_lines:
		chars += l.length()
	for l in announcement_lines:
		if skipped:
			break
		var dur := total * float(l.length()) / maxf(chars, 1.0)
		GameManager.show_message(l, dur + 0.3)
		var t := 0.0
		while t < dur and not skipped:
			await get_tree().process_frame
			t += get_process_delta_time()
	if stream and voice.playing and not skipped:
		await voice.finished
	voice.stop()
	GameManager.announcing = false
	_open_cell()

func _open_cell() -> void:
	GameManager.show_message("POWER FAILURE - CELL DOOR RELEASED. GO!", 3.0)
	get_tree().call_group("door_cell", "open")
