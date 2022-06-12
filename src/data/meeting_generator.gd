class_name MeetingGenerator
extends Reference

const MAX_DURATION = 2
const EASY_DURATION_MODIFIER = 2
const MEDIUM_DURATION_MODIFIER = 4
const HARD_DURATION_MODIFIER = 6

const SIMPLE_ACTION_STRINGS: StringPool = preload("res://data/simple_action_pool.tres")
const NAME_POOL: StringPool = preload("res://data/name_pool.tres")

const EASY_TINT_POOL: ColorPool = preload("res://data/easy_meeting_tints.tres")
const MEDIUM_TINT_POOL: ColorPool = preload("res://data/medium_meeting_tints.tres")
const HARD_TINT_POOL: ColorPool = preload("res://data/hard_meeting_tints.tres")


static func random_special_bad() -> int:
	return Meeting.Special.NO_RESCHEDULE


static func random_special_good() -> int:
	return Meeting.Special.LEISURE


static func generate_easy() -> Meeting:
	var result = Meeting.new()
	result.special = Meeting.Special.NONE
	result.title = SIMPLE_ACTION_STRINGS.random_string_loc()# % [NAME_POOL.random_string_loc()]
	result.tint = EASY_TINT_POOL.random_color()
	match randi() % 2:
		0:
			result.duration = randi() % MAX_DURATION + 1
			result.special = random_special_bad()
		1:
			result.duration = randi() % MAX_DURATION + EASY_DURATION_MODIFIER
		2:
			result.duration = randi() % MAX_DURATION + MEDIUM_DURATION_MODIFIER
			result.special = random_special_good()

	return result


static func generate_medium() -> Meeting:
	var result = Meeting.new()
	result.title = SIMPLE_ACTION_STRINGS.random_string_loc()# % [NAME_POOL.random_string_loc()]
	result.tint = MEDIUM_TINT_POOL.random_color()
	match randi() % 2:
		0:
			result.duration = randi() % MAX_DURATION + EASY_DURATION_MODIFIER
			result.special = random_special_bad()
		1:
			result.duration = randi() % MAX_DURATION + MEDIUM_DURATION_MODIFIER
			result.special = Meeting.Special.NONE
		2:
			result.duration = randi() % MAX_DURATION + HARD_DURATION_MODIFIER
			result.special = random_special_good()

	return result


static func generate_hard() -> Meeting:
	var result = Meeting.new()
	match randi() % 2:
		0:
			result.duration = randi() % MAX_DURATION + MEDIUM_DURATION_MODIFIER
			result.special = random_special_bad()
			result.title = SIMPLE_ACTION_STRINGS.random_string_loc()# % [NAME_POOL.random_string_loc()]
			result.tint = MEDIUM_TINT_POOL.random_color()
		1:
			result.duration = randi() % MAX_DURATION + HARD_DURATION_MODIFIER
			result.special = Meeting.Special.NONE
			result.title = SIMPLE_ACTION_STRINGS.random_string_loc()# % [NAME_POOL.random_string_loc()]
			result.tint = MEDIUM_TINT_POOL.random_color()
	return result


static func generate_week(queue: Array, week_number: int, day_count: int, slots_per_day: int) -> Array:
	var max_duration = day_count * slots_per_day / 2 + min(week_number / 2, slots_per_day) - day_count * 2
	var duration = 0
	
	while duration <= max_duration:
		var item
		var rand = randi() % 10 - min(week_number / 2, 7)
		match rand:
			1, 7, 8, 9:
				item = generate_easy()
			2, 4, 5, 6:
				item = generate_medium()
			_:
				item = generate_hard()
		
		duration += item.duration
		queue.append(item)

	return queue
