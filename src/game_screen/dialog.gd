class_name Dialog
extends Control

enum Emotion {
	NORMAL,
	FROWN,
	YELL,
	SMILE
}

export (Emotion) var emotion setget set_emotion
export (String) var text setget set_text

onready var _dialog_label: RichTextLabel = $"Panel/MarginContainer/DialogLabel"
onready var _portrait: AnimatedSprite = $"Portrait"


func _ready() -> void:
	set_text(text)
	set_emotion(emotion)
	_portrait.play()


func set_text(val: String) -> void:
	text = val
	if is_inside_tree():
		_dialog_label.bbcode_text = text


func set_emotion(val: int) -> void:
	emotion = val
	if is_inside_tree():
		match val:
			Emotion.NORMAL:
				_portrait.frames = preload("res://assets/texture/boss_talking.tres")
			Emotion.FROWN:
				_portrait.frames = preload("res://assets/texture/boss_frowning.tres")
			Emotion.YELL:
				_portrait.frames = preload("res://assets/texture/boss_yelling.tres")
			Emotion.SMILE:
				_portrait.frames = preload("res://assets/texture/boss_smiling.tres")
