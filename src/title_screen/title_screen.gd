extends Control

const MEETING_REQUEST_SCENE = preload("res://game_screen/meeting_request.tscn")
const DAY_COUNT: int = 5
const SLOT_COUNT: int = 18

onready var _fader = $"Fader"
onready var _title_scene: Control = $"TitleScene"
onready var _credits_scene: Control = $"CreditsScene"
onready var _settings_scene: Control = $"SettingsScene"
onready var _tutorial_scene: Control = $"TutorialScene"
onready var _scenes = [
	_title_scene, _credits_scene, 
	_settings_scene, _tutorial_scene
]
onready var _calendars = [
	$"Background/Calendar",
	$"Background/Calendar2"
]
onready var _column_width = _calendars[0].rect_size.x / DAY_COUNT
onready var _row_height = _calendars[0].rect_size.y / SLOT_COUNT
onready var _last_placement = Vector2(0, _row_height)

var _scroll_speed = 33
var _calendar_idx = 0
var _transition_target: Control = null
var _meetings = []

func _ready() -> void:
	_generate_initial_items()


func _process(delta: float) -> void:
	for cal in _calendars:
		cal.rect_position.x -= delta * _scroll_speed
		if cal.rect_position.x <= -cal.rect_size.x:
			cal.rect_position.x = cal.rect_size.x
	
	for req in _meetings:
		req.rect_position.x -= delta * _scroll_speed
		if req.rect_position.x <= -req.rect_size.x:
			_recycle_item(req)
	
	_last_placement.x -= delta * _scroll_speed


func _recycle_item(req: MeetingRequest) -> void:
	var meeting = MeetingGenerator.generate_dummy()
	
	if _last_placement.y + meeting.duration * _row_height >= (SLOT_COUNT - 2) * _row_height:
		_last_placement.y = _row_height * (randi() % 4 + 1)
		_last_placement.x += _column_width
	
	req.is_resizing = true
	req.is_static = true
	req.is_expiring = false
	req.meeting = meeting
	req.rect_position = _last_placement
	_last_placement.y += (meeting.duration + randi() % 10) * _row_height


func _generate_initial_items() -> void:
	for i in range(20):
		var req = MEETING_REQUEST_SCENE.instance()
		req.column_width = _column_width
		req.row_height = _row_height
		_recycle_item(req)
		_meetings.append(req)
		$Background.add_child(req)


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_BackToTitleButton_pressed() -> void:
	_transition_to(_title_scene)


func _on_CreditsButton_pressed():
	_transition_to(_credits_scene)


func _on_TutorialButton_pressed():
	_transition_to(_tutorial_scene)


func _on_SettingsButton_pressed():
	_transition_to(_settings_scene)


func _on_NewGameButton_pressed():
	_fader.fade_out()
	yield(_fader, "fade_out_completed")
	var err = get_tree().change_scene("res://game_screen/game_screen.tscn")
	ErrorHandler.handle(err)


func _transition_to(scene: Control) -> void:
	if _transition_target != null:
		return

	_transition_target = scene
	_fader.fade_out()
	yield(_fader, "fade_out_completed")

	for scene in _scenes:
		scene.visible = false
	scene.visible = true

	_transition_target = null
	_fader.fade_in()
