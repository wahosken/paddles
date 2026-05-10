extends Area2D

const SPEED := 300.0
const HORIZONTAL_SPEED := 140.0

const SCREEN_HEIGHT := 450.0
const PADDLE_HALF_HEIGHT := 50.0

const MIN_X := 420.0
const MAX_X := 780.0
const HOME_X := 750.0
const DEFAULT_POSITION := Vector2(755.0, 225.0)
const NORMAL_ATTACK_X := 610.0
const AGGRESSIVE_ATTACK_X := 420.0
const DEFENSE_X := 770.0

const FOLLOW_DEAD_ZONE := 8.0
const VERTICAL_DANGER_SPEED := 160.0

const AGGRESSIVE_MIN_INTERVAL := 2
const AGGRESSIVE_MAX_INTERVAL := 5

var ball: Node2D
var main: Node

var paddle_velocity := Vector2.ZERO
var previous_position := Vector2.ZERO

var was_ball_coming_toward_ai := false
var is_aggressive_this_shot := false
var shots_until_aggressive := 3

func _ready():
	ball = get_tree().current_scene.get_node("Ball")
	main = get_tree().current_scene
	previous_position = position
	choose_next_aggressive_interval()

func _process(delta):
	if main.is_paused or not main.can_move_paddles:
		paddle_velocity = Vector2.ZERO
		previous_position = position
		return
	
	if ball == null:
		return

	update_aggression_state()
	move_vertically(delta)
	move_horizontally(delta)

	position.x = clamp(position.x, MIN_X, MAX_X)
	position.y = clamp(
		position.y,
		PADDLE_HALF_HEIGHT,
		SCREEN_HEIGHT - PADDLE_HALF_HEIGHT
	)

	paddle_velocity = (position - previous_position) / delta
	previous_position = position

func update_aggression_state():
	var ball_is_coming_toward_ai: bool = ball.direction.x > 0.0

	# This triggers once when the ball starts coming toward the enemy.
	if ball_is_coming_toward_ai and not was_ball_coming_toward_ai:
		shots_until_aggressive -= 1

		if shots_until_aggressive <= 0:
			is_aggressive_this_shot = true
			choose_next_aggressive_interval()
		else:
			is_aggressive_this_shot = false

	# Once the ball is moving away, reset this shot's aggression.
	if not ball_is_coming_toward_ai:
		is_aggressive_this_shot = false

	was_ball_coming_toward_ai = ball_is_coming_toward_ai

func choose_next_aggressive_interval():
	shots_until_aggressive = randi_range(
		AGGRESSIVE_MIN_INTERVAL,
		AGGRESSIVE_MAX_INTERVAL
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
		if is_aggressive_this_shot:
			target_x = AGGRESSIVE_ATTACK_X
		elif ball_vertical_speed > VERTICAL_DANGER_SPEED:
			target_x = DEFENSE_X
		else:
			target_x = NORMAL_ATTACK_X
	else:
		target_x = HOME_X

	position.x = move_toward(
		position.x,
		target_x,
		HORIZONTAL_SPEED * delta
	)
	
func reset_position():
	position = DEFAULT_POSITION
	paddle_velocity = Vector2.ZERO
	previous_position = position
	was_ball_coming_toward_ai = false
	is_aggressive_this_shot = false
	choose_next_aggressive_interval()
