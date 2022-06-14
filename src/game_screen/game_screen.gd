extends Control

const PLAYLIST = [
	preload("res://assets/sound/soundtrack1.ogg"),
	preload("res://assets/sound/soundtrack2.ogg")
]
const MEETING_REQUEST_SCENE = preload("res://game_screen/meeting_request.tscn")
const PICKUP_SCENE = preload("res://game_screen/pickup.tscn")

const MAX_MOOD = 100.0
const DAY_COUNT: int = 5
const SLOT_COUNT: int = 18
const TOTAL_SLOT_COUNT = DAY_COUNT * SLOT_COUNT
const MOOD_RESTORATION_RATE = 1.2 # per second
const MOOD_DECREASE_RATE = 2 # per second
const EXPIRATION_PENALTY = 15.0 # mood points

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
onready var _fader: Fader = $"Fader"
onready var _game_over: Node = $"GameOverScreen"
onready var _shaker: Shaker = $"Shaker"
onready var _dialog_popup: DialogPopup = $"DialogPopup"
onready var _soundtrack_player: AudioStreamPlayer = $"SoundtrackPlayer"
onready var _bonus_label: Label = $"BonusLabel"

var _skip_count = 0
var _cursor_offset = Vector2.ZERO
var _time = 0
var _is_time_progressing = true
var _time_speed_multiplier = 1.0
var _week_number = 1
var _is_dragging = false
var _current_request: MeetingRequest = null
var _pending_requests: Array = []
var _slots: Array = []
var _time_since_tick = 0.0
var _current_calendar = 0
var _current_day = 0
var _column_width = 96
var _row_height = 16
var _current_queue = []
var _backlog = []
var _intro_text = [
	tr("txt_intro1"),
	tr("txt_intro2"),
	tr("txt_intro3")
]
var _current_intro_text = 0
var _hints_pending = {
	"txt_hint_payday" : true,  #
	"txt_hint_weekend" : true, #
	"txt_hint_time" : true, #
	"txt_hint_expiration" : true, #
	"txt_hint_no_reschedule" : true, #
	"txt_hint_important" : true, #
	"txt_hint_important_expiration" : true, #
	"txt_hint_unimportant" : true, #
	"txt_hint_leisure" : true, #
	"txt_hint_free_time" : true, #
	"txt_hint_start" : true, #
	"txt_hint_reschedule" : true, #
	"txt_hint_in_progress" : true, #
	"txt_hint_in_advance" : true, #
}
var _dialog_queue = []
var _soundtrack_idx = 0

func _ready() -> void:
	_hud.max_mood = MAX_MOOD
	_column_width = _calendar.rect_size.x / DAY_COUNT
	_cursor.column_width = _column_width
	_cursor.row_height = _row_height
	_cursor.rect_size.x = _column_width
	_cursor.rect_size.y = _row_height
	_hud.set_current_week(_week_number)
	_slots.resize(TOTAL_SLOT_COUNT)
	_setup_pickups()
	MeetingGenerator.generate_week(_current_queue, _week_number, DAY_COUNT, SLOT_COUNT)
	create_request(_current_queue.pop_back())
	_show_intro()
	_soundtrack_player.stream = PLAYLIST[_soundtrack_idx]
	_soundtrack_player.play()


func _process(delta):
	if _is_time_progressing:
		var current_item = get_request()
				
		if current_item is Pickup:
			current_item.pick_up()

		if current_item is MeetingRequest:
			if current_item.meeting.special == Meeting.Special.LEISURE:
				_hud.mood_modifier = Hud.MoodModifier.DOUBLE_UP
				_hud.current_mood += MOOD_RESTORATION_RATE * 2 * delta * _time_speed_multiplier
			else:
				_hud.mood_modifier = Hud.MoodModifier.DOWN
				_hud.current_mood -= MOOD_DECREASE_RATE * delta * _time_speed_multiplier
				
				if _hud.current_mood <= _hud.max_mood / 2 \
					and Settings.enable_hints \
					and _hints_pending["txt_hint_free_time"]:
						_hints_pending["txt_hint_free_time"] = false
						_show_dialog(tr("txt_hint_free_time"), true, Dialog.Emotion.FROWN)
		elif _hud.current_mood < _hud.max_mood:
			_hud.mood_modifier = Hud.MoodModifier.UP
			_hud.current_mood += MOOD_RESTORATION_RATE * delta * _time_speed_multiplier
		else:
			_hud.mood_modifier = Hud.MoodModifier.NONE

		
		if _current_request != null and _current_request.slot.x >= 0 and float(_to_slot_index(_current_request.slot)) / TOTAL_SLOT_COUNT <= _time:
			_release_current_request()
			_sfx_player.stream = preload("res://assets/sound/fail2.wav")
			_sfx_player.play()

		_time += delta * time_speed * _time_speed_multiplier
		_time_shroud.progress = _time
		_time_since_tick += delta * _time_speed_multiplier

		if float(_current_day + 1) / DAY_COUNT <= _time:
			_current_day += 1

		if _time >= 1.0:
			_reset_time()
			_toggle_time(false)
			_end_week()

	if _time_since_tick >= tick_interval:
		_time_since_tick = 0.0
		if _pending_requests.empty():
			if not _backlog.empty():
				create_request(_backlog.pop_back())
			elif not _current_queue.empty():
				create_request(_current_queue.pop_back())
			else:
				$FastForwardCotainer.visible = true
		else:
			if not _current_queue.empty() and randi() % _current_queue.size() >= _pending_requests.size():
				create_request(_current_queue.pop_back())
			if not _backlog.empty() and randi() % _backlog.size() >= _pending_requests.size():
				create_request(_backlog.pop_back())

	if Input.is_action_just_pressed("system_pause"):
		_gui.pause()
	
	if _is_dragging:
		_cursor.rect_global_position = _snap(get_global_mouse_position() + _cursor_offset)
		_cursor.is_selected = not can_place_request(_current_request)


func _set_time_speed_multiplier(val: float) -> void:
	_time_speed_multiplier = val
	for req in _pending_requests:
		req.speed_multiplier = _time_speed_multiplier


func _toggle_time(val: bool) -> void:
	_is_time_progressing = val
	for req in _pending_requests:
		req.is_expiring = val


func _show_intro() -> void:
	for intro in _intro_text:
		_show_dialog(intro, false)

	if Settings.enable_hints:
		_show_dialog(tr("txt_hint_start"), true)


func get_request() -> Node:
	var index = floor(TOTAL_SLOT_COUNT * _time)
	return _slots[index]


func get_calendar() -> Control:
	return _calendars[_current_calendar % _calendars.size()]


func create_request(meeting) -> void:
	$FastForwardCotainer.visible = false
	var scene = MEETING_REQUEST_SCENE.instance()
	scene.is_expiring = true
	scene.speed_multiplier = _time_speed_multiplier
	scene.meeting = meeting
	scene.column_width = _column_width
	scene.row_height = _row_height
	scene.rect_size.x = _column_width
	scene.rect_size.y = _row_height * 2
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
	
	if Settings.enable_hints \
		and _hints_pending["txt_hint_reschedule"]:
			var request_count = 0
			var last_req
			for slot in _slots:
				if slot is MeetingRequest and last_req != slot:
					last_req = slot
					request_count += 1
				if request_count >= 3:
					_hints_pending["txt_hint_reschedule"] = false
					_show_dialog(tr("txt_hint_reschedule"), true)
					break


func can_place_request(request: MeetingRequest) -> bool:
	var cursor_pos = _cursor.rect_position + _cursor_offset
	var cal_rect = Rect2(_calendar.rect_position, _calendar.rect_size)
	var success = false
	
	if not cal_rect.has_point(cursor_pos):
		return false

	var slot_pos = _to_slot_position(_cursor.rect_position + _cursor_offset)
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
			return false # taken by a different appointment
		if (index + i) / SLOT_COUNT != lane:
			return false # not in the same lane
		if (index + i) % SLOT_COUNT == 0:
			return false # padding hours, top
		if (index + i) % SLOT_COUNT == SLOT_COUNT - 1:
			return false # padding hours, bottom

	if request.meeting.special == Meeting.Special.IN_ADVANCE_ONLY:
		var current_slot = int(_time * TOTAL_SLOT_COUNT)
		var day = current_slot / SLOT_COUNT
		var last_day_slot = (day + 1) * SLOT_COUNT
		if index <= last_day_slot:
			return false

	return true


func _reset_time() -> void:
	_time = 0.0
	_time_shroud.progress = 0.0
	_current_day = 0


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
	_sfx_player.stream = preload("res://assets/sound/week_end1.wav")
	_sfx_player.play()
	
	yield(_week_end_tween, "tween_all_completed")

	for n in prev_calendar.get_children():
		if n is MeetingRequest:
			n.queue_free()
		elif n is Pickup:
			n.queue_free()
	
	for i in range(_slots.size()):
		_slots[i] = null
	
	
	_setup_pickups()

	_week_number += 1
	_start_week()


func _start_week() -> void:
	_skip_count = 0
	_hud.skips = _skip_count
	if not _current_queue.empty():
		_backlog.append_array(_current_queue)
		_current_queue.clear()

	MeetingGenerator.generate_week(_current_queue, _week_number, DAY_COUNT, SLOT_COUNT)
	_hud.set_current_week(_week_number)
	if not _dialog_popup.visible:
		_toggle_time(true)


func _setup_pickups() -> void:
	for i in range(DAY_COUNT):
		var pickup = PICKUP_SCENE.instance() as Pickup
		pickup.is_payday = true
		pickup.is_mood_up = i == DAY_COUNT - 1
		pickup.connect("picked_up", self, "_on_pickup_picked_up")
		
		var slot = Vector2(i, SLOT_COUNT - 1)
		_slots[_to_slot_index(slot)] = pickup

		slot.x *= _column_width
		slot.y *= _row_height
		pickup.rect_position = slot
		_calendar.add_child(pickup)


func _drag_cursor_start(request: MeetingRequest) -> void:
	if not request.is_expiring:
		var index = _to_slot_index(request.slot)
		if float(index) / TOTAL_SLOT_COUNT <= _time:
			if _hints_pending["txt_hint_in_progress"] and Settings.enable_hints:
				_show_dialog(tr("txt_hint_in_progress") % [request.meeting.title], true, Dialog.Emotion.FROWN)
				_hints_pending["txt_hint_in_progress"] = false
			_sfx_player.stream = preload("res://assets/sound/fail2.wav")
			_sfx_player.play()
			return
		
		if request.is_static and request.meeting.special == Meeting.Special.NO_RESCHEDULE:
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
	if _current_request != null:
		_current_request.is_selected = false
	_cursor.visible = false
	_is_dragging = false
	_current_request = null


func _drag_cursor_end(request) -> void:
	var success = false
	if can_place_request(request):
		place_request(request, _to_slot_position(_cursor.rect_position + _cursor_offset))
		success = true
	elif _to_slot_index(_to_slot_position(_cursor.rect_position + _cursor_offset)) < _time * TOTAL_SLOT_COUNT:
		if _hints_pending["txt_hint_time"] and Settings.enable_hints:
			_hints_pending["txt_hint_time"] = false
			_show_dialog(tr("txt_hint_time") % [request.meeting.title], true, Dialog.Emotion.FROWN)
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
	request.connect("stabilised", self, "_on_meeting_request_stabilised")

func _snap(pos: Vector2) -> Vector2:
	if pos.y <= _calendar.rect_position.y \
		or pos.y >= _calendar.rect_position.y + _calendar.rect_size.y:
			return pos

	pos.y = floor(pos.y / _row_height) * _row_height
	pos.x = floor(pos.x / _column_width) * _column_width
	return pos


func _to_slot_position(pos: Vector2) -> Vector2:
	pos -= _calendar.rect_position
	pos.y = int(pos.y / _row_height)
	pos.x = int(pos.x / _column_width)
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


func _show_dialog(text: String, is_hint: bool = false, emotion: int = 0) -> void:
	if _dialog_popup.visible:
		_dialog_queue.append({
			text = text,
			is_hint = is_hint,
			emotion = emotion
		})
	else:
		_do_show_dialog(text, is_hint, emotion)


func _do_show_dialog(text: String, is_hint: bool = false, emotion: int = 0) -> void:
	_toggle_time(false)
	_dialog_popup.visible = true
	_dialog_popup.text = text
	_dialog_popup.emotion = emotion
	_dialog_popup.show_disable_hints = is_hint


func _on_meeting_request_gui_input(event: InputEvent, request: MeetingRequest) -> void:
	if event.is_action_pressed("action"):
		_drag_cursor_start(request)
	elif _is_dragging and event.is_action_released("action"):
		_drag_cursor_end(request)


func _on_meeting_request_expired(request: MeetingRequest) -> void:
	if _cursor.meeting == request.meeting:
		_release_current_request()
	_remove_from_pending(request)

	match request.meeting.special:
		Meeting.Special.IMPORTANT:
			_hud.current_mood -= EXPIRATION_PENALTY * max(3, _skip_count)
			_skip_count += 1
			_hud.shake_mood_meter()
			if Settings.enable_screenshake:
				_shaker.shake_horizontal(self, "rect_position", 8, 8)
		Meeting.Special.NOT_IMPORTANT, Meeting.Special.LEISURE:
			_skip_count += 1
		_:
			_hud.current_mood -= EXPIRATION_PENALTY * _skip_count / 2.0
			if _skip_count > 0:
				_hud.shake_mood_meter()
				if Settings.enable_screenshake:
					_shaker.shake_horizontal(self, "rect_position", 4, 4)
			_skip_count += 1
	_hud.skips = _skip_count

	if request.meeting.special == Meeting.Special.IMPORTANT and _hints_pending["txt_hint_important_expiration"] and Settings.enable_hints:
		_show_dialog(tr("txt_hint_important_expiration") % [request.meeting.title], true, Dialog.Emotion.YELL)
		_hints_pending["txt_hint_important_expiration"] = false
	elif request.meeting.special != Meeting.Special.NOT_IMPORTANT \
		and request.meeting.special != Meeting.Special.LEISURE \
		and _hints_pending["txt_hint_expiration"] and Settings.enable_hints:
		_show_dialog(tr("txt_hint_expiration") % [request.meeting.title], true, Dialog.Emotion.FROWN)
		_hints_pending["txt_hint_expiration"] = false


func _on_meeting_request_stabilised(request: MeetingRequest) -> void:
	if request.meeting.special == Meeting.Special.IN_ADVANCE_ONLY:
		if _hints_pending["txt_hint_in_advance"] and Settings.enable_hints:
			_show_dialog(tr("txt_hint_in_advance") % [request.meeting.title], true, Dialog.Emotion.NORMAL)
			_hints_pending["txt_hint_in_advance"] = false
	
	if request.meeting.special == Meeting.Special.NO_RESCHEDULE:
		if _hints_pending["txt_hint_no_reschedule"] and Settings.enable_hints:
			_show_dialog(tr("txt_hint_no_reschedule") % [request.meeting.title], true, Dialog.Emotion.NORMAL)
			_hints_pending["txt_hint_no_reschedule"] = false
	
	if request.meeting.special == Meeting.Special.IMPORTANT:
		if _hints_pending["txt_hint_important"] and Settings.enable_hints:
			_show_dialog(tr("txt_hint_important") % [request.meeting.title], true, Dialog.Emotion.FROWN)
			_hints_pending["txt_hint_important"] = false
	
	if request.meeting.special == Meeting.Special.LEISURE:
		if _hints_pending["txt_hint_leisure"] and Settings.enable_hints:
			_show_dialog(tr("txt_hint_leisure") % [request.meeting.title], true, Dialog.Emotion.SMILE)
			_hints_pending["txt_hint_leisure"] = false
	
	if request.meeting.special == Meeting.Special.NOT_IMPORTANT:
		if _hints_pending["txt_hint_unimportant"] and Settings.enable_hints:
			_show_dialog(tr("txt_hint_unimportant") % [request.meeting.title], true, Dialog.Emotion.SMILE)
			_hints_pending["txt_hint_unimportant"] = false


func _on_pickup_picked_up(sender: Pickup):
	if sender.is_payday:
		if _hints_pending["txt_hint_payday"] and Settings.enable_hints:
			_show_dialog(tr("txt_hint_payday"), true, Dialog.Emotion.SMILE)
			_hints_pending["txt_hint_payday"] = false

		var point_count = 10.0 * _hud.current_mood / _hud.max_mood
		var bonus = int(_hud.current_mood / _hud.max_mood * 100)
		_bonus_label.show_at(tr("ui_bonus") % [point_count, bonus], sender.rect_global_position)
		_hud.current_score += point_count

	if sender.is_mood_up:
		if _hints_pending["txt_hint_weekend"] and Settings.enable_hints:
			_show_dialog(tr("txt_hint_weekend"), true, Dialog.Emotion.SMILE)
			_hints_pending["txt_hint_weekend"] = false
		_hud.current_mood *= 1.3


func _on_Hud_mood_ran_out() -> void:
	_toggle_time(false)
	_soundtrack_player.stop()
	_sfx_player.stream = preload("res://assets/sound/lose1.wav")
	_sfx_player.play()
	
	if Settings.enable_screenshake:
		_shaker.shake_horizontal(self, "rect_position", 8, 8)
	
	_hud.shake_mood_meter()
	_game_over.show_game_over(_week_number, _hud.current_score)


func _on_DialogPopup_disable_hints_pressed() -> void:
	_toggle_time(true)
	_dialog_popup.visible = false
	Settings.enable_hints = false
	Settings.save_settings()


func _on_DialogPopup_ok_pressed() -> void:
	_toggle_time(true)
	_dialog_popup.visible = false
	
	if not _dialog_queue.empty():
		var d = _dialog_queue.pop_front()
		_do_show_dialog(d.text, d.is_hint, d.emotion)


func _on_AnimationPlayer_ready() -> void:
	$FastForwardCotainer/AnimationPlayer.play("end_week_float")


func _on_FastForwardButton_button_down() -> void:
	_set_time_speed_multiplier(8.0)


func _on_FastForwardButton_button_up() -> void:
	_set_time_speed_multiplier(1.0)


func _on_SoundtrackPlayer_finished() -> void:
	_soundtrack_idx = (_soundtrack_idx + 1) % PLAYLIST.size()
	_soundtrack_player.stream = PLAYLIST[_soundtrack_idx]
	_soundtrack_player.play()
