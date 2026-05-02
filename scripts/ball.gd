extends Area2D

const START_SPEED := 300.0
const SPEED_INCREASE := 25.0
const MAX_SPEED := 600.0

const SCREEN_WIDTH := 800.0
const SCREEN_HEIGHT := 450.0

const BALL_RADIUS := 10.0
const PADDLE_HALF_WIDTH := 10.0
const PADDLE_HALF_HEIGHT := 50.0

var speed := START_SPEED
var direction := Vector2.ZERO
var is_active := false

signal player_scored
signal enemy_scored
signal paddle_hit

func _ready():
	reset_ball()

func _process(delta):
	if not is_active:
		return

	position += direction * speed * delta

	check_wall_bounce()
	check_paddle_hit()
	check_scoring()

func check_wall_bounce():
	if position.y <= BALL_RADIUS:
		position.y = BALL_RADIUS
		direction.y = abs(direction.y)

	if position.y >= SCREEN_HEIGHT - BALL_RADIUS:
		position.y = SCREEN_HEIGHT - BALL_RADIUS
		direction.y = -abs(direction.y)

func check_paddle_hit():
	var paddles := get_tree().get_nodes_in_group("paddles")

	for paddle in paddles:
		if not is_touching_paddle(paddle):
			continue

		# Only bounce off the player paddle if the ball is moving left.
		if paddle.name == "PlayerPaddle" and direction.x < 0.0:
			bounce_from_paddle(paddle)
			return

		# Only bounce off the enemy paddle if the ball is moving right.
		if paddle.name == "EnemyPaddle" and direction.x > 0.0:
			bounce_from_paddle(paddle)
			return

func is_touching_paddle(paddle: Node2D) -> bool:
	var x_distance: float = abs(position.x - paddle.position.x)
	var y_distance: float = abs(position.y - paddle.position.y)

	var touching_x: bool = x_distance <= BALL_RADIUS + PADDLE_HALF_WIDTH
	var touching_y: bool = y_distance <= BALL_RADIUS + PADDLE_HALF_HEIGHT

	return touching_x and touching_y

func bounce_from_paddle(paddle: Node2D):
	var hit_offset: float = position.y - paddle.position.y
	var normalized_offset: float = clamp(hit_offset / PADDLE_HALF_HEIGHT, -1.0, 1.0)

	if paddle.name == "PlayerPaddle":
		position.x = paddle.position.x + PADDLE_HALF_WIDTH + BALL_RADIUS + 1.0
		direction.x = 1.0

	if paddle.name == "EnemyPaddle":
		position.x = paddle.position.x - PADDLE_HALF_WIDTH - BALL_RADIUS - 1.0
		direction.x = -1.0

	direction.y = normalized_offset
	direction = direction.normalized()

	speed = min(speed + SPEED_INCREASE, MAX_SPEED)

	paddle_hit.emit()

func check_scoring():
	if position.x < -BALL_RADIUS:
		enemy_scored.emit()
		reset_ball()

	if position.x > SCREEN_WIDTH + BALL_RADIUS:
		player_scored.emit()
		reset_ball()

func start_ball():
	is_active = true

	var x_direction: float = -1.0 if randf() < 0.5 else 1.0
	var y_direction: float = randf_range(-0.6, 0.6)

	direction = Vector2(x_direction, y_direction).normalized()

func stop_ball():
	is_active = false
	direction = Vector2.ZERO

func reset_ball():
	position = Vector2(SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0)
	speed = START_SPEED
	stop_ball()
