extends Control

const MEETING_REQUEST_SCENE = preload("res://game_screen/meeting_request.tscn")
const DAY_COUNT = 5
const SLOT_COUNT = 18
const TOTAL_SLOT_COUNT = DAY_COUNT * SLOT_COUNT

export(float) var time_speed = 1.0 / 90.0 / 10  # % per second

onready var _gui = $"Gui"
onready var _cursor: Control = $"Cursor"
onready var _meeting_queue: Control = $"MeetingQueueMargin/MeetingQueue"
onready var _calendar: Control = $"Calendar"
onready var _week_label: Label = $"WeekLabel"
onready var _time_shroud: TimeShroud = $"TimeShroud"

var _time = 0
var _week_number = 1
var _is_dragging = false
var _current_request: MeetingRequest = null
var _pending_requests: Array = []
var _slots: Array = []

func _ready() -> void:
	_slots.resize(TOTAL_SLOT_COUNT)
	create_request()
	create_request()
	create_request()


func _process(delta):
	_time += delta * time_speed
	_time_shroud.progress = _time

	if Input.is_action_just_pressed("system_pause"):
		_gui.pause()
	
	if _is_dragging:
		_cursor.rect_global_position = _snap(get_global_mouse_position())


func create_request() -> void:
	var meeting = Meeting.new()
	meeting.title = "Meet and greet"
	meeting.duration = 3
	meeting.special = Meeting.Special.LEISURE
	
	var scene = MEETING_REQUEST_SCENE.instance()
	scene.meeting = meeting
	scene.rect_position.x += _meeting_queue.rect_size.x
	scene.rect_position.x += scene.rect_size.x * _pending_requests.size()
	scene.target_position.x = scene.rect_size.x * _pending_requests.size()
	_meeting_queue.add_child(scene)
	_pending_requests.append(scene)
	_setup_request(scene)


func place_request(request: MeetingRequest, slot: Vector2) -> void:
	if request.slot.x > 0:
		var old_index = request.slot.x * SLOT_COUNT + request.slot.y
		for i in range(request.meeting.duration):
			_slots[old_index + i] = null

	var index = slot.x * SLOT_COUNT + slot.y
	for i in range(request.meeting.duration):
		_slots[index + i] = request
	request.slot = slot

	_pending_requests.remove(_pending_requests.find(request))
	for i in range(_pending_requests.size()):
		var req = _pending_requests[i]
		req.target_position.x = req.rect_size.x * i

	request.is_static = true
	request.is_resizing = true
	request.get_parent().remove_child(request)
	_calendar.add_child(request)
	request.rect_global_position = _cursor.rect_global_position


func can_place_request(request: MeetingRequest, slot: Vector2) -> bool:
	var index = slot.x * SLOT_COUNT + slot.y

	if float(index) / TOTAL_SLOT_COUNT <= _time:
		return false

	for i in range(request.meeting.duration):
		if _slots[index + i] != null and _slots[index + i] != request:
			return false

	return true


func _drag_cursor_start(request) -> void:
	_cursor.visible = true
	_is_dragging = true
	_current_request = request
	_current_request.is_selected = true
	_cursor.meeting = request.meeting


func _drag_cursor_end(request) -> void:
	var slot_pos = _to_slot_position(_cursor.rect_position)
	if can_place_request(request, slot_pos):
		place_request(request, slot_pos)

	_current_request.is_selected = false
	_cursor.visible = false
	_is_dragging = false
	_current_request = null


func _setup_request(request: MeetingRequest):
	request.connect("gui_input", self, "_on_meeting_request_gui_input", [request])


func _snap(pos: Vector2) -> Vector2:
	if pos.y <= _calendar.rect_position.y \
		or pos.y >= _calendar.rect_position.y + _calendar.rect_size.y:
			return pos

	pos.y = floor(pos.y / 16) * 16
	pos.x = floor(pos.x / 96) * 96
	return pos


func _to_slot_position(pos: Vector2) -> Vector2:
	pos -= _calendar.rect_position
	pos.y = floor(pos.y / 16)
	pos.x = floor(pos.x / 96)
	return pos


func _on_meeting_request_gui_input(event: InputEvent, request: MeetingRequest) -> void:
	if event.is_action_pressed("action"):
		_drag_cursor_start(request)
	if event.is_action_released("action"):
		_drag_cursor_end(request)
