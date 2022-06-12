class_name DialogPopup
extends MarginContainer

signal disable_hints_pressed()
signal ok_pressed()

export(bool) var show_disable_hints = false setget set_show_disable_hints
export(String) var text = "" setget set_text
export(Dialog.Emotion) var emotion = Dialog.Emotion.NORMAL setget set_emotion

onready var _disable_hints_button: Button = $"VBoxContainer/MarginContainer2/HBoxContainer/DisableHintsButton"
onready var _ok_button: Button = $"VBoxContainer/MarginContainer2/HBoxContainer/OkButton"
onready var _dialog: Dialog = $"VBoxContainer/MarginContainer/Dialog"

func _ready() -> void:
	set_show_disable_hints(show_disable_hints)
	set_text(text)
	set_emotion(emotion)


func set_show_disable_hints(val: bool) -> void:
	show_disable_hints = val
	if is_inside_tree():
		_disable_hints_button.visible = val


func set_text(val: String) -> void:
	text = val
	if is_inside_tree():
		_dialog.text = val


func set_emotion(val: int) -> void:
	emotion = val
	if is_inside_tree():
		_dialog.emotion = val


func _on_DisableHintsButton_pressed() -> void:
	emit_signal("disable_hints_pressed")


func _on_OkButton_pressed() -> void:
	emit_signal("ok_pressed")
