extends Area2D

const SPEED := 400.0

const SCREEN_HEIGHT := 450.0
const PADDLE_HALF_HEIGHT := 50.0

const MIN_X := 20.0
const MAX_X := 380.0

const DEFAULT_POSITION := Vector2(45.0, 224.0)


const AI_HORIZONTAL_SPEED := 140.0
const AI_VERTICAL_SPEED := 300.0

const AI_HOME_X := 45.0
const AI_NORMAL_ATTACK_X := 190.0
const AI_AGGRESSIVE_ATTACK_X := 380.0
const AI_DEFENSE_X := 25.0

const AI_FOLLOW_DEAD_ZONE := 8.0
const AI_VERTICAL_DANGER_SPEED := 160.0

const AGGRESSIVE_MIN_INTERVAL := 2
const AGGRESSIVE_MAX_INTERVAL := 5

var was_ball_coming_toward_ai := false
var is_aggressive_this_shot := false
var shots_until_aggressive := 3


var move_direction := Vector2.ZERO
var paddle_velocity := Vector2.ZERO
var previous_position := Vector2.ZERO

var main: Node
var joystick: Node

func _ready():
	main = get_tree().current_scene
	joystick = main.get_node("UI/UIHide/TouchControls/VirtualJoystick")
	previous_position = position
	choose_next_aggressive_interval()

func _process(delta):
	if main.is_paused or not main.can_move_paddles:
		paddle_velocity = Vector2.ZERO
		previous_position = position
		return

	if main.play_mode == main.PlayMode.AUTOPLAY:
		move_as_ai(delta)
		return
	
	move_direction = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		move_direction.y -= 1.0

	if Input.is_action_pressed("move_down"):
		move_direction.y += 1.0

	if Input.is_action_pressed("move_left"):
		move_direction.x -= 1.0

	if Input.is_action_pressed("move_right"):
		move_direction.x += 1.0

	if move_direction == Vector2.ZERO:
		var using_joystick: bool = (
			main.control_mode == main.ControlMode.JOYSTICK_LEFT
			or main.control_mode == main.ControlMode.JOYSTICK_RIGHT
		)

		if using_joystick:
			if joystick != null:
				move_direction = joystick.get_input_vector()

	if move_direction.length() > 1.0:
		move_direction = move_direction.normalized()

	position += move_direction * SPEED * delta

	position.x = clamp(position.x, MIN_X, MAX_X)
	position.y = clamp(position.y, PADDLE_HALF_HEIGHT, SCREEN_HEIGHT - PADDLE_HALF_HEIGHT)
	
	paddle_velocity = (position - previous_position) / delta
	previous_position = position

func reset_position():
	position = DEFAULT_POSITION
	paddle_velocity = Vector2.ZERO
	previous_position = position
	was_ball_coming_toward_ai = false
	is_aggressive_this_shot = false
	choose_next_aggressive_interval()
	
func move_as_ai(delta):
	var ball = main.ball
	
	if ball == null:
		return

	update_aggression_state()
	move_ai_vertically(delta)
	move_ai_horizontally(delta)

	position.x = clamp(position.x, MIN_X, MAX_X)
	position.y = clamp(
		position.y,
		PADDLE_HALF_HEIGHT,
		SCREEN_HEIGHT - PADDLE_HALF_HEIGHT
	)

	paddle_velocity = (position - previous_position) / delta
	previous_position = position

func update_aggression_state():
	var ball_is_coming_toward_ai: bool = main.ball.direction.x < 0.0

	if ball_is_coming_toward_ai and not was_ball_coming_toward_ai:
		shots_until_aggressive -= 1

		if shots_until_aggressive <= 0:
			is_aggressive_this_shot = true
			choose_next_aggressive_interval()
		else:
			is_aggressive_this_shot = false

	if not ball_is_coming_toward_ai:
		is_aggressive_this_shot = false

	was_ball_coming_toward_ai = ball_is_coming_toward_ai

func choose_next_aggressive_interval():
	shots_until_aggressive = randi_range(
		AGGRESSIVE_MIN_INTERVAL,
		AGGRESSIVE_MAX_INTERVAL
	)

func move_ai_vertically(delta):
	var difference_y: float = main.ball.position.y - position.y

	if abs(difference_y) > AI_FOLLOW_DEAD_ZONE:
		position.y = move_toward(
			position.y,
			main.ball.position.y,
			AI_VERTICAL_SPEED * delta
		)

func move_ai_horizontally(delta):
	var target_x := AI_HOME_X

	var ball_is_coming_toward_ai: bool = main.ball.direction.x < 0.0
	var ball_vertical_speed: float = abs(main.ball.direction.y * main.ball.speed)

	if ball_is_coming_toward_ai:
		if is_aggressive_this_shot:
			target_x = AI_AGGRESSIVE_ATTACK_X
		elif ball_vertical_speed > AI_VERTICAL_DANGER_SPEED:
			target_x = AI_DEFENSE_X
		else:
			target_x = AI_NORMAL_ATTACK_X
	else:
		target_x = AI_HOME_X

	position.x = move_toward(
		position.x,
		target_x,
		AI_HORIZONTAL_SPEED * delta
	)
