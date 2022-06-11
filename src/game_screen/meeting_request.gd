class_name MeetingRequest
extends Control

signal expired(sender)

export(Resource) var meeting setget set_meeting
export(bool) var is_resizing = false setget set_is_resizing
export(float) var scroll_speed = 4
export(bool) var is_static = false
export(bool) var is_expiring = false setget set_is_expiring
export(bool) var is_expiration_visible = true setget set_is_progress_visible

var current_expiration = 0.0
var target_position = Vector2.ZERO
var is_selected = false setget set_is_selected
var slot: Vector2 = Vector2(-1, -1)

onready var _background: Control = $"Background"
onready var _title_label: Label = $"MarginContainer/VBoxContainer/TitleLabel"
onready var _duration_label: Label = $"MarginContainer/VBoxContainer/HBoxContainer/DurationLabel"
onready var _icon: TextureRect = $"MarginContainer/VBoxContainer/HBoxContainer/Icon"
onready var _expiration_progress: TextureProgress = $"ExpirationProgress"

func _ready() -> void:
	set_meeting(meeting)


func _process(delta: float) -> void:
	if is_expiring and current_expiration <= meeting.expiration_time:
		current_expiration += delta
		_expiration_progress.value = current_expiration
		
		var shake_strength = clamp(current_expiration / meeting.expiration_time - 0.33, 0.0, 1.0)
		shake_strength = ceil(shake_strength * 4.0)
		
		_expiration_progress.material.set_shader_param("shake_strength", shake_strength)
		_background.material.set_shader_param("shake_strength", shake_strength)
	elif is_expiring:
		emit_signal("expired", self)
		set_is_expiring(false)

	if rect_position != target_position and not is_static:
		if (target_position - rect_position).length_squared() <= 2:
			rect_position = target_position
			return
		
		var direction = (target_position - rect_position).normalized()
		rect_position += direction * scroll_speed


func set_is_resizing(value: bool) -> void:
	is_resizing = value
	if meeting != null and is_inside_tree():
		_duration_label.get_parent().visible = meeting.duration > 1
		rect_size.y = meeting.duration * 16
		rect_size.x = 96 # TODO: magic numbers


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
			rect_size.y = meeting.duration * 16


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
