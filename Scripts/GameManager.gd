# Autoload: global run state (score, deaths, timer, keycard, alarm, on-screen messages).
extends Node

signal hp_changed(hp: int, max_hp: int)
signal message(text: String, duration: float)
signal keycard_changed(has: bool)
signal alarm_changed(on: bool)

var player = null            # set by the player in _ready()
var score: int = 0          
var total_documents: int = 0 # how many exist in the level, counted at load
var collected_entries: Array[int] = [] # indices into ScpArchive.ENTRIES
var deaths: int = 0
var run_time: float = 0.0
var timer_running: bool = false
var announcing: bool = false 
var voice_busy: bool = false # a PA announcement is playing: guards stay quiet
var message_until_msec: int = 0 # an important message holds the box until this time
var hp: int = 3
var max_hp: int = 3

# Taking the keycard starts a lockdown countdown. Reaching the gate stops it,
# dying resets it with the keycard, and running it out ends the run.
const ESCAPE_SECONDS := 114.5   # the detonation in alarm.mp3 lands here
const END_SCENE := "res://Scenes/UI/EndScreen.tscn"

var escape_left: float = 0.0
var escape_running: bool = false
var failed: bool = false

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
	if escape_running:
		escape_left = maxf(escape_left - delta, 0.0)
		if escape_left <= 0.0:
			fail_escape()

func reset_run() -> void:
	score = 0
	deaths = 0
	run_time = 0.0
	timer_running = false
	announcing = false
	voice_busy = false
	message_until_msec = 0
	collected_entries.clear()
	has_keycard = false
	alarm_on = false
	escape_left = 0.0
	escape_running = false
	failed = false
	AudioManager.stop_alarm()

# Dying rewinds the keycard, but deliberately NOT the lockdown. The countdown
# the breach started keeps running across deaths, siren and all, so dying costs
# real time. Only reset_run() clears it, for a fresh attempt from the title.
func clear_keycard() -> void:
	has_keycard = false

func start_escape_timer() -> void:
	escape_left = ESCAPE_SECONDS
	escape_running = true

func stop_escape_timer() -> void:
	escape_running = false

# The lockdown ran out. No checkpoint saves this one.
func fail_escape() -> void:
	if failed:
		return
	failed = true
	escape_running = false
	timer_running = false
	alarm_on = false
	# the detonation is still playing: it rings out over the fade, and
	# EndScreen stops it when the scene lands
	SceneTransition.load_scene(load(END_SCENE))

func add_score() -> void:
	score += 1

func collect_entry(i: int) -> void:
	if i >= 0 and not collected_entries.has(i):
		collected_entries.append(i)

func set_hp(new_hp: int, new_max: int) -> void:
	hp = new_hp
	max_hp = new_max
	hp_changed.emit(hp, max_hp)

# Everything shares one message box, so a hint walked into mid-announcement
# used to wipe the subtitle off the screen. Important messages (announcements,
# story beats) reserve the box; ordinary ones are dropped while it is held.
# Returns whether the message was actually shown.
func show_message(text: String, duration: float = 3.0, important: bool = false) -> bool:
	var now := Time.get_ticks_msec()
	if not important and now < message_until_msec:
		return false
	if important:
		message_until_msec = now + int(duration * 1000.0)
	message.emit(text, duration)
	return true

# Plays a voice clip and splits its subtitle across lines, each shown for a
# share of the audio proportional to its length. Kept here rather than on the
# caller because the caller may be freed while this is still running.
func announce(sfx: String, lines: Array[String]) -> void:
	voice_busy = true
	AudioManager.play(sfx, -2.0)
	var total: float = AudioManager.length_of(sfx)
	var chars := 0
	for l in lines:
		chars += l.length()
	for l in lines:
		var dur: float = total * float(l.length()) / maxf(chars, 1.0)
		show_message(l, dur + 0.3, true)
		await get_tree().create_timer(dur, false).timeout   # false: pauses with the tree
	voice_busy = false

func format_escape() -> String:
	var t: int = int(ceilf(escape_left))
	return "%d:%02d" % [floori(t / 60.0), t % 60]

func format_time() -> String:
	var t := int(run_time)
	return "%d:%02d" % [floori(t / 60.0), t % 60]

# Kept from the starter kit
func load_next_level(next_scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(next_scene)
