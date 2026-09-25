extends CharacterBody2D
#double jump ON by default, coyote time,
# jump buffering, variable jump height (release SPACE early = short hop),
# heavier fall gravity, acceleration/friction, plus a PUNCH attack and 3 HP.

signal died

@export_group("Movement")
@export var move_speed: float = 340.0
@export var ground_accel: float = 2800.0
@export var ground_friction: float = 3400.0
@export var air_accel: float = 2100.0
@export var jump_velocity: float = 690.0
@export var gravity: float = 1850.0
@export var fall_gravity_multiplier: float = 1.3
@export var max_fall_speed: float = 950.0
@export var jump_cut_multiplier: float = 0.5   # <1 = shorter hop when SPACE released early
@export var coyote_time: float = 0.10           # can still jump a moment after leaving a ledge
@export var jump_buffer_time: float = 0.12      # jump pressed slightly before landing still counts
@export var max_jumps: int = 2                  # 1 = single jump, 2 = double jump

@export_group("Combat")
@export var max_hp: int = 3
@export var punch_duration: float = 0.22
@export var punch_cooldown: float = 0.38
@export var invincible_time: float = 1.2
@export var stomp_bounce: float = 520.0

const HURT_SOUNDS := 2
const PUNCH_SOUNDS := 2

var facing: int = 1
var movement_enabled: bool = true
var dead: bool = false
var hp: int = 3
var spawn_position: Vector2 = Vector2.ZERO
var jumps_left: int = 2
var coyote: float = 0.0
var jump_buffer: float = 0.0
var invincible: float = 0.0
var stun: float = 0.0
var punch_timer: float = 0.0
var punch_cd: float = 0.0
var punch_hit_done: bool = false
var shake: float = 0.0
var look_x: float = 0.0
var was_on_floor: bool = false
var fall_speed: float = 0.0   # downward speed carried into the landing
var squash_tween: Tween

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var particle_trails: CPUParticles2D = $ParticleTrails
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var hurtbox: Area2D = $Hurtbox
@onready var punch_area: Area2D = $PunchArea
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("Player")
	spawn_position = global_position
	hp = max_hp
	GameManager.player = self
	GameManager.set_hp(hp, max_hp)

func _physics_process(delta: float) -> void:
	if dead:
		return
	invincible = maxf(invincible - delta, 0.0)
	stun = maxf(stun - delta, 0.0)
	punch_cd = maxf(punch_cd - delta, 0.0)
	var on_floor := is_on_floor()

	# gravity (falls faster than it rises)
	if not on_floor:
		var g := gravity * (fall_gravity_multiplier if velocity.y > 0.0 else 1.0)
		velocity.y = minf(velocity.y + g * delta, max_fall_speed)
		fall_speed = velocity.y   # move_and_slide zeroes this on contact, so remember it

	# coyote time + refill jumps on the ground
	if on_floor:
		coyote = coyote_time
		jumps_left = max_jumps
		if not was_on_floor:
			_squash(Vector2(1.25, 0.8))
			_land()
	else:
		coyote -= delta
		if coyote <= 0.0 and jumps_left == max_jumps:
			jumps_left = max_jumps - 1   # walked off a ledge: the first jump is gone
	was_on_floor = on_floor

	# input
	var axis := 0.0
	var can_act := movement_enabled and stun <= 0.0
	var jump_pressed := false
	if can_act:
		axis = Input.get_axis("Left", "Right")
		jump_pressed = Input.is_action_just_pressed("Jump")
		if jump_pressed:
			jump_buffer = jump_buffer_time
		if Input.is_action_just_released("Jump") and velocity.y < 0.0:
			velocity.y *= jump_cut_multiplier
		if Input.is_action_just_pressed("Punch") and punch_cd <= 0.0:
			_start_punch()
	jump_buffer -= delta

	if can_act:
		if jump_buffer > 0.0 and coyote > 0.0:          # ground / coyote jump
			_do_jump(1.0)
			jumps_left = max_jumps - 1
			coyote = 0.0
			jump_buffer = 0.0
		elif jump_pressed and jumps_left > 0:            # air jump (double jump)
			_do_jump(0.94)
			jumps_left -= 1
			jump_buffer = 0.0

	# horizontal movement
	if axis != 0.0:
		facing = 1 if axis > 0.0 else -1
		var a := ground_accel if on_floor else air_accel
		velocity.x = move_toward(velocity.x, axis * move_speed, a * delta)
	else:
		var f := ground_friction if on_floor else air_accel * 0.5
		velocity.x = move_toward(velocity.x, 0.0, f * delta)

	move_and_slide()
	if is_on_ceiling():
		velocity.y = maxf(velocity.y, 0.0)

	_update_punch(delta)
	_check_hurtbox()
	if global_position.y > 900.0:   # fell out of the world
		die()

func _do_jump(power: float) -> void:
	velocity.y = -jump_velocity * power
	AudioManager.play("jump", -3.0, 1.0 if power >= 1.0 else 1.25)
	_squash(Vector2(0.75, 1.3))

# Landing volume tracks how far you fell, so stepping off a kerb is not the
# same sound as dropping off the ceiling, and tiny hops stay silent.
func _land() -> void:
	if fall_speed < 220.0:
		return
	var t := clampf((fall_speed - 220.0) / (max_fall_speed - 220.0), 0.0, 1.0)
	AudioManager.play("land", lerpf(-13.0, -2.0, t), randf_range(0.95, 1.06))

func _squash(target: Vector2) -> void:
	if dead:
		return
	if squash_tween and squash_tween.is_valid():
		squash_tween.kill()
	sprite.scale = target
	squash_tween = create_tween()
	squash_tween.tween_property(sprite, "scale", Vector2.ONE, 0.16)

# ------------------------------------------------------------------ combat
func _start_punch() -> void:
	punch_timer = punch_duration
	punch_cd = punch_cooldown
	punch_hit_done = false
	AudioManager.play("punch_%d" % (randi() % PUNCH_SOUNDS + 1), -4.0, randf_range(0.95, 1.1))

func _update_punch(delta: float) -> void:
	if punch_timer <= 0.0:
		return
	punch_timer -= delta
	punch_area.position.x = absf(punch_area.position.x) * facing
	if not punch_hit_done and punch_timer < punch_duration - 0.05:
		punch_hit_done = true
		for b in punch_area.get_overlapping_bodies():
			if b.has_method("take_hit"):
				b.take_hit(1, facing)
				shake = maxf(shake, 5.0)

func _check_hurtbox() -> void:
	if dead:
		return
	for b in hurtbox.get_overlapping_bodies():
		if b.is_in_group("Traps"):
			die()
			return
		if b.is_in_group("SCP"):
			if b.has_method("is_deadly") and b.is_deadly():
				die("neck_snap")
				return
		elif b.is_in_group("Enemy") and b.has_method("can_hurt") and b.can_hurt():
			var stomp := velocity.y > 60.0 and global_position.y < b.global_position.y - 42.0
			if stomp:
				b.take_hit(2, facing)
				velocity.y = -stomp_bounce
				jumps_left = maxi(jumps_left, 1)
				AudioManager.play("guard_hit")
			else:
				hurt(1, b.global_position.x)

func hurt(dmg: int, from_x: float) -> void:
	if dead or invincible > 0.0:
		return
	hp -= dmg
	GameManager.set_hp(hp, max_hp)
	AudioManager.play("hurt_%d" % (randi() % HURT_SOUNDS + 1))
	shake = 8.0
	if hp <= 0:
		die()
		return
	invincible = invincible_time
	stun = 0.22
	var dir := signf(global_position.x - from_x)
	if dir == 0.0:
		dir = -float(facing)
	velocity = Vector2(dir * 380.0, -360.0)

func heal_full() -> void:
	hp = max_hp
	GameManager.set_hp(hp, max_hp)

func die(death_sound: String = "") -> void:
	if dead:
		return
	dead = true
	GameManager.deaths += 1
	velocity = Vector2.ZERO
	if death_sound != "":
		AudioManager.play(death_sound)      # SCP-173 snaps your neck; acid and lasers do not
	else:
		AudioManager.play("hurt_%d" % (randi() % HURT_SOUNDS + 1))
	death_particles.restart()
	death_particles.emitting = true
	shake = 10.0
	get_tree().call_group("bullets", "queue_free")
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2.ZERO, 0.18)
	await tw.finished
	global_position = spawn_position
	hp = max_hp
	invincible = 0.0
	stun = 0.0
	punch_timer = 0.0
	GameManager.set_hp(hp, max_hp)
	get_tree().call_group("resettable", "reset_to_start")
	await get_tree().create_timer(0.45).timeout
	velocity = Vector2.ZERO
	dead = false
	died.emit()
	var tw2 := create_tween()
	tw2.tween_property(sprite, "scale", Vector2.ONE, 0.15)

# ------------------------------------------------------------------ visuals
func _process(delta: float) -> void:
	if dead:
		return
	var anim := "Idle"
	if punch_timer > 0.0:
		anim = "Punch"
	elif not is_on_floor():
		anim = "Jump"
	elif absf(velocity.x) > 30.0:
		anim = "Walk"
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = facing < 0
	particle_trails.emitting = is_on_floor() and absf(velocity.x) > 30.0
	# blink while invincible
	if invincible > 0.0 and int(Time.get_ticks_msec() / 80.0) % 2 == 0:
		sprite.modulate.a = 0.35
	else:
		sprite.modulate.a = 1.0
	# camera look-ahead + shake
	look_x = lerpf(look_x, facing * 110.0, 3.0 * delta)
	shake = move_toward(shake, 0.0, 40.0 * delta)
	camera.offset = Vector2(look_x, 0.0) + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
