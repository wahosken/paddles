extends Area2D

const SPEED := 400.0

const SCREEN_HEIGHT := 450.0
const PADDLE_HALF_HEIGHT := 50.0

const MIN_X := 20.0
const MAX_X := 380.0

const DEFAULT_POSITION := Vector2(45.0, 224.0)

var move_direction := Vector2.ZERO
var paddle_velocity := Vector2.ZERO
var previous_position := Vector2.ZERO

var main: Node
var joystick: Node

func _ready():
	main = get_tree().current_scene
	joystick = main.get_node("UI/UIHide/TouchControls/VirtualJoystick")
	previous_position = position

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
	
func move_as_ai(delta):
	var ball = main.ball

	var difference_y: float = ball.position.y - position.y

	if abs(difference_y) > 10.0:
		position.y = move_toward(
			position.y,
			ball.position.y,
			SPEED * 0.85 * delta
		)

	var home_x: float = DEFAULT_POSITION.x
	var attack_x: float = 300.0
	var defense_x: float = 35.0

	var target_x: float = home_x

	var ball_coming_toward_player: bool = ball.direction.x < 0.0
	var ball_vertical_speed: float = abs(ball.direction.y * ball.speed)
	var ball_is_close: bool = ball.position.x < 500.0

	if ball_coming_toward_player:
		if ball_vertical_speed > 220.0:
			target_x = defense_x
		elif ball_is_close:
			target_x = attack_x
		else:
			target_x = home_x
	else:
		target_x = home_x

	position.x = move_toward(
		position.x,
		target_x,
		SPEED * 0.35 * delta
	)

	position.x = clamp(position.x, MIN_X, MAX_X)
	position.y = clamp(position.y, PADDLE_HALF_HEIGHT, SCREEN_HEIGHT - PADDLE_HALF_HEIGHT)

	paddle_velocity = (position - previous_position) / delta
	previous_position = position
