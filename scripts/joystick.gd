extends Control

const MAX_DISTANCE := 50.0
const DEAD_ZONE := 0.15

@onready var knob: TextureRect = $JoystickKnob

var input_vector := Vector2.ZERO
var is_dragging := false
var active_touch_index := -1
var center := Vector2.ZERO

signal joystick_pressed

func _ready() -> void:
	center = size / 2.0
	reset_knob()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			joystick_pressed.emit()
			is_dragging = true
			active_touch_index = event.index
			update_joystick(event.position)
		elif event.index == active_touch_index:
			stop_dragging()

	if event is InputEventScreenDrag and event.index == active_touch_index:
		update_joystick(event.position)

	if event is InputEventMouseButton:
		if event.pressed:
			joystick_pressed.emit()
			is_dragging = true
			update_joystick(event.position)
		else:
			stop_dragging()

	if event is InputEventMouseMotion and is_dragging:
		update_joystick(event.position)

func update_joystick(local_position: Vector2) -> void:
	var offset: Vector2 = local_position - center

	if offset.length() > MAX_DISTANCE:
		offset = offset.normalized() * MAX_DISTANCE

	input_vector = offset / MAX_DISTANCE

	if input_vector.length() < DEAD_ZONE:
		input_vector = Vector2.ZERO

	knob.position = center + offset - knob.size / 2.0

func stop_dragging() -> void:
	is_dragging = false
	active_touch_index = -1
	input_vector = Vector2.ZERO
	reset_knob()

func reset_knob() -> void:
	knob.position = center - knob.size / 2.0

func get_input_vector() -> Vector2:
	return input_vector
