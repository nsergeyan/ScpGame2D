# Autoload: plays sound effects, looping ambient music and the alarm siren.
# Usage from any script:  AudioManager.play("punch")
extends Node

const PATHS := {
	"jump": "res://Assets/Sound/FX/jump.wav",
	"coin": "res://Assets/Sound/FX/coin_pickup.wav",
	"hurt": "res://Assets/Sound/FX/hurt.wav",
	"punch": "res://Assets/Sound/FX/punch.wav",
	"guard_hit": "res://Assets/Sound/FX/guard_hit.wav",
	"guard_down": "res://Assets/Sound/FX/guard_down.wav",
	"shoot": "res://Assets/Sound/FX/shoot.wav",
	"button": "res://Assets/Sound/FX/button.wav",
	"door": "res://Assets/Sound/FX/door.wav",
	"checkpoint": "res://Assets/Sound/FX/checkpoint.wav",
	"keycard": "res://Assets/Sound/FX/keycard.wav",
	"crumble": "res://Assets/Sound/FX/crumble.wav",
	"zap": "res://Assets/Sound/FX/zap.wav",
	"statue_step": "res://Assets/Sound/FX/statue_step.wav",
	"guard_spot_1": "res://Assets/Sound/Voice/guard_spot_1.mp3",
	"guard_spot_2": "res://Assets/Sound/Voice/guard_spot_2.mp3",
	"guard_spot_3": "res://Assets/Sound/Voice/guard_spot_3.mp3",
	"guard_spot_4": "res://Assets/Sound/Voice/guard_spot_4.mp3",
	"guard_lost_1": "res://Assets/Sound/Voice/guard_lost_1.mp3",
	"guard_lost_2": "res://Assets/Sound/Voice/guard_lost_2.mp3",
	"guard_lost_3": "res://Assets/Sound/Voice/guard_lost_3.mp3",
	"guard_fire_1": "res://Assets/Sound/Voice/guard_fire_1.mp3",
	"guard_fire_2": "res://Assets/Sound/Voice/guard_fire_2.mp3",
	"guard_die_1": "res://Assets/Sound/Voice/guard_die_1.mp3",
	"guard_die_2": "res://Assets/Sound/Voice/guard_die_2.mp3",
	"pa_chime": "res://Assets/Sound/FX/pa_chime.wav",
	"escape": "res://Assets/Sound/FX/escape.wav",
	"level_complete": "res://Assets/Sound/FX/level_complete.wav",
	"ambient": "res://Assets/Sound/Music/level_ambient.mp3",
	"outro": "res://Assets/Sound/Music/outro.mp3",
	"menu": "res://Assets/Sound/Music/menu_theme.mp3",
	"alarm": "res://Assets/Sound/FX/alarm.wav",
}

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var alarm_player: AudioStreamPlayer
var music_on := false
var alarm_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in PATHS:
		streams[key] = load(PATHS[key])
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(func(): if music_on: music_player.play())
	alarm_player = AudioStreamPlayer.new()
	add_child(alarm_player)
	alarm_player.finished.connect(func(): if alarm_active: alarm_player.play())

func play(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not streams.has(sfx_name) or streams[sfx_name] == null:
		return
	for p in pool:
		if not p.playing:
			p.stream = streams[sfx_name]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	# every player busy: reuse the first one
	pool[0].stream = streams[sfx_name]
	pool[0].volume_db = volume_db
	pool[0].pitch_scale = pitch
	pool[0].play()

func play_music(music_name: String = "ambient", volume_db: float = -8.0, loop: bool = true) -> void:
	music_on = loop
	music_player.stream = streams[music_name]
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	music_on = false
	music_player.stop()

func start_alarm(volume_db: float = -14.0) -> void:
	alarm_active = true
	alarm_player.stream = streams["alarm"]
	alarm_player.volume_db = volume_db
	alarm_player.play()

func stop_alarm() -> void:
	alarm_active = false
	alarm_player.stop()
