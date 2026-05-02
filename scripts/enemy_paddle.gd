extends Area2D

const SPEED := 250.0
const SCREEN_HEIGHT := 450.0
const PADDLE_HALF_HEIGHT := 50.0
const FOLLOW_DEAD_ZONE := 8.0

var ball: Node2D

func _ready():
	ball = get_tree().current_scene.get_node("Ball")

func _physics_process(delta):
	if ball == null:
		return

	var difference: float = ball.position.y - position.y

	if abs(difference) > FOLLOW_DEAD_ZONE:
		position.y = move_toward(
			position.y,
			ball.position.y,
			SPEED * delta
		)

	position.y = clamp(
		position.y,
		PADDLE_HALF_HEIGHT,
		SCREEN_HEIGHT - PADDLE_HALF_HEIGHT
	)
