tool
class_name TimeShroud
extends Control

export(int) var sections = 5
export(float) var progress = 0.0 setget set_progress
export(Color) var color = Color.black

func _draw() -> void:
	var portion = 1.0 / sections

	for i in range(sections):
		var p = clamp((progress - i * portion) * sections, 0.0, 1.0)
		var rect = Rect2(i * rect_size.x / sections, 0, rect_size.x / sections, rect_size.y * p)
		draw_rect(rect, color)
	
	# TODO: simplify
	var last_section = floor(progress * sections)
	var remainder = progress - portion * last_section
	var p = clamp(remainder * sections, 0.0, 1.0)
	var x1 = last_section * rect_size.x / sections
	var x2 = (last_section + 1) * rect_size.x / sections 
	var y = rect_size.y * p
	draw_line(Vector2(x1, y), Vector2(x2, y), Color.red)


func set_progress(value: float) -> void:
	progress = value
	if is_inside_tree():
		update()
