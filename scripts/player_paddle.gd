extends Area2D

const SPEED := 400.0

const SCREEN_HEIGHT := 450.0
const PADDLE_HALF_HEIGHT := 50.0

const MIN_X := 20.0
const MAX_X := 380.0

var move_direction := Vector2.ZERO
var paddle_velocity := Vector2.ZERO
var previous_position := Vector2.ZERO

var main: Node
var joystick: Node

func _ready():
	main = get_tree().current_scene
	joystick = main.get_node("UI/TouchControls/VirtualJoystick")
	previous_position = position

func _process(delta):
	if main.is_paused:
		paddle_velocity = Vector2.ZERO
		previous_position = position
		return
	
	move_direction = Vector2.ZERO

	# Keyboard / Input Map controls always work.
	if Input.is_action_pressed("move_up"):
		move_direction.y -= 1.0

	if Input.is_action_pressed("move_down"):
		move_direction.y += 1.0

	if Input.is_action_pressed("move_left"):
		move_direction.x -= 1.0

	if Input.is_action_pressed("move_right"):
		move_direction.x += 1.0

	# Joystick only controls the paddle if joystick mode is active
	# AND no keyboard/input-map direction is currently being used.
	if move_direction == Vector2.ZERO:
		if main.control_mode == main.ControlMode.JOYSTICK:
			if joystick != null:
				move_direction = joystick.get_input_vector()

	if move_direction.length() > 1.0:
		move_direction = move_direction.normalized()

	position += move_direction * SPEED * delta

	position.x = clamp(position.x, MIN_X, MAX_X)
	position.y = clamp(position.y, PADDLE_HALF_HEIGHT, SCREEN_HEIGHT - PADDLE_HALF_HEIGHT)
	
	paddle_velocity = (position - previous_position) / delta
	previous_position = position
