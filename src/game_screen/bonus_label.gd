class_name BonusLabel
extends Label

onready var _tween: Tween = $"Tween"

func show_at(bonus_text: String, pos: Vector2) -> void:
	visible = true
	rect_position = pos
	text = bonus_text
	_tween.interpolate_property(self, \
		"rect_global_position", pos, pos + Vector2(0, -64), \
		1.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_tween.interpolate_property(self, \
		"modulate:a", 1.0, 0.0, \
		2.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_tween.start()
