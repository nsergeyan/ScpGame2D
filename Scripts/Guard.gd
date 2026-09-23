extends CharacterBody2D
# Facility guard. Two behaviours
#  PATROL - walks back and forth, charges the player when he sees him. Melee.
#  RIFLE  - stands still, aims (red laser sight), then fires a slow bullet. Walls/crates block his view.
# The player can PUNCH guards (F) or STOMP them by landing on their head.(Like Mario)

enum Kind { PATROL, RIFLE }
enum State { PATROL, ALERT, STUNNED, DEAD }

@export var kind: Kind = Kind.PATROL
@export var max_hp: int = 2
@export var patrol_distance: float = 192.0   # pixels each side of the start position
@export var patrol_speed: float = 70.0
@export var chase_speed: float = 190.0
@export var sight_range: float = 480.0
@export var sight_height: float = 120.0
@export var fire_interval: float = 2.2
@export var telegraph_time: float = 0.5
@export var bullet_speed: float = 380.0
@export var gravity: float = 1800.0
@export var start_facing: int = -1
@export var alert_memory: float = 2.0

const BULLET_SCENE := preload("res://Scenes/Enemies/Bullet.tscn")
const SPOT_LINES := 4
const LOST_LINES := 3
const FIRE_LINES := 2
const DIE_LINES := 2
const VOICE_COOLDOWN_MSEC := 2000

var hp: int = 2
var state: State = State.PATROL
var facing: int = -1
var home: Vector2 = Vector2.ZERO
var alert_timer: float = 0.0
var stun_timer: float = 0.0
var fire_timer: float = 1.0
var aim_timer: float = 0.0
var aim_target: Vector2 = Vector2.ZERO
var hit_flash: float = 0.0
var invuln: float = 0.0
var ledge_ray: RayCast2D
var announced_fire: bool = false   # per guard: he only calls the shot once per engagement
static var _last_voice_msec: int = -999999

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var alert_mark: Label = $AlertMark

func _ready() -> void:
	add_to_group("Enemy")
	add_to_group("resettable")
	hp = max_hp
	home = global_position
	facing = start_facing
	ledge_ray = RayCast2D.new()
	ledge_ray.target_position = Vector2(0, 70)
	ledge_ray.collision_mask = 1
	ledge_ray.position = Vector2(facing * 34, -6)
	add_child(ledge_ray)
	alert_mark.visible = false

func reset_to_start() -> void:
	if state == State.DEAD:
		return
	global_position = home
	velocity = Vector2.ZERO
	state = State.PATROL
	announced_fire = false
	facing = start_facing
	aim_timer = 0.0
	fire_timer = 1.0
	alert_mark.visible = false
	sprite.modulate = Color.WHITE
	queue_redraw()

func can_hurt() -> bool:
	return state != State.DEAD and state != State.STUNNED

# ------------------------------------------------------------------ combat
func take_hit(dmg: int, dir: int) -> void:
	if state == State.DEAD or invuln > 0.0:
		return
	hp -= dmg
	invuln = 0.25
	hit_flash = 0.15
	AudioManager.play("guard_hit")
	if hp <= 0:
		_die(dir)
		return
	state = State.STUNNED
	stun_timer = 0.45
	aim_timer = 0.0
	velocity = Vector2(dir * 280.0, -220.0)
	queue_redraw()

func _die(dir: int) -> void:
	state = State.DEAD
	remove_from_group("Enemy")
	remove_from_group("resettable")
	set_deferred("collision_layer", 0)
	alert_mark.visible = false
	AudioManager.play("guard_down")
	_say("guard_die", DIE_LINES)
	aim_timer = 0.0
	queue_redraw()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "rotation", dir * 1.4, 0.4)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tw.tween_property(sprite, "position:y", -16.0, 0.4)
	await tw.finished
	queue_free()

# ------------------------------------------------------------------ AI
func _player_ok() -> bool:
	return is_instance_valid(GameManager.player) and not GameManager.player.dead

func _can_see(p: Node2D) -> bool:
	var dx: float = p.global_position.x - global_position.x
	var dy: float = p.global_position.y - global_position.y
	if absf(dx) > sight_range or absf(dy) > sight_height:
		return false
	if kind == Kind.PATROL and signf(dx) != float(facing) and absf(dx) > 90.0:
		return false   # patrol guards only look forward
	var q := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -50), p.global_position + Vector2(0, -40), 1)
	q.exclude = [p.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()

func _face(dir: int) -> void:
	if dir != 0 and dir != facing:
		facing = dir
		ledge_ray.position.x = facing * 34

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	hit_flash = maxf(hit_flash - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)
	if not is_on_floor():
		velocity.y += gravity * delta

	var p: Node2D = GameManager.player if _player_ok() else null
	match state:
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			stun_timer -= delta
			if stun_timer <= 0.0:
				state = State.ALERT if kind == Kind.PATROL else State.PATROL
				alert_timer = alert_memory
		State.PATROL:
			_do_patrol(p)
		State.ALERT:
			_do_alert(p, delta)
	move_and_slide()
	_update_visuals()

# Radio chatter. The cooldown is static, shared by every guard, so they never
# talk over each other no matter how many see the player at once.
func _say(prefix: String, count: int) -> bool:
	if GameManager.announcing or GameManager.voice_busy:
		return false   # never talk over a facility announcement
	var now := Time.get_ticks_msec()
	if now - _last_voice_msec < VOICE_COOLDOWN_MSEC:
		return false
	_last_voice_msec = now
	AudioManager.play("%s_%d" % [prefix, randi() % count + 1], -3.0)
	return true

func _do_patrol(p: Node2D) -> void:
	if kind == Kind.RIFLE:
		velocity.x = 0.0
		if p and _can_see(p):
			state = State.ALERT
			fire_timer = 0.6
			_say("guard_spot", SPOT_LINES)
		return
	if patrol_distance <= 0.0:
		velocity.x = 0.0
	else:
		var off := global_position.x - home.x
		if (off > patrol_distance and facing > 0) or (off < -patrol_distance and facing < 0) \
				or is_on_wall() or not ledge_ray.is_colliding():
			_face(-facing)
		velocity.x = facing * patrol_speed
	if p and _can_see(p):
		state = State.ALERT
		alert_timer = alert_memory
		_say("guard_spot", SPOT_LINES)

func _do_alert(p: Node2D, delta: float) -> void:
	if kind == Kind.RIFLE:
		velocity.x = 0.0
		if p == null or not _can_see(p):
			aim_timer = 0.0
			state = State.PATROL
			announced_fire = false
			_say("guard_lost", LOST_LINES)
			queue_redraw()
			return
		_face(1 if p.global_position.x > global_position.x else -1)
		if aim_timer > 0.0:
			aim_target = p.global_position + Vector2(0, -42)   # keeps tracking while aiming
			aim_timer -= delta
			queue_redraw()
			if aim_timer <= 0.0:
				_fire()
		else:
			fire_timer -= delta
			if fire_timer <= 0.0:
				aim_timer = telegraph_time
				aim_target = p.global_position + Vector2(0, -42)
				if not announced_fire and _say("guard_fire", FIRE_LINES):
					announced_fire = true
		return
	# PATROL guard: charge
	if p and _can_see(p):
		alert_timer = alert_memory
	else:
		alert_timer -= delta
	if p == null or alert_timer <= 0.0:
		state = State.PATROL
		_say("guard_lost", LOST_LINES)
		return
	_face(1 if p.global_position.x > global_position.x else -1)
	if not ledge_ray.is_colliding():
		velocity.x = 0.0      # stops at ledges instead of running off
	else:
		velocity.x = facing * chase_speed

func _fire() -> void:
	AudioManager.play("shoot", -4.0)
	var muzzle := global_position + Vector2(facing * 44, -46)
	var b := BULLET_SCENE.instantiate()
	b.global_position = muzzle
	b.velocity = (aim_target - muzzle).normalized() * bullet_speed
	get_parent().add_child(b)
	fire_timer = fire_interval
	aim_timer = 0.0
	queue_redraw()

# ------------------------------------------------------------------ visuals
func _update_visuals() -> void:
	sprite.flip_h = facing < 0
	var anim := "idle"
	if state == State.STUNNED:
		anim = "hurt"
	elif absf(velocity.x) > 20.0:
		anim = "walk"
	if sprite.animation != anim:
		sprite.play(anim)
	alert_mark.visible = state == State.ALERT
	if hit_flash > 0.0:
		sprite.modulate = Color(3, 3, 3)
	elif aim_timer > 0.0 and int(Time.get_ticks_msec() / 70.0) % 2 == 0:
		sprite.modulate = Color(1.6, 0.6, 0.6)
	else:
		sprite.modulate = Color.WHITE

func _draw() -> void:
	# red laser sight while aiming (telegraphs the shot)
	if aim_timer > 0.0:
		var from := Vector2(facing * 44, -46)
		draw_line(from, to_local(aim_target), Color(1, 0.1, 0.1, 0.65), 2.0)
