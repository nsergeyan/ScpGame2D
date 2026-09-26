extends CharacterBody2D
# SCP-173 style statue.
#  - It is FROZEN while the player is facing it.
#  - The moment the player looks away (faces the other direction) it chases.
#  - Touching it = death. It cannot be hurt; it falls into pits and is gone.

@export var chase_speed: float = 215.0
@export var blink_speed: float = 900.0   # while the player's eyes are shut
@export var start_active: bool = false
@export var gravity: float = 1800.0
@export var watch_distance: float = 1100.0
@export var reset_freeze: float = 0.6   # held still and harmless right after a respawn

var active: bool = false
var gone: bool = false
var reset_timer: float = 0.0
var home: Vector2 = Vector2.ZERO
var stone_tween: Tween

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("SCP")
	add_to_group("resettable")
	home = global_position
	active = start_active

func activate() -> void:
	if active or gone:
		return
	active = true
	GameManager.show_message("SCP-173 is awake! It moves when you look away. Keep it in sight!", 4.0, true)

func reset_to_start() -> void:
	global_position = home
	velocity = Vector2.ZERO
	gone = false
	reset_timer = reset_freeze
	visible = true
	shape.set_deferred("disabled", false)
	active = start_active or GameManager.has_keycard   # chase again if the player already holds the keycard
	sprite.frame = 0

func is_deadly() -> bool:
	return not gone and reset_timer <= 0.0

func take_hit(_dmg: int, _dir: int) -> void:
	# Punching stone hurts your hand. Avoid it instead!
	AudioManager.play("guard_hit", -6.0, 0.6)

func _is_watched(p: Node2D) -> bool:
	var dx: float = global_position.x - p.global_position.x
	return float(p.facing) == signf(dx) and absf(dx) < watch_distance

func _physics_process(delta: float) -> void:
	if gone:
		AudioManager.stop_statue()
		return
	var p = GameManager.player
	# The clock only runs once the player is back in control, otherwise the
	# freeze is spent during the death animation.
	if not (is_instance_valid(p) and p.dead):
		reset_timer = maxf(reset_timer - delta, 0.0)
	if not is_on_floor():
		velocity.y += gravity * delta
	var moving := false
	if active and is_instance_valid(p) and not p.dead and reset_timer <= 0.0:
		if BlinkUI.eyes_shut:
			# eyes shut: it does not care where you were looking, and it lunges
			velocity.x = signf(p.global_position.x - global_position.x) * blink_speed
			sprite.frame = 1
			moving = true
		elif _is_watched(p):
			velocity.x = 0.0
			sprite.frame = 0
		else:
			velocity.x = signf(p.global_position.x - global_position.x) * chase_speed
			sprite.frame = 1
			moving = true
	else:
		velocity.x = 0.0
	move_and_slide()
	if moving:
		var d := 0.0
		if is_instance_valid(p):
			d = absf(p.global_position.x - global_position.x)
		AudioManager.drive_statue(clampf(-5.0 - d / 90.0, -30.0, -5.0))
	else:
		AudioManager.stop_statue()   # silence the instant the player looks at it
	if global_position.y > 860.0:
		gone = true
		AudioManager.stop_statue()
		visible = false
		shape.set_deferred("disabled", true)
		GameManager.show_message("SCP-173 fell into the acid... Keep moving!", 3.0, true)
		AudioManager.stop_alarm()   # siren stops, red lights keep pulsing until you escape
