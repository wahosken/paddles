extends Node2D

const WINNING_SCORE := 3

const SHAKE_DURATION := 0.20
const SHAKE_STRENGTH := 2.0

const JOYSTICK_LEFT_POSITION := Vector2(20.0, 280.0)
const JOYSTICK_RIGHT_POSITION := Vector2(640.0, 280.0)

const START_SCREEN_DELAY := 0.75
const GAME_OVER_RESTART_DELAY := 0.75
const ROUND_INPUT_DELAY := 0.75

const AUTOPLAY_DELAY := 0.65

var can_start_round := false
var can_restart_after_game_over := false
var can_move_paddles := false
var can_start_from_start_screen := false

var background_textures: Array[Texture2D] = [
	preload("res://assets/backgrounds/default.png"),
	preload("res://assets/backgrounds/forest.png"),
	preload("res://assets/backgrounds/royal.png"),
	preload("res://assets/backgrounds/pearl.png"),
	preload("res://assets/backgrounds/wahosken.png")
]

@onready var player_paddle = $PlayerPaddle
@onready var enemy_paddle = $EnemyPaddle

@onready var player_score_label: Label = $UI/PlayerScoreLabel
@onready var enemy_score_label: Label = $UI/EnemyScoreLabel

@onready var game_title: Label = $UI/GameTitle

@onready var pause_button: TextureButton = $UI/PauseButton
@onready var pause_menu: Control = $UI/PauseMenu
@onready var resume_button: Button = $UI/PauseMenu/PauseMenuPanel/PauseMenuContent/ResumeButton
@onready var restart_button: Button = $UI/PauseMenu/PauseMenuPanel/PauseMenuContent/RestartButton
@onready var mode_option_button: OptionButton = $UI/PauseMenu/PauseMenuPanel/PauseMenuContent/ModeOptionButton
@onready var background_option_button: OptionButton = $UI/PauseMenu/PauseMenuPanel/PauseMenuContent/BackgroundOptionButton
@onready var mute_button: Button = $UI/PauseMenu/PauseMenuPanel/PauseMenuContent/MuteButton
@onready var control_option_button: OptionButton = $UI/PauseMenu/PauseMenuPanel/PauseMenuContent/ControlOptionButton
@onready var volume_slider: HSlider = $UI/PauseMenu/PauseMenuPanel/PauseMenuContent/VolumeSlider

@onready var background: Sprite2D = $Background


@onready var virtual_joystick: Control = $UI/UIHide/TouchControls/VirtualJoystick
@onready var touch_controls: Control = $UI/UIHide/TouchControls
@onready var up: TouchScreenButton = $UI/UIHide/TouchControls/Up
@onready var down: TouchScreenButton = $UI/UIHide/TouchControls/Down
@onready var left: TouchScreenButton = $UI/UIHide/TouchControls/Left
@onready var right: TouchScreenButton = $UI/UIHide/TouchControls/Right

enum GameState {
	START_SCREEN,
	PLAYING,
	POINT_PAUSE,
	GAME_OVER
}

enum ControlMode {
	JOYSTICK_RIGHT,
	JOYSTICK_LEFT,
	BUTTONS
}

enum PlayMode {
	CLASSIC,
	UNLIMITED,
	AUTOPLAY
}

var play_mode: PlayMode = PlayMode.CLASSIC

var control_mode: ControlMode = ControlMode.JOYSTICK_RIGHT

var game_state: GameState = GameState.START_SCREEN
var player_score := 0
var enemy_score := 0

var shake_time := 0.0
var camera_start_position := Vector2.ZERO

var is_paused := false
var was_ball_active_before_pause := false
var is_muted := false

var using_touch_controls := false

var master_volume := 80.0

var can_pause := false

@onready var ball = $Ball
@onready var message_label: Label = $UI/MessageLabel
@onready var game_camera = $GameCamera
@onready var score_sound = $ScoreSound
@onready var win_sound = $WinSound
@onready var paddle_hit_sound = $PaddleHitSound
@onready var lose_sound = $LoseSound
@onready var enemy_score_sound = $EnemyScoreSound
@onready var wall_hit_sound: AudioStreamPlayer = $WallHitSound

func _ready():
	setup_pause_menu()
	_on_volume_changed(master_volume)
	update_control_visibility()
	
	set_default_background()
	
	camera_start_position = game_camera.position
	
	ball.player_scored.connect(_on_player_scored)
	ball.enemy_scored.connect(_on_enemy_scored)
	ball.paddle_hit.connect(_on_paddle_hit)
	ball.wall_hit.connect(_on_wall_hit)
	
	virtual_joystick.joystick_pressed.connect(handle_press_anywhere)

	show_start_screen()
	update_score_labels()
	
	is_paused = false
	pause_menu.visible = false

	await get_tree().create_timer(0.25).timeout
	can_pause = true


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

func reset_paddles():
	player_paddle.reset_position()

func _input(event):
	
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		using_touch_controls = true
		update_control_visibility()

	if event is InputEventKey:
		using_touch_controls = false
		update_control_visibility()
		
	if event.is_action_pressed("pause"):
		if can_pause:
			toggle_pause()
		return
		
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			resume_game()
			return
	
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
	if is_paused:
		return

	if game_state == GameState.START_SCREEN:
		if can_start_round:
			start_round()

	elif game_state == GameState.POINT_PAUSE:
		if can_start_round:
			start_round()

	elif game_state == GameState.GAME_OVER:
		if can_restart_after_game_over:
			reset_game()
			show_start_screen()

func show_start_screen():
	game_state = GameState.START_SCREEN
	can_start_round = false
	can_move_paddles = false
	
	message_label.text = "\n\nPress anywhere to start\n\n\n\n\nKeyboard: WASD / Arrow Keys\nTouch: Joystick or Buttons\nPause: Esc or Pause Button"
	message_label.visible = true
	game_title.visible = true
	
	ball.reset_ball()
	reset_paddles()
	
	await get_tree().create_timer(ROUND_INPUT_DELAY).timeout
	
	if game_state == GameState.START_SCREEN:
		can_start_round = true

	if play_mode == PlayMode.UNLIMITED:
		message_label.text = "Unlimited Mode\nPlay forever\n\n\n\nPress anywhere to start"

	elif play_mode == PlayMode.AUTOPLAY:
		message_label.text = "Autoplay mode\nWatch forever\n\n\n\nPress anywhere to start"

func start_round():
	game_state = GameState.PLAYING
	can_start_round = false
	can_move_paddles = true
	message_label.visible = false
	game_title.visible = false
	ball.start_ball()

func _on_player_scored():
	if game_state != GameState.PLAYING:
		return

	player_score += 1
	update_score_labels()
	shake_screen()
	score_sound.play()

	if play_mode == PlayMode.AUTOPLAY:
		auto_start_next_autoplay_round()
	elif play_mode == PlayMode.CLASSIC and player_score >= WINNING_SCORE:
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

	if play_mode == PlayMode.AUTOPLAY:
		auto_start_next_autoplay_round()
	elif play_mode == PlayMode.CLASSIC and enemy_score >= WINNING_SCORE:
		lose_sound.play()
		show_game_over("Enemy wins!")
	else:
		show_point_pause("Enemy scored!")

func show_point_pause(message: String):
	game_state = GameState.POINT_PAUSE
	can_start_round = false
	can_move_paddles = false
	
	ball.reset_ball()
	reset_paddles()
	
	message_label.text = message + "\n\n\n\n\nPress anything for next round"
	message_label.visible = true
	game_title.visible = false
	
	await get_tree().create_timer(ROUND_INPUT_DELAY).timeout
	
	if game_state == GameState.POINT_PAUSE:
		can_start_round = true

func show_game_over(message: String):
	game_state = GameState.GAME_OVER
	can_restart_after_game_over = false
	can_move_paddles = false
	
	ball.reset_ball()
	reset_paddles()
	
	message_label.text = message + "\n\n\n\n\nPress anything to start a new game"
	message_label.visible = true
	game_title.visible = true
	
	await get_tree().create_timer(GAME_OVER_RESTART_DELAY).timeout
	
	if game_state == GameState.GAME_OVER:
		can_restart_after_game_over = true

func reset_game():
	player_score = 0
	enemy_score = 0
	can_start_round = false
	can_move_paddles = false
	update_score_labels()
	ball.reset_ball()
	reset_paddles()
	
func reset_autoplay_paddles():
	player_paddle.reset_position()
	enemy_paddle.reset_position()

func update_score_labels():
	player_score_label.text = str(player_score)
	enemy_score_label.text = str(enemy_score)

func shake_screen():
	shake_time = SHAKE_DURATION

func _on_paddle_hit():
	paddle_hit_sound.pitch_scale = randf_range(0.9, 1.1)
	paddle_hit_sound.play()

func _on_wall_hit():
	wall_hit_sound.pitch_scale = randf_range(0.95, 1.05)
	wall_hit_sound.play()

func setup_pause_menu():
	pause_button.pressed.connect(toggle_pause)
	pause_menu.visible = false

	resume_button.pressed.connect(resume_game)
	restart_button.pressed.connect(restart_match)
	mode_option_button.item_selected.connect(_on_play_mode_selected)
	background_option_button.item_selected.connect(_on_background_selected)
	control_option_button.item_selected.connect(_on_control_mode_selected)
	mute_button.pressed.connect(toggle_mute)

	volume_slider.value = master_volume
	volume_slider.value_changed.connect(_on_volume_changed)

	background_option_button.clear()
	background_option_button.add_item("Default", 0)
	background_option_button.add_item("Forest", 1)
	background_option_button.add_item("Royal", 2)
	background_option_button.add_item("Pearl", 3)
	background_option_button.add_item("Wahosken", 4)
	

	control_option_button.clear()
	control_option_button.add_item("Joystick Right", ControlMode.JOYSTICK_RIGHT)
	control_option_button.add_item("Joystick Left", ControlMode.JOYSTICK_LEFT)
	control_option_button.add_item("Buttons", ControlMode.BUTTONS)
	control_option_button.select(control_mode)

	mode_option_button.clear()
	mode_option_button.add_item("Classic", PlayMode.CLASSIC)
	mode_option_button.add_item("Unlimited", PlayMode.UNLIMITED)
	mode_option_button.add_item("Autoplay", PlayMode.AUTOPLAY)
	mode_option_button.select(play_mode)
	
func toggle_pause():
	if not can_pause:
		return

	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	is_paused = true
	was_ball_active_before_pause = ball.is_active

	if was_ball_active_before_pause:
		ball.pause_ball()

	pause_menu.visible = true
	resume_button.grab_focus()

func resume_game():
	is_paused = false
	pause_menu.visible = false

	if was_ball_active_before_pause:
		ball.resume_ball()
		
func restart_match():
	is_paused = false
	pause_menu.visible = false
	reset_game()
	show_start_screen()
	
func _on_play_mode_selected(index: int):
	play_mode = index as PlayMode
	reset_game()
	show_start_screen()
	
func toggle_mute():
	is_muted = not is_muted

	var master_bus_index: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, is_muted)

	if is_muted:
		mute_button.text = "Unmute"
	else:
		mute_button.text = "Mute"
	
func _on_background_selected(index: int):
	if index < 0 or index >= background_textures.size():
		return

	background.texture = background_textures[index]

func set_default_background():
	background.texture = background_textures[0]
	background_option_button.select(0)

func update_control_visibility():
	if not using_touch_controls:
		touch_controls.visible = false
		return

	touch_controls.visible = true

	var using_buttons: bool = control_mode == ControlMode.BUTTONS
	var using_joystick: bool = (
		control_mode == ControlMode.JOYSTICK_LEFT
		or control_mode == ControlMode.JOYSTICK_RIGHT
	)

	up.visible = using_buttons
	down.visible = using_buttons
	left.visible = using_buttons
	right.visible = using_buttons

	virtual_joystick.visible = using_joystick

	if control_mode == ControlMode.JOYSTICK_LEFT:
		virtual_joystick.position = JOYSTICK_LEFT_POSITION

	if control_mode == ControlMode.JOYSTICK_RIGHT:
		virtual_joystick.position = JOYSTICK_RIGHT_POSITION

func _on_control_mode_selected(index: int):
	control_mode = index as ControlMode
	update_control_visibility()

func _on_volume_changed(value: float):
	master_volume = value

	var master_bus_index: int = AudioServer.get_bus_index("Master")

	if value <= 0.0:
		AudioServer.set_bus_volume_db(master_bus_index, -80.0)
	else:
		var volume_db: float = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(master_bus_index, volume_db)

	if is_muted and value > 0.0:
		is_muted = false
		AudioServer.set_bus_mute(master_bus_index, false)
		mute_button.text = "Mute"

func auto_start_next_autoplay_round():
	game_state = GameState.POINT_PAUSE
	can_start_round = false
	can_move_paddles = false
	
	ball.reset_ball()
	reset_autoplay_paddles()
	message_label.visible = false
	
	await get_tree().create_timer(AUTOPLAY_DELAY).timeout
	
	if play_mode == PlayMode.AUTOPLAY and game_state == GameState.POINT_PAUSE and not is_paused:
		start_round()
