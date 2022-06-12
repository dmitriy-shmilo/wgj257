extends Control

const MEETING_REQUEST_SCENE = preload("res://game_screen/meeting_request.tscn")
const DAY_COUNT: int = 5
const SLOT_COUNT: int = 18
const TOTAL_SLOT_COUNT = DAY_COUNT * SLOT_COUNT
const MOOD_RESTORATION_RATE = 1.0 # per second
const MOOD_DECREASE_RATE = 1.0 # per second

export(float) var time_speed = 1.0 / TOTAL_SLOT_COUNT / 2.0 # % per second
export(float) var tick_interval = 1.0 # seconds

onready var _gui = $"Gui"
onready var _cursor: Control = $"Cursor"
onready var _meeting_queue: Control = $"MeetingQueueMargin/MeetingQueue"
onready var _calendars: Array = [$"Calendar", $"Calendar2"]
onready var _time_shroud: TimeShroud = $"TimeShroud"
onready var _sfx_player: AudioStreamPlayer = $"SfxPlayer"
onready var _calendar: Control = _calendars[0]
onready var _week_end_tween: Tween = $"WeekEndTween"
onready var _hud: Hud = $"Top/Hud"

var _time = 0
var _is_time_progressing = true
var _week_number = 1
var _is_dragging = false
var _current_request: MeetingRequest = null
var _pending_requests: Array = []
var _slots: Array = []
var _time_since_tick = 0.0
var _current_calendar = 0
var _current_day = 0


func _ready() -> void:
	_hud.set_current_week(_week_number)
	_slots.resize(TOTAL_SLOT_COUNT)
	create_request()


func _process(delta):
	# TODO: for testing, remove later
	if Input.is_action_pressed("right"):
		time_speed = 0.2
	else:
		time_speed = 1.0 / TOTAL_SLOT_COUNT / 2.0

	if _is_time_progressing:
		if get_request() != null:
			_hud.mood_modifier = Hud.MoodModifier.DOWN
			_hud.current_mood -= MOOD_DECREASE_RATE * delta
		elif _hud.current_mood < _hud.max_mood:
			_hud.mood_modifier = Hud.MoodModifier.UP
			_hud.current_mood += MOOD_RESTORATION_RATE * delta
		else:
			_hud.mood_modifier = Hud.MoodModifier.NONE

		if _current_request != null and _current_request.slot.x >= 0 and float(_to_slot_index(_current_request.slot)) / TOTAL_SLOT_COUNT <= _time:
			_release_current_request()
			_sfx_player.stream = preload("res://assets/sound/fail2.wav")
			_sfx_player.play()

		_time += delta * time_speed
		_time_shroud.progress = _time
		_time_since_tick += delta

		if float(_current_day + 1) / DAY_COUNT <= _time:
			_current_day += 1
			_end_day()

		if _time >= 1.0:
			_reset_time()
			_is_time_progressing = false
			_end_week()

	if _time_since_tick >= tick_interval:
		_time_since_tick = 0.0
		if randi() % 5 >= _pending_requests.size():
			create_request()

	if Input.is_action_just_pressed("system_pause"):
		_gui.pause()
	
	if _is_dragging:
		_cursor.rect_global_position = _snap(get_global_mouse_position())
		

func get_request() -> MeetingRequest:
	var index = floor(TOTAL_SLOT_COUNT * _time)
	return _slots[index]


func get_calendar() -> Control:
	return _calendars[_current_calendar % _calendars.size()]


func create_request() -> void:
	var meeting
	# TODO: adjust difficulty as weeks progress
	# TODO: pre-generate meetings based on total time
	match randi() % 10:
		0:
			meeting = MeetingGenerator.generate_hard()
		1,2:
			meeting = MeetingGenerator.generate_medium()
		_:
			meeting = MeetingGenerator.generate_easy()
	var scene = MEETING_REQUEST_SCENE.instance()
	scene.is_expiring = true
	scene.meeting = meeting
	scene.rect_position.x += _meeting_queue.rect_size.x
	scene.rect_position.x += scene.rect_size.x * _pending_requests.size()
	scene.target_position.x = scene.rect_size.x * _pending_requests.size()
	_setup_request(scene)


func place_request(request: MeetingRequest, slot: Vector2) -> void:
	if request.slot.x >= 0:
		var old_index = _to_slot_index(request.slot)
		for i in range(request.meeting.duration):
			_slots[old_index + i] = null

	var index = _to_slot_index(slot)
	for i in range(request.meeting.duration):
		_slots[index + i] = request
	request.slot = slot

	_remove_from_pending(request)

	request.is_static = true
	request.is_resizing = true
	request.is_expiring = false
	request.is_expiration_visible = false
	request.get_parent().remove_child(request)
	_calendar.add_child(request)
	request.rect_global_position = _cursor.rect_global_position


func can_place_request(request: MeetingRequest) -> bool:
	var cursor_pos = _cursor.rect_position
	var cal_rect = Rect2(_calendar.rect_position, _calendar.rect_size)
	var success = false
	
	if not cal_rect.has_point(cursor_pos):
		return false

	var slot_pos = _to_slot_position(_cursor.rect_position)
	var index = _to_slot_index(slot_pos)
	var lane = index / SLOT_COUNT

	if request.slot.x >= 0 and float(_to_slot_index(request.slot)) / TOTAL_SLOT_COUNT <= _time:
		return false
	if float(index) / TOTAL_SLOT_COUNT <= _time:
		return false
	if index + request.meeting.duration >= _slots.size():
		return false

	for i in range(request.meeting.duration):
		if _slots[index + i] != null and _slots[index + i] != request:
			return false
		if (index + i) / SLOT_COUNT != lane:
			return false

	return true


func _reset_time() -> void:
	_time = 0.0
	_time_shroud.progress = 0.0
	_current_day = 0


func _end_day() -> void:
	_hud.current_mood += _hud.max_mood / DAY_COUNT
	_hud.current_score += 5


func _end_week() -> void:
	for req in _pending_requests:
		req.is_expiring = false

	var prev_calendar = get_calendar()
	_current_calendar = (_current_calendar + 1) % _calendars.size()
	_calendar = get_calendar()
	
	_calendar.rect_position.x = rect_size.x
	_week_end_tween \
		.interpolate_property(prev_calendar, \
			"rect_position", \
			prev_calendar.rect_position, \
			Vector2(-prev_calendar.rect_size.x, \
			 	prev_calendar.rect_position.y), \
			0.75, Tween.TRANS_BACK)
	_week_end_tween \
		.interpolate_property(_calendar, \
			"rect_position", \
			_calendar.rect_position, \
			Vector2(0, \
			 	_calendar.rect_position.y), \
			0.75, Tween.TRANS_BACK)
	_week_end_tween.start()
	
	yield(_week_end_tween, "tween_all_completed")

	for n in prev_calendar.get_children():
		n.queue_free()
	
	for i in range(_slots.size()):
		_slots[i] = null
	
	for req in _pending_requests:
		req.is_expiring = true

	_week_number += 1
	_start_week()


func _start_week() -> void:
	_hud.set_current_week(_week_number)
	_is_time_progressing = true


func _drag_cursor_start(request: MeetingRequest) -> void:
	if not request.is_expiring:
		var index = _to_slot_index(request.slot)
		if float(index) / TOTAL_SLOT_COUNT <= _time:
			_sfx_player.stream = preload("res://assets/sound/fail2.wav")
			_sfx_player.play()
			return

	_cursor.visible = true
	_is_dragging = true
	_current_request = request
	_current_request.is_selected = true
	_cursor.meeting = request.meeting
	
	_sfx_player.stream = preload("res://assets/sound/take1.wav")
	_sfx_player.play()

func _release_current_request() -> void:
	_current_request.is_selected = false
	_cursor.visible = false
	_is_dragging = false
	_current_request = null


func _drag_cursor_end(request) -> void:
	var success = false
	if can_place_request(request):
		place_request(request, _to_slot_position(_cursor.rect_position))
		success = true

	_release_current_request()

	if success:
		_sfx_player.stream = preload("res://assets/sound/put1.wav")
	else:
		_sfx_player.stream = preload("res://assets/sound/fail1.wav")
	_sfx_player.play()


func _setup_request(request: MeetingRequest):
	_meeting_queue.add_child(request)
	_pending_requests.append(request)
	request.connect("gui_input", self, "_on_meeting_request_gui_input", [request])
	request.connect("expired", self, "_on_meeting_request_expired")


func _snap(pos: Vector2) -> Vector2:
	if pos.y <= _calendar.rect_position.y \
		or pos.y >= _calendar.rect_position.y + _calendar.rect_size.y:
			return pos

	pos.y = floor(pos.y / 16) * 16
	pos.x = floor(pos.x / 96) * 96
	return pos


func _to_slot_position(pos: Vector2) -> Vector2:
	pos -= _calendar.rect_position
	pos.y = int(pos.y / 16)
	pos.x = int(pos.x / 96)
	return pos


func _to_slot_index(slot_pos: Vector2) -> int:
	return int(slot_pos.x * SLOT_COUNT) + int(slot_pos.y)


func _remove_from_pending(request: MeetingRequest) -> void:
	var index = _pending_requests.find(request)
	if index < 0:
		return
	_pending_requests.remove(index)
	for i in range(_pending_requests.size()):
		var req = _pending_requests[i]
		req.target_position.x = req.rect_size.x * i


func _on_meeting_request_gui_input(event: InputEvent, request: MeetingRequest) -> void:
	if event.is_action_pressed("action"):
		_drag_cursor_start(request)
	elif _is_dragging and event.is_action_released("action"):
		_drag_cursor_end(request)


func _on_meeting_request_expired(request: MeetingRequest) -> void:
	if _cursor.meeting == request.meeting:
		_release_current_request()

	_remove_from_pending(request)

