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

const BAD_SPECIALS = [
	Meeting.Special.NONE,
	Meeting.Special.NO_RESCHEDULE,
	Meeting.Special.IMPORTANT,
	#Meeting.Special.SECOND_HALF_ONLY,
	Meeting.Special.IN_ADVANCE_ONLY,
	#Meeting.Special.FIRST_HALF_ONLY
]

const GOOD_SPECIALS = [
	Meeting.Special.NONE,
	Meeting.Special.NOT_IMPORTANT,
	Meeting.Special.LEISURE,
]

static func random_special_bad(week: int) -> int:
	var rand = randi() % int(min((week + 3), BAD_SPECIALS.size()))
	return BAD_SPECIALS[rand]


static func random_special_good(week: int) -> int:
	var rand = randi() % int(min((week + 3), GOOD_SPECIALS.size()))
	return GOOD_SPECIALS[rand]


static func generate_easy(week: int) -> Meeting:
	var result = Meeting.new()
	result.special = Meeting.Special.NONE
	result.title = SIMPLE_ACTION_STRINGS.random_string_loc()# % [NAME_POOL.random_string_loc()]
	result.tint = EASY_TINT_POOL.random_color()
	match randi() % 3:
		0:
			result.duration = randi() % MAX_DURATION + 1
			result.special = random_special_bad(week)
		1:
			result.duration = randi() % MAX_DURATION + EASY_DURATION_MODIFIER
		2:
			result.duration = randi() % MAX_DURATION + MEDIUM_DURATION_MODIFIER
			result.special = random_special_good(week)

	return result


static func generate_medium(week: int) -> Meeting:
	var result = Meeting.new()
	result.title = SIMPLE_ACTION_STRINGS.random_string_loc()# % [NAME_POOL.random_string_loc()]
	result.tint = MEDIUM_TINT_POOL.random_color()
	match randi() % 3:
		0:
			result.duration = randi() % MAX_DURATION + EASY_DURATION_MODIFIER
			result.special = random_special_bad(week)
		1:
			result.duration = randi() % MAX_DURATION + MEDIUM_DURATION_MODIFIER
			result.special = Meeting.Special.NONE
		2:
			result.duration = randi() % MAX_DURATION + HARD_DURATION_MODIFIER
			result.special = random_special_good(week)

	return result


static func generate_hard(week: int) -> Meeting:
	var result = Meeting.new()
	match randi() % 2:
		0:
			result.duration = randi() % MAX_DURATION + MEDIUM_DURATION_MODIFIER
			result.special = random_special_bad(week)
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
				item = generate_easy(week_number)
			2, 4, 5, 6:
				item = generate_medium(week_number)
			_:
				item = generate_hard(week_number)
		item.special = Meeting.Special.LEISURE
		duration += item.duration
		queue.append(item)

	return queue
