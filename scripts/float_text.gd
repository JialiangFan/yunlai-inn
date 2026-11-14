extends Node2D
## 飘字：收钱、客人评价之类的提示，往上飘一会儿就消失。

const LIFE := 1.6

var font: Font
var text := ""
var color := Color.WHITE
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	position.y -= 26.0 * delta
	modulate.a = clampf(1.0 - t / LIFE, 0.0, 1.0)
	if t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var p := Vector2(-w / 2.0, 0)
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.7))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
