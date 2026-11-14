extends "res://scripts/walker.gd"
## 顾客：进门 → 落座等跑堂点菜 → 等上菜 → 吃饭 → 去柜台结账（没有掌柜就在桌边自己算账）→ 离开。
## 等得太久会生气走掉，客栈声望下降。

enum S { WALK_IN, WANT_ORDER, WAIT_FOOD, EATING, SELF_PAY, TO_COUNTER, LEAVING }

const ORDER_PATIENCE := 18.0
const FOOD_PATIENCE := 30.0
const EAT_TIME := 5.0
const SELF_PAY_TIME := 6.0

var gtype: Dictionary
var robe := Color.WHITE  # 每位客人衣服颜色各不相同
var sash := Color.RED
var dish: Dictionary
var price := 0
var table_idx := -1
var state := S.WALK_IN
var patience := 0.0
var patience_max := 1.0
var total_patience := 1.0
var strain := 0.0  # 累积的“等得心烦”，用来算满意度
var timer := 0.0
var order = null
var angry := false
var anim := 0.0


func setup(t: Dictionary, d: Dictionary, table: int) -> void:
	gtype = t
	robe = Color(t.colors.pick_random())
	sash = main.random_sash()
	dish = d
	table_idx = table
	price = main.price_of(d)
	speed = 115.0
	total_patience = (ORDER_PATIENCE + FOOD_PATIENCE) * float(gtype.patience)
	walk_to(main.seat_pos(table))


func _process(delta: float) -> void:
	anim += delta
	match state:
		S.WALK_IN:
			if step_walk(delta):
				state = S.WANT_ORDER
				patience_max = ORDER_PATIENCE * float(gtype.patience)
				patience = patience_max
				main.request_order(self)
		S.WANT_ORDER, S.WAIT_FOOD:
			var d: float = delta * main.patience_decay()
			patience -= d
			strain += d
			if patience <= 0.0:
				leave_angry()
		S.EATING:
			timer -= delta
			if timer <= 0.0:
				main.customer_done_eating(self)
		S.SELF_PAY:
			timer -= delta
			strain += delta * 0.3
			if timer <= 0.0:
				main.customer_paid(self)
				main.customer_left_table(self, false)
				go_home()
		S.TO_COUNTER:
			strain += delta * 0.3 * main.patience_decay()
			step_walk(delta)
		S.LEAVING:
			if step_walk(delta):
				main.customer_gone(self)
				queue_free()
	queue_redraw()


func wants_order() -> bool:
	return state == S.WANT_ORDER


func waiting_food() -> bool:
	return state == S.WAIT_FOOD


func is_waiting() -> bool:
	return state == S.WANT_ORDER or state == S.WAIT_FOOD


func at_counter() -> bool:
	return state == S.TO_COUNTER and path.is_empty()


func order_taken(o) -> void:
	order = o
	state = S.WAIT_FOOD
	patience_max = FOOD_PATIENCE * float(gtype.patience)
	patience = patience_max


func serve() -> void:
	state = S.EATING
	timer = EAT_TIME


func self_pay() -> void:
	state = S.SELF_PAY
	timer = SELF_PAY_TIME


func go_counter(pos: Vector2) -> void:
	state = S.TO_COUNTER
	walk_to(pos)


func go_home() -> void:
	state = S.LEAVING
	speed = 125.0
	walk_to(main.door_pos())


func leave_angry() -> void:
	angry = true
	main.customer_left_table(self, true)
	go_home()


## 没吃上饭但也不算生气地离开（比如食材用完了）。
func leave_quietly() -> void:
	main.customer_left_table(self, false)
	go_home()


func _draw() -> void:
	var walking := state == S.WALK_IN or state == S.LEAVING or (state == S.TO_COUNTER and is_walking())
	var bob := absf(sin(anim * 11.0)) * 2.5 if walking else 0.0
	var o := Vector2(0, -bob)
	if not draw_sprite(o, main.art.guest(gtype.name)):
		draw_body(o, robe, true, sash)
		_draw_hat(o)
	match state:
		S.WANT_ORDER:
			_bubble(o + Vector2(0, -66), "点菜！", Color("c0392b"))
			_patience_bar(o + Vector2(0, -48))
		S.WAIT_FOOD:
			_bubble(o + Vector2(0, -66), dish.name, Color("3b2a1a"))
			_patience_bar(o + Vector2(0, -48))
		S.EATING:
			var ratio := clampf(1.0 - timer / EAT_TIME, 0.0, 1.0)
			draw_rect(Rect2(o + Vector2(-14, -48), Vector2(28, 4)), Color(0, 0, 0, 0.45))
			draw_rect(Rect2(o + Vector2(-14, -48), Vector2(28 * ratio, 4)), Color("8fd16a"))
		S.SELF_PAY:
			_bubble(o + Vector2(0, -66), "自己算账…", Color("8a7560"))
		S.TO_COUNTER:
			disc(o + Vector2(12, -2), 4.0, Color("d4a640"))
		S.LEAVING:
			if angry:
				draw_string(main.font, o + Vector2(-12, -46), "哼！", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ff5b4b"))


func _draw_hat(o: Vector2) -> void:
	match gtype.name:
		"农夫":  # 斗笠
			draw_colored_polygon(PackedVector2Array([o + Vector2(-15, -19), o + Vector2(15, -19), o + Vector2(0, -32)]), Color("d9b45a"))
			draw_line(o + Vector2(-15, -19), o + Vector2(15, -19), Color("a8853a"), 2.0)
		"书生":  # 方巾
			draw_rect(Rect2(o + Vector2(-7, -27), Vector2(14, 7)), Color("2d3a4a"))
			draw_line(o + Vector2(6, -22), o + Vector2(11, -13), Color("2d3a4a"), 2.0)
		"侠客":  # 背剑、红头带
			draw_line(o + Vector2(-13, 10), o + Vector2(12, -20), Color("9aa3ad"), 2.5)
			draw_line(o + Vector2(-8, -19), o + Vector2(8, -19), Color("c0392b"), 3.0)
			disc(o + Vector2(0, -26), 4.0, HAIR)
		"商贾":  # 瓜皮帽
			disc(o + Vector2(0, -21), 7.5, Color("4a2c17"))
			draw_rect(Rect2(o + Vector2(-8, -21), Vector2(16, 3)), Color("4a2c17"))
			disc(o + Vector2(0, -28), 2.0, Color("c0392b"))


func _bubble(pos: Vector2, text: String, col: Color) -> void:
	var f: Font = main.font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 12.0
	var r := Rect2(pos + Vector2(-w / 2.0, -10), Vector2(w, 20))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-5, 9), pos + Vector2(5, 9), pos + Vector2(0, 15)]), Color("fffdf6"))
	draw_rect(r, Color("fffdf6"))
	draw_rect(r, Color("8b5a2b"), false, 1.0)
	draw_string(f, pos + Vector2(-w / 2.0 + 6.0, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)


func _patience_bar(pos: Vector2) -> void:
	var ratio := clampf(patience / patience_max, 0.0, 1.0)
	var r := Rect2(pos + Vector2(-16, -3), Vector2(32, 5))
	draw_rect(r, Color(0, 0, 0, 0.55))
	draw_rect(Rect2(r.position, Vector2(r.size.x * ratio, r.size.y)), Color("e74c3c").lerp(Color("4caf50"), ratio))
