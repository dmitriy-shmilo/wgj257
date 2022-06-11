extends Control
class_name SettingsScene

const KEY_BINDING_BUTTON_SCENE = preload("res://title_screen/settings/keybinding_button.tscn")
const KEY_BINDING_LABEL_SCENE = preload("res://title_screen/settings/keybinding_label.tscn")
const SUPPORTED_LANGUAGES = ["en", "ru", "uk"]

export(bool) var show_language_settings = true

onready var _back_button = $"VBoxContainer/BackToTitleButton"
onready var _tab_container = $"VBoxContainer/PanelContainer/TabContainer"
onready var _keybindings_grid = $"VBoxContainer/PanelContainer/TabContainer/KeyBindings/GridContainer"
onready var _keybinding_popup = $"KeyBindingPopup"
onready var _master_volume_slider = $"VBoxContainer/PanelContainer/TabContainer/SoundSettings/Container/MasterVolume/VolumeSlider"
onready var _sfx_volume_slider = $"VBoxContainer/PanelContainer/TabContainer/SoundSettings/Container/SfxVolume/VolumeSlider"
onready var _music_volume_slider = $"VBoxContainer/PanelContainer/TabContainer/SoundSettings/Container/MusicVolume/VolumeSlider"
onready var _fullscreen_checkbox: CheckBox = $"VBoxContainer/PanelContainer/TabContainer/OtherSettings/Container/FullscreenCheckbox"
onready var _particles_checkbox: CheckBox = $"VBoxContainer/PanelContainer/TabContainer/OtherSettings/Container/ParticlesCheckbox"
onready var _language_tab: Control = $"VBoxContainer/PanelContainer/TabContainer/LanguageSettings"
onready var _language_container: VBoxContainer = $"VBoxContainer/PanelContainer/TabContainer/LanguageSettings/Container"

var _current_binding_button: KeyBindingButton = null
var _require_reload: bool = false
var _new_locale: String

func _ready() -> void:
	_new_locale = Settings.locale

	_prepare_tabs()
	_prepare_language()
	_prepare_keybindings()
	_prepare_volume()
	_prepare_other()


func _prepare_tabs() -> void:
	var labels = ["ui_sound_settings", 
		"ui_language_settings",
		"ui_key_bindings",
		"ui_other_settings"]
	
	for i in labels.size():
		_tab_container.set_tab_title(i, tr(labels[i]))
	
	if not show_language_settings:
		_tab_container.remove_child(_language_tab)


func _prepare_language() -> void:
	var group = ButtonGroup.new()
	var current_locale = Settings.locale
	for lang in SUPPORTED_LANGUAGES:
		var button = CheckButton.new()
		button.text = tr("ui_lang_" + lang)
		button.group = group
		button.pressed = current_locale == lang
		button.connect("pressed", self, "_on_language_button_pressed", [lang])
		_language_container.add_child(button)


func _prepare_volume() -> void:
	_master_volume_slider.value = Settings.master_volume
	_sfx_volume_slider.value = Settings.sfx_volume
	_music_volume_slider.value = Settings.music_volume


func _prepare_other() -> void:
	_fullscreen_checkbox.pressed = Settings.fullscreen
	_particles_checkbox.pressed = Settings.particles


func _prepare_keybindings() -> void:
	for action in Settings.CONFIGURABLE_KEYS:
		var label = KEY_BINDING_LABEL_SCENE.instance()
		label.text = tr("key_" + action)
		var button = KEY_BINDING_BUTTON_SCENE.instance()
		button.action = action
		button.connect("pressed", \
			self, \
			"_on_KeyBindingButton_keybind_requested",
			[button])
		_keybindings_grid.add_child(label)
		_keybindings_grid.add_child(button)


func _on_language_button_pressed(lang) -> void:
	_new_locale = lang


func _on_MasterVolumeSlider_value_changed(value) -> void:
	Settings.master_volume = value


func _on_MusicVolumeSlider_value_changed(value) -> void:
	Settings.music_volume = value


func _on_SfxVolumeSlider_value_changed(value) -> void:
	Settings.sfx_volume = value


func _on_SpeechVolumeSlider_value_changed(value) -> void:
	Settings.speech_volume = value


func _on_BackToTitleButton_pressed():
	# locale change requires a whole scene reload in order to take effect properly
	if Settings.locale != _new_locale:
		Settings.locale = _new_locale
		Settings.save_settings()
		var err = get_tree().reload_current_scene()
		ErrorHandler.handle(err)
	else:
		Settings.save_settings()


func _on_KeyBindingButton_keybind_requested(sender: KeyBindingButton) -> void:
	_current_binding_button = sender
	_keybinding_popup.action = sender.action
	_keybinding_popup.popup_centered()


func _on_KeybindingCancelButton_pressed() -> void:
	_keybinding_popup.hide()
	_current_binding_button = null


func _on_KeyBindingPopup_action_remapped(action, event) -> void:
	var events = InputMap.get_action_list(action)
	
	for i in range(events.size()):
		if events[i] is InputEventKey:
			InputMap.action_erase_event(action, events[i])
			break
	
	if event != null:
		InputMap.action_add_event(action, event)

	_current_binding_button.refresh_label()
	_keybinding_popup.hide()


func _on_FullscreenCheckbox_toggled(button_pressed: bool) -> void:
	Settings.fullscreen = button_pressed


func _on_ParticlesCheckbox_toggled(button_pressed: bool) -> void:
	Settings.particles = button_pressed


func _on_ParticlesLabel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_pressed():
		_particles_checkbox.pressed = !_particles_checkbox.pressed


func _on_FullscreenLabel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_pressed():
		_fullscreen_checkbox.pressed = !_fullscreen_checkbox.pressed


func _on_Settings_visibility_changed() -> void:
	if visible:
		_back_button.grab_focus()
