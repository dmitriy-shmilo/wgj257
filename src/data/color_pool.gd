class_name ColorPool
extends Resource

export(Array, Color) var colors = []


func random_color() -> Color:
	return colors[randi() % colors.size()]
