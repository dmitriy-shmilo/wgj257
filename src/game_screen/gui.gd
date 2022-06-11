extends Node
class_name Gui

onready var _pause_container: ColorRect = $"PauseContainer"
onready var _pause_controls: Control = $"PauseContainer/PauseControls"
onready var _continue_button: Button = $"PauseContainer/PauseControls/HBoxContainer/ContinueButton"
onready var _settings: SettingsScene = $"PauseContainer/Settings"

func unpause() -> void:
	_pause_container.visible = false
	get_tree().paused = false


func pause() -> void:
	get_tree().paused = true
	_pause_container.visible = true
	_continue_button.grab_focus()


func _on_QuitButton_pressed() -> void:
	_pause_container.visible = false
	get_tree().paused = false
	var err = get_tree().change_scene("res://title_screen/title_screen.tscn")
	ErrorHandler.handle(err)


func _on_ContinueButton_pressed() -> void:
	unpause()


func _on_SettingsButton_pressed() -> void:
	_settings.visible = true
	_pause_controls.visible = false


func _on_Settings_BackToTitleButton_pressed() -> void:
	_settings.visible = false
	_pause_controls.visible = true
