class_name MeetingRequest
extends Control

export(Color) var tint = Color.aquamarine setget set_tint

onready var _background: Control = $"Background"

func _ready() -> void:
	set_tint(tint)


func set_tint(color: Color):
	if is_inside_tree():
		_background.material.set_shader_param("tint", color)

func _on_MeetingRequest_gui_input(event: InputEvent) -> void:
	pass
