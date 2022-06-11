class_name StringPool
extends Resource

export (Array, String) var strings = [null]


func random_string() -> String:
	return strings[randi() % strings.size()]


func random_string_loc() -> String:
	return tr(strings[randi() % strings.size()])
