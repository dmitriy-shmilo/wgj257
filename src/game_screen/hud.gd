class_name Hud
extends Control

signal mood_ran_out()

const MOOD_UP = preload("res://assets/texture/icon_mood_up.tres")
const MOOD_DOWN = preload("res://assets/texture/icon_mood_down.tres")

enum MoodModifier {
	NONE,
	UP,
	DOUBLE_UP,
	DOWN,
	DOUBLE_DOWN
}

var max_mood = 100.0 setget set_max_mood
var current_mood = 100.0 setget set_current_mood
var mood_modifier = MoodModifier.NONE setget set_mood_modifier
var current_score = 0.0 setget set_current_score
var current_week = 1 setget set_current_week

onready var _mood_modifier_icons = [
	$"MoodModifierIcon",
	$"MoodModifierIcon2"
]
onready var _mood_progress: TextureProgress = $"MoodProgress"
onready var _score_label: Label = $"ScoreLabel"
onready var _week_label: Label = $"WeekLabel"
onready var _animation_player: AnimationPlayer = $"AnimationPlayer"
onready var _shaker: Shaker = $"Shaker"
onready var _sfx_player: AudioStreamPlayer = $"SfxPlayer"

func _ready() -> void:
	_animation_player.play("default")
	set_max_mood(max_mood)
	set_current_mood(current_mood)
	set_current_week(current_week)
	set_mood_modifier(mood_modifier)
	set_current_score(current_score)


func set_max_mood(value: float) -> void:
	max_mood = value
	if is_inside_tree():
		_mood_progress.max_value = value


func set_current_mood(value: float) -> void:
	if value <= 0:
		emit_signal("mood_ran_out")

	current_mood = clamp(value, 0, max_mood)
	if is_inside_tree():
		_mood_progress.value = current_mood


func set_mood_modifier(value: int) -> void:
	mood_modifier = value
	if is_inside_tree():
		match value:
			MoodModifier.NONE:
				_mood_modifier_icons[0].texture = null
				_mood_modifier_icons[1].texture = null
			MoodModifier.UP:
				_mood_modifier_icons[0].texture = MOOD_UP
				_mood_modifier_icons[1].texture = null
			MoodModifier.DOUBLE_UP:
				_mood_modifier_icons[0].texture = MOOD_UP
				_mood_modifier_icons[1].texture = MOOD_UP
			MoodModifier.DOWN:
				_mood_modifier_icons[0].texture = MOOD_DOWN
				_mood_modifier_icons[1].texture = null
			MoodModifier.DOUBLE_DOWN:
				_mood_modifier_icons[0].texture = MOOD_DOWN
				_mood_modifier_icons[1].texture = MOOD_DOWN


func set_current_score(value: float) -> void:
	if value > current_score:
		_sfx_player.stream = preload("res://assets/sound/score_gain1.wav")
		_sfx_player.play()

	current_score = value
	if is_inside_tree():
		_score_label.text = "%0.2f" % value


func set_current_week(value: int) -> void:
	current_week = value
	if is_inside_tree():
		_week_label.text = tr("ui_week_label") % [value]


func shake_mood_meter() -> void:
	_shaker.shake_horizontal(_mood_progress, "rect_position", 6, 10)
