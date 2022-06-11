extends Node2D


onready var _gui = $"Gui"

func _ready() -> void:
	pass


func _process(_event):
	if Input.is_action_just_pressed("system_pause"):
		_gui.pause()
