class_name MeetingRequest
extends Control

export(Resource) var meeting setget set_meeting
export(bool) var is_resizing = false

onready var _background: Control = $"Background"
onready var _title_label: Label = $"MarginContainer/VBoxContainer/TitleLabel"
onready var _duration_label: Label = $"MarginContainer/VBoxContainer/HBoxContainer/DurationLabel"
onready var _icon: TextureRect = $"MarginContainer/VBoxContainer/HBoxContainer/Icon"

func _ready() -> void:
	set_meeting(meeting)


func set_meeting(value: Meeting):
	meeting = value
	if meeting != null and is_inside_tree():
		_title_label.text = meeting.get_short_title()
		_duration_label.text = meeting.get_duration_string()
		_icon.texture = meeting.get_icon()
		_background.material.set_shader_param("tint", meeting.tint)
		if is_resizing:
			rect_size.y = meeting.duration * 16

func _on_MeetingRequest_gui_input(event: InputEvent) -> void:
	pass
