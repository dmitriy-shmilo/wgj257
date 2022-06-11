class_name MeetingRequest
extends Control

export(Resource) var meeting setget set_meeting
export(bool) var is_resizing = false setget set_is_resizing
export(float) var scroll_speed = 4
export(bool) var is_static = false

var target_position = Vector2.ZERO
var is_selected = false setget set_is_selected
var slot: Vector2 = Vector2(-1, -1)

onready var _background: Control = $"Background"
onready var _title_label: Label = $"MarginContainer/VBoxContainer/TitleLabel"
onready var _duration_label: Label = $"MarginContainer/VBoxContainer/HBoxContainer/DurationLabel"
onready var _icon: TextureRect = $"MarginContainer/VBoxContainer/HBoxContainer/Icon"

func _ready() -> void:
	set_meeting(meeting)


func _process(delta: float) -> void:
	if rect_position != target_position and not is_static:
		if (target_position - rect_position).length_squared() <= 2:
			rect_position = target_position
			return
		
		var direction = (target_position - rect_position).normalized()
		rect_position += direction * scroll_speed


func set_is_resizing(value: bool) -> void:
	is_resizing = value
	if meeting != null and is_inside_tree():
		rect_size.y = meeting.duration * 16
		rect_size.x = 96 # TODO: magic numbers


func set_meeting(value: Meeting):
	meeting = value
	if meeting != null and is_inside_tree():
		_title_label.text = meeting.get_short_title()
		_duration_label.text = meeting.get_duration_string()
		_icon.texture = meeting.get_icon()
		_background.material.set_shader_param("tint", meeting.tint)
		if is_resizing:
			rect_size.y = meeting.duration * 16


func set_is_selected(value: bool) -> void:
	modulate.a = 0.4 if value else 1


func _on_MeetingRequest_gui_input(event: InputEvent) -> void:
	pass
