extends Area2D

const SPEED := 300.0
const HORIZONTAL_SPEED := 140.0

const SCREEN_HEIGHT := 450.0
const PADDLE_HALF_HEIGHT := 50.0

const MIN_X := 420.0
const MAX_X := 780.0
const HOME_X := 750.0
const ATTACK_X := 420.0
const DEFENSE_X := 770.0

const FOLLOW_DEAD_ZONE := 8.0

var ball: Node2D

var paddle_velocity := Vector2.ZERO
var previous_position := Vector2.ZERO

var main: Node

func _ready():
	ball = get_tree().current_scene.get_node("Ball")
	main = get_tree().current_scene
	previous_position = position

func _process(delta):
	if main.is_paused:
		paddle_velocity = Vector2.ZERO
		previous_position = position
		return
	
	if ball == null:
		return

	move_vertically(delta)
	move_horizontally(delta)

	position.x = clamp(position.x, MIN_X, MAX_X)
	position.y = clamp(
		position.y,
		PADDLE_HALF_HEIGHT,
		SCREEN_HEIGHT - PADDLE_HALF_HEIGHT
	)

func move_vertically(delta):
	var difference_y: float = ball.position.y - position.y

	if abs(difference_y) > FOLLOW_DEAD_ZONE:
		position.y = move_toward(
			position.y,
			ball.position.y,
			SPEED * delta
		)

func move_horizontally(delta):
	var target_x := HOME_X

	var ball_is_coming_toward_ai: bool = ball.direction.x > 0.0
	var ball_vertical_speed: float = abs(ball.direction.y * ball.speed)

	if ball_is_coming_toward_ai:
		if ball_vertical_speed > 160.0:
			target_x = DEFENSE_X
		else:
			target_x = ATTACK_X
	else:
		target_x = HOME_X

	position.x = move_toward(
		position.x,
		target_x,
		HORIZONTAL_SPEED * delta
	)
	
	paddle_velocity = (position - previous_position) / delta
	previous_position = position
