extends Node2D

@export var column_width := 170.0
@export var column_top_y := -450.0
@export var column_bottom_y := 450.0
@export var column_alpha := 0.16
@export var core_alpha := 0.11
@export var circle_radius := 62.0
@export var circle_alpha := 0.16
@export var pulse_speed := 2.2

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var height: float = column_bottom_y - column_top_y
	var strip_count: int = 24
	var strip_width: float = column_width / float(strip_count)

	for i in range(strip_count):
		var center_u: float = (float(i) + 0.5) / float(strip_count)
		var edge_fade: float = 1.0 - absf(center_u - 0.5) * 2.0
		var alpha: float = column_alpha * pow(edge_fade, 1.8)
		if alpha <= 0.001:
			continue
		var x: float = -column_width * 0.5 + float(i) * strip_width
		draw_rect(
			Rect2(x, column_top_y, strip_width + 1.0, height),
			Color(1.0, 1.0, 1.0, alpha),
			true
		)

	var core_width: float = column_width * 0.18
	draw_rect(
		Rect2(-core_width * 0.5, column_top_y, core_width, height),
		Color(1.0, 1.0, 1.0, core_alpha),
		true
	)

	var pulse: float = 0.5 + sin(_time * TAU * pulse_speed) * 0.5
	var center := Vector2(0.0, column_bottom_y)
	var glow_radius: float = circle_radius + pulse * 12.0

	draw_circle(center, glow_radius, Color(1.0, 1.0, 1.0, circle_alpha * 0.35))
	draw_arc(center, glow_radius, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, circle_alpha), 3.0, true)
	draw_arc(center, circle_radius * 0.68, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, circle_alpha * 0.65), 2.0, true)
