class_name StringPool
extends Resource

export (Array, String) var strings = [null]
var _index = 0

func _init() -> void:
	strings.shuffle()


func random_string() -> String:
	_index = (_index + 1) % strings.size()
	if _index == 0:
		strings.shuffle()
	return strings[_index]


func random_string_loc() -> String:
	_index = (_index + 1) % strings.size()
	if _index == 0:
		strings.shuffle()
	return tr(strings[_index])
