# Autoload: global run state (score, deaths, timer, keycard, alarm, on-screen messages).
extends Node

signal hp_changed(hp: int, max_hp: int)
signal message(text: String, duration: float)
signal keycard_changed(has: bool)
signal alarm_changed(on: bool)

var player = null            # set by the player in _ready()
var score: int = 0          
var total_documents: int = 0 # how many exist in the level, counted at load
var deaths: int = 0
var run_time: float = 0.0
var timer_running: bool = false
var announcing: bool = false 
var hp: int = 3
var max_hp: int = 3

var has_keycard: bool = false:
	set(v):
		has_keycard = v
		keycard_changed.emit(v)

var alarm_on: bool = false:
	set(v):
		alarm_on = v
		alarm_changed.emit(v)

func _process(delta: float) -> void:
	if timer_running:
		run_time += delta

func reset_run() -> void:
	score = 0
	deaths = 0
	run_time = 0.0
	timer_running = false
	announcing = false
	has_keycard = false
	alarm_on = false
	AudioManager.stop_alarm()

func add_score() -> void:
	score += 1

func set_hp(new_hp: int, new_max: int) -> void:
	hp = new_hp
	max_hp = new_max
	hp_changed.emit(hp, max_hp)

func show_message(text: String, duration: float = 3.0) -> void:
	message.emit(text, duration)

func format_time() -> String:
	var t := int(run_time)
	return "%d:%02d" % [floori(t / 60.0), t % 60]

# Kept from the starter kit
func load_next_level(next_scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(next_scene)
