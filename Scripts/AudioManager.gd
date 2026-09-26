# Autoload: plays sound effects, looping ambient music and the alarm siren.
# Usage from any script:  AudioManager.play("jump")
extends Node

const PATHS := {
	"jump": "res://Assets/Sound/FX/jump.wav",
	"land": "res://Assets/Sound/FX/land.wav",
	"coin": "res://Assets/Sound/FX/coin_pickup.wav",
	"hurt_1": "res://Assets/Sound/FX/hurt_1.wav",
	"hurt_2": "res://Assets/Sound/FX/hurt_2.wav",
	"punch_1": "res://Assets/Sound/FX/punch_1.wav",
	"punch_2": "res://Assets/Sound/FX/punch_2.wav",
	"guard_hit": "res://Assets/Sound/FX/guard_hit.wav",
	"guard_down": "res://Assets/Sound/FX/guard_down.wav",
	"shoot": "res://Assets/Sound/FX/shoot.wav",
	"button": "res://Assets/Sound/FX/button.wav",
	"door": "res://Assets/Sound/FX/door.wav",
	"checkpoint": "res://Assets/Sound/FX/checkpoint.wav",
	"keycard": "res://Assets/Sound/FX/keycard.wav",
	"crumble": "res://Assets/Sound/FX/crumble.wav",
	"zap": "res://Assets/Sound/FX/zap.wav",
	"statue_move": "res://Assets/Sound/FX/statue_move.wav",
	"neck_snap": "res://Assets/Sound/FX/neck_snap.wav",
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
	"document_intel": "res://Assets/Sound/Voice/document_intel.mp3",
	"pa_chime": "res://Assets/Sound/FX/pa_chime.wav",
	"escape": "res://Assets/Sound/FX/escape.wav",
	"level_complete": "res://Assets/Sound/FX/level_complete.wav",
	"ambient": "res://Assets/Sound/Music/level_ambient.mp3",
	"outro": "res://Assets/Sound/Music/outro.mp3",
	"menu": "res://Assets/Sound/Music/menu_theme.mp3",
	"alarm": "res://Assets/Sound/FX/alarm.mp3",
}

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var alarm_player: AudioStreamPlayer
var statue_player: AudioStreamPlayer
var statue_on := false
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
	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(func(): if music_on: music_player.play())
	statue_player = AudioStreamPlayer.new()
	add_child(statue_player)
	alarm_player = AudioStreamPlayer.new()
	add_child(alarm_player)
	# The lockdown track is a one-shot sequence that ends in the detonation,
	# so it is deliberately not relooped.

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

# One shared channel for guard radio chatter, so two guards can never talk over
# each other. Returns false when a line is already playing and interrupt is off,
# which lets the caller know it was not heard. Death cries pass interrupt.
# Tree pause does not stop audio, since this node runs with PROCESS_MODE_ALWAYS.
# The archive calls this so opening it silences music, voice, effects and siren.
func set_paused(paused: bool) -> void:
	music_player.stream_paused = paused
	voice_player.stream_paused = paused
	alarm_player.stream_paused = paused
	statue_player.stream_paused = paused
	for p in pool:
		p.stream_paused = paused

func play_voice(sfx_name: String, volume_db: float = -3.0, interrupt: bool = false) -> bool:
	if not streams.has(sfx_name) or streams[sfx_name] == null:
		return false
	if voice_player.playing and not interrupt:
		return false
	voice_player.stream = streams[sfx_name]
	voice_player.volume_db = volume_db
	voice_player.play()
	return true

func length_of(sfx_name: String) -> float:
	if streams.has(sfx_name) and streams[sfx_name]:
		return streams[sfx_name].get_length()
	return 0.0

func play_music(music_name: String = "ambient", volume_db: float = -8.0, loop: bool = true) -> void:
	music_on = loop
	music_player.stream = streams[music_name]
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	music_on = false
	music_player.stop()

# SCP-173's drag is one continuous loop rather than discrete steps, so it is
# held on its own channel and the volume follows the distance every frame.
# Call this each frame while it moves; call stop_statue when it freezes.
func drive_statue(volume_db: float) -> void:
	statue_player.volume_db = volume_db
	if statue_on:
		return
	statue_on = true
	statue_player.stream = streams["statue_move"]
	statue_player.play()

func stop_statue() -> void:
	if not statue_on:
		return
	statue_on = false
	statue_player.stop()

# The lockdown has to be heard over the level ambience, which runs at -9, so it
# plays loud and ducks the music under it. The track's own range does the rest:
# the klaxons sit well below the detonation, which peaks near full scale.
var music_db_before_alarm: float = 0.0

func start_alarm(volume_db: float = -4.0) -> void:
	if not alarm_active:
		music_db_before_alarm = music_player.volume_db
		music_player.volume_db = music_db_before_alarm - 14.0
	alarm_active = true
	alarm_player.stream = streams["alarm"]
	alarm_player.volume_db = volume_db
	alarm_player.play()

func stop_alarm() -> void:
	if alarm_active:
		music_player.volume_db = music_db_before_alarm
	alarm_active = false
	alarm_player.stop()
