extends Area2D

const SPEED := 350.0
const SCREEN_HEIGHT := 450.0
const PADDLE_HALF_HEIGHT := 50.0

func _process(delta):
	var direction := 0.0

	if Input.is_action_pressed("move_up"):
		direction -= 1.0

	if Input.is_action_pressed("move_down"):
		direction += 1.0

	position.y += direction * SPEED * delta

	position.y = clamp(
		position.y,
		PADDLE_HALF_HEIGHT,
		SCREEN_HEIGHT - PADDLE_HALF_HEIGHT
	)
