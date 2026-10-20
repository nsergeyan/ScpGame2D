extends Area2D
# Slow bullet fired by rifle guards. Hurts the player, disappears on walls/crates.

var velocity: Vector2 = Vector2.ZERO
var life: float = 5.0

func _ready() -> void:
	add_to_group("bullets")
	body_entered.connect(_on_body_entered)
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.hurt(1, global_position.x - signf(velocity.x) * 10.0)
	queue_free()
