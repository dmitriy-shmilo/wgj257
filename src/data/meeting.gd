class_name Meeting
extends Resource

const SHORT_TITLE_LENGTH = 14

enum Special {
	NONE,
	NO_RESCHEDULE,
	IMPORTANT,
	LEISURE
}

const SPECIAL_TEXTURE_MAP = {
	Special.NONE: null,
	Special.NO_RESCHEDULE: preload("res://assets/texture/icon_lock.tres"),
	Special.IMPORTANT: preload("res://assets/texture/icon_warning.tres"),
	Special.LEISURE: preload("res://assets/texture/icon_heart.tres"),
}

export(String) var title = "Title"
export(int) var duration = 2
export(Special) var special = Special.NONE
export(Color) var tint = Color.white

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
