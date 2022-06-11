extends Control

const MEETING_REQUEST_SCENE = preload("res://game_screen/meeting_request.tscn")

onready var _gui = $"Gui"
onready var _cursor: Control = $"Cursor"
onready var _meeting_queue: Control = $"MeetingQueue"

var _is_dragging = false
var _current_request: MeetingRequest = null

func _ready() -> void:
	create_request()


func _process(_event):
	if Input.is_action_just_pressed("system_pause"):
		_gui.pause()
	
	if _is_dragging:
		_cursor.rect_global_position = get_global_mouse_position()


func create_request() -> void:
	var scene = MEETING_REQUEST_SCENE.instance()
	scene.rect_position = Vector2(100, 0)
	_meeting_queue.add_child(scene)
	_setup_request(scene)


func _drag_cursor_start(request) -> void:
	_cursor.visible = true
	_is_dragging = true
	_current_request = request


func _drag_cursor_end(request) -> void:
	_cursor.visible = false
	_is_dragging = false
	_current_request = null


func _setup_request(request: MeetingRequest):
	request.connect("gui_input", self, "_on_meeting_request_gui_input", [request])


func _on_meeting_request_gui_input(event: InputEvent, request: MeetingRequest) -> void:
	if event.is_action_pressed("action"):
		_drag_cursor_start(request)
	if event.is_action_released("action"):
		_drag_cursor_end(request)
