class_name MeetingGenerator
extends Reference

const MAX_DURATION = 2
const EASY_DURATION_MODIFIER = 2
const MEDIUM_DURATION_MODIFIER = 4
const HARD_DURATION_MODIFIER = 6

const MEETING_TITLE_POOL: StringPool = preload("res://data/meeting_title_pool.tres")
const NO_RESCHEDULE_MEETING_TITLE_POOL: StringPool = preload("res://data/meeting_no_reschedule_title_pool.tres")
const IMPORTANT_MEETING_TITLE_POOL: StringPool = preload("res://data/meeting_important_title_pool.tres")
const IN_ADVANCE_ONLY_MEETING_TITLE_POOL: StringPool = preload("res://data/meeting_advance_title_pool.tres")
const NOT_IMPORTANT_MEETING_TITLE_POOL: StringPool = preload("res://data/meeting_unimportant_title_pool.tres")
const LEISURE_MEETING_TITLE_POOL: StringPool = preload("res://data/meeting_leisure_title_pool.tres")

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
	var rand = randi() % int(min(week + 1, BAD_SPECIALS.size()))
	return BAD_SPECIALS[rand]


static func random_special_good(week: int) -> int:
	var rand = randi() % int(min(week + 1, GOOD_SPECIALS.size()))
	return GOOD_SPECIALS[rand]


static func generate_easy(week: int) -> Meeting:
	var result = Meeting.new()
	result.special = Meeting.Special.NONE
	result.tint = EASY_TINT_POOL.random_color()
	match randi() % 3:
		0:
			result.duration = randi() % MAX_DURATION + 1
		1:
			result.duration = randi() % MAX_DURATION + EASY_DURATION_MODIFIER
			result.special = random_special_bad(week)
		2:
			result.duration = randi() % MAX_DURATION + MEDIUM_DURATION_MODIFIER
			result.special = random_special_good(week)

	return result


static func generate_medium(week: int) -> Meeting:
	var result = Meeting.new()
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
			result.tint = MEDIUM_TINT_POOL.random_color()
		1:
			result.duration = randi() % MAX_DURATION + HARD_DURATION_MODIFIER
			result.special = Meeting.Special.NONE
			result.tint = MEDIUM_TINT_POOL.random_color()
	return result


static func generate_week(queue: Array, week_number: int, day_count: int, slots_per_day: int) -> Array:
	var max_duration = day_count * slots_per_day / 2 + min(week_number / 2, slots_per_day) - day_count * 2
	var duration = 0
	
	var specials = {}
	
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
		
		if item.special != Meeting.Special.NONE:
			var count = specials.get(item.special, 0) + 1
			specials[item.special] = count
			if count > min(week_number / 2 + 1, 3):
				continue

		match item.special:
			Meeting.Special.IMPORTANT:
				item.title = IMPORTANT_MEETING_TITLE_POOL.random_string_loc()
			Meeting.Special.NOT_IMPORTANT:
				item.title = NOT_IMPORTANT_MEETING_TITLE_POOL.random_string_loc()
			Meeting.Special.NO_RESCHEDULE:
				item.title = NO_RESCHEDULE_MEETING_TITLE_POOL.random_string_loc()
			Meeting.Special.IN_ADVANCE_ONLY:
				item.title = IN_ADVANCE_ONLY_MEETING_TITLE_POOL.random_string_loc()
			Meeting.Special.LEISURE:
				item.title = LEISURE_MEETING_TITLE_POOL.random_string_loc()
			_:
				item.title = MEETING_TITLE_POOL.random_string_loc()

		duration += item.duration
		queue.append(item)

	return queue
