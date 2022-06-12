class_name Pickup
extends Control

signal picked_up(sender)

export(bool) var is_payday = true setget set_is_payday
export(bool) var is_mood_up = true setget set_is_mood_up

onready var _icon_container = $"IconContainer"
onready var _payday_icon = $"IconContainer/PaydayIcon"
onready var _mood_up_icon = $"IconContainer/MoodUpIcon"
onready var _tween = $"Tween"

var _is_picked_up = false

func _ready() -> void:
	set_is_payday(is_payday)
	set_is_mood_up(is_mood_up)


func reset():
	_icon_container.modulate.a = 1.0
	_icon_container.rect_position = rect_position


func pick_up():
	if _is_picked_up:
		return
	
	_is_picked_up = true
	_tween.stop_all()
	_tween.interpolate_property(_icon_container, "rect_position", \
		Vector2.ZERO, \
		Vector2(0, -rect_size.y), \
		0.25)
	_tween.interpolate_property(_icon_container, "modulate:a", \
		modulate.a, \
		0, \
		0.25)
	_tween.start()
	yield(_tween, "tween_all_completed")
	emit_signal("picked_up", self)


func set_is_payday(value: bool):
	is_payday = value
	if is_inside_tree():
		_payday_icon.visible = value


func set_is_mood_up(value: bool):
	is_mood_up = value
	if is_inside_tree():
		_mood_up_icon.visible = value

