extends Control

onready var _dialog: Dialog = $"VBoxContainer/Dialog"

func show_game_over(weeks, score) -> void:
	_dialog.text = tr("txt_game_over") % [weeks, score]
	visible = true


func _on_QuitButton_pressed():
	var err = get_tree().change_scene("res://title_screen/title_screen.tscn")
	ErrorHandler.handle(err)


func _on_RetryButton_pressed():
	var err = get_tree().change_scene("res://game_screen/game_screen.tscn")
	ErrorHandler.handle(err)
