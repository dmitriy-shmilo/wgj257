tool
extends Control

export(float) var lane_width = 96
export(float) var slot_height = 16
export(float) var lane_count = 5
export(float) var slot_count = 18
export(Color) var lane_delimeter_color = Color.black
export(Color) var slot_delimeter_color = Color.black
export(Color) var slot_alt_delimeter_color = Color.black
export(Color) var background_color = Color.white
export(Color) var reserve_background_color = Color.orange

func _draw() -> void:
	
	draw_rect(Rect2(Vector2.ZERO, rect_size), background_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(rect_size.x, slot_height)), reserve_background_color)
	draw_rect(Rect2(Vector2(0, rect_size.y - slot_height + 1), Vector2(rect_size.x, slot_height)), reserve_background_color)
	
	for lane in range(lane_count):
		draw_line( \
			Vector2(lane_width * lane, 0), \
			Vector2(lane_width * lane, rect_size.y), \
			lane_delimeter_color)
		for slot in range(1, slot_count):
			draw_line( \
				Vector2(lane_width * lane, slot * slot_height), \
				Vector2(lane_width * (lane + 1), slot * slot_height), \
				slot_alt_delimeter_color if slot % 2 == 0 else slot_delimeter_color)
