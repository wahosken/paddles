extends Control

func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		show()

	if event is InputEventKey or event is InputEventJoypadMotion or event is InputEventJoypadButton:
		hide()
