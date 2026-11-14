extends "res://scripts/walker.gd"
## 伙计：按职位干活——掌柜在柜台收钱，厨师守灶做菜，跑堂点菜上菜，杂役收拾桌子。
## 能力值影响干活快慢，毅力低的会偷懒。

const Data = preload("res://scripts/data.gd")
const SLACK_TIME := 4.0

var info: Dictionary  # {"name", "role", "stats": {能力: 数值}, "wage"}
var home := Vector2.ZERO
var steps: Array = []  # 每一步：{"move": 位置} 或 {"wait": 秒数, "do": 回调}
var wait_timer := 0.0
var carrying := ""  # 端着的菜的颜色
var order_slip = null  # 记下了、还没交给后厨的菜单
var order = null  # 厨师正在做的菜
var cook_timer := 0.0
var cook_total := 1.0
var pay_target = null  # 掌柜正在给结账的客人
var pay_timer := 0.0
var pay_total := 1.0
var slack_timer := 0.0
var anim := 0.0


func role() -> String:
	return info.role


func stat(s: String) -> int:
	return int(info.stats[s])


## 能力值换成效率倍率：50 点是 1 倍，99 点约 1.5 倍。
func skill_mult(s: String) -> float:
	return 0.5 + stat(s) / 100.0


func apply_role_speed() -> void:
	match info.role:
		"跑堂":
			speed = 110.0 + stat("技巧") * 0.9
		"杂役":
			speed = 100.0 + stat("反应") * 0.6
		_:
			speed = 120.0


func reset_work() -> void:
	steps.clear()
	path.clear()
	carrying = ""
	order_slip = null
	order = null
	pay_target = null
	wait_timer = 0.0
	slack_timer = 0.0
	position = home


func _process(delta: float) -> void:
	anim += delta
	if delta > 0.0 and not main.is_rest_day:
		if slack_timer > 0.0:
			slack_timer -= delta
		else:
			_maybe_slack(delta)
			match info.role:
				"厨师":
					_cook(delta)
				"掌柜":
					_cashier(delta)
				_:
					_serve_tasks(delta)
	queue_redraw()


func _maybe_slack(delta: float) -> void:
	if info.get("trait", "") == "勤快":
		return
	var chance := (100 - stat("毅力")) / 100.0 * 0.008 * delta
	if randf() < chance:
		slack_timer = SLACK_TIME
		main.on_staff_slack(self)


func _cook(delta: float) -> void:
	position = home
	if order == null:
		order = main.next_kitchen_order()
		if order != null:
			cook_total = float(order.dish.cook) / (skill_mult("厨艺") * main.stove_speed())
			cook_timer = cook_total
			main.sfx.play("chop", -3.0)  # 先切菜再下锅
	else:
		cook_timer -= delta
		if cook_timer <= 0.0:
			main.dish_ready(order)
			order = null


func _cashier(delta: float) -> void:
	position = home
	if pay_target == null:
		pay_target = main.next_payer()
		if pay_target != null:
			pay_total = 2.5 / skill_mult("计算")
			pay_timer = pay_total
	elif not is_instance_valid(pay_target):
		pay_target = null
	else:
		pay_timer -= delta
		if pay_timer <= 0.0:
			main.finish_payment(pay_target)
			pay_target = null


func _serve_tasks(delta: float) -> void:
	if steps.is_empty():
		var task = main.claim_task(self)
		if task != null:
			steps = main.build_steps(self, task)
		elif position.distance_to(home) > 1.0:
			if path.is_empty():
				walk_to(home)
			step_walk(delta)
	if not steps.is_empty():
		_run_step(delta)


func _run_step(delta: float) -> void:
	var s: Dictionary = steps[0]
	if s.has("move"):
		if not s.has("started"):
			s["started"] = true
			walk_to(s["move"])
		if step_walk(delta):
			steps.pop_front()
	else:
		wait_timer += delta
		if wait_timer >= _step_time(s):
			wait_timer = 0.0
			steps.pop_front()
			var ok: bool = s["do"].call()
			if not ok:
				steps.clear()
				carrying = ""
				order_slip = null


func _step_time(s: Dictionary) -> float:
	return float(s["wait"]) / skill_mult(Data.ROLE_STAT[info.role])


func _draw() -> void:
	var moving := is_walking() and slack_timer <= 0.0
	var bob := absf(sin(anim * 12.0)) * 2.0 if moving else 0.0
	var o := Vector2(0, -bob)
	var sprite: Texture2D = main.art.staff(info.role, int(info.get("look", 0)))
	# 每个伙计有自己的衣服颜色和腰带颜色
	var robe := Color(info.get("color", Data.ROLE_COLOR[info.role]))
	var sash := Color(info.get("sash", "d33a2c"))
	match "" if sprite != null else info.role:
		"":  # art 文件夹里有这个职位的图片
			draw_sprite(o, sprite)
		"厨师":
			if order != null and slack_timer <= 0.0:
				o.x = sin(anim * 9.0) * 2.0
			draw_body(o, Color("f4f1ea"), false, sash)
			draw_rect(Rect2(o + Vector2(-7, -31), Vector2(14, 9)), Color.WHITE)
			disc(o + Vector2(0, -32), 7.0, Color.WHITE)
			draw_rect(Rect2(o + Vector2(-7, -24), Vector2(14, 2)), sash)  # 帽檐的色带
		"掌柜":
			draw_body(o, robe, false, Color("d4a640"))
			disc(o + Vector2(0, -21), 7.5, Color("2a1d14"))
			draw_rect(Rect2(o + Vector2(-8, -21), Vector2(16, 3)), Color("2a1d14"))
			disc(o + Vector2(0, -28), 2.0, sash)  # 帽顶的珠子
		"杂役":
			draw_line(o + Vector2(13, 12), o + Vector2(17, -16), Color("8b5a2b"), 2.5)  # 扫帚
			draw_colored_polygon(PackedVector2Array([o + Vector2(8, 10), o + Vector2(18, 10), o + Vector2(14, 18)]), Color("c9a24a"))
			draw_body(o, robe, true, Color("4a3a2a"))
			draw_rect(Rect2(o + Vector2(-8, -24), Vector2(16, 5)), sash)  # 头巾
		_:
			draw_body(o, robe, false, sash)
			draw_rect(Rect2(o + Vector2(-7, 2), Vector2(14, 9)), Color("f4f1ea"))  # 围裙
			draw_rect(Rect2(o + Vector2(5, -12), Vector2(9, 4)), Color.WHITE)  # 肩上的毛巾
			draw_rect(Rect2(o + Vector2(-7, -25), Vector2(14, 4)), sash.darkened(0.3))  # 小帽
	if carrying != "":
		var hp := o + Vector2(14, -10)
		disc(hp, 8.0, Color("f8f4ea"))
		disc(hp, 5.0, Color(carrying))
	elif order_slip != null:
		draw_rect(Rect2(o + Vector2(10, -9), Vector2(9, 11)), Color("fffdf6"))
		draw_line(o + Vector2(12, -6), o + Vector2(17, -6), Color("888888"), 1.0)
		draw_line(o + Vector2(12, -3), o + Vector2(17, -3), Color("888888"), 1.0)
	var f: Font = main.font
	# 名字
	var nm: String = info.name
	var nw := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var np := Vector2(-nw / 2.0, 30)
	if info.role == "厨师":
		np = Vector2(-nw / 2.0 - 34, 0)
	elif info.role == "掌柜":
		np = Vector2(-nw - 16, 0)
	draw_string_outline(f, np, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(1, 1, 1, 0.7))
	draw_string(f, np, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("3b2a1a"))
	if main.selected_staff == self:
		draw_arc(Vector2(0, 14), 17.0, 0.0, TAU, 32, Color("ffd34d"), 2.0, true)
	# 状态
	if slack_timer > 0.0:
		draw_string_outline(f, o + Vector2(-20, -40), "偷懒…", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color(1, 1, 1, 0.8))
		draw_string(f, o + Vector2(-20, -40), "偷懒…", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7a6a5a"))
	elif info.role == "厨师" and order != null:
		_bar(Vector2(-22, 18), 44.0, 1.0 - cook_timer / cook_total, Color("f39c12"))
		var dish_name: String = order.dish.name
		draw_string(f, Vector2(24, 4), dish_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("3b2a1a"))
	elif info.role == "掌柜" and pay_target != null:
		_bar(Vector2(-16, -38), 32.0, 1.0 - pay_timer / pay_total, Color("ffd34d"))
	elif not steps.is_empty() and steps[0].has("wait") and wait_timer > 0.0:
		_bar(Vector2(-14, -38), 28.0, wait_timer / _step_time(steps[0]), Color("6fb3e0"))


func _bar(pos: Vector2, w: float, ratio: float, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(w, 5)), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(pos, Vector2(w * clampf(ratio, 0.0, 1.0), 5)), col)
