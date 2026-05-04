extends Control

@onready var fullscreen_button: TextureButton = $FullscreenButton

func _ready() -> void:
	hide()

	if fullscreen_button:
		fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		show()

	if event is InputEventKey:
		hide()

func _on_fullscreen_button_pressed() -> void:
	var current_mode := DisplayServer.window_get_mode()

	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
