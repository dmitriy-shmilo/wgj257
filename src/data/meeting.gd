class_name Meeting
extends Resource

const SHORT_TITLE_LENGTH = 20

enum Special {
	NONE,
	IMPORTANT,
	NO_RESCHEDULE,
	IN_ADVANCE_ONLY,
	LEISURE,
	NOT_IMPORTANT,
}

const SPECIAL_TEXTURE_MAP = {
	Special.NONE: null,
	Special.NO_RESCHEDULE: preload("res://assets/texture/icon_lock.tres"),
	Special.IN_ADVANCE_ONLY: preload("res://assets/texture/icon_advance.tres"),
	Special.NOT_IMPORTANT: preload("res://assets/texture/icon_unimportant.tres"),
	Special.IMPORTANT: preload("res://assets/texture/icon_important.tres"),
	Special.LEISURE: preload("res://assets/texture/icon_leisure.tres"),
}

export(String) var title = "Title"
export(int) var duration = 2
export(Special) var special = Special.NONE
export(Color) var tint = Color.white
export(float) var expiration_time = 20.0

func get_short_title() -> String:
	if title.length() > SHORT_TITLE_LENGTH:
		return title.substr(0, SHORT_TITLE_LENGTH - 3) + "..."
	return title


func get_duration_string() -> String:
	match duration:
		0, 1:
			return "30min"
		_:
			if duration % 2 == 0:
				return str(duration / 2) + "hr"
			else:
				return str(duration / 2) + ".5hr"


func get_icon() -> Texture:
	return SPECIAL_TEXTURE_MAP[special]

