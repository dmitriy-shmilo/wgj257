class_name MeetingRequest
extends Control

signal expired(sender)
signal stabilised(sender)

export(Resource) var meeting setget set_meeting
export(bool) var is_resizing = false setget set_is_resizing
export(float) var scroll_speed = 80
export(bool) var is_static = false
export(bool) var is_expiring = false setget set_is_expiring
export(bool) var is_expiration_visible = true setget set_is_progress_visible
export(float) var speed_multiplier = 1.0

var current_expiration = 0.0
var target_position = Vector2.ZERO
var is_selected = false setget set_is_selected
var slot: Vector2 = Vector2(-1, -1)
var row_height = 16
var column_width = 96

onready var _background: Control = $"Background"
onready var _title_label: Label = $"MarginContainer/VBoxContainer/TitleLabel"
onready var _duration_label: Label = $"MarginContainer/VBoxContainer/HBoxContainer/DurationLabel"
onready var _icon: TextureRect = $"MarginContainer/VBoxContainer/HBoxContainer/Icon"
onready var _expiration_progress: TextureProgress = $"ExpirationProgress"
onready var _sfx_player: AudioStreamPlayer = $"SfxPlayer"

var _is_stable = false

func _ready() -> void:
	set_meeting(meeting)


func _process(delta: float) -> void:
	if is_expiring and current_expiration <= meeting.expiration_time:
		current_expiration += delta * speed_multiplier
		_expiration_progress.value = current_expiration
		
		var shake_strength = clamp(current_expiration / meeting.expiration_time - 0.33, 0.0, 1.0)
		shake_strength = ceil(shake_strength * 4.0)
		
		_expiration_progress.material.set_shader_param("shake_strength", shake_strength)
		_background.material.set_shader_param("shake_strength", shake_strength)
	elif is_expiring:
		set_is_expiring(false)
		_sfx_player.stream = preload("res://assets/sound/expire1.wav")
		_sfx_player.play()
		emit_signal("expired", self)
		yield(_sfx_player, "finished")
		queue_free()

	if is_expiring:
		if rect_position != target_position and not is_static:
			if (target_position - rect_position).length_squared() <= 2:
				rect_position = target_position
				return
			
			var direction = (target_position - rect_position).normalized()
			rect_position += direction * scroll_speed * delta * speed_multiplier
		elif not _is_stable:
			_is_stable = true
			emit_signal("stabilised", self)
	elif is_static and not _is_stable:
			_is_stable = true
			emit_signal("stabilised", self)


func set_is_resizing(value: bool) -> void:
	is_resizing = value
	if meeting != null and is_inside_tree():
		_duration_label.get_parent().visible = meeting.duration > 1
		rect_size.y = meeting.duration * row_height
		rect_size.x = column_width


func set_meeting(value: Meeting):
	meeting = value
	if meeting != null and is_inside_tree():
		_expiration_progress.value = 0.0
		_expiration_progress.max_value = meeting.expiration_time
		_title_label.text = meeting.get_short_title()
		_duration_label.text = meeting.get_duration_string()
		_icon.texture = meeting.get_icon()
		_background.material.set_shader_param("tint", meeting.tint)
		if is_resizing:
			_duration_label.get_parent().visible = meeting.duration > 1
			rect_size.y = meeting.duration * row_height


func set_is_selected(value: bool) -> void:
	modulate.a = 0.4 if value else 1


func set_is_expiring(value: bool) -> void:
	is_expiring = value
	if is_inside_tree():
		_expiration_progress.material.set_shader_param("shake_strength", 0.0)
		_background.material.set_shader_param("shake_strength", 0.0)


func set_is_progress_visible(value: bool) -> void:
	is_expiration_visible = value
	if is_inside_tree():
		_expiration_progress.visible = value


func _on_MeetingRequest_gui_input(event: InputEvent) -> void:
	pass
