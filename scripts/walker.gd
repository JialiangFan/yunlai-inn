extends Node2D
## 会走路的小人（顾客、跑堂、厨师）的共用部分：沿走道一段段走，以及画身体。

const SKIN := Color("f1c9a0")
const HAIR := Color("2a1d14")

var main
var speed := 120.0
var path: Array = []
var facing := 1.0  # 1 朝右，-1 朝左（图片左右翻转）
var walk_phase := 0.0  # 走路的步子相位，走起来才涨


func walk_to(dest: Vector2) -> void:
	path = main.route(position, dest)


## 每帧调用，走到终点时返回 true。
func step_walk(delta: float) -> bool:
	var remaining := speed * delta
	while remaining > 0.0 and not path.is_empty():
		var p: Vector2 = path[0]
		var dist := position.distance_to(p)
		if absf(p.x - position.x) > 1.0:
			facing = signf(p.x - position.x)
		walk_phase += minf(dist, remaining) / 14.0  # 大约每 14 像素迈一步
		if dist <= remaining:
			position = p
			remaining -= dist
			path.pop_front()
		else:
			position = position.move_toward(p, remaining)
			remaining = 0.0
	return path.is_empty()


func is_walking() -> bool:
	return not path.is_empty()


func disc(p: Vector2, r: float, c: Color) -> void:
	draw_circle(p, r, c, true, -1.0, true)


## 用图片画小人：脚底对准站位，按高度等比缩放。没有图返回 false。
func draw_sprite(o: Vector2, t: Texture2D, height := 58.0) -> bool:
	if t == null:
		return false
	var sz := t.get_size()
	var w := sz.x * height / sz.y
	var step := sin(walk_phase * PI) if is_walking() else 0.0  # 左右脚交替
	ellipse(Vector2(0, 14), 13.0 - absf(step) * 2.0, 4.5, Color(0, 0, 0, 0.22))
	if is_walking():  # 脚下扬起一点尘土
		var dust := fmod(walk_phase, 1.0)
		disc(Vector2(-facing * (6.0 + dust * 8.0), 13.0 - dust * 4.0), 2.0 + dust * 2.0, Color(0.8, 0.7, 0.55, 0.35 * (1.0 - dust)))
	# 以脚底为轴：走路时身体左右摇摆、一颠一颠，朝哪边走就翻向哪边
	var lift := absf(step) * 3.0
	draw_set_transform(o + Vector2(0, 15.0 - lift), step * 0.08, Vector2(facing, 1.0))
	draw_texture_rect(t, Rect2(Vector2(-w / 2.0, -height), Vector2(w, height)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
	disc(Vector2.ZERO, rx, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 画一个古装小人：影子、鞋、交领长袍、腰带、衣袖、手、头发和五官。
func draw_body(o: Vector2, robe: Color, bun := true, sash := Color(0, 0, 0, 0)) -> void:
	var line := robe.darkened(0.55)
	var shade := robe.darkened(0.22)
	# 影子
	ellipse(Vector2(0, 14), 13.0, 4.5, Color(0, 0, 0, 0.22))
	# 鞋
	ellipse(o + Vector2(-4.5, 12.5), 3.2, 2.0, Color("2a1d14"))
	ellipse(o + Vector2(4.5, 12.5), 3.2, 2.0, Color("2a1d14"))
	# 长袍（上窄下宽），右半边加暗面
	var robe_pts := PackedVector2Array([o + Vector2(-8, -8), o + Vector2(8, -8), o + Vector2(12.5, 11), o + Vector2(-12.5, 11)])
	draw_colored_polygon(robe_pts, robe)
	draw_colored_polygon(PackedVector2Array([o + Vector2(2, -8), o + Vector2(8, -8), o + Vector2(12.5, 11), o + Vector2(3, 11)]), shade)
	robe_pts.append(robe_pts[0])
	draw_polyline(robe_pts, line, 1.2, true)
	# 交领
	draw_line(o + Vector2(-5, -8), o + Vector2(3, 1), robe.lightened(0.55), 2.0, true)
	draw_line(o + Vector2(5, -8), o + Vector2(0, -2), robe.lightened(0.35), 1.5, true)
	# 腰带
	draw_rect(Rect2(o + Vector2(-10, 0), Vector2(20, 3)), sash if sash.a > 0.0 else line)
	if sash.a > 0.0:  # 腰带垂下的穗子
		draw_line(o + Vector2(4, 3), o + Vector2(5, 9), sash, 2.0, true)
	# 衣袖和手
	for sx in [-1.0, 1.0]:
		ellipse(o + Vector2(10.5 * sx, -1), 4.2, 6.0, shade if sx > 0 else robe)
		draw_arc(o + Vector2(10.5 * sx, -1), 4.2, 0.0, TAU, 16, line, 1.0, true)
		disc(o + Vector2(10.5 * sx, 5), 2.4, SKIN)
	# 头：发髻、脸、头发、五官
	if bun:
		disc(o + Vector2(0, -25), 3.6, HAIR)
	disc(o + Vector2(0, -16), 8.6, line.darkened(0.3))
	disc(o + Vector2(0, -16), 7.8, SKIN)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-7.8, -16), o + Vector2(-6, -22), o + Vector2(0, -24.5), o + Vector2(6, -22), o + Vector2(7.8, -16), o + Vector2(4, -19.5), o + Vector2(-4, -19.5)]), HAIR)
	ellipse(o + Vector2(-2.8, -14.5), 1.0, 1.4, HAIR)
	ellipse(o + Vector2(2.8, -14.5), 1.0, 1.4, HAIR)
	disc(o + Vector2(-4.5, -12), 1.6, Color(0.95, 0.5, 0.45, 0.35))
	disc(o + Vector2(4.5, -12), 1.6, Color(0.95, 0.5, 0.45, 0.35))
	draw_line(o + Vector2(-1.2, -10.5), o + Vector2(1.2, -10.5), Color("b0604a"), 1.0, true)
