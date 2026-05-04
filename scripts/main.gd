extends Node2D

const WINNING_SCORE := 3

const SHAKE_DURATION := 0.20
const SHAKE_STRENGTH := 2.0


enum GameState {
	START_SCREEN,
	PLAYING,
	POINT_PAUSE,
	GAME_OVER
}

var game_state: GameState = GameState.START_SCREEN
var player_score := 0
var enemy_score := 0

var shake_time := 0.0
var camera_start_position := Vector2.ZERO

@onready var ball = $Ball
@onready var player_score_label = $UI/PlayerScoreLabel
@onready var enemy_score_label = $UI/EnemyScoreLabel
@onready var message_label = $UI/MessageLabel
@onready var game_camera = $GameCamera
@onready var score_sound = $ScoreSound
@onready var win_sound = $WinSound
@onready var paddle_hit_sound = $PaddleHitSound
@onready var lose_sound = $LoseSound
@onready var enemy_score_sound = $EnemyScoreSound

func _ready():
	camera_start_position = game_camera.position
	
	ball.player_scored.connect(_on_player_scored)
	ball.enemy_scored.connect(_on_enemy_scored)
	ball.paddle_hit.connect(_on_paddle_hit)

	show_start_screen()
	update_score_labels()

func _process(delta):
	if shake_time > 0.0:
		shake_time -= delta

		var random_offset := Vector2(
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH),
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH)
		)

		game_camera.position = camera_start_position + random_offset
	else:
		game_camera.position = camera_start_position

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		handle_press_anywhere()

	if event is InputEventScreenTouch and event.pressed:
		handle_press_anywhere()

	if event.is_action_pressed("ui_accept"):
		handle_press_anywhere()

	if event.is_action_pressed("move_up"):
		handle_press_anywhere()

	if event.is_action_pressed("move_down"):
		handle_press_anywhere()

	if event.is_action_pressed("move_left"):
		handle_press_anywhere()

	if event.is_action_pressed("move_right"):
		handle_press_anywhere()

func handle_press_anywhere():
	if game_state == GameState.START_SCREEN:
		start_round()
	elif game_state == GameState.POINT_PAUSE:
		start_round()
	elif game_state == GameState.GAME_OVER:
		reset_game()
		show_start_screen()

func show_start_screen():
	game_state = GameState.START_SCREEN
	message_label.visible = true
	ball.reset_ball()

func start_round():
	game_state = GameState.PLAYING
	message_label.visible = false
	ball.start_ball()

func _on_player_scored():
	if game_state != GameState.PLAYING:
		return

	player_score += 1
	update_score_labels()
	shake_screen()
	score_sound.play()

	if player_score >= WINNING_SCORE:
		win_sound.play()
		show_game_over("You win!")
	else:
		show_point_pause("You scored!")
		

func _on_enemy_scored():
	if game_state != GameState.PLAYING:
		return

	enemy_score += 1
	update_score_labels()
	shake_screen()
	enemy_score_sound.play()

	if enemy_score >= WINNING_SCORE:
		lose_sound.play()
		show_game_over("Enemy wins!")
	else:
		show_point_pause("Enemy scored!")

func show_point_pause(message: String):
	game_state = GameState.POINT_PAUSE
	ball.reset_ball()
	message_label.text = message
	message_label.visible = true

func show_game_over(message: String):
	game_state = GameState.GAME_OVER
	ball.reset_ball()
	message_label.text = message
	message_label.visible = true

func reset_game():
	player_score = 0
	enemy_score = 0
	update_score_labels()
	ball.reset_ball()

func update_score_labels():
	player_score_label.text = str(player_score)
	enemy_score_label.text = str(enemy_score)

func shake_screen():
	shake_time = SHAKE_DURATION

func _on_paddle_hit():
	paddle_hit_sound.pitch_scale = randf_range(0.9, 1.1)
	paddle_hit_sound.play()
