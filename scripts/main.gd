extends Node2D
## 云来客栈 —— 原创古风客栈经营游戏。
## 主控：周历与休假日、迎客、伙计派活、后厨、柜台结账、城镇、比赛、访客事件、画面与界面。

const Data = preload("res://scripts/data.gd")
const Customer = preload("res://scripts/customer.gd")
const Worker = preload("res://scripts/worker.gd")
const FloatText = preload("res://scripts/float_text.gd")
const Art = preload("res://scripts/art.gd")
const Sfx = preload("res://scripts/sfx.gd")

# ---------------- 经营数值 ----------------
const START_MONEY := 2000
const START_REP := 10.0
const OPEN_HOUR := 8.0
const CLOSE_HOUR := 20.0
const SECONDS_PER_HOUR := 15.0  # 1 倍速下游戏里一小时 = 15 秒，一个营业日约 3 分钟
const RENT := 50
const START_PIECES := [Vector2i(7, 3), Vector2i(8, 3)]  # 开局两张长方桌拼在一起，4 个座位
const MAX_STAFF := 8
const DECOR_COSTS := [600, 1500, 3500]
const DECOR_NAMES := ["朴素", "雅致", "气派", "富丽堂皇"]
const FOOD_PACKS := [100, 300]  # 粮行每类食材一次进的份量
const RUSH_FOOD := 100  # 营业日急购的份量，价格翻倍
const LOW_FOOD := 60  # 某类食材低于这个数就提醒
const AUTO_FOOD_STEP := 100
const AUTO_FOOD_MAX := 8000
const CASH_RESERVE := 800  # 自动补货、自动玩家花钱都至少留这么多周转

# 客人身份。fav：最爱的菜系（Data.CATEGORIES 序号），点到爱吃的更满意；rep：声望到了才会上门；say：进门的口头禅。
const GUEST_TYPES := [
	{"name": "农夫", "colors": ["6b8e4e", "8a7a4a", "5f8a6a", "9a6a3a"], "budget": [18, 45], "patience": 1.3, "tip": 0.05, "weight": 3.0, "fav": 0, "rep": 0,
		"say": ["掌柜的，来碗面，要大碗的！", "地里活忙，吃完就走。"]},
	{"name": "书生", "colors": ["7fa7c9", "e8e2d0", "6ab0b0", "a8c0e0"], "budget": [30, 80], "patience": 1.15, "tip": 0.1, "weight": 3.0, "fav": 1, "rep": 0,
		"say": ["小二，可有清雅些的点心？", "读书读饿了……"]},
	{"name": "侠客", "colors": ["8c2f39", "2e2e3a", "5a3a7a", "b04a2a"], "budget": [45, 170], "patience": 0.8, "tip": 0.1, "weight": 2.0, "fav": 3, "rep": 0,
		"say": ["好酒好肉尽管上！", "快些，爷还要赶路。"]},
	{"name": "商贾", "colors": ["c8963e", "d9732a", "a85a8a", "b8a040"], "budget": [90, 320], "patience": 0.9, "tip": 0.2, "weight": 1.0, "fav": 4, "rep": 0,
		"say": ["拣贵的上，不差钱。", "谈完这笔买卖，正好吃顿好的。"]},
	{"name": "镖师", "colors": ["7a5a3a", "5a4a3a"], "budget": [60, 200], "patience": 0.9, "tip": 0.1, "weight": 1.2, "fav": 3, "rep": 10,
		"say": ["押了三天镖，饿坏了！", "大块的肉，多来几盘！"]},
	{"name": "道士", "colors": ["6a7a80", "8a9aa0"], "budget": [30, 90], "patience": 1.25, "tip": 0.15, "weight": 0.8, "fav": 5, "rep": 10,
		"say": ["贫道观你这店，有兴旺之相。", "来碗热汤，暖暖身子。"]},
	{"name": "和尚", "colors": ["c8a050", "b08a40"], "budget": [20, 60], "patience": 1.4, "tip": 0.0, "weight": 0.8, "fav": 0, "rep": 0,
		"say": ["阿弥陀佛，来碗素面。", "施主，化个缘可好？"]},
	{"name": "官差", "colors": ["2e2e2e", "6a2a2a"], "budget": [30, 110], "patience": 0.75, "tip": 0.0, "weight": 1.0, "fav": 2, "rep": 20,
		"say": ["巡街巡累了，弄两个家常菜。", "快着点，公务在身！"]},
	{"name": "千金小姐", "colors": ["e8a0b0", "d890c0"], "budget": [100, 280], "patience": 0.85, "tip": 0.3, "weight": 0.7, "fav": 1, "rep": 35,
		"say": ["听说你家的点心做得精致？", "丫鬟，帮我挑个干净座儿。"]},
	{"name": "乞丐", "colors": ["8a7a6a", "6a5a4a"], "budget": [6, 24], "patience": 1.6, "tip": 0.0, "weight": 0.6, "fav": 0, "rep": 0,
		"say": ["掌柜行行好，一碗阳春面就成。", "今儿讨到几文钱，也来下回馆子！"]},
	{"name": "胡商", "colors": ["3a6aa0", "a04a3a"], "budget": [130, 420], "patience": 0.9, "tip": 0.3, "weight": 0.6, "fav": 4, "rep": 50,
		"say": ["远道而来，要尝尝中原的鱼！", "银子有的是，好菜尽管上。"]},
]
const SASH_COLORS := ["d33a2c", "e0b84a", "3f7d3a", "2d6ea8", "f2f2e8", "8a3ab0"]
const STAFF_COLORS := {
	"掌柜": ["5b3a6e", "3a4a6e", "6e3a3a"],
	"厨师": ["f4f1ea"],
	"跑堂": ["4f6d8f", "3f7d6a", "8f6a4f", "6a5a9a"],
	"杂役": ["8a6a46", "6a7a4a", "7a5a5a"],
}

const TASK_PRIORITY := {"deliver": 0, "order": 1, "clean": 2}

const INTRO_TEXT := "【第一章 · 重振祖业】\n父亲走得急，只给你留下城南这间旧客栈，还有一个掌柜、一个厨师、一个跑堂。对街的福满楼正等着看笑话。\n本章目标：声望达到 30。\n\n每周营业六天，伙计们自己干活，你看着大堂、应付上门的访客；第七天是休假日，可以进城：粮行进货、人力市场招人、木工坊添桌装修、杂货铺给伙计买东西，还能报名参加厨艺比赛。\n\n伙计各有能力：厨艺、计算、技巧、反应决定干活快慢，魅力招揽客人，毅力低的会偷懒，向心力低的会辞工。\n\n一路赢下五场比赛，云来客栈就能名扬天下！\n\n快捷键：空格 暂停/继续，1 / 2 / 3 切换速度"

# ---------------- 场景布局 ----------------
const KITCHEN_RECT := Rect2(20, 70, 860, 110)
const HALL_RECT := Rect2(20, 200, 860, 510)
# 大堂网格：17 x 10 格，每格 50 像素。第 0 行传菜道，第 8、9 行门口和柜台，中间摆桌子
const GRID_O := Vector2(25, 200)
const CELL := 50.0
const GCOLS := 17
const GROWS := 10
const PASS_POS := Vector2(450, 189)  # 出菜口
const PICKUP_POS := Vector2(450, 225)  # 跑堂在出菜口前站的位置
const DOOR_POS := Vector2(450, 745)
const CASHIER_POS := Vector2(790, 646)  # 掌柜站的位置
const PAY_SPOT := Vector2(790, 696)  # 客人结账排队的第一个位置
# 摆件位：靠墙和门口两侧，不挡走道
const DECOR_SLOTS := [
	Vector2(44, 372), Vector2(856, 372), Vector2(44, 566), Vector2(856, 566), Vector2(292, 664), Vector2(610, 664),
]
# 墙上挂画位：后厨与大堂之间的隔墙，避开出菜口。坐标是画轴顶端
const WALL_SLOTS := [Vector2(90, 186), Vector2(195, 186), Vector2(300, 186), Vector2(600, 186), Vector2(705, 186), Vector2(810, 186)]
const STOVE_POS := [Vector2(250, 122), Vector2(450, 122), Vector2(650, 122)]


class Order:
	var dish: Dictionary
	var price := 0
	var customer: Object
	var table_idx := -1
	var canceled := false


var font: SystemFont
var title_font: SystemFont  # 标题用楷体，更有古风
var art = Art.new()  # 图片素材，没有就用代码画
var sfx  # 音效
var money := START_MONEY
var food: Array = []  # 四类食材库存，序号对应 Data.FOOD_KINDS
var food_price: Array = []  # 本周各类食材的价格倍率
var reputation := START_REP
var day := 1
var day_time := 0.0
var clock := 0.0
var is_open := true
var day_over := false
var is_rest_day := false
var game_started := false
var game_finished := false
var decor_level := 0
var table_level := 0
var stove_level := 0
var counter_level := 0
var ornaments := {}  # 已买的摆件：id -> 摆件位序号（挂画是 WALL_SLOTS 的序号，其余是 DECOR_SLOTS 的）
var pieces: Array = []  # 长方桌摆在哪些格子（Vector2i）。挨着摆就拼成长桌
var expand_level := 0  # 扩建到第几档（Data.EXPANSIONS）
var arranging := false  # 休假日进店布置
var drag = null  # 正在拖的东西：{"kind": "table", "i"} 或 {"kind": "orn", "id"}
var auto_food_on := true  # 休假日自动补货
var auto_food_target: Array = []  # 各类食材自动补到的数
var food_fixed: Array = [false, false, false, false]  # 玩家手动调过的那类就固定，不再自动算
var food_used_week: Array = [0, 0, 0, 0]  # 这周卖菜实际用掉的食材（不含放坏）
var food_hist: Array = []  # 最近三周卖菜用掉的，最新的在前
var seats_last_week := 0
var hover_shop := ""  # 集市里鼠标指着的铺子
var speed := 1.0
var last_speed := 1.0
var spawn_timer := 2.0

var dishes: Array = []  # 全部菜（扁平），每道带 cat / tier / unlocked / ratio
var tables: Array = []  # 每张桌子：{"customer", "dirty", "plate"}
var staff: Array = []  # 伙计节点
var selected_staff = null
var market: Array = []  # 人力市场本周的应征者
var customers: Array = []
var tasks: Array = []  # 跑堂/杂役待办：点菜 / 传菜 / 收拾
var kitchen_queue: Array = []
var pass_orders: Array = []  # 做好、摆在出菜口等人端的菜
var cashier_queue: Array = []  # 在柜台排队结账的客人
var research = null  # {"dish": 菜, "points": 进度}
var stats := {}
var log_lines := PackedStringArray()

# 比赛
var contest_idx := 0
var contest_active := false
var contest_days := 0
var contest_value := 0.0
var contest_sat_sum := 0.0
var contest_sat_n := 0

# 当天的访客事件
var event_hour := -1.0
var mishap_hour := -1.0  # 今天没选项的天灾在几点
var last_mishap := ""  # 昨天出的天灾，连着两天不重复
var today_patience := 1.0
var today_arrival := 1.0
var critic_today := false
var scholar_loan := false
var popup_event := ""
var festival_today := ""  # 今天是什么节，空就是平常日子

# 剧情：对门的醉仙楼
var story_step := 0  # 下一段剧情在 Data.STORY 里的序号
var story_wait_week := 0  # 擂台没赢的话，过几周再来
var rivals: Array = []  # 同行的现状：{"rep", "price", "open", "closed", "weak"}，对应 Data.RIVALS
var chapter := 0  # 主线进行到第几章（Data.CHAPTERS 序号）
var ending_shown := false
var regular_friend: Array = [0, 0, 0, 0]  # 四位常客的交情，对应 Data.REGULARS
var regular_today := {}  # 今天来过的常客

var chars_layer: Node2D
var fx_layer: Node2D
var flights: Array = []  # 飞行中的特效：菜飞到出菜口、铜钱飞进钱匣、上菜的热气。{"kind", "from", "to", "start", "dur", "dish"}

# 自动测试：命令行加 -- --autotest [--shots=截图目录]
var autotest := false
var shots_dir := ""
var jump_market := false
var auto_done := {}

# 界面
var lbl_day: Label
var lbl_money: Label
var lbl_food: Label
var lbl_rep: Label
var bar_rep: ProgressBar
var speed_buttons: Array = []
var tabs: TabContainer
var lbl_research: Label
var bar_research: ProgressBar
var dish_rows: Array = []
var staff_box: VBoxContainer
var staff_rows: Array = []
var lbl_town_status: Label
var food_rows: Array = []  # 粮行每类食材一行：{"lbl", "buy": [按钮], "rush", "auto"}
var market_rows: Array = []
var settings_panel: PanelContainer
var daylight: CanvasModulate
var glow_layer: Node2D
var status_panel: PanelContainer
var status_body: VBoxContainer
var calc_panel: PanelContainer
var calc_info: Label
var calc_qty_lbl: Label
var calc_cost_lbl: Label
var calc_ok: Button
var calc_kind := 0
var calc_qty := 0
var ledger_panel: PanelContainer
var ledger_body: VBoxContainer
var ledger_history: Array = []  # 前几周的账：{"week", "start", "end", "items"}，最新的在前
var calendar_panel: PanelContainer
var calendar_body: VBoxContainer
var town_scroll: ScrollContainer
var town_sections := {}
var btn_auto_food: Button
var lbl_table_grade: Label
var btn_table_grade: Button
var lbl_stove: Label
var btn_stove: Button
var lbl_counter: Label
var btn_counter: Button
var ornament_rows: Array = []
var lbl_tables: Label
var btn_table: Button
var lbl_decor: Label
var btn_decor: Button
var lbl_item_target: Label
var item_buttons: Array = []
var btn_open_shop: Button
var contest_labels: Array = []
var lbl_contest: Label
var btn_contest: Button
var btn_arrange: Button
var btn_expand: Button
var lbl_rivals: Label
var lbl_log: RichTextLabel
var bar_day: ProgressBar
var dim: ColorRect
var popup: PanelContainer
var popup_title: Label
var popup_body: Label
var popup_portrait: TextureRect  # 访客事件的立绘，art/portraits/<id>.png
var popup_portrait_key := ""  # 下一个弹窗要配哪张立绘
var popup_button: Button
var popup_button2: Button
var popup_action := Callable()
var popup_action2 := Callable()
var ui_refresh_timer := 0.0


func _ready() -> void:
	randomize()
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
		elif a.begins_with("--seed="):  # 固定随机种子，实验可复现
			seed(int(a.trim_prefix("--seed=")))
		elif a.begins_with("--play="):
			autoplay_weeks = int(a.trim_prefix("--play="))
		elif a == "--market":  # 调试用：开局直接进休假日的集市
			jump_market = true
		elif a.begins_with("--shots="):
			shots_dir = a.trim_prefix("--shots=")
	font = SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "SimHei",  # Windows
		"Hiragino Sans GB", "Heiti SC",  # Mac（PingFang SC 能找到但 Godot 加载失败，别加）
		"Noto Sans CJK SC", "WenQuanYi Micro Hei", "sans-serif"])  # Linux
	title_font = SystemFont.new()
	title_font.font_names = PackedStringArray([
		"KaiTi", "楷体",  # Windows
		"Kaiti SC", "STKaiti", "Songti SC",  # Mac
		"AR PL UKai CN", "Microsoft YaHei UI", "Hiragino Sans GB", "sans-serif"])
	title_font.font_weight = 700
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # 地板图平铺要用
	sfx = Sfx.new()
	add_child(sfx)
	chars_layer = Node2D.new()
	chars_layer.y_sort_enabled = true
	add_child(chars_layer)
	fx_layer = Node2D.new()
	fx_layer.z_index = 10
	add_child(fx_layer)
	fx_layer.draw.connect(_draw_flights)
	# 日夜光照：整个大堂（不含界面）按时辰调色；灯光单独一层用加亮混合画上去
	daylight = CanvasModulate.new()
	add_child(daylight)
	glow_layer = Node2D.new()
	glow_layer.z_index = 9
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_layer.material = glow_mat
	add_child(glow_layer)
	glow_layer.draw.connect(_draw_glow)
	_init_dishes()
	for r in Data.RIVALS:
		rivals.append({"rep": r.rep, "price": r.price, "open": int(r.open_week) == 1, "closed": false, "weak": 0})
	for k in Data.FOOD_KINDS:
		food.append(int(k.start))
		food_price.append(1.0)
		auto_food_target.append(int(k.start))
	pieces = START_PIECES.duplicate()
	_rebuild_seats()
	_reset_day_stats()
	_build_ui()
	for role in ["掌柜", "厨师", "跑堂"]:
		var info := _make_staff(role, 45, 65)
		info.stats["毅力"] = randi_range(50, 65)
		_add_staff(info, true)
	_refresh_market()
	_schedule_event()
	_refresh_ui()
	if autoplay_weeks > 0:
		_start_game()
	elif jump_market:
		_start_game()
		day = 6
		_enter_rest_day()
	elif not autotest and FileAccess.file_exists(_save_path()):
		_show_popup("云来客栈", INTRO_TEXT, "重新开张", _start_game, "读取存档", _load_game)
	else:
		_show_popup("云来客栈", INTRO_TEXT, "开张营业", _start_game)


func _init_dishes() -> void:
	for ci in Data.CATEGORIES.size():
		var cat: Dictionary = Data.CATEGORIES[ci]
		var start: int = Data.START_UNLOCKED.get(cat.name, 0)
		for j in cat.dishes.size():
			var nd: Dictionary = cat.dishes[j].duplicate()
			nd["cat"] = ci
			nd["tier"] = j
			nd["food"] = cat.food
			nd["unlocked"] = j < start
			nd["ratio"] = 1.0
			nd["research_cost"] = int(nd.price) * 12
			nd["research_need"] = 10.0 + float(nd.taste) * 8.0
			dishes.append(nd)


func _process(delta: float) -> void:
	_update_daylight()
	if is_rest_day:
		queue_redraw()  # 集市里的路人在走
		return
	if not game_started or delta <= 0.0:
		return
	clock += delta
	var cooking := false
	for w in staff:
		if w.role() == "厨师" and w.order != null and w.slack_timer <= 0.0:
			cooking = true
	sfx.set_sizzle(cooking)
	if not day_over:
		day_time += delta
		if is_open:
			if current_hour() >= CLOSE_HOUR:
				is_open = false
				_log("戌时到了，挂上打烊牌，不再迎客。")
			else:
				spawn_timer -= delta
				if spawn_timer <= 0.0:
					_try_spawn_customer()
					spawn_timer = _next_spawn_interval()
				if event_hour > 0.0 and current_hour() >= event_hour:
					event_hour = -1.0
					_trigger_random_event()
				if mishap_hour > 0.0 and current_hour() >= mishap_hour:
					mishap_hour = -1.0
					_trigger_mishap()
		elif customers.is_empty():
			_end_day()
	ui_refresh_timer -= delta
	if ui_refresh_timer <= 0.0:
		ui_refresh_timer = 0.2
		_refresh_ui()
	if autotest:
		_autotest_tick()
	elif autoplay_weeks > 0:
		_autoplay_tick()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and _calc_key(event):
		get_viewport().set_input_as_handled()
		return
	if is_rest_day and arranging and not popup.visible:
		var mp := get_global_mouse_position()
		var mbt := event as InputEventMouseButton
		if mbt != null and mbt.button_index == MOUSE_BUTTON_LEFT:
			if mbt.pressed:
				drag = _pick_at(mp)
			elif drag != null:
				_drop(drag, mp)
				drag = null
			queue_redraw()
		elif event is InputEventMouseMotion and drag != null:
			queue_redraw()
	elif is_rest_day and not popup.visible:
		if event is InputEventMouseMotion:
			var h := _shop_at(get_global_mouse_position())
			if h != hover_shop:
				hover_shop = h
				Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if h != "" else Input.CURSOR_ARROW)
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var s := _shop_at(get_global_mouse_position())
			if s != "":
				_open_shop(s)
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not game_started or popup.visible:
		return
	match k.keycode:
		KEY_SPACE:
			_set_speed(last_speed if speed == 0.0 else 0.0)
		KEY_1:
			_set_speed(1.0)
		KEY_2:
			_set_speed(2.0)
		KEY_3:
			_set_speed(3.0)


# ---------------- 时间与周历 ----------------

func current_hour() -> float:
	return OPEN_HOUR + day_time / SECONDS_PER_HOUR


func weekday() -> int:
	return (day - 1) % 7


func week() -> int:
	return (day - 1) / 7 + 1


func season_of_week(w: int) -> int:
	return ((w - 1) / Data.WEEKS_PER_SEASON) % Data.SEASONS.size()


func season() -> Dictionary:
	return Data.SEASONS[season_of_week(week())]


func _festival_name() -> String:
	var wi := (week() - 1) % Data.WEEKS_PER_SEASON
	for f in Data.FESTIVALS:
		if int(f.season) == season_of_week(week()) and int(f.week) == wi and int(f.weekday) == weekday():
			return f.name
	return ""


func _date_text() -> String:
	return "第 %d 周 %s" % [week(), Data.WEEKDAYS[weekday()]]


func _clock_text() -> String:
	if is_rest_day:
		return "歇业"
	var h := current_hour()
	var names := ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
	var shichen: String = names[int(floor((h + 1.0) / 2.0)) % 12]
	return "%s时 %02d:%02d" % [shichen, int(h) % 24, int(fmod(h, 1.0) * 60.0)]


# ---------------- 迎客 ----------------

func _next_spawn_interval() -> float:
	var h := current_hour()
	var rush := 1.0
	if (h >= 11.0 and h < 13.0) or (h >= 17.0 and h < 19.0):
		rush = 1.6  # 午饭、晚饭时分客人多
	var charm := 0.0
	for w in staff:
		if w.role() == "厨师" or w.role() == "掌柜":
			charm += w.stat("魅力") / 250.0
	var rate := (1.0 + reputation / 35.0 + decor_level * 0.15 + charm) * rush * today_arrival * (1.0 + decor_bonus("arrival"))
	rate *= float(season().arrival) * (1.6 if festival_today != "" else 1.0) * _rival_mult()
	rate *= 1.0 + 0.06 * _trait_count("爱吹牛")
	return randf_range(0.7, 1.3) * 7.0 / rate


func _try_spawn_customer() -> void:
	stats.visitors += 1
	var g: Dictionary = _pick_guest_type()
	if randf() < 0.05:
		var ri := randi() % Data.REGULARS.size()
		if not regular_today.has(ri):
			regular_today[ri] = true
			var r: Dictionary = Data.REGULARS[ri]
			g = {"name": r.name, "colors": r.colors, "budget": r.budget, "patience": 1.3, "tip": 0.15, "fav": r.fav, "say": r.say, "regular": ri}
	var budget := randi_range(int(g.budget[0]), int(g.budget[1]))
	var dish = _pick_dish(budget, int(g.fav))
	var text_pos := DOOR_POS + Vector2(randf_range(-150, 150), randf_range(-95, -70))
	if dish == null:
		stats.lost_price += 1
		var why := "菜价太贵" if _food_total() >= LOW_FOOD else "店里没食材"
		_float_text(text_pos, "%s嫌%s，走了" % [g.name, why], Color("ffe2b0"))
		return
	var open_tables := _free_tables()
	if open_tables.is_empty():
		stats.lost_full += 1
		_float_text(text_pos, "客满了，%s只好离开" % g.name, Color("ffe2b0"))
		return
	var ti: int = open_tables.pick_random()
	var c = Customer.new()
	c.main = self
	c.position = DOOR_POS
	tables[ti].customer = c
	chars_layer.add_child(c)
	c.setup(g, dish, ti)
	customers.append(c)
	sfx.play("bell", -8.0)
	if randf() < 0.35 or g.has("regular"):
		_float_text(text_pos, "%s：%s" % [g.name, g.say.pick_random()], Color("fff3d6"))
	if not staff_of("跑堂").is_empty():
		sfx.voice("welcome", 0.6)


func _pick_guest_type() -> Dictionary:
	var weights: Array = []
	for g in GUEST_TYPES:
		var w: float = g.weight if reputation >= float(g.rep) else 0.0
		if g.name == "商贾" or g.name == "胡商" or g.name == "千金小姐":
			w += 1.5 if _regular_at(0, 0) else 0.0  # 王员外领来的朋友
			w += reputation / 25.0 + decor_bonus("rich")  # 名气越大，有钱的客人越多
		weights.append(w)
	return GUEST_TYPES[_weighted_index(weights)]


func _pick_dish(budget: int, fav := -1):
	var options: Array = []
	var weights: Array = []
	for d in dishes:
		if d.unlocked and price_of(d) <= budget and food[d.food] >= int(d.cost):
			options.append(d)
			weights.append((float(d.taste) + 1.0) * (2.0 if int(d.cat) == int(season().fav) else 1.0) * (3.0 if int(d.cat) == fav else 1.0))
	if options.is_empty():
		return null
	return options[_weighted_index(weights)]


func _weighted_index(weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return weights.size() - 1


func _free_tables() -> Array:
	var result: Array = []
	for i in tables.size():
		if tables[i].customer == null and not tables[i].dirty:
			result.append(i)
	return result


func price_of(d: Dictionary) -> int:
	return int(round(float(d.price) * float(d.ratio)))


## 客人耐心消耗的速度：杂役照应、装修、说书先生都能让客人沉得住气。
func patience_decay() -> float:
	var help := 0.0
	for w in staff_of("杂役"):
		help += (w.stat("反应") * 0.4 + w.stat("魅力") * 0.15) / 100.0
	var school := 0.9 if _regular_at(2, 1) else 1.0  # 周夫子在大堂教书
	return clampf(1.0 - help * 0.6, 0.45, 1.0) * today_patience * school / (1.0 + decor_level * 0.1 + decor_bonus("patience"))


# ---------------- 位置与走道 ----------------

func cell_center(c: Vector2i) -> Vector2:
	return GRID_O + (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func cell_of(p: Vector2) -> Vector2i:
	var c := Vector2i(((p - GRID_O) / CELL).floor())
	return Vector2i(clampi(c.x, 0, GCOLS - 1), clampi(c.y, 0, GROWS - 1))


## 座位 i（tables[i]）：客人站的位置、跑堂站的位置、菜摆的位置。
func seat_pos(i: int) -> Vector2:
	return cell_center(tables[i].cell) + Vector2(0, 10)


func serve_pos(i: int) -> Vector2:
	return seat_pos(i) + Vector2(18, 0)


func plate_pos(i: int) -> Vector2:
	var t: Dictionary = tables[i]
	return cell_center(t.piece) + Vector2(0, -7 if t.cell.y < t.piece.y else 7)


func _in_area(c: Vector2i) -> bool:
	var e: Dictionary = Data.EXPANSIONS[expand_level]
	return c.x >= int(e.cols[0]) and c.x <= int(e.cols[1]) and c.y >= int(e.rows[0]) and c.y <= int(e.rows[1])


## 能走的格子：传菜道和门口两排随便走；中间几排只有扩建过的列能走；桌子占的格子不能走。
func _walkable(c: Vector2i, blocked: Array) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= GCOLS or c.y >= GROWS or blocked.has(c):
		return false
	if c.y == 0 or c.y >= 8:
		return true
	var e: Dictionary = Data.EXPANSIONS[expand_level]
	return c.x >= int(e.cols[0]) and c.x <= int(e.cols[1])


const DIRS8 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]


## 格子上的广度优先寻路（八方向，不切角）。返回从 a 到 b 的格子序列（不含 a），走不通返回空。
func _grid_path(a: Vector2i, b: Vector2i, blocked: Array) -> Array:
	if a == b:
		return []
	var prev := {a: a}
	var queue: Array = [a]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if c == b:
			break
		for d in DIRS8:
			var n: Vector2i = c + d
			if prev.has(n) or not (n == b or _walkable(n, blocked)):
				continue
			if d.x != 0 and d.y != 0 and not (_walkable(Vector2i(c.x + d.x, c.y), blocked) and _walkable(Vector2i(c.x, c.y + d.y), blocked)):
				continue
			prev[n] = c
			queue.append(n)
	if not prev.has(b):
		return []
	var out: Array = []
	var c: Vector2i = b
	while c != a:
		out.push_front(c)
		c = prev[c]
	return out


## 重新算座位：每张长方桌上下各一个座位（被别的桌子占了、或已经算给别的桌子的就没有）。
func _rebuild_seats() -> void:
	tables.clear()
	for sc in _seat_cells(pieces):
		tables.append({"customer": null, "dirty": false, "plate": "", "dish_name": "", "cell": sc[0], "piece": sc[1]})


## 这样摆有哪些座位：[[座位格, 桌子格], ...]
func _seat_cells(ps: Array) -> Array:
	var out: Array = []
	var used := {}
	for p in ps:
		for side in [-1, 1]:
			var c: Vector2i = p + Vector2i(0, side)
			if c.y >= 1 and c.y <= 7 and not ps.has(c) and not used.has(c):
				used[c] = true
				out.append([c, p])
	return out


## 这样摆行不行：都在扩建范围内、不重叠，出菜口能走到每个座位和大门。
func _layout_ok(ps: Array) -> bool:
	var seen := {}
	for p in ps:
		if not _in_area(p) or seen.has(p):
			return false
		seen[p] = true
	var start := cell_of(PICKUP_POS)
	for p in ps:
		for side in [-1, 1]:
			var c: Vector2i = p + Vector2i(0, side)
			if c.y >= 1 and c.y <= 7 and not ps.has(c) and _grid_path(start, c, ps).is_empty():
				return false
	return not _grid_path(start, cell_of(DOOR_POS), ps).is_empty()



func door_pos() -> Vector2:
	return DOOR_POS


## 在大堂网格上绕开桌子走。
func route(from: Vector2, to: Vector2) -> Array:
	var pts: Array = []
	for c in _grid_path(cell_of(from), cell_of(to), pieces):
		pts.append(cell_center(c))
	if not pts.is_empty():
		pts.pop_back()  # 最后一格直接走到确切位置
	pts.append(to)
	return pts


# ---------------- 伙计 ----------------

func staff_of(role: String) -> Array:
	var result: Array = []
	for w in staff:
		if w.role() == role:
			result.append(w)
	return result


func _role_room(role: String) -> bool:
	return staff_of(role).size() < int(Data.ROLE_LIMIT[role])


func _make_staff(role: String, skill: int, loyalty: int) -> Dictionary:
	var st := {}
	for s in Data.STATS:
		st[s] = randi_range(12, 45)
	st[Data.ROLE_STAT[role]] = skill
	st["向心力"] = loyalty
	var info := {"name": _random_name(), "role": role, "stats": st, "wage": 0,
		"color": STAFF_COLORS[role].pick_random(), "sash": SASH_COLORS.pick_random(),
		"look": randi() % 3, "trait": Data.TRAITS.pick_random().name}  # look：长相（第几套图）
	info["wage"] = fair_wage(info)
	return info


func random_sash() -> Color:
	return Color(SASH_COLORS.pick_random())


func _random_name() -> String:
	var taken := {}
	for w in staff:
		taken[w.info.name] = true
	for m in market:
		taken[m.name] = true
	var nm := ""
	for i in 20:
		nm = Data.SURNAMES.pick_random() + Data.GIVEN.pick_random()
		if not taken.has(nm):
			break
	return nm


## 伙计觉得自己该拿的工钱：看最拿手的本事和魅力。
func fair_wage(info: Dictionary) -> int:
	var st: Dictionary = info.stats
	var best := 0
	for s in Data.SKILL_STATS:
		best = maxi(best, int(st[s]))
	var wage := 30 + int((best + int(st["魅力"])) / 3.0)
	return int(wage * 0.9) if info.get("trait", "") == "抠门" else wage


func _trait_count(t: String) -> int:
	var n := 0
	for w in staff:
		if w.info.get("trait", "") == t:
			n += 1
	return n


func _add_staff(info: Dictionary, starting: bool) -> void:
	var w = Worker.new()
	w.main = self
	w.info = info
	chars_layer.add_child(w)
	staff.append(w)
	_layout_staff()
	w.position = w.home if (starting or is_rest_day) else DOOR_POS
	_rebuild_staff_list()


## 按职位给每个伙计分配站位：厨师守灶，掌柜在柜台，跑堂在出菜口前，杂役在门边。
func _layout_staff() -> void:
	var counts := {"掌柜": 0, "厨师": 0, "跑堂": 0, "杂役": 0}
	for w in staff:
		var r: String = w.role()
		var i: int = counts[r]
		counts[r] = i + 1
		match r:
			"厨师":
				var sp: Vector2 = STOVE_POS[mini(i, STOVE_POS.size() - 1)]
				w.home = Vector2(sp.x, 166)
			"掌柜":
				w.home = CASHIER_POS
			"跑堂":
				w.home = Vector2(360 + i * 60, 225)
			"杂役":
				w.home = Vector2(96 + i * 52, 652)
		w.apply_role_speed()
	if staff_of("掌柜").is_empty():
		_flush_cashier_queue()


func on_staff_slack(w) -> void:
	stats.slacks += 1
	if randf() < 0.3:
		_log("%s偷了会儿懒。" % w.info.name)


func _select_staff(w) -> void:
	selected_staff = w
	_refresh_ui()


func _change_role(w) -> void:
	if not is_rest_day:
		return
	var roles: Array = Data.ROLES
	var start := roles.find(w.role())
	for k in range(1, roles.size()):
		var r: String = roles[(start + k) % roles.size()]
		if _role_room(r):
			_log("%s从%s改当%s。" % [w.info.name, w.role(), r])
			w.info.role = r
			_layout_staff()
			w.reset_work()
			_rebuild_staff_list()
			return
	_log("其他职位都满了，没法调。")


func _raise_wage(w) -> void:
	w.info.wage = int(w.info.wage) + 10
	w.info.stats["向心力"] = mini(99, w.stat("向心力") + 12)
	_log("给%s加了工钱，现在每天 %d 文。" % [w.info.name, w.info.wage])
	_refresh_ui()


func _fire(w) -> void:
	if not is_rest_day:
		return
	var r: String = w.role()
	if (r == "厨师" or r == "跑堂") and staff_of(r).size() <= 1:
		_log("店里不能一个%s都没有。" % r)
		return
	_remove_staff(w)
	_log("辞退了%s。" % w.info.name)


func _remove_staff(w) -> void:
	staff.erase(w)
	if selected_staff == w:
		selected_staff = null
	w.queue_free()
	_layout_staff()
	_rebuild_staff_list()


# ---------------- 跑堂、杂役派活 ----------------

func request_order(c) -> void:
	tasks.append({"type": "order", "table": c.table_idx, "customer": c, "created": clock})


func claim_task(w):
	var r: String = w.role()
	var can_clean := r == "杂役" or staff_of("杂役").is_empty()
	var best_i := -1
	var best_score := INF
	var i := 0
	while i < tasks.size():
		var t: Dictionary = tasks[i]
		if not _task_valid(t):
			tasks.remove_at(i)
			continue
		var allowed: bool = (t.type == "clean" and can_clean) or (t.type != "clean" and r == "跑堂")
		if allowed:
			var score: float = float(TASK_PRIORITY[t.type]) * 100000.0 + float(t.created) + w.position.distance_to(serve_pos(t.table)) * 0.01
			if score < best_score:
				best_score = score
				best_i = i
		i += 1
	if best_i < 0:
		return null
	var task: Dictionary = tasks[best_i]
	tasks.remove_at(best_i)
	return task


func _task_valid(t: Dictionary) -> bool:
	match t.type:
		"order":
			return is_instance_valid(t.customer) and t.customer.wants_order()
		"deliver":
			return not t.order.canceled
		"clean":
			return tables[t.table].dirty
	return false


func build_steps(w, t: Dictionary) -> Array:
	var ti: int = t.table
	match t.type:
		"order":
			return [
				{"move": serve_pos(ti)},
				{"wait": 0.8, "do": _take_order.bind(w, t.customer), "anim": "write", "face": -1.0},
				{"move": PICKUP_POS},
				{"wait": 0.3, "do": _hand_to_kitchen.bind(w)},
			]
		"deliver":
			return [
				{"move": PICKUP_POS},
				{"wait": 0.3, "do": _pick_up.bind(w, t.order)},
				{"move": serve_pos(ti)},
				{"wait": 0.4, "do": _serve.bind(w, t.order), "face": -1.0},
			]
		"clean":
			return [
				{"move": serve_pos(ti)},
				{"wait": 1.0, "do": _clean_table.bind(ti), "anim": "wipe", "face": -1.0},
			]
	return []


func _take_order(w, c) -> bool:
	if not is_instance_valid(c) or not c.wants_order():
		return false
	var cost: int = c.dish.cost
	var k: int = c.dish.food
	if food[k] < cost:
		_float_text(c.position + Vector2(0, -50), "食材用完了…", Color("ffe2b0"))
		stats.lost_price += 1
		c.leave_quietly()
		return false
	food[k] -= cost
	food_used_week[k] += cost
	stats.ingredients += cost
	if food[k] < LOW_FOOD and not stats.food_warned:
		stats.food_warned = true
		_log("%s快用完了！可以在「城镇」里急购。" % Data.FOOD_KINDS[k].name)
	var o := Order.new()
	o.dish = c.dish
	o.price = c.price
	o.customer = c
	o.table_idx = c.table_idx
	c.order_taken(o)
	w.order_slip = o
	sfx.voice("order", 0.35)
	return true


func _hand_to_kitchen(w) -> bool:
	var o = w.order_slip
	w.order_slip = null
	if o != null and not o.canceled:
		kitchen_queue.append(o)
	return true


func _pick_up(w, o) -> bool:
	pass_orders.erase(o)
	if o.canceled:
		return false
	w.carrying = o.dish.color
	w.carrying_name = o.dish.name
	return true


func _serve(w, o) -> bool:
	w.carrying = ""
	if o.canceled or not is_instance_valid(o.customer) or not o.customer.waiting_food():
		stats.wasted += 1
		return false
	tables[o.table_idx].plate = o.dish.color
	tables[o.table_idx].dish_name = o.dish.name
	_fly("puff", plate_pos(o.table_idx), Vector2.ZERO, 0.7)
	o.customer.serve()
	sfx.play("ding", -4.0)
	sfx.voice("serve", 0.3)
	return true


func _clean_table(ti: int) -> bool:
	tables[ti].dirty = false
	tables[ti].plate = ""
	return true


# ---------------- 后厨 ----------------

func next_kitchen_order():
	while not kitchen_queue.is_empty():
		var o = kitchen_queue.pop_front()
		if not o.canceled:
			return o
	return null


func dish_ready(o) -> void:
	if o.canceled:
		stats.wasted += 1
		return
	pass_orders.append(o)
	var chefs := staff_of("厨师")
	for ci in chefs.size():
		if chefs[ci].order == o:
			_fly("dish", STOVE_POS[mini(ci, STOVE_POS.size() - 1)], PASS_POS, 0.45, 0.0, o.dish.name)
	tasks.append({"type": "deliver", "table": o.table_idx, "order": o, "created": clock})


# ---------------- 结账 ----------------

func customer_done_eating(c) -> void:
	if randf() < 0.3:
		_float_text(c.position + Vector2(0, -60), ["嗝～", "饱了！", "舒坦"].pick_random(), Color.WHITE)
	if staff_of("掌柜").is_empty():
		c.self_pay()  # 没掌柜：在桌边自己慢慢算账，占着桌子
		return
	customer_left_table(c, false)
	cashier_queue.append(c)
	c.go_counter(_queue_pos(cashier_queue.size() - 1))


func _queue_pos(i: int) -> Vector2:
	return PAY_SPOT + Vector2(-34 * mini(i, 5), 0)


func next_payer():
	if cashier_queue.is_empty():
		return null
	var c = cashier_queue[0]
	if is_instance_valid(c) and c.at_counter():
		return c
	return null


func finish_payment(c) -> void:
	cashier_queue.erase(c)
	if is_instance_valid(c):
		customer_paid(c)
		c.go_home()
	for i in cashier_queue.size():
		cashier_queue[i].walk_to(_queue_pos(i))


## 柜台没人了：排队的客人直接付钱走人。
func _flush_cashier_queue() -> void:
	for c in cashier_queue:
		if is_instance_valid(c):
			customer_paid(c)
			c.go_home()
	cashier_queue.clear()


func _waiter_charm_bonus() -> float:
	var ws := staff_of("跑堂")
	if ws.is_empty():
		return 0.0
	var total := 0.0
	for w in ws:
		total += w.stat("魅力")
	return (total / ws.size() - 40.0) / 100.0 * 0.15


func customer_paid(c) -> void:
	var d: Dictionary = c.dish
	var ratio: float = float(c.price) / float(d.price)
	var wait_frac: float = clampf(c.strain / c.total_patience, 0.0, 1.0)
	var s: float = 0.62 + float(d.taste) * 0.07 + decor_level * 0.05 + _waiter_charm_bonus() - wait_frac * 0.45
	s += float(Data.TABLE_GRADES[table_level].sat) + decor_bonus("sat")
	if int(d.cat) == int(c.gtype.fav):
		s += 0.08  # 吃到最爱的菜系
	s += 0.04 * _trait_count("嘴甜") - 0.02 * _trait_count("爱吹牛")
	if ratio > 1.0:
		s -= (ratio - 1.0) * 0.8
	else:
		s += (1.0 - ratio) * 0.3
	s = clampf(s, 0.0, 1.0)
	var tip := 0
	var word := ""
	if s >= 0.8:
		tip = int(round(c.price * float(c.gtype.tip) * (1.0 + decor_bonus("tip")) * (1.5 if festival_today != "" else 1.0)))
		word = "好吃！"
	elif s >= 0.55:
		word = "不错"
	elif s >= 0.3:
		word = "一般般"
	else:
		word = "不值这个价…"
	var income: int = c.price + tip
	_book("营业", income)
	money += income
	if not staff_of("掌柜").is_empty():  # 铜钱一枚枚飞进柜台的钱匣
		for j in clampi(income / 30 + 1, 1, 6):
			_fly("coin", c.position + Vector2(0, -24), CASHIER_POS + Vector2(-20, 18), 0.4, j * 0.08)
	sfx.play("coin", -5.0)
	sfx.voice("bye", 0.25)
	stats.served += 1
	stats.income += income
	stats.tips += tip
	stats.sat_sum += s
	if contest_active:
		match Data.CONTESTS[contest_idx].type:
			"served":
				contest_value += 1.0
			"income":
				contest_value += income
			"satisfaction":
				contest_sat_sum += s
				contest_sat_n += 1
				contest_value = contest_sat_sum / contest_sat_n * 100.0
			"fine":
				if int(d.tier) == 2:
					contest_value += 1.0
	var txt := "+%d文" % income
	if tip > 0:
		txt += "（赏%d）" % tip
	_float_text(c.position + Vector2(0, -50), txt, Color("ffd34d"))
	_float_text(c.position + Vector2(0, -72), word, Color.WHITE)
	if c.gtype.has("regular") and s >= 0.55:
		_regular_up(int(c.gtype.regular))


func customer_left_table(c, angry: bool) -> void:
	var t: Dictionary = tables[c.table_idx]
	if t.customer == c:
		t.customer = null
	if angry:
		if c.order != null:
			c.order.canceled = true
			if pass_orders.has(c.order):
				pass_orders.erase(c.order)
				stats.wasted += 1
		stats.angry += 1
		sfx.play("angry", -4.0)
		if c.wants_order():
			stats.angry_order += 1
		_float_text(c.position + Vector2(0, -50), "等太久，气走了！", Color("ff7b6b"))
		_log("一位%s等得不耐烦，拂袖而去。" % c.gtype.name)
	elif t.plate != "":
		t.dirty = true
		tasks.append({"type": "clean", "table": c.table_idx, "created": clock})


func customer_gone(c) -> void:
	customers.erase(c)
	cashier_queue.erase(c)


func _change_rep(amount: float) -> void:
	if amount > 0.0:
		amount *= (1.0 - reputation / 150.0) * (1.0 + decor_bonus("rep"))  # 名气越高越难再涨
	reputation = clampf(reputation + amount, 0.0, 100.0)


## 营业声望每天打烊统一结算：看当天平均满意度和气走的比例，单日最多 +1.2、-1.5。
## 这样一天来 20 位还是 50 位客人，声望都不会暴涨暴跌。美食家来的那天影响 ×1.25。
func _daily_rep() -> void:
	var n: int = stats.served + stats.angry
	if n <= 0:
		return
	var avg_sat: float = stats.sat_sum / maxf(stats.served, 1.0)
	var angry_rate := float(stats.angry) / n
	var r := (1.2 + 4.0 * (avg_sat - 0.55) - 10.0 * angry_rate) * minf(1.0, n / 20.0)
	if critic_today:
		r *= 1.25
	_change_rep(clampf(r, -1.5, 1.2))


# ---------------- 一天的开始与结束 ----------------

func _reset_day_stats() -> void:
	stats = {"visitors": 0, "served": 0, "angry": 0, "angry_order": 0, "lost_full": 0, "lost_price": 0, "wasted": 0,
		"income": 0, "tips": 0, "ingredients": 0, "food_bought": 0, "sat_sum": 0.0, "slacks": 0,
		"rep_start": reputation, "food_warned": false}


func _start_game() -> void:
	game_started = true
	week_cash_start = money
	sfx.play("gong", -4.0)
	sfx.voice("open")
	if autotest:
		var lengths := PackedStringArray()
		for k in sfx._streams:
			lengths.append("%s=%.2fs" % [k, sfx._streams[k].get_length()])
		print("[autotest] sounds: ", ", ".join(lengths), " | voices: ", sfx._voices.keys())
	_log("云来客栈开张啦！")
	_set_speed(32.0 if autoplay_weeks > 0 else (8.0 if autotest else 1.0))


func _end_day() -> void:
	day_over = true
	sfx.play("gong", -6.0)
	var wages := 0
	for w in staff:
		wages += int(w.info.wage)
	money -= wages + RENT
	tasks.clear()
	kitchen_queue.clear()
	pass_orders.clear()
	cashier_queue.clear()
	for t in tables:
		t.dirty = false
		t.plate = ""
	for w in staff:
		w.reset_work()
	_book("工钱", -wages)
	_book("租金", -RENT)
	_daily_rep()
	var notes := _daily_growth()
	var spoiled := PackedStringArray()  # 菜蔬、河鲜放不住，每天坏掉一些
	for k in food.size():
		var lost := int(food[k] * float(Data.FOOD_KINDS[k].spoil) * float(season().spoil))
		if lost > 0:
			food[k] -= lost
			spoiled.append("%s %d" % [Data.FOOD_KINDS[k].name, lost])
	for w in staff:
		if w.info.get("trait", "") == "贪吃":
			var k := randi() % food.size()
			var eaten := mini(food[k], randi_range(8, 20))
			if eaten > 0:
				food[k] -= eaten
				spoiled.append("%s偷吃 %s %d" % [w.info.name, Data.FOOD_KINDS[k].name, eaten])
	if contest_active:
		contest_days += 1
	var earned: int = stats.income - wages - RENT - stats.food_bought
	var body := "今日来客 %d 位：招待 %d 位，气走 %d 位，客满错过 %d 位，嫌贵或没食材离开 %d 位。\n\n" % [
		stats.visitors, stats.served, stats.angry, stats.lost_full, stats.lost_price]
	body += "收入　%d 文（含赏钱 %d 文）\n工钱　-%d 文\n租金　-%d 文\n" % [stats.income, stats.tips, wages, RENT]
	if stats.food_bought > 0:
		body += "急购食材　-%d 文\n" % stats.food_bought
	body += "净赚　%+d 文\n\n用掉食材 %d，还剩 %s　　声望 %d → %d" % [
		earned, stats.ingredients, _food_text(), int(stats.rep_start), int(reputation)]
	if not spoiled.is_empty():
		body += "\n放坏了：" + "，".join(spoiled)
	if stats.served > 0:
		body += "　　平均满意度 %d" % int(stats.sat_sum / stats.served * 100.0)
	if contest_active:
		body += "\n\n比赛「%s」第 %d / 6 天：%s" % [Data.CONTESTS[contest_idx].name, contest_days, _contest_progress_text()]
	if notes != "":
		body += "\n\n" + notes
	_log("%s打烊，净赚 %+d 文。" % [_date_text(), earned])
	if autoplay_weeks > 0:
		_autoplay_day_end()
	if autotest:
		print("[autotest]   angry while waiting to order: %d" % stats.angry_order)
		print("[autotest] %s end: visitors=%d served=%d angry=%d full=%d lost=%d income=%d food=%d money=%d rep=%.1f slacks=%d staff=%d" % [
			_date_text(), stats.visitors, stats.served, stats.angry, stats.lost_full, stats.lost_price,
			stats.income, _food_total(), money, reputation, stats.slacks, staff.size()])
	_refresh_ui()
	if money < 0 and autoplay_weeks > 0:
		print("[play] BANKRUPT at %s money=%d" % [_date_text(), money])
		get_tree().quit()
		return
	if money < 0:
		var e: Dictionary = Data.ENDINGS["annexed" if rivals[1].open else "sold"]
		_show_popup(e.title, body + "\n\n账上亏空 %d 文。" % -money + e.text, "重新开始", _restart)
	elif weekday() == 5:
		_enter_rest_day(body)  # 一周打完烊，直接进集市
	else:
		_show_popup("%s打烊" % _date_text(), body, "明天接着开张", _start_next_day)


## 每个营业日结束：伙计长经验、向心力随工钱变化、研发推进。
func _daily_growth() -> String:
	var notes := PackedStringArray()
	for w in staff:
		var key: String = Data.ROLE_STAT[w.role()]
		w.info.stats[key] = mini(99, w.stat(key) + randi_range(0, 2))
		var fair := fair_wage(w.info)
		var loyal: int = w.stat("向心力")
		if int(w.info.wage) < fair - 5:
			loyal -= 2
		elif int(w.info.wage) >= fair:
			loyal += 1
		w.info.stats["向心力"] = clampi(loyal, 0, 99)
	if research != null:
		var pts := 0.0
		for w in staff_of("厨师"):
			pts += w.stat("厨艺") / 8.0
		research.points += pts
		var d: Dictionary = research.dish
		if research.points >= float(d.research_need):
			d.unlocked = true
			notes.append("研发成功：「%s」上了菜单！" % d.name)
			_log("研发成功：「%s」上了菜单！" % d.name)
			research = null
	return "\n".join(notes)


func _start_next_day() -> void:
	day += 1
	day_time = 0.0
	is_open = true
	day_over = false
	is_rest_day = false
	spawn_timer = 2.0
	today_patience = 1.0
	today_arrival = 1.0
	critic_today = false
	festival_today = _festival_name()
	regular_today.clear()
	_reset_day_stats()
	_schedule_event()
	sfx.play("gong", -4.0)
	sfx.voice("open")
	_log("%s开张。" % _date_text())
	if festival_today != "":
		_log("今天是%s，街上热闹，客人多、赏钱也大方！" % festival_today)
	_set_speed(speed if speed > 0.0 else last_speed)
	queue_redraw()


func _enter_rest_day(week_summary := "") -> void:
	_close_week_ledger()  # 先把这一周的账结了
	day += 1
	is_rest_day = true
	day_over = false
	selected_staff = null
	var notes := PackedStringArray()
	# 借钱的书生
	if scholar_loan:
		scholar_loan = false
		if randf() < 0.6:
			money += 700
			notes.append("那位赶考书生高中了，派人送来 700 文谢礼！")
		else:
			notes.append("借给书生的盘缠，看来是要不回来了。")
	# 向心力太低的伙计辞工
	for w in staff.duplicate():
		if w.stat("向心力") < 25 and randf() < 0.5:
			var r: String = w.role()
			if (r == "厨师" or r == "跑堂") and staff_of(r).size() <= 1:
				continue
			notes.append("%s嫌工钱少、干得不痛快，辞工走了。" % w.info.name)
			_remove_staff(w)
	festival_today = ""
	if week() % Data.WEEKS_PER_SEASON == 0:
		var ns: Dictionary = Data.SEASONS[season_of_week(week() + 1)]
		notes.append("下周入%s：%s" % [ns.name, ns.desc])
		var tax := Data.TAX_BASE + 30 * tables.size() + 200 * decor_level
		if _regular_at(3, 0):
			tax /= 2
		money -= tax
		_book("税与失窃", -tax)
		notes.append("这一季的税银 %d 文交到了县衙%s。" % [tax, "（赵捕头帮着说情，减了一半）" if _regular_at(3, 0) else ""])
	if money > 0 and randf() < Data.THEFT_CHANCE * pow(0.5, staff_of("杂役").size()):
		var lost := int(money * randf_range(0.1, 0.2))
		money -= lost
		_book("税与失窃", -lost)
		notes.append("夜里遭了贼，柜上丢了 %d 文！（杂役守夜能防贼）" % lost)
		_log("夜里遭贼，丢了 %d 文。" % lost)
	notes.append_array(_update_rivals())
	_refresh_market()
	_roll_food_prices()
	_plan_restock()
	var restock := _auto_restock()
	if restock != "":
		notes.append(restock)
	chars_layer.visible = false  # 休假日画集市街景，大堂里的人先藏起来
	var title := "第 %d 周结束，进集市" % week()
	var result := ""
	if contest_active and contest_days >= 6:
		result = _finish_contest()
	var ending := ""
	if not ending_shown and (game_finished or week() >= Data.FINAL_WEEK):
		ending = _ending()
	if ending != "":
		ending_shown = true
		var e: Dictionary = Data.ENDINGS[ending]
		_show_popup(e.title, (result + "\n\n" if result != "" else "") + e.text + "\n\n（可以继续经营）", "继续经营", _after_rest_popup)
	else:
		var body := "办完事点街尾的「回店开张」，开始新的一周。"
		if week() == 1:
			body = "今天歇业，掌柜的去逛集市。点街上的铺子就能办事：\n· 粮行：进食材、设自动补货\n· 人力市场：本周有新的应征者\n· 木工坊：添桌、装修、桌椅、灶台、摆件\n· 杂货铺：给伙计买道具\n· 街口告示牌：报名比赛\n\n" + body
		if result != "":
			body = result + "\n\n" + body
		if not notes.is_empty():
			body = "\n".join(notes) + "\n\n" + body
		if week_summary != "":
			body = "【周六账目】\n" + week_summary + "\n\n" + body
		_show_popup(title, body, "逛集市", _after_rest_popup)
	_rebuild_staff_list()
	_refresh_ui()
	queue_redraw()
	_save_game()


# ---------------- 存档 ----------------
# 只在休假日存：这时大堂没有客人和订单，存经营数据就够了。读档后回到那个休假日的集市。

const SAVE_VARS := ["money", "food", "food_price", "reputation", "day", "decor_level", "table_level", "stove_level", "counter_level", "expand_level",
	"auto_food_on", "auto_food_target", "contest_idx", "contest_active", "contest_days", "contest_value",
	"contest_sat_sum", "contest_sat_n", "scholar_loan", "game_finished", "food_fixed", "food_used_week", "food_hist", "seats_last_week", "story_step", "story_wait_week", "regular_friend", "rivals", "chapter", "ending_shown", "ledger", "ledger_history", "week_cash_start"]


func _save_path() -> String:
	return "user://autotest_save.json" if autotest else "user://save.json"


func _save_game() -> void:
	var s := {"pieces": pieces.map(func(c): return [c.x, c.y]), "ornaments": ornaments, "market": market, "staff": [], "dishes": [], "research": null}
	for k in SAVE_VARS:
		s[k] = get(k)
	for w in staff:
		s.staff.append(w.info)
	for d in dishes:
		s.dishes.append([d.unlocked, d.ratio])
	if research != null:
		s.research = {"dish": dishes.find(research.dish), "points": research.points}
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(s, "", false))  # 不排序键，能力值读回来顺序不乱


func _load_game() -> void:
	var s = JSON.parse_string(FileAccess.get_file_as_string(_save_path()))
	if typeof(s) != TYPE_DICTIONARY:
		_show_popup("云来客栈", "存档坏了，读不出来，只能重新开张。", "开张营业", _start_game)
		return
	for k in SAVE_VARS:
		if s.has(k):  # 老存档里没有的新字段，保持开局值
			set(k, type_convert(s[k], typeof(get(k))))
	food = food.map(func(v): return int(v))
	auto_food_target = auto_food_target.map(func(v): return int(v))
	if s.has("pieces"):
		pieces = s.pieces.map(func(v): return Vector2i(int(v[0]), int(v[1])))
	_rebuild_seats()
	ornaments.clear()
	for id in s.ornaments:
		ornaments[id] = int(s.ornaments[id])
	for i in dishes.size():
		dishes[i].unlocked = s.dishes[i][0]
		dishes[i].ratio = float(s.dishes[i][1])
	research = null
	if s.research != null:
		research = {"dish": dishes[int(s.research.dish)], "points": float(s.research.points)}
	# JSON 里的数都成了小数，能力值、工钱改回整数
	for info in s.staff + s.market:
		for st in info.stats:
			info.stats[st] = int(info.stats[st])
		info.wage = int(info.wage)
		if info.has("fee"):
			info.fee = int(info.fee)
	market = s.market
	for w in staff:
		w.queue_free()
	staff.clear()
	selected_staff = null
	for info in s.staff:
		_add_staff(info, true)
	game_started = true
	is_rest_day = true
	day_over = false
	chars_layer.visible = false
	_log("读取存档：%s。" % _date_text())
	_rebuild_staff_list()
	_refresh_ui()
	queue_redraw()
	tabs.current_tab = 2


func _after_rest_popup() -> void:
	if chapter < Data.CHAPTERS.size() and _chapter_done(chapter):
		var done: Dictionary = Data.CHAPTERS[chapter]
		chapter += 1
		var text := "「%s」目标达成：%s。" % [done.title, done.goal]
		var title := "本章完成"
		if chapter < Data.CHAPTERS.size():
			var nx: Dictionary = Data.CHAPTERS[chapter]
			title = nx.title
			text += "\n\n" + nx.text + "\n\n本章目标：" + nx.goal
		_log("%s完成。" % done.title)
		_show_popup(title, text, "继续", _after_rest_popup)
		return
	if _story_due():
		var ev: Dictionary = Data.STORY[story_step]
		story_step += 1
		var text: String = ev.text
		if text.contains("%d"):
			text = text % int(ev.cost)
		popup_portrait_key = "portraits/rival_boss"
		_show_popup(ev.title, text, ev.yes, _story_choice.bind(ev, true), ev.no, _story_choice.bind(ev, false))
		return
	tabs.current_tab = 2
	if autotest:
		_autotest_rest_day()
	elif autoplay_weeks > 0:
		_autoplay_rest_day()


# ---------------- 休假日布置 ----------------

func _toggle_arrange() -> void:
	if not is_rest_day:
		return
	arranging = not arranging
	drag = null
	hover_shop = ""
	_refresh_ui()
	queue_redraw()


## 鼠标按下的地方有什么能拖的。
func _pick_at(mp: Vector2):
	for id in ornaments:
		var s := int(ornaments[id])
		var c: Vector2 = WALL_SLOTS[s] + Vector2(0, 30) if _is_wall(id) else DECOR_SLOTS[s] + Vector2(0, -6)
		if mp.distance_to(c) < 28.0:
			return {"kind": "orn", "id": id}
	var pi := pieces.find(cell_of(mp))
	if pi >= 0:
		return {"kind": "table", "i": pi}
	return null


## 松手：放到最近的同类空位；那里已经有东西就两个对调。
func _drop(d: Dictionary, mp: Vector2) -> void:
	if d.kind == "table":
		var c := cell_of(mp)
		var ps: Array = pieces.duplicate()
		ps[d.i] = c
		if not _in_area(c):
			_float_text(mp, "那里还没扩建", Color("ffe2b0"))
		elif ps.count(c) > 1:
			_float_text(mp, "那儿已经有桌子了", Color("ffe2b0"))
		elif not _layout_ok(ps):
			_float_text(mp, "这样摆，伙计走不到座位", Color("ffe2b0"))
		else:
			pieces = ps
			_rebuild_seats()
		_refresh_ui()
		return
	var slots: Array = WALL_SLOTS if _is_wall(d.id) else DECOR_SLOTS
	var best := -1
	for s in slots.size():
		if mp.distance_to(slots[s]) < 90.0 and (best < 0 or mp.distance_to(slots[s]) < mp.distance_to(slots[best])):
			best = s
	if best < 0:
		return
	for id in ornaments:
		if id != d.id and _is_wall(id) == _is_wall(d.id) and int(ornaments[id]) == best:
			ornaments[id] = ornaments[d.id]
	ornaments[d.id] = best
	_refresh_ui()


# ---------------- 主线与结局 ----------------

func _chapter_done(i: int) -> bool:
	match i:
		0:
			return reputation >= 30.0
		1:
			return contest_idx >= 2 and rivals[1].closed
		2:
			return contest_idx >= Data.CONTESTS.size()
	return false


## 该看哪个结局（Data.ENDINGS 的键）。破产的结局在 _end_day 里另算。
func _ending() -> String:
	if game_finished:
		for r in rivals:
			if not r.closed:
				return "famous"
		return "overlord"
	return "keeper" if money > 0 and reputation >= 50.0 else "plain"


# ---------------- 同行 ----------------

func _avg_price_ratio() -> float:
	var sum := 0.0
	var n := 0
	for d in dishes:
		if d.unlocked:
			sum += float(d.ratio)
			n += 1
	return sum / n if n > 0 else 1.0


## 同行抢客：每家开着的同行按它和你的声望比、菜价比，分走一些客人。
func _rival_mult() -> float:
	var my_price := _avg_price_ratio()
	var m := 1.0
	for r in rivals:
		if r.open:
			var p := 0.12 * clampf(float(r.rep) / maxf(reputation, 5.0), 0.3, 1.5) * clampf(my_price / float(r.price), 0.6, 1.6)
			m *= 1.0 - clampf(p, 0.0, 0.3)
	return m


## 每个休假日同行动一动：开张、涨声望、打价格战、撑不住关门。返回要告诉玩家的消息。
func _update_rivals() -> PackedStringArray:
	var notes := PackedStringArray()
	for i in rivals.size():
		var d: Dictionary = Data.RIVALS[i]
		var r: Dictionary = rivals[i]
		if not r.open:
			if not r.closed and int(d.open_week) == week() + 1:
				r.open = true
				notes.append("对街新开了一家%s：%s" % [d.name, d.desc])
			continue
		r.rep = minf(100.0, float(r.rep) + float(d.grow) * randf_range(0.5, 1.5) + (1.0 if float(r.rep) < reputation else 0.0))
		if reputation > float(r.rep) + 5.0 and float(r.price) > 0.75:
			r.price = snappedf(float(r.price) - 0.05, 0.05)
			notes.append("%s降价了（菜价 ×%.2f），想把客人抢回去。" % [d.name, r.price])
		elif reputation < float(r.rep) and float(r.price) < float(d.price):
			r.price = snappedf(float(r.price) + 0.05, 0.05)
		r.weak = int(r.weak) + 1 if float(r.rep) < reputation * 0.45 else 0
		if int(r.weak) >= 3:
			r.open = false
			r.closed = true
			_change_rep(3.0)
			notes.append("%s生意被你抢光，撑不下去关门了！（声望 +3）" % d.name)
			_log("%s关门了。" % d.name)
	return notes


func _rivals_text() -> String:
	var lines := PackedStringArray()
	if chapter < Data.CHAPTERS.size():
		lines.append("%s —— 目标：%s" % [Data.CHAPTERS[chapter].title, Data.CHAPTERS[chapter].goal])
	lines.append("城南酒楼：云来客栈 声望 %d、菜价 ×%.2f" % [int(reputation), _avg_price_ratio()])
	for i in rivals.size():
		var r: Dictionary = rivals[i]
		if r.open:
			lines.append("　%s 声望 %d、菜价 ×%.2f" % [Data.RIVALS[i].name, int(r.rep), float(r.price)])
		elif r.closed:
			lines.append("　%s 已关门" % Data.RIVALS[i].name)
	return "\n".join(lines)


# ---------------- 常客 ----------------

## 第 ri 位常客的交情到没到第 step 档（Data.REGULAR_STEPS）。
func _regular_at(ri: int, step: int) -> bool:
	return int(regular_friend[ri]) >= int(Data.REGULAR_STEPS[step])


func _regular_up(ri: int) -> void:
	regular_friend[ri] = int(regular_friend[ri]) + 1
	var r: Dictionary = Data.REGULARS[ri]
	var step: int = Data.REGULAR_STEPS.find(int(regular_friend[ri]))
	if step < 0:
		return
	var text: String = Data.REGULAR_STORY[r.id][step]
	match [r.id, step]:
		["wang", 1]:
			money += 1500
		["liu", 1]:
			food[1] += 300
		["zhou", 0]:
			_change_rep(6.0)
		["zhao", 1]:
			_change_rep(8.0)
	_log("和%s的交情更深了。" % r.name)
	if popup.visible:  # 正有别的弹窗，就只记进日志
		_log(text.replace("\n", ""))
		return
	popup_portrait_key = "guests/" + r.id
	_show_popup("老主顾 · %s" % r.name, text, "好", Callable())


# ---------------- 剧情 ----------------

func _story_due() -> bool:
	if story_step > 0 and rivals[1].closed:
		story_step = Data.STORY.size()  # 醉仙楼已经关门，后面的戏不用唱了
	if game_finished or story_step >= Data.STORY.size():
		return false
	return week() >= maxi(int(Data.STORY[story_step].week), story_wait_week)


func _story_choice(ev: Dictionary, yes: bool) -> void:
	var msg := _story_effect(ev, yes)
	_log(msg)
	_refresh_ui()
	_show_popup(ev.title, msg, "知道了", _after_rest_popup)


func _best_cook():
	var best = null
	for w in staff_of("厨师"):
		if best == null or w.stat("厨艺") > best.stat("厨艺"):
			best = w
	return best


## 剧情选择的后果，返回给玩家看的结果。
func _story_effect(ev: Dictionary, yes: bool) -> String:
	var cost: int = ev.cost
	var prefix := ""
	if yes and money < cost:
		prefix = "银钱不够，只好作罢。\n"
		yes = false
	if yes:
		money -= cost
	var best = _best_cook()
	match ev.id:
		"rival_open":
			rivals[1].open = true
			return "醉仙楼开张了。往后得打起精神，别让人比下去。"
		"rival_poach":
			if best == null:
				return prefix + "店里眼下没有厨师，醉仙楼的人白跑一趟。"
			if yes:
				best.info.stats["向心力"] = mini(99, best.stat("向心力") + 20)
				best.info.wage = int(best.info.wage) + 10
				return "%s收了红包，拍着胸脯说生是云来客栈的人。" % best.info.name
			if staff_of("厨师").size() > 1:
				_remove_staff(best)
				_rebuild_staff_list()
				return prefix + "%s卷了铺盖，跳槽去了醉仙楼。" % best.info.name
			return prefix + "%s念着旧情，到底没走。" % best.info.name
		"rival_rumor":
			if yes:
				_change_rep(5.0)
				return "县衙的人验看了后厨，张榜澄清。街坊们都说云来客栈干净实在，声望反倒涨了。"
			_change_rep(-8.0)
			return prefix + "谣言越传越真，好些老客都不来了。声望掉了一截。"
		"rival_duel":
			if yes and best != null and randf() < best.stat("厨艺") / 110.0:
				money += cost * 2
				rivals[1].open = false
				rivals[1].closed = true
				_change_rep(8.0)
				return "%s在擂台上一道菜惊艳四座，赢回 %d 文！\n醉仙楼没脸再开，钱东家关门回乡了。" % [best.info.name, cost * 2]
			story_step -= 1  # 过四周再下战书
			story_wait_week = week() + 4
			if yes:
				_change_rep(-3.0)
				return "擂台上输了一招，赌注没了。钱东家说，过一个月再比一回。"
			_change_rep(-2.0)
			return prefix + "你没应战，醉仙楼的人在街上笑话了好几天。他们说一个月后还会再来。"
	return prefix


func _end_rest_day() -> void:
	if not is_rest_day:
		return
	arranging = false
	drag = null
	_save_game()  # 存下休假日里买的东西
	chars_layer.visible = true
	hover_shop = ""
	_start_next_day()


## 休假日自动补货：每类食材补到设定的数，钱不够就补能付得起的部分。
func _auto_restock() -> String:
	if not auto_food_on:
		return ""
	var bought := PackedStringArray()
	var short := false
	var used := {}  # 已解锁的菜用得到哪几类食材
	for d in dishes:
		if d.unlocked:
			used[int(d.food)] = true
	for k in food.size():
		var need: int = auto_food_target[k] - food[k]
		if need <= 0 or not used.has(k):
			continue
		var amount := mini(need, int(maxi(money - CASH_RESERVE, 0) / _food_mult(k)))
		if amount < need:
			short = true
		if amount <= 0:
			continue
		money -= _food_cost(k, amount)
		_book("常规采购", -_food_cost(k, amount))
		food[k] += amount
		bought.append("%s %d" % [Data.FOOD_KINDS[k].name, amount])
	if bought.is_empty():
		return "银钱不够，这周没能自动补货。" if short else ""
	var msg := "自动补货：进了 " + "，".join(bought) + ("（银钱不够，没补满）" if short else "")
	_log(msg)
	return msg


## 每个休假日食材行情变一变。
func _roll_food_prices() -> void:
	for k in food_price.size():
		food_price[k] = clampf(snappedf(food_price[k] * randf_range(0.8, 1.25), 0.05), 0.7, 1.5)


## 食材价格倍率：本周行情 × 季节倾向。
func _food_mult(k: int) -> float:
	var liu := 0.85 if k == 1 and _regular_at(1, 0) else 1.0  # 柳三娘让价
	return float(food_price[k]) * float(season().price[k]) * liu


func _food_cost(k: int, amount: int) -> int:
	return ceili(amount * _food_mult(k))


func _food_total() -> int:
	var t := 0
	for v in food:
		t += v
	return t


func _food_text() -> String:
	var parts := PackedStringArray()
	for k in food.size():
		parts.append("%s %d" % [Data.FOOD_KINDS[k].name, food[k]])
	return "，".join(parts)


func _toggle_auto_food() -> void:
	auto_food_on = not auto_food_on
	_refresh_ui()


func _change_auto_food(k: int, step: int) -> void:
	auto_food_target[k] = clampi(auto_food_target[k] + step, 0, AUTO_FOOD_MAX)
	food_fixed[k] = true  # 手动调过就按玩家的来
	_refresh_ui()


func _smart_food(k: int) -> void:
	food_fixed[k] = false
	_refresh_ui()


## 智能补货：按最近三周卖菜实际用掉的量预测下周（不算放坏的，免得越买越坏越买），
## 再看座位变化、下周有没有节日，留一成半余量；每周最多上调 35%、下调 25%。
func _plan_restock() -> void:
	food_hist.push_front(food_used_week.duplicate())
	if food_hist.size() > 3:
		food_hist.pop_back()
	food_used_week = [0, 0, 0, 0]
	var cap := clampf(float(tables.size()) / maxf(1.0, float(seats_last_week)), 0.8, 1.35) if seats_last_week > 0 else 1.0
	seats_last_week = tables.size()
	var fest := 1.0
	for d in range(1, 7):  # 下周六个营业日里有节日就多备一点
		var dd := day + d
		var w := (dd - 1) / 7 + 1
		for f in Data.FESTIVALS:
			if int(f.season) == season_of_week(w) and int(f.week) == (w - 1) % Data.WEEKS_PER_SEASON and int(f.weekday) == (dd - 1) % 7:
				fest = 1.1
	var weights := [0.6, 0.3, 0.1]
	for k in food.size():
		if food_fixed[k]:
			continue
		var base := 0.0
		var wsum := 0.0
		for i in food_hist.size():
			base += float(food_hist[i][k]) * weights[i]
			wsum += weights[i]
		var target := 0
		if base <= 0.0:  # 刚研发出来、还没卖过：按这类菜的成本备个底
			var costs: Array = []
			for d in dishes:
				if d.unlocked and int(d.food) == k:
					costs.append(int(d.cost))
			if costs.is_empty():
				continue
			costs.sort()
			target = maxi(120, int(costs[costs.size() / 2]) * 8)
		else:
			var forecast := base / wsum * cap * fest
			target = int(forecast + maxf(60.0, forecast * 0.15))
		var prev: int = auto_food_target[k]
		if prev > 0:
			target = clampi(target, int(prev * 0.75), int(prev * 1.35))
		auto_food_target[k] = clampi(target, 0, AUTO_FOOD_MAX)


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


# ---------------- 城镇 ----------------

func _buy_food(k: int, amount: int) -> void:
	var cost := _food_cost(k, amount)
	if not is_rest_day or money < cost:
		return
	money -= cost
	_book("常规采购", -cost)
	food[k] += amount
	_log("在粮行进了 %d %s，花了 %d 文。" % [amount, Data.FOOD_KINDS[k].name, cost])
	_refresh_ui()


func _rush_food(k: int) -> void:
	var cost := _food_cost(k, RUSH_FOOD) * 2
	if is_rest_day or money < cost:
		return
	money -= cost
	_book("急购本金", -cost / 2)
	_book("急购加价", -cost + cost / 2)
	food[k] += RUSH_FOOD
	stats.food_bought += cost
	stats.food_warned = false
	_log("派人急购了 %d %s，花了 %d 文。" % [RUSH_FOOD, Data.FOOD_KINDS[k].name, cost])
	_refresh_ui()


func _refresh_market() -> void:
	market.clear()
	# 先放店里缺的（跑堂按每 4 座 1 人、厨师按每 6 座 1 人算），再随机补满三个
	var roles: Array = []
	for must in [["跑堂", 4.0], ["厨师", 6.0]]:
		if staff_of(must[0]).size() < ceili(tables.size() / must[1]) and _role_room(must[0]):
			roles.append(must[0])
	var rest: Array = Data.ROLES.duplicate()
	rest.shuffle()
	for r in rest:
		if roles.size() < 3 and not roles.has(r):
			roles.append(r)
	for i in 3:
		var role: String = roles[i]
		var info := _make_staff(role, randi_range(20, 65), randi_range(45, 75))
		info["fee"] = 100 + int(info.stats[Data.ROLE_STAT[role]]) * 4
		market.append(info)


func _hire_candidate(i: int) -> void:
	if not is_rest_day or i >= market.size():
		return
	var cand: Dictionary = market[i]
	if cand.get("hired", false) or staff.size() >= MAX_STAFF or money < int(cand.fee):
		return
	var role: String = cand.role
	if not _role_room(role):
		role = ""
		for r in Data.ROLES:
			if _role_room(r):
				role = r
				break
		if role == "":
			return
	money -= int(cand.fee)
	_book("招人", -int(cand.fee))
	cand["hired"] = true
	var info := {"name": cand.name, "role": role, "stats": cand.stats.duplicate(), "wage": cand.wage,
		"color": STAFF_COLORS[role].pick_random(), "sash": cand.sash, "look": cand.look, "trait": cand.trait}
	_add_staff(info, false)
	_log("从人力市场雇来%s，当%s。" % [cand.name, role])
	_refresh_ui()


func _table_cost() -> int:
	return 200 + 120 * (pieces.size() - START_PIECES.size())


## 新桌子放哪：摆得下、不挡路的格子里，挑多出座位最多的；一样多就挑离中间近的。没有返回 (-1, -1)。
func _free_piece_cell() -> Vector2i:
	var e: Dictionary = Data.EXPANSIONS[expand_level]
	var best := Vector2i(-1, -1)
	var best_score := -INF
	var base := _seat_cells(pieces).size()
	for r in range(int(e.rows[0]), int(e.rows[1]) + 1):
		for col in range(int(e.cols[0]), int(e.cols[1]) + 1):
			var c := Vector2i(col, r)
			if pieces.has(c) or not _layout_ok(pieces + [c]):
				continue
			var gain := _seat_cells(pieces + [c]).size() - base
			if gain <= 0:
				continue  # 多一张桌子却不多座位，不算摆得下
			var score := gain * 100.0 - absf(col - 8) - absf(r - 3) * 0.5
			if score > best_score:
				best_score = score
				best = c
	return best


func _buy_table() -> void:
	var cost := _table_cost()
	var c := _free_piece_cell()
	if not is_rest_day or c.x < 0 or money < cost:
		return
	money -= cost
	_book("店面", -cost)
	pieces.append(c)
	_rebuild_seats()
	_log("木工坊送来一张长方桌，现在有 %d 个座位。" % tables.size())
	_refresh_ui()
	queue_redraw()


func _expand() -> void:
	if not is_rest_day or expand_level >= Data.EXPANSIONS.size() - 1:
		return
	var e: Dictionary = Data.EXPANSIONS[expand_level + 1]
	if money < int(e.cost):
		return
	money -= int(e.cost)
	_book("店面", -int(e.cost))
	expand_level += 1
	_log("大堂扩建：%s，能摆更多桌子了。" % e.name)
	_refresh_ui()
	queue_redraw()


## 摆件加成：把已买摆件里同一种加成加起来。
func decor_bonus(kind: String) -> float:
	var total := 0.0
	for it in Data.DECOR_ITEMS:
		if it.bonus == kind and ornaments.has(it.id):
			total += float(it.value)
	return total


func stove_speed() -> float:
	return float(Data.STOVE_GRADES[stove_level].speed)


func _upgrade_tables() -> void:
	if not is_rest_day or table_level >= Data.TABLE_GRADES.size() - 1:
		return
	var g: Dictionary = Data.TABLE_GRADES[table_level + 1]
	if money < int(g.cost):
		return
	money -= int(g.cost)
	_book("店面", -int(g.cost))
	table_level += 1
	_log("桌椅换成了%s。" % g.name)
	_refresh_ui()
	queue_redraw()


func _upgrade_stove() -> void:
	if not is_rest_day or stove_level >= Data.STOVE_GRADES.size() - 1:
		return
	var g: Dictionary = Data.STOVE_GRADES[stove_level + 1]
	if money < int(g.cost):
		return
	money -= int(g.cost)
	_book("店面", -int(g.cost))
	stove_level += 1
	_log("后厨砌了%s，出菜更快了。" % g.name)
	_refresh_ui()
	queue_redraw()


func _upgrade_counter() -> void:
	if not is_rest_day or counter_level >= Data.COUNTER_GRADES.size() - 1:
		return
	var g: Dictionary = Data.COUNTER_GRADES[counter_level + 1]
	if money < int(g.cost):
		return
	money -= int(g.cost)
	_book("店面", -int(g.cost))
	counter_level += 1
	_log("柜台换成了%s，结账更快了。" % g.name)
	_refresh_ui()
	queue_redraw()


func counter_speed() -> float:
	return float(Data.COUNTER_GRADES[counter_level].speed)


func _free_slot(after := -1, wall := false) -> int:
	var used := {}
	for id in ornaments:
		if _is_wall(id) == wall:
			used[int(ornaments[id])] = true
	var n: int = WALL_SLOTS.size() if wall else DECOR_SLOTS.size()
	for k in range(1, n + 1):
		var s := (after + k) % n
		if not used.has(s):
			return s
	return -1


func _buy_ornament(id: String) -> void:
	if not is_rest_day or ornaments.has(id):
		return
	for it in Data.DECOR_ITEMS:
		if it.id == id:
			var slot := _free_slot(-1, it.get("wall", false))
			if slot < 0 or money < int(it.cost):
				return
			money -= int(it.cost)
			_book("店面", -int(it.cost))
			ornaments[id] = slot
			_log("木工坊送来了%s。" % it.name)
	_refresh_ui()
	queue_redraw()


func _move_ornament(id: String) -> void:
	if not is_rest_day or not ornaments.has(id):
		return
	var slot := _free_slot(int(ornaments[id]), _is_wall(id))
	if slot >= 0:
		ornaments[id] = slot
		queue_redraw()
		_refresh_ui()


func _buy_decor() -> void:
	if not is_rest_day or decor_level >= DECOR_COSTS.size():
		return
	var cost: int = DECOR_COSTS[decor_level]
	if money < cost:
		return
	money -= cost
	_book("店面", -cost)
	decor_level += 1
	_log("装修升级为「%s」。" % DECOR_NAMES[decor_level])
	_refresh_ui()
	queue_redraw()


func _buy_item(k: int) -> void:
	var it: Dictionary = Data.ITEMS[k]
	var w = selected_staff
	if not is_rest_day or w == null or not is_instance_valid(w) or money < int(it.price):
		return
	money -= int(it.price)
	var st: Dictionary = w.info.stats
	st[it.stat] = mini(99, int(st[it.stat]) + int(it.amount))
	st["向心力"] = mini(99, int(st["向心力"]) + int(it.loyal))
	w.apply_role_speed()
	_log("给%s买了%s。" % [w.info.name, it.name])
	_refresh_ui()


# ---------------- 菜谱研发 ----------------

func _start_research(d: Dictionary) -> void:
	if research != null or d.unlocked or money < int(d.research_cost):
		return
	money -= int(d.research_cost)
	_book("研发", -int(d.research_cost))
	research = {"dish": d, "points": 0.0}
	_log("厨师们开始琢磨新菜「%s」。" % d.name)
	_refresh_ui()


func _next_locked(ci: int):
	for d in dishes:
		if int(d.cat) == ci and not d.unlocked:
			return d
	return null


func _change_price(d: Dictionary, step: int) -> void:
	d.ratio = clampf(snappedf(float(d.ratio) + step * 0.1, 0.1), 0.6, 2.0)
	_refresh_ui()


# ---------------- 比赛 ----------------

func _contest_block_reason() -> String:
	if contest_idx >= Data.CONTESTS.size():
		return "比赛已经全部赢下"
	if contest_active:
		return "比赛进行中"
	var c: Dictionary = Data.CONTESTS[contest_idx]
	if reputation < float(c.rep):
		return "声望要到 %d" % c.rep
	if tables.size() < int(c.tables):
		return "店面要有 %d 个座位" % c.tables
	if not is_rest_day:
		return "休假日才能报名"
	if money < int(c.fee):
		return "报名费不够"
	return ""


func _sign_contest() -> void:
	if _contest_block_reason() != "":
		return
	var c: Dictionary = Data.CONTESTS[contest_idx]
	money -= int(c.fee)
	_book("比赛", -int(c.fee))
	contest_active = true
	contest_days = 0
	contest_value = 0.0
	contest_sat_sum = 0.0
	contest_sat_n = 0
	_log("报名参加「%s」，下周六天比%s。" % [c.name, Data.CONTEST_TYPES[c.type]])
	_refresh_ui()


func _contest_progress_text() -> String:
	var c: Dictionary = Data.CONTESTS[contest_idx]
	if c.type == "satisfaction":
		return "平均满意度 %d / 目标 %d" % [int(contest_value), int(c.target)]
	return "%s %d / 目标 %d" % [Data.CONTEST_TYPES[c.type], int(contest_value), int(c.target)]


func _finish_contest() -> String:
	var c: Dictionary = Data.CONTESTS[contest_idx]
	contest_active = false
	var line := "比赛「%s」结束：%s。" % [c.name, _contest_progress_text()]
	if contest_value >= float(c.target):
		money += int(c.prize)
		_book("比赛", int(c.prize))
		reputation = minf(100.0, reputation + 5.0)
		contest_idx += 1
		_log("赢下「%s」，奖金 %d 文！" % [c.name, c.prize])
		if contest_idx >= Data.CONTESTS.size():
			game_finished = true
		return line + "\n云来客栈获胜！奖金 %d 文，声望 +5。" % c.prize
	_log("「%s」没比过，下次再来。" % c.name)
	return line + "\n可惜没达到目标，报名费打了水漂。随时可以再报名。"


# ---------------- 访客事件 ----------------

## 有选项的事件（弹窗，等你拿主意）每天 35%；没选项的天灾（走水、大雪）每天 12%，只飘字记日志、不打断。
func _schedule_event() -> void:
	event_hour = randf_range(9.5, 17.0) if randf() < 0.35 else -1.0
	mishap_hour = randf_range(9.5, 17.0) if randf() < 0.12 else -1.0


func _trigger_random_event() -> void:
	var options: Array = []
	for ev in Data.EVENTS:
		if ev.id == "master_chef" and (not _role_room("厨师") or staff.size() >= MAX_STAFF):
			continue
		if ev.id == "scholar" and scholar_loan:
			continue
		options.append(ev)
	options.append(Data.DISASTERS[0])  # 官府查店有选项，混在普通访客里
	_trigger_event(options.pick_random())


## 没选项的天灾：直接生效，飘字 + 日志，不弹窗。
func _trigger_mishap() -> void:
	var options: Array = []
	for ev in Data.DISASTERS:
		if ev.no == "" and ev.id != last_mishap and (not ev.has("season") or int(ev.season) == season_of_week(week())):
			options.append(ev)
	if options.is_empty():
		return
	var ev: Dictionary = options.pick_random()
	last_mishap = ev.id
	_float_text(Vector2(450, 300), "【%s】" % ev.title, Color("ffb070"))
	_event_accept(ev)


func _trigger_event(ev: Dictionary) -> void:
	var cost: int = ev.cost
	var text: String = ev.text
	if text.contains("%d"):
		text = text % cost
	popup_event = ev.id
	popup_portrait_key = "portraits/" + ev.id
	_show_popup(ev.title, text, ev.yes, _event_accept.bind(ev), ev.no, _event_decline.bind(ev))


func _event_accept(ev: Dictionary) -> void:
	var cost: int = ev.cost
	if money < cost:
		_log("银钱不够，只好作罢。")
		_event_decline(ev)
		return
	money -= cost
	_book("事件", -cost)
	match ev.id:
		"storyteller":
			today_patience *= 0.7
			_change_rep(1.0)
			_log("说书先生开讲，满堂喝彩。")
		"acrobat":
			today_arrival = 1.4
			_log("门口锣鼓喧天，引来不少客人。")
		"scholar":
			scholar_loan = true
			_log("借给赶考书生 %d 文盘缠。" % cost)
		"bully":
			_log("给了地痞 %d 文，打发走了。" % cost)
		"critic":
			critic_today = true
			_log("美食家入座，今天的评价分量加倍。")
		"doctor":
			for w in staff:
				w.info.stats["向心力"] = mini(99, w.stat("向心力") + 10)
				w.info.stats["毅力"] = mini(99, w.stat("毅力") + 6)
			_log("伙计们喝了药茶，精神抖擞。")
		"inspect":
			_log("差役收了茶钱，随便看了两眼就走了。")
		"fire":
			if not staff_of("杂役").is_empty() or randf() < 0.5:
				food[0] = maxi(0, food[0] - 30)
				_log("火扑灭了，只烧了些柴米。")
			else:
				money -= 400
				_book("事件", -400)
				today_arrival *= 0.5
				_change_rep(-2.0)
				_log("火势太大，灶台烧坏了，修灶花了 400 文，客人也吓跑了一半。（有杂役能更快扑灭）")
		"snow":
			today_arrival *= 0.4
			_log("大雪封路，今天客人少得很。")
		"master_chef":
			var info := _make_staff("厨师", randi_range(78, 92), 70)
			_add_staff(info, false)
			_log("名厨%s留下来掌勺了！" % info.name)
	_refresh_ui()


func _event_decline(ev: Dictionary) -> void:
	if ev.id == "inspect":
		if _regular_at(3, 1):
			_log("赵捕头打过招呼，差役转了一圈就走了。")
		elif randf() < 0.4 + 0.15 * decor_level + 0.1 * staff_of("杂役").size():
			_change_rep(2.0)
			_log("后厨查得干干净净，差役当众夸了两句。（声望 +2）")
		else:
			money -= 500
			_change_rep(-3.0)
			_log("差役说后厨脏乱，罚了 500 文。（装修好、杂役多更容易过关）")
	elif ev.id == "bully" and _regular_at(3, 0):
		_log("地痞一听赵捕头的名字，灰溜溜地走了。")
	elif ev.id == "bully" and randf() < 0.6:
		var scared := 0
		for c in customers.duplicate():
			if is_instance_valid(c) and c.is_waiting():
				c.leave_angry()
				scared += 1
		_change_rep(-3.0)
		_log("地痞在店里闹了一通，吓跑了 %d 位客人。" % scared)
	elif ev.id == "bully":
		_log("街坊们帮着把地痞轰走了。")


# ---------------- 提示 ----------------

func _float_text(pos: Vector2, text: String, color: Color) -> void:
	var ft = FloatText.new()
	ft.font = font
	ft.text = text
	ft.color = color
	ft.position = pos
	fx_layer.add_child(ft)


func _log(msg: String) -> void:
	log_lines.append("[color=#a08a70]%s %s[/color]  %s" % [Data.WEEKDAYS[weekday()], _clock_text(), msg])
	while log_lines.size() > 5:
		log_lines.remove_at(0)
	if lbl_log != null:
		lbl_log.text = "\n".join(log_lines)


# ---------------- 画面 ----------------

func _disc(p: Vector2, r: float, c: Color) -> void:
	draw_circle(p, r, c, true, -1.0, true)


func _shadow(center: Vector2, r: float) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, 0.4))
	_disc(Vector2.ZERO, r, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 几缕往上飘的热气。strength 0~1 控制浓淡。
func _steam(p: Vector2, t: float, strength: float) -> void:
	for k in 3:
		var rise := fmod(t * 14.0 + k * 7.0, 21.0)
		var x := sin(t * 3.0 + k * 2.0 + rise * 0.2) * 3.0 + (k - 1) * 5.0
		_disc(p + Vector2(x, -rise), 2.5 + rise * 0.12, Color(1, 1, 1, (0.45 - rise / 50.0) * strength))


func _fly(kind: String, from: Vector2, to: Vector2, dur: float, delay := 0.0, dish_name := "") -> void:
	flights.append({"kind": kind, "from": from, "to": to, "start": clock + delay, "dur": dur, "dish": dish_name})


## 画在最上层 fx_layer 上，盖住人物。
func _draw_flights() -> void:
	for f in flights.duplicate():
		var k: float = (clock - float(f.start)) / float(f.dur)
		if k < 0.0:
			continue
		if k >= 1.0:
			flights.erase(f)
			continue
		var p: Vector2 = f.from.lerp(f.to, k) + Vector2(0, -sin(k * PI) * 30.0)  # 抛物线
		match f.kind:
			"dish":
				var dt: Texture2D = art.dish(f.dish)
				if dt != null:
					fx_layer.draw_texture_rect(dt, Rect2(p - Vector2(11, 11), Vector2(22, 22)), false)
				else:
					fx_layer.draw_circle(p, 8.0, Color("f8f4ea"))
			"coin":
				fx_layer.draw_circle(p, 5.0, Color("d4a640"))
				fx_layer.draw_circle(p, 3.0, Color("ffd34d"))
				fx_layer.draw_rect(Rect2(p - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color("8a6a1a"))
			"puff":  # 原地一团热气散开
				for j in 5:
					var a := j * TAU / 5.0
					fx_layer.draw_circle(f.from + Vector2(cos(a), sin(a) * 0.6) * (6.0 + k * 14.0) + Vector2(0, -k * 10.0), 4.0 + k * 3.0, Color(1, 1, 1, 0.55 * (1.0 - k)))
	fx_layer.queue_redraw()


## 天黑的程度：0 = 白天，1 = 入夜。申时末开始泛黄，酉时渐暗，戌时全黑；休假日的集市一直是白天。
func night_amount() -> float:
	if is_rest_day or not game_started:
		return 0.0
	return clampf((current_hour() - 17.0) / 2.0, 0.0, 1.0)


func _update_daylight() -> void:
	var h := current_hour()
	var dusk := 0.0 if (is_rest_day or not game_started) else clampf((h - 15.5) / 1.5, 0.0, 1.0)
	var n := night_amount()
	daylight.color = Color.WHITE.lerp(Color(1.0, 0.88, 0.72), dusk).lerp(Color(0.52, 0.56, 0.78), n)
	glow_layer.queue_redraw()


## 夜里的灯光：灯笼、灶火、柜台和门口各一团暖光（加亮混合，叠在调暗的画面上）。
func _draw_glow() -> void:
	var n := night_amount()
	if n < 0.02:
		return
	var lights: Array = [[Vector2(450, 690), 70.0], [CASHIER_POS + Vector2(0, 10), 60.0]]
	if decor_level >= 1:
		for p in [Vector2(36, 280), Vector2(36, 470), Vector2(864, 280), Vector2(864, 470)]:
			lights.append([p, 55.0])
	var chefs := staff_of("厨师")
	for i in mini(chefs.size(), STOVE_POS.size()):
		lights.append([STOVE_POS[i] + Vector2(0, 10), 60.0 if chefs[i].order != null else 35.0])
	var flicker := 0.92 + 0.08 * sin(Time.get_ticks_msec() / 160.0)
	for l in lights:
		var p: Vector2 = l[0]
		var r: float = l[1] * flicker
		for k in 4:
			glow_layer.draw_circle(p, r * (1.0 - k * 0.22), Color(1.0, 0.62, 0.25, 0.07 * n), true, -1.0, true)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("2b1d14"))
	if is_rest_day and not arranging:
		_draw_market()
		return
	_draw_kitchen()
	_draw_hall()
	_draw_tables()
	_draw_decor()
	if arranging:
		var hint := "布置中：按住拖动桌子、摆件、字画，松手放到最近的空位"
		draw_string_outline(font, Vector2(40, 700), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(40, 700), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe9b0"))
	elif is_rest_day:
		draw_rect(Rect2(20, 200, 860, 508), Color(0.08, 0.05, 0.02, 0.35))
		var banner := Rect2(290, 410, 320, 60)
		draw_rect(banner, Color("3b1a12"))
		draw_rect(banner, Color("d4a640"), false, 2.0)
		var txt := "休假日 · 今日歇业"
		var tw := title_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(title_font, Vector2(450 - tw / 2.0, 449), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("f3d27a"))


func _draw_kitchen() -> void:
	# 后厨：青白相间的瓷砖
	draw_rect(KITCHEN_RECT, Color("d4e4d0"))
	for y in range(70, 180, 22):
		for x in range(20, 880, 22):
			if (x / 22 + y / 22) % 2 == 0:
				draw_rect(Rect2(x, y, mini(22, 880 - x), mini(22, 180 - y)), Color("bcd3b8"))
	draw_string(title_font, Vector2(26, 176), "后厨", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.2, 0.3, 0.2, 0.45))
	draw_rect(Rect2(20, 62, 860, 10), Color("5a3a22"))
	# 后墙的架子：坛子和挂着的腊肉、辣椒
	for x in [120, 680]:
		draw_rect(Rect2(x, 84, 120, 4), Color("6b4226"))
		for k in 4:
			var jp := Vector2(x + 16 + k * 28, 76)
			_disc(jp, 7.0, Color("7a4a2a") if k % 2 == 0 else Color("4a6b7a"))
			draw_rect(Rect2(jp + Vector2(-3, -10), Vector2(6, 4)), Color("c8b48a"))
	for k in 3:
		var hx := 320.0 + k * 14.0
		draw_line(Vector2(hx, 72), Vector2(hx, 80), Color("5a3a22"), 1.0)
		draw_rect(Rect2(hx - 3, 80, 6, 12), Color("9e3a24") if k != 1 else Color("c0392b"))
	# 左边米缸、菜筐（食材越少越空）
	_disc(Vector2(60, 108), 18.0, Color("8b5a2b"))
	_disc(Vector2(60, 108), 13.0, Color("efe6d2") if food[0] >= LOW_FOOD else Color("6b4a2a"))
	draw_rect(Rect2(38, 138, 52, 28), Color("a0744a"))
	if food[1] >= LOW_FOOD:
		_disc(Vector2(50, 147), 6.0, Color("6aa84f"))
		_disc(Vector2(64, 149), 6.0, Color("e06666"))
		_disc(Vector2(78, 146), 6.0, Color("f1c232"))
	# 右边砧板、水缸
	draw_rect(Rect2(798, 92, 58, 34), Color("c69c6d"))
	draw_line(Vector2(810, 100), Vector2(840, 116), Color("8a8a8a"), 3.0)
	_disc(Vector2(828, 154), 16.0, Color("4a6b7a"))
	_disc(Vector2(828, 154), 12.0, Color("7fb3c8"))
	# 灶台
	var t := Time.get_ticks_msec() / 1000.0
	var chefs := staff_of("厨师")
	for i in STOVE_POS.size():
		var sp: Vector2 = STOVE_POS[i]
		var chef = chefs[i] if i < chefs.size() else null
		var base: Color = [Color("5b524a"), Color("8a4a3a"), Color("b8902a")][stove_level]  # 铁灶 / 青砖 / 黄铜
		if chef == null:
			base = base.lerp(Color("c8c0b4"), 0.6)
		draw_rect(Rect2(sp + Vector2(-40, -22), Vector2(80, 44)), base)
		draw_rect(Rect2(sp + Vector2(-40, -22), Vector2(80, 7)), base.darkened(0.3))
		_disc(sp + Vector2(0, 3), 15.0, Color("1e1e1e"))
		_disc(sp + Vector2(0, 3), 12.0, Color("3c3c3c"))
		if chef != null and chef.order != null:
			var glow := 0.6 + 0.4 * sin(t * 14.0 + i)
			draw_arc(sp + Vector2(0, 3), 17.0, 0.0, TAU, 32, Color(1.0, 0.55, 0.1, glow), 3.0, true)
			for k in 2:
				var fp := sp + Vector2(-25 + k * 50, 8)
				_disc(fp, 3.5 + sin(t * 14.0 + k) * 1.2, Color("ff8a1c"))
				_disc(fp + Vector2(0, 1), 2.0, Color("ffd34d"))
			# 颠勺：菜被抛起再落回锅里
			var toss := maxf(0.0, sin(t * 7.0 + i * 1.7)) * 12.0
			var dtex: Texture2D = art.dish(chef.order.dish.name)
			if dtex != null:
				draw_texture_rect(dtex, Rect2(sp + Vector2(-9, -6 - toss), Vector2(18, 18)), false)
			else:
				_disc(sp + Vector2(0, 3 - toss), 7.5, Color(chef.order.dish.color))
			for k in 4:  # 火星
				var a := fmod(t * 3.0 + k * 0.37 + i, 1.0)
				_disc(sp + Vector2(sin(k * 2.3 + i) * 16.0 * a, 10 - a * 26.0), 1.6 * (1.0 - a), Color(1.0, 0.75, 0.2, 1.0 - a))
			_steam(sp + Vector2(0, -10), t + i, 1.0)
			var done: float = 1.0 - chef.cook_timer / chef.cook_total
			draw_arc(sp + Vector2(0, 3), 24.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(done, 0.0, 1.0), 32, Color("ffd34d"), 3.0, true)
	# 柜台和出菜口
	draw_rect(Rect2(20, 178, 860, 22), Color("6b4226"))
	draw_rect(Rect2(20, 178, 860, 5), Color("8b5a2b"))
	draw_rect(Rect2(400, 176, 100, 26), Color("a8743f"))
	draw_string(font, Vector2(508, 196), "出菜口", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f3d9a8"))
	var n := pass_orders.size()
	var gap := minf(20.0, 90.0 / maxf(n, 1))
	for j in n:
		var pp := PASS_POS + Vector2((j - (n - 1) / 2.0) * gap, 0)
		_disc(pp, 8.0, Color("f8f4ea"))
		_disc(pp, 5.0, Color(pass_orders[j].dish.color))


func _draw_hall() -> void:
	draw_rect(HALL_RECT, Color("c99e6c"))
	var floor_tex: Texture2D = art.tex("furniture/floor_%d" % decor_level)  # 装修越好地面越讲究
	if floor_tex == null:
		floor_tex = art.tex("furniture/floor")
	if floor_tex != null:
		draw_texture_rect(floor_tex, HALL_RECT, true)  # 平铺
	# 木地板：每块木板深浅略有不同，带木纹和接缝（有地板图时跳过）
	var row := 0
	for y in (range(200, 708, 26) if floor_tex == null else []):
		var off := 0 if row % 2 == 0 else 55
		var h := mini(26, 708 - y)
		for x in range(20 - 55 + off, 880, 110):
			var x0 := maxi(x, 20)
			var x1 := mini(x + 110, 880)
			if x1 <= x0:
				continue
			var tone := float((x * 7 + y * 13) % 9) / 9.0
			draw_rect(Rect2(x0, y, x1 - x0, h), Color("c99e6c").lerp(Color("b98c5a"), tone * 0.6))
			draw_line(Vector2(x0 + 6, y + 9), Vector2(x1 - 10, y + 9 + (tone - 0.5) * 3.0), Color(0.55, 0.38, 0.22, 0.18), 1.0)
			draw_line(Vector2(x0, y), Vector2(x0, y + h), Color("9c7146"), 1.0)
		draw_line(Vector2(20, y), Vector2(880, y), Color("9c7146"), 1.0)
		draw_line(Vector2(20, y + 1), Vector2(880, y + 1), Color(1, 1, 1, 0.08), 1.0)
		row += 1
	# 分区地面：传菜道、前厅、柜台、杂物间各用不同的颜色和铺法
	if floor_tex == null:
		_zone(Rect2(20, 200, 860, 50), Color("94603e"), Color("6e4228"), "plank", "传菜道")
		_zone(Rect2(340, 600, 220, 108), Color("a3aeb2"), Color("7d888c"), "stone", "前厅")
		_zone(Rect2(690, 600, 190, 108), Color("8a3b2c"), Color("5e2418"), "plank", "柜台")
		_zone(Rect2(20, 600, 200, 108), Color("9aa785"), Color("78845f"), "tile", "杂物间")
	# 四角朱红立柱
	for p in [Vector2(30, 210), Vector2(870, 210)]:
		draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 18)), Color("7a2518"))
		draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 4)), Color("a8392a"))
		draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 18)), Color("4a170c"), false, 1.0)
	draw_rect(Rect2(14, 62, 6, 650), Color("5a3a22"))
	draw_rect(Rect2(880, 62, 6, 650), Color("5a3a22"))
	if decor_level >= 3:  # 红地毯
		draw_rect(Rect2(425, 236, 50, 446), Color("9e2b25"))
		draw_rect(Rect2(425, 236, 4, 446), Color("d4a640"))
		draw_rect(Rect2(471, 236, 4, 446), Color("d4a640"))
	# 收银柜台：木工坊可以换
	var counter_tex: Texture2D = art.tex("furniture/counter_%d" % counter_level)
	if counter_tex != null:
		var cs := counter_tex.get_size() * (160.0 / counter_tex.get_size().x)
		draw_texture_rect(counter_tex, Rect2(Vector2(790, 670) - cs / 2.0, cs), false)
	else:
		_draw_counter()
	# 大门
	draw_rect(Rect2(20, 708, 860, 12), Color("5a3a22"))
	draw_rect(Rect2(395, 706, 110, 14), Color("2b1d14"))
	draw_rect(Rect2(410, 684, 80, 20), Color("8c2f39"))
	draw_string(font, Vector2(437, 699), "迎客", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f3d27a"))


func _draw_counter() -> void:
	draw_rect(Rect2(740, 660, 100, 18), Color("6b4226"))
	draw_rect(Rect2(740, 660, 100, 4), Color("8b5a2b"))
	draw_rect(Rect2(752, 664, 28, 10), Color("3b2416"))
	for k in 5:
		_disc(Vector2(756 + k * 5, 669), 1.6, Color("d4a640"))
	draw_string(font, Vector2(796, 675), "柜台", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f3d9a8"))


# ---------------- 休假日的集市 ----------------

const SHOPS := {
	"grain": {"name": "粮行", "flag": "粮", "rect": Rect2(30, 108, 200, 240), "wall": "e8d8b0", "roof": "4a5a6a"},
	"labor": {"name": "人力市场", "flag": "工", "rect": Rect2(244, 108, 200, 240), "wall": "e0cfa8", "roof": "5a4a6a"},
	"carpenter": {"name": "木工坊", "flag": "木", "rect": Rect2(458, 108, 200, 240), "wall": "d8c09a", "roof": "4a3a2a"},
	"grocer": {"name": "杂货铺", "flag": "货", "rect": Rect2(672, 108, 200, 240), "wall": "ead8b8", "roof": "6a3a3a"},
	"notice": {"name": "比赛告示", "rect": Rect2(56, 470, 150, 130)},
	"home": {"name": "回店开张", "rect": Rect2(690, 470, 170, 150)},
}


func _shop_at(p: Vector2) -> String:
	for id in SHOPS:
		var r: Rect2 = SHOPS[id].rect
		if r.has_point(p):
			return id
	return ""


func _open_shop(id: String) -> void:
	sfx.play("bell", -6.0)
	match id:
		"grain", "labor", "grocer":
			tabs.current_tab = 2
			town_scroll.ensure_control_visible.call_deferred(town_sections[id])
		"carpenter":
			tabs.current_tab = 3
		"notice":
			tabs.current_tab = 4
		"home":
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			_end_rest_day()
			return
	var r: Rect2 = SHOPS[id].rect
	_float_text(Vector2(r.get_center().x, r.end.y - 30), "走进%s" % SHOPS[id].name, Color("ffe9b0"))


func _draw_market() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# 天空和远山
	draw_rect(Rect2(20, 62, 860, 80), Color("bcd8e4"))
	draw_colored_polygon(PackedVector2Array([Vector2(20, 142), Vector2(140, 92), Vector2(260, 130), Vector2(400, 86), Vector2(560, 128), Vector2(700, 96), Vector2(880, 132), Vector2(880, 142)]), Color("9ab8b0"))
	for k in 3:
		var cx := fmod(120.0 + k * 300.0 + t * 6.0, 900.0) + 20.0
		draw_circle(Vector2(cx, 82 + k * 6), 12, Color(1, 1, 1, 0.8), true, -1.0, true)
		draw_circle(Vector2(cx + 14, 80 + k * 6), 15, Color(1, 1, 1, 0.8), true, -1.0, true)
		draw_circle(Vector2(cx + 30, 84 + k * 6), 11, Color(1, 1, 1, 0.8), true, -1.0, true)
	# 青石板街
	draw_rect(Rect2(20, 340, 860, 368), Color("9aa2a4"))
	var row := 0
	for y in range(340, 708, 30):
		var off := 0 if row % 2 == 0 else 32
		for x in range(20 - off, 880, 64):
			var cell := Rect2(maxf(x, 20) + 1, y + 1, minf(x + 64, 880) - maxf(x, 20) - 2, minf(30, 708 - y) - 2)
			if cell.size.x > 2:
				var tone := float((x * 7 + y * 11) % 9) / 9.0
				draw_rect(cell, Color("a8b0b2").lerp(Color("8e979a"), tone))
		row += 1
	# 屋前的台阶
	draw_rect(Rect2(20, 340, 860, 10), Color("6e6258"))
	# 四间铺子
	for id in ["grain", "labor", "carpenter", "grocer"]:
		_draw_shop(id, SHOPS[id])
	# 街上挂的彩旗
	for k in 18:
		var fx := 30.0 + k * 48.0
		draw_line(Vector2(fx, 360 + (k % 2) * 4), Vector2(fx + 48, 360 + ((k + 1) % 2) * 4), Color("5a3a22"), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(fx + 18, 362), Vector2(fx + 30, 362), Vector2(fx + 24, 374)]), [Color("d33a2c"), Color("e0b84a"), Color("3f7d3a"), Color("2d6ea8")][k % 4])
	# 告示牌
	var nr: Rect2 = SHOPS.notice.rect
	var hl := hover_shop == "notice"
	draw_rect(Rect2(nr.position + Vector2(18, 40), Vector2(8, 90)), Color("5a3a22"))
	draw_rect(Rect2(nr.position + Vector2(124, 40), Vector2(8, 90)), Color("5a3a22"))
	draw_rect(Rect2(nr.position + Vector2(6, 16), Vector2(138, 80)), Color("8b5a2b"))
	draw_rect(Rect2(nr.position + Vector2(6, 16), Vector2(138, 80)), Color("f3d27a") if hl else Color("4a2c17"), false, 3.0 if hl else 2.0)
	draw_colored_polygon(PackedVector2Array([nr.position + Vector2(0, 18), nr.position + Vector2(75, 0), nr.position + Vector2(150, 18)]), Color("4a3a2a"))
	for k in 3:
		draw_rect(Rect2(nr.position + Vector2(16 + k * 42, 28), Vector2(34, 44)), Color("f4ecd8"))
		for j in 4:
			draw_line(nr.position + Vector2(20 + k * 42, 36 + j * 8), nr.position + Vector2(44 + k * 42, 36 + j * 8), Color("6a5a4a"), 1.0)
	draw_rect(Rect2(nr.position + Vector2(16 + contest_idx % 3 * 42, 28), Vector2(34, 44)), Color("d33a2c"), false, 2.0)
	_market_label(nr.position + Vector2(75, 90), "比赛告示", hl)
	# 回店的牌坊
	var hr: Rect2 = SHOPS.home.rect
	hl = hover_shop == "home"
	draw_rect(Rect2(hr.position + Vector2(14, 34), Vector2(12, 110)), Color("8c2f39"))
	draw_rect(Rect2(hr.position + Vector2(144, 34), Vector2(12, 110)), Color("8c2f39"))
	draw_colored_polygon(PackedVector2Array([hr.position + Vector2(0, 30), hr.position + Vector2(20, 8), hr.position + Vector2(150, 8), hr.position + Vector2(170, 30)]), Color("3a3a4a"))
	draw_rect(Rect2(hr.position + Vector2(30, 34), Vector2(110, 30)), Color("3b1a12"))
	draw_rect(Rect2(hr.position + Vector2(30, 34), Vector2(110, 30)), Color("f3d27a") if hl else Color("d4a640"), false, 3.0 if hl else 2.0)
	var home_txt := "回店开张"
	var hw := title_font.get_string_size(home_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(title_font, hr.position + Vector2(85 - hw / 2.0, 56), home_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f3d27a"))
	draw_colored_polygon(PackedVector2Array([hr.position + Vector2(70, 92), hr.position + Vector2(100, 92), hr.position + Vector2(100, 84), hr.position + Vector2(116, 100), hr.position + Vector2(100, 116), hr.position + Vector2(100, 108), hr.position + Vector2(70, 108)]), Color("f3d27a") if hl else Color("e0c890"))
	# 赶集的路人
	var colors := [Color("6b8e4e"), Color("7fa7c9"), Color("8c2f39"), Color("c8963e"), Color("a85a8a"), Color("4f6d8f"), Color("d9732a")]
	for k in 7:
		var lane := 410.0 + (k % 3) * 70.0
		var dir := 1.0 if k % 2 == 0 else -1.0
		var x := fmod(k * 137.0 + t * (28.0 + k * 4.0), 900.0)
		if dir < 0.0:
			x = 900.0 - x
		var p := Vector2(x, lane)
		if p.x < 30.0 or p.x > 870.0:
			continue
		var bob := absf(sin(t * 9.0 + k)) * 2.0
		_shadow(p + Vector2(0, 12), 10.0)
		_disc(p + Vector2(0, 2 - bob), 10.0, colors[k])
		_disc(p + Vector2(0, -12 - bob), 6.5, Color("f1c9a0"))
		_disc(p + Vector2(0, -16 - bob), 5.5, Color("2a1d14") if k % 3 != 0 else Color("d9b45a"))
		if k == 2:  # 挑担的货郎
			draw_line(p + Vector2(-16, -4 - bob), p + Vector2(16, -4 - bob), Color("5a3a22"), 2.0)
			_disc(p + Vector2(-16, 4 - bob), 5.0, Color("c8a060"))
			_disc(p + Vector2(16, 4 - bob), 5.0, Color("c8a060"))
	draw_string(title_font, Vector2(330, 700), "点铺子进去办事", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.75))


func _draw_shop(id: String, s: Dictionary) -> void:
	var r: Rect2 = s.rect
	var hl := hover_shop == id
	var wall := Color(s.wall)
	# 墙和柱子
	draw_rect(Rect2(r.position + Vector2(10, 56), Vector2(r.size.x - 20, 176)), wall)
	draw_rect(Rect2(r.position + Vector2(10, 56), Vector2(8, 176)), Color("8c2f39"))
	draw_rect(Rect2(r.position + Vector2(r.size.x - 18, 56), Vector2(8, 176)), Color("8c2f39"))
	# 屋顶：两头起翘的瓦檐
	var roof := Color(s.roof)
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(-4, 46), r.position + Vector2(24, 8), r.position + Vector2(r.size.x - 24, 8), r.position + Vector2(r.size.x + 4, 46), r.position + Vector2(r.size.x - 8, 60), r.position + Vector2(8, 60)]), roof)
	for k in range(int(r.position.x) + 24, int(r.end.x) - 20, 10):
		draw_line(Vector2(k, r.position.y + 12), Vector2(k - 6, r.position.y + 56), roof.darkened(0.3), 1.0)
	draw_line(r.position + Vector2(-4, 46), r.position + Vector2(-10, 38), roof.darkened(0.2), 3.0)
	draw_line(r.position + Vector2(r.size.x + 4, 46), r.position + Vector2(r.size.x + 10, 38), roof.darkened(0.2), 3.0)
	# 招牌
	var board := Rect2(r.position + Vector2(40, 66), Vector2(r.size.x - 80, 30))
	draw_rect(board, Color("2a1a10"))
	draw_rect(board, Color("f3d27a") if hl else Color("d4a640"), false, 3.0 if hl else 2.0)
	var nm: String = s.name
	var tw := title_font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(title_font, board.get_center() + Vector2(-tw / 2.0, 7), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f3d27a"))
	# 门洞和门帘
	var door := Rect2(r.position + Vector2(r.size.x / 2.0 - 26, 108), Vector2(52, 124))
	draw_rect(door, Color("3a2416"))
	draw_rect(Rect2(door.position, Vector2(door.size.x, 30)), Color("2d6ea8") if id != "carpenter" else Color("8a6a46"))
	# 幌子：竖挂的布招
	var fp := r.position + Vector2(r.size.x - 34, 100)
	draw_line(fp + Vector2(0, -6), fp + Vector2(18, -6), Color("5a3a22"), 2.0)
	draw_rect(Rect2(fp, Vector2(18, 44)), Color("d33a2c"))
	draw_colored_polygon(PackedVector2Array([fp + Vector2(0, 44), fp + Vector2(18, 44), fp + Vector2(9, 52)]), Color("d33a2c"))
	draw_string(title_font, fp + Vector2(1, 30), s.flag, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe9b0"))
	# 门前摊位上的货
	var stall := Rect2(r.position + Vector2(18, 196), Vector2(60, 34))
	draw_rect(stall, Color("8b5a2b"))
	draw_rect(Rect2(stall.position, Vector2(stall.size.x, 5)), Color("a8743f"))
	var sp := stall.position
	match id:
		"grain":  # 米袋
			for k in 3:
				_disc(sp + Vector2(12 + k * 18, -4), 9.0, Color("e8dcc0"))
				draw_line(sp + Vector2(8 + k * 18, -12), sp + Vector2(16 + k * 18, -12), Color("8a6a46"), 2.0)
		"labor":  # 招工的榜和应征的人
			draw_rect(Rect2(sp + Vector2(4, -26), Vector2(30, 24)), Color("f4ecd8"))
			draw_string(font, sp + Vector2(7, -9), "招工", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8c2f39"))
			for k in 2:
				_disc(sp + Vector2(44 + k * 10, -6), 6.0, [Color("4f6d8f"), Color("6b8e4e")][k])
				_disc(sp + Vector2(44 + k * 10, -15), 4.0, Color("f1c9a0"))
		"carpenter":  # 木板和锯子
			for k in 3:
				draw_rect(Rect2(sp + Vector2(4, -6 - k * 6), Vector2(52, 5)), Color("c69c6d").darkened(k * 0.1))
			draw_line(sp + Vector2(40, -26), sp + Vector2(58, -10), Color("9aa3ad"), 3.0)
		"grocer":  # 坛坛罐罐和布匹
			_disc(sp + Vector2(12, -6), 7.0, Color("4a6b7a"))
			_disc(sp + Vector2(28, -6), 7.0, Color("7a4a2a"))
			draw_rect(Rect2(sp + Vector2(38, -16), Vector2(18, 14)), Color("a85a8a"))
			draw_rect(Rect2(sp + Vector2(38, -16), Vector2(18, 4)), Color("e0b84a"))
	if hl:
		draw_rect(Rect2(r.position + Vector2(6, 54), Vector2(r.size.x - 12, 180)), Color(1, 0.9, 0.5, 0.12))
		_market_label(r.position + Vector2(r.size.x / 2.0, 252), "点击进入" + nm, true)


func _market_label(center: Vector2, text: String, highlight: bool) -> void:
	var w := title_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16.0
	var r := Rect2(center + Vector2(-w / 2.0, -12), Vector2(w, 22))
	draw_rect(r, Color("3b1a12") if highlight else Color(0.2, 0.1, 0.05, 0.75))
	draw_string(title_font, r.position + Vector2(8, 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe9b0"))


## 挂在墙上的字画，p 是画轴顶端。
func _draw_wall_art(id: String, p: Vector2) -> void:
	var t: Texture2D = art.tex("furniture/" + id)
	if t != null:
		var sz := t.get_size() * (62.0 / t.get_size().y)
		draw_texture_rect(t, Rect2(p - Vector2(sz.x / 2.0, 0), sz), false)
		return
	draw_rect(Rect2(p + Vector2(-13, 0), Vector2(26, 60)), Color("efe6d2"))
	draw_rect(Rect2(p + Vector2(-15, 0), Vector2(30, 4)), Color("5a3a22"))
	draw_rect(Rect2(p + Vector2(-15, 58), Vector2(30, 4)), Color("5a3a22"))


func _is_wall(id: String) -> bool:
	for it in Data.DECOR_ITEMS:
		if it.id == id:
			return it.get("wall", false)
	return false


## 画一件摆件。art/furniture/<id>.png 存在就用图片。
func _draw_ornament(id: String, p: Vector2) -> void:
	_shadow(p + Vector2(0, 14), 16.0)
	var t: Texture2D = art.tex("furniture/" + id)
	if t != null:
		var sz := t.get_size() * (40.0 / maxf(t.get_size().x, t.get_size().y))
		draw_texture_rect(t, Rect2(p + Vector2(-sz.x / 2.0, 14 - sz.y), sz), false)
		return
	match id:
		"screen":  # 三扇山水屏风
			for k in 3:
				var r := Rect2(p + Vector2(-17 + k * 11.5, -26), Vector2(11, 36))
				draw_rect(r, Color("f2ead8"))
				draw_rect(r, Color("6b2a1a"), false, 2.0)
				draw_colored_polygon(PackedVector2Array([r.position + Vector2(1, 28), r.position + Vector2(5, 14 + k * 3), r.position + Vector2(10, 28)]), Color("6a8a7a"))
				_disc(r.position + Vector2(7, 8), 2.0, Color("c0392b"))
		"scroll":  # 挂轴字画
			draw_rect(Rect2(p + Vector2(-12, -34), Vector2(24, 3)), Color("5a3a22"))
			draw_rect(Rect2(p + Vector2(-10, -31), Vector2(20, 40)), Color("f4ecd8"))
			draw_rect(Rect2(p + Vector2(-10, -31), Vector2(20, 40)), Color("8b5a2b"), false, 1.5)
			for k in 3:
				draw_line(p + Vector2(-3 + k * 4, -25), p + Vector2(-3 + k * 4, 0), Color("2a1d14"), 1.5)
			draw_rect(Rect2(p + Vector2(2, 2), Vector2(4, 4)), Color("c0392b"))
			draw_rect(Rect2(p + Vector2(-12, 9), Vector2(24, 3)), Color("5a3a22"))
		"fish":  # 青花鱼缸
			_disc(p, 15.0, Color("2d6ea8"))
			_disc(p, 12.5, Color("8fc6e0"))
			var tt := Time.get_ticks_msec() / 1000.0
			for k in 2:
				var fp := p + Vector2(cos(tt * 1.5 + k * 3.0), sin(tt * 1.5 + k * 3.0) * 0.6) * 6.0
				_disc(fp, 2.6, Color("ff7a2a"))
			draw_arc(p, 15.0, 0.0, TAU, 32, Color("eef2f5"), 1.5, true)
		"flower":  # 牡丹花架
			draw_line(p + Vector2(-8, 12), p + Vector2(-6, -6), Color("5a3a22"), 2.5)
			draw_line(p + Vector2(8, 12), p + Vector2(6, -6), Color("5a3a22"), 2.5)
			draw_rect(Rect2(p + Vector2(-9, -10), Vector2(18, 6)), Color("8b4a2b"))
			for k in 4:
				var fp2 := p + Vector2(-7 + k * 5, -16 - (k % 2) * 5)
				_disc(fp2, 4.5, Color("e85a8a") if k % 2 == 0 else Color("f29ab8"))
				_disc(fp2, 1.5, Color("ffd34d"))
			_disc(p + Vector2(-9, -12), 3.0, Color("4f9447"))
			_disc(p + Vector2(9, -12), 3.0, Color("4f9447"))
		"curio":  # 博古架
			var r2 := Rect2(p + Vector2(-16, -30), Vector2(32, 42))
			draw_rect(r2, Color("5a2a1a"))
			draw_rect(Rect2(r2.position + Vector2(3, 3), r2.size - Vector2(6, 6)), Color("7a3a24"))
			draw_line(p + Vector2(-13, -16), p + Vector2(13, -16), Color("5a2a1a"), 2.0)
			draw_line(p + Vector2(-13, -2), p + Vector2(13, -2), Color("5a2a1a"), 2.0)
			draw_line(p + Vector2(0, -27), p + Vector2(0, -16), Color("5a2a1a"), 2.0)
			_disc(p + Vector2(-7, -21), 3.5, Color("4a8ab8"))
			_disc(p + Vector2(7, -21), 3.0, Color("e0b84a"))
			_disc(p + Vector2(-5, -7), 3.5, Color("3f9a6a"))
			draw_rect(Rect2(p + Vector2(3, -10), Vector2(7, 7)), Color("c0392b"))
			_disc(p + Vector2(0, 5), 3.5, Color("eef2f5"))
		"censer":  # 铜鼎香炉，冒着烟
			draw_line(p + Vector2(-8, 4), p + Vector2(-10, 12), Color("8a6a2a"), 2.5)
			draw_line(p + Vector2(8, 4), p + Vector2(10, 12), Color("8a6a2a"), 2.5)
			_disc(p, 10.0, Color("b8902a"))
			draw_rect(Rect2(p + Vector2(-11, -6), Vector2(22, 4)), Color("8a6a2a"))
			draw_arc(p + Vector2(-11, -8), 3.0, PI, TAU, 8, Color("8a6a2a"), 2.0, true)
			draw_arc(p + Vector2(11, -8), 3.0, PI, TAU, 8, Color("8a6a2a"), 2.0, true)
			var ts := Time.get_ticks_msec() / 1000.0
			for k in 3:
				var rise := fmod(ts * 8.0 + k * 9.0, 27.0)
				_disc(p + Vector2(sin(ts * 2.0 + k) * 3.0, -10 - rise), 2.5 + rise * 0.08, Color(0.85, 0.85, 0.85, 0.5 - rise / 60.0))


## 画一块分区地面：plank 木板 / stone 石板 / tile 方砖，左上角淡淡写上区名。
func _zone(r: Rect2, base: Color, line: Color, kind: String, label: String) -> void:
	draw_rect(r, base)
	match kind:
		"plank":
			var row := 0
			for y in range(int(r.position.y), int(r.end.y), 16):
				draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), line, 1.0)
				var off := 0 if row % 2 == 0 else 40
				for x in range(int(r.position.x) + off, int(r.end.x), 80):
					draw_line(Vector2(x, y), Vector2(x, minf(y + 16, r.end.y)), line, 1.0)
				row += 1
		"stone":
			var row := 0
			for y in range(int(r.position.y), int(r.end.y), 36):
				var off := 0 if row % 2 == 0 else 27
				for x in range(int(r.position.x) - off, int(r.end.x), 54):
					var cell := Rect2(maxf(x, r.position.x) + 2, y + 2, minf(x + 54, r.end.x) - maxf(x, r.position.x) - 4, minf(36.0, r.end.y - y) - 4)
					if cell.size.x > 2 and cell.size.y > 2:
						var tone := float((x * 5 + y * 3) % 7) / 7.0
						draw_rect(cell, base.lerp(base.lightened(0.15), tone))
						draw_rect(cell, line, false, 1.0)
				row += 1
		"tile":
			for y in range(int(r.position.y), int(r.end.y), 24):
				for x in range(int(r.position.x), int(r.end.x), 24):
					if (x / 24 + y / 24) % 2 == 0:
						draw_rect(Rect2(x, y, minf(24, r.end.x - x), minf(24, r.end.y - y)), base.darkened(0.08))
			draw_rect(r, line, false, 1.0)
	draw_rect(r, line.darkened(0.2), false, 2.0)
	draw_string(title_font, r.position + Vector2(6, 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.45))


func _draw_tables() -> void:
	# 没扩建的地方：堆着杂物，暗下去
	var e: Dictionary = Data.EXPANSIONS[expand_level]
	for r in range(1, 8):
		for c in range(1, GCOLS - 1):  # 最靠墙的两列留给摆件和灯笼，不堆杂物
			if c >= int(e.cols[0]) and c <= int(e.cols[1]):
				continue
			var cc := cell_center(Vector2i(c, r))
			draw_rect(Rect2(cc - Vector2(CELL, CELL) / 2.0, Vector2(CELL, CELL)), Color(0.12, 0.08, 0.04, 0.55))
			if (c * 7 + r * 3) % 4 == 0:  # 零散的木箱、麻袋
				draw_rect(Rect2(cc - Vector2(12, 10), Vector2(24, 20)), Color("6b4a2a"))
				draw_rect(Rect2(cc - Vector2(12, 10), Vector2(24, 20)), Color("3b2416"), false, 1.5)
				draw_line(cc - Vector2(12, 10), cc + Vector2(12, 10), Color("3b2416"), 1.0)
			elif (c * 5 + r) % 6 == 0:
				_disc(cc, 10.0, Color("a08a5a"))
	if expand_level < Data.EXPANSIONS.size() - 1:
		draw_string(title_font, cell_center(Vector2i(1, 4)) + Vector2(-20, 6), "未扩建", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.9, 0.7, 0.5))
	if arranging:  # 布置时画出能摆桌子的格子
		for r in range(int(e.rows[0]), int(e.rows[1]) + 1):
			for c in range(int(e.cols[0]), int(e.cols[1]) + 1):
				var cc := cell_center(Vector2i(c, r))
				draw_rect(Rect2(cc - Vector2(CELL, CELL) / 2.0, Vector2(CELL, CELL)), Color(1, 1, 1, 0.25), false, 1.0)
	# 椅子：每个座位一把，按桌椅档次配套
	var chair: Texture2D = art.tex("furniture/chair_%d" % table_level)
	for i in tables.size():
		var sp := cell_center(tables[i].cell) + Vector2(0, 4)
		if chair != null:
			draw_texture_rect(chair, Rect2(sp - Vector2(14, 14), Vector2(28, 28)), false)
		else:
			draw_rect(Rect2(sp - Vector2(10, 8), Vector2(20, 16)), Color("94602f"))
	# 长方桌：挨着摆的几张连成一条长桌
	var ttex: Texture2D = art.tex("furniture/rtable_%d" % table_level)
	var wood: Color = [Color("b07a45"), Color("7a2e1e"), Color("6a2418")][table_level]
	var mouse := get_global_mouse_position()
	for pi in pieces.size():
		var p := cell_center(pieces[pi])
		if drag != null and drag.kind == "table" and drag.i == pi:
			p = mouse  # 正被拖着
		var r := Rect2(p - Vector2(CELL / 2.0, 18), Vector2(CELL, 36))
		draw_rect(Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.18))  # 影子
		if ttex != null:
			draw_texture_rect(ttex, r, false)
		else:
			draw_rect(r, wood)
			draw_rect(r, wood.darkened(0.4), false, 1.5)
			if table_level >= 2:
				draw_rect(r.grow(-3), Color("d4a640"), false, 1.0)
	# 桌上的菜：每个座位面前一份
	for i in tables.size():
		var t: Dictionary = tables[i]
		var pp := plate_pos(i)
		if t.plate == "":
			_disc(pp, 3.5, Color("eef2f5"))  # 一只茶杯
			draw_arc(pp, 3.5, 0.0, TAU, 12, Color("6b8fb5"), 1.0, true)
			continue
		var dish_tex: Texture2D = null if t.dirty else art.dish(t.dish_name)
		# 正在吃：菜一点点变少，冒热气
		var left := 1.0
		var c = t.customer
		if c != null and is_instance_valid(c) and c.state == Customer.S.EATING:
			left = clampf(c.timer / Customer.EAT_TIME, 0.0, 1.0)
		if dish_tex != null:
			_disc(pp, 11.0, Color("f8f4ea"))  # 空盘底
			var sz := 26.0 * (0.45 + 0.55 * left)
			draw_texture_rect(dish_tex, Rect2(pp - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), false)
			if left < 1.0:
				_steam(pp + Vector2(0, -8), clock + i, left)
		else:
			_disc(pp, 9.0, Color("f8f4ea"))
			if t.dirty:
				_disc(pp, 4.0, Color("b5a58c"))  # 残羹
			else:
				_disc(pp, 6.0, Color(t.plate))


func _draw_decor() -> void:
	var lantern: Texture2D = art.tex("furniture/palace_lantern" if decor_level >= 3 else "furniture/lantern")
	var bonsai: Texture2D = art.tex("furniture/bonsai")
	if decor_level >= 1 and lantern != null:  # 灯笼，富丽堂皇换宫灯
		for p in [Vector2(36, 280), Vector2(36, 470), Vector2(864, 280), Vector2(864, 470)]:
			var ls := lantern.get_size() * (44.0 / lantern.get_size().y)
			draw_texture_rect(lantern, Rect2(p - ls / 2.0, ls), false)
	elif decor_level >= 1:  # 红灯笼
		for p in [Vector2(36, 280), Vector2(36, 470), Vector2(864, 280), Vector2(864, 470)]:
			draw_line(p + Vector2(0, -24), p + Vector2(0, -12), Color("2b1d14"), 2.0)
			draw_rect(Rect2(p + Vector2(-6, -14), Vector2(12, 4)), Color("d4a640"))
			_disc(p, 11.0, Color("d33a2c"))
			_disc(p + Vector2(-3, -3), 4.0, Color(1, 0.65, 0.45, 0.5))
			draw_rect(Rect2(p + Vector2(-6, 10), Vector2(12, 4)), Color("d4a640"))
			draw_line(p + Vector2(0, 14), p + Vector2(0, 24), Color("e0b84a"), 2.0)
	if decor_level >= 2 and bonsai != null:
		for p in [Vector2(48, 222), Vector2(852, 222), Vector2(864, 640)]:
			draw_texture_rect(bonsai, Rect2(p - Vector2(18, 24), Vector2(36, 36)), false)
	elif decor_level >= 2:  # 盆栽
		for p in [Vector2(48, 222), Vector2(852, 222), Vector2(864, 640)]:
			draw_rect(Rect2(p + Vector2(-11, 2), Vector2(22, 16)), Color("8b4a2b"))
			_disc(p + Vector2(-6, -4), 9.0, Color("3f7d3a"))
			_disc(p + Vector2(6, -4), 9.0, Color("4f9447"))
			_disc(p + Vector2(0, -12), 9.0, Color("5aa852"))
	# 摆件
	var mouse := get_global_mouse_position()
	for id in ornaments:
		var dragging: bool = drag != null and drag.kind == "orn" and drag.id == id
		if _is_wall(id):
			_draw_wall_art(id, mouse - Vector2(0, 30) if dragging else WALL_SLOTS[int(ornaments[id])])
		else:
			_draw_ornament(id, mouse if dragging else DECOR_SLOTS[int(ornaments[id])])
	# 牌匾
	var plaque := Rect2(370, 64, 160, 28)
	draw_rect(plaque, Color("3b1a12"))
	draw_rect(plaque, Color("d4a640") if (decor_level >= 3 or game_finished) else Color("8b5a2b"), false, 2.0)
	var title := "天下名店" if game_finished else "云来客栈"
	var tw := title_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(title_font, Vector2(450 - tw / 2.0, 86), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f3d27a"))
	# 已赢得的奖杯摆在牌匾两边
	for k in contest_idx:
		var cp := Vector2(352 - k * 18, 78) if k % 2 == 0 else Vector2(548 + k * 18, 78)
		_disc(cp, 6.0, Color("e0b84a"))
		draw_rect(Rect2(cp + Vector2(-3, 5), Vector2(6, 5)), Color("b8902a"))


# ---------------- 界面 ----------------

func _box(bg: Color, border: Color, radius: int, border_w: int, margin: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 16
	th.set_color("font_color", "Label", Color("3b2a1a"))
	# 主按钮：朱红漆面带金边和投影
	th.set_stylebox("normal", "Button", _btn_box(Color("a8392a"), Color("d4a640")))
	th.set_stylebox("hover", "Button", _btn_box(Color("c04a35"), Color("f0c860")))
	th.set_stylebox("pressed", "Button", _btn_box(Color("7a2518"), Color("d4a640"), false))
	th.set_stylebox("hover_pressed", "Button", _btn_box(Color("7a2518"), Color("f0c860"), false))
	th.set_stylebox("disabled", "Button", _btn_box(Color("c4b6a2"), Color("b0a08a"), false))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color("fff6e5"))
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color("ffd34d"))
	th.set_color("font_hover_pressed_color", "Button", Color("ffd34d"))
	th.set_color("font_disabled_color", "Button", Color("f6efe3"))
	th.set_font_size("font_size", "Button", 14)
	# 勾选框不要按钮底色
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		th.set_stylebox(st, "CheckBox", StyleBoxEmpty.new())
	th.set_font_size("font_size", "CheckBox", 15)
	# 次要按钮：米色木牌
	th.set_type_variation("SecondaryButton", "Button")
	th.set_stylebox("normal", "SecondaryButton", _btn_box(Color("efe2c6"), Color("b08a5a")))
	th.set_stylebox("hover", "SecondaryButton", _btn_box(Color("f8eed8"), Color("8b5a2b")))
	th.set_stylebox("pressed", "SecondaryButton", _btn_box(Color("8b5a2b"), Color("5a3a22"), false))
	th.set_stylebox("hover_pressed", "SecondaryButton", _btn_box(Color("8b5a2b"), Color("5a3a22"), false))
	th.set_stylebox("disabled", "SecondaryButton", _btn_box(Color("e6dccb"), Color("cfc2ae"), false))
	th.set_color("font_color", "SecondaryButton", Color("5a3a22"))
	th.set_color("font_hover_color", "SecondaryButton", Color("3b2416"))
	th.set_color("font_pressed_color", "SecondaryButton", Color("ffe9b0"))
	th.set_color("font_hover_pressed_color", "SecondaryButton", Color("ffe9b0"))
	th.set_color("font_disabled_color", "SecondaryButton", Color("b0a08a"))
	# 顶栏的倍速按钮
	th.set_type_variation("BarButton", "Button")
	th.set_stylebox("normal", "BarButton", _btn_box(Color("4a2e1c"), Color("7a5634")))
	th.set_stylebox("hover", "BarButton", _btn_box(Color("5c3a24"), Color("c8963e")))
	th.set_stylebox("pressed", "BarButton", _btn_box(Color("c8963e"), Color("f3d27a"), false))
	th.set_stylebox("hover_pressed", "BarButton", _btn_box(Color("c8963e"), Color("f3d27a"), false))
	th.set_color("font_color", "BarButton", Color("e8d6b0"))
	th.set_color("font_pressed_color", "BarButton", Color("2a1a10"))
	th.set_color("font_hover_pressed_color", "BarButton", Color("2a1a10"))
	th.set_stylebox("panel", "PanelContainer", _box(Color("f6ead2"), Color("8b5a2b"), 8, 2, 10))
	# 标签页：楷体书签
	th.set_stylebox("panel", "TabContainer", _box(Color("f6ead2"), Color("c8963e"), 4, 1, 6))
	var tab_sel := _box(Color("8c2f39"), Color("d4a640"), 6, 2, 7)
	tab_sel.corner_radius_bottom_left = 0
	tab_sel.corner_radius_bottom_right = 0
	tab_sel.set_content_margin(SIDE_LEFT, 14)
	tab_sel.set_content_margin(SIDE_RIGHT, 14)
	th.set_stylebox("tab_selected", "TabContainer", tab_sel)
	var tab_off := _box(Color("e3d0aa"), Color("b08a5a"), 6, 1, 7)
	tab_off.corner_radius_bottom_left = 0
	tab_off.corner_radius_bottom_right = 0
	tab_off.set_content_margin(SIDE_LEFT, 14)
	tab_off.set_content_margin(SIDE_RIGHT, 14)
	th.set_stylebox("tab_unselected", "TabContainer", tab_off)
	var tab_hover: StyleBoxFlat = tab_off.duplicate()
	tab_hover.bg_color = Color("f0e0bd")
	th.set_stylebox("tab_hovered", "TabContainer", tab_hover)
	th.set_font("font", "TabContainer", title_font)
	th.set_font_size("font_size", "TabContainer", 18)
	th.set_color("font_selected_color", "TabContainer", Color("ffe9b0"))
	th.set_color("font_unselected_color", "TabContainer", Color("5a4030"))
	th.set_color("font_hovered_color", "TabContainer", Color("3b2a1a"))
	th.set_stylebox("background", "ProgressBar", _box(Color("2a1a10"), Color("c8963e"), 4, 1, 0))
	th.set_stylebox("fill", "ProgressBar", _box(Color("e0a92e"), Color("e0a92e"), 4, 0, 0))
	# 细滚动条
	var grab := _box(Color("c8a878"), Color("c8a878"), 3, 0, 0)
	th.set_stylebox("grabber", "VScrollBar", grab)
	var grab_hi := _box(Color("a8834f"), Color("a8834f"), 3, 0, 0)
	th.set_stylebox("grabber_highlight", "VScrollBar", grab_hi)
	th.set_stylebox("grabber_pressed", "VScrollBar", grab_hi)
	var track := _box(Color(0, 0, 0, 0.06), Color(0, 0, 0, 0), 3, 0, 0)
	track.content_margin_left = 3
	track.content_margin_right = 3
	th.set_stylebox("scroll", "VScrollBar", track)
	th.set_stylebox("separator", "HSeparator", _line_box())
	return th


func _btn_box(bg: Color, border: Color, raised := true) -> StyleBoxFlat:
	var sb := _box(bg, border, 5, 1, 5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	if raised:
		sb.shadow_color = Color(0.2, 0.1, 0.03, 0.35)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, 2)
	return sb


func _line_box() -> StyleBoxLine:
	var sl := StyleBoxLine.new()
	sl.color = Color("d9c09a")
	sl.thickness = 1
	return sl


func _label(text: String, size: int, color: Color = Color("3b2a1a")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _wrap(l: Label, width: float = 330.0) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	l.custom_minimum_size = Vector2(width, 0)
	return l


func _hint(text: String) -> Label:
	return _wrap(_label(text, 13, Color("8a7560")))


func _button(text: String, on_press: Callable, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.theme_type_variation = variation
	b.pressed.connect(sfx.play.bind("click", -8.0))
	b.pressed.connect(on_press)
	return b


func _title_label(text: String, size: int, color: Color) -> Label:
	var l := _label(text, size, color)
	l.add_theme_font_override("font", title_font)
	return l


## 顶栏的数值牌：深色圆角底 + 小图标 + 数字。返回数字标签。
func _chip(parent: Control, icon: String, color: Color) -> Label:
	var chip := PanelContainer.new()
	var sb := _box(Color("24160c"), Color("6b4a2a"), 14, 1, 4)
	sb.content_margin_left = 8
	sb.content_margin_right = 12
	chip.add_theme_stylebox_override("panel", sb)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(chip)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	chip.add_child(hb)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(20, 20)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.draw.connect(_draw_icon.bind(ic, icon))
	hb.add_child(ic)
	var l := _label("", 17, color)
	hb.add_child(l)
	return l


func _draw_icon(c: Control, icon: String) -> void:
	var m := c.size / 2.0
	match icon:
		"coin":  # 铜钱
			c.draw_circle(m, 9.0, Color("e0b84a"), true, -1.0, true)
			c.draw_circle(m, 7.0, Color("c9962a"), true, -1.0, true)
			c.draw_rect(Rect2(m - Vector2(2.5, 2.5), Vector2(5, 5)), Color("24160c"))
		"food":  # 一碗米饭
			c.draw_circle(m + Vector2(0, -1), 6.5, Color("f8f4ea"), true, -1.0, true)
			c.draw_colored_polygon(PackedVector2Array([m + Vector2(-9, 0), m + Vector2(9, 0), m + Vector2(6, 7), m + Vector2(-6, 7)]), Color("b0452c"))
			c.draw_line(m + Vector2(-9, 0), m + Vector2(9, 0), Color("e0b84a"), 1.5)
		"star":  # 声望星
			var pts := PackedVector2Array()
			for k in 10:
				var r := 9.0 if k % 2 == 0 else 4.0
				var a := -PI / 2.0 + k * PI / 5.0
				pts.append(m + Vector2(cos(a), sin(a)) * r)
			c.draw_colored_polygon(pts, Color("f3c94a"))


func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


func _card() -> PanelContainer:
	var card := PanelContainer.new()
	var sb := _box(Color("fffaf0"), Color("d9b98a"), 6, 1, 7)
	sb.border_width_left = 4
	sb.content_margin_left = 10
	sb.shadow_color = Color(0.3, 0.18, 0.05, 0.12)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	card.add_theme_stylebox_override("panel", sb)
	return card


func _section(text: String) -> Label:
	return _title_label("◆ " + text, 19, Color("8c2f39"))


func _scroll(content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	layer.add_child(root)

	# 顶栏
	var top := PanelContainer.new()
	top.position = Vector2.ZERO
	top.size = Vector2(1280, 62)
	var top_sb := _box(Color("3b2416"), Color("c8963e"), 0, 0, 8)
	top_sb.border_width_bottom = 3
	top_sb.content_margin_left = 14
	top_sb.content_margin_right = 12
	top.add_theme_stylebox_override("panel", top_sb)
	root.add_child(top)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	top.add_child(bar)
	bar.add_child(_title_label("云来客栈", 30, Color("f3d27a")))
	var day_box := VBoxContainer.new()
	day_box.add_theme_constant_override("separation", 3)
	day_box.alignment = BoxContainer.ALIGNMENT_CENTER
	lbl_day = _label("", 15, Color("f6ead2"))
	day_box.add_child(lbl_day)
	bar_day = ProgressBar.new()
	bar_day.show_percentage = false
	bar_day.max_value = 1.0
	bar_day.custom_minimum_size = Vector2(190, 5)
	bar_day.add_theme_stylebox_override("background", _box(Color("1e120a"), Color("1e120a"), 2, 0, 0))
	bar_day.add_theme_stylebox_override("fill", _box(Color("7fb3c8"), Color("7fb3c8"), 2, 0, 0))
	day_box.add_child(bar_day)
	bar.add_child(day_box)
	lbl_money = _chip(bar, "coin", Color("ffd34d"))
	lbl_food = _chip(bar, "food", Color("cfe8b0"))
	lbl_rep = _chip(bar, "star", Color("f6ead2"))
	bar_rep = ProgressBar.new()
	bar_rep.max_value = 100.0
	bar_rep.show_percentage = false
	bar_rep.custom_minimum_size = Vector2(80, 8)
	bar_rep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_rep.get_parent().add_child(bar_rep)
	bar.add_child(_spacer())
	for spec in [["店况", _open_status], ["日历", _open_calendar], ["账本", _open_ledger]]:
		var tb := _button(spec[0], spec[1], "BarButton")
		tb.custom_minimum_size = Vector2(56, 34)
		tb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_child(tb)
	var sound_btn := _button("设置", _toggle_settings, "BarButton")
	sound_btn.custom_minimum_size = Vector2(60, 34)
	sound_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(sound_btn)
	var speed_names := ["暂停", "1倍", "2倍", "3倍"]
	for i in speed_names.size():
		var b := _button(speed_names[i], _set_speed.bind(float(i)), "BarButton")
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(48, 34)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_child(b)
		speed_buttons.append(b)

	# 右侧掌柜面板
	var side := PanelContainer.new()
	side.position = Vector2(892, 70)
	side.size = Vector2(380, 642)
	root.add_child(side)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	side.add_child(vb)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(tabs)
	tabs.add_child(_build_menu_tab())
	tabs.add_child(_build_staff_tab())
	tabs.add_child(_build_town_tab())
	tabs.add_child(_build_shop_tab())
	tabs.add_child(_build_contest_tab())
	for i in 5:
		tabs.set_tab_title(i, ["菜谱", "伙计", "城镇", "店面", "比赛"][i])
	var log_card := PanelContainer.new()
	log_card.add_theme_stylebox_override("panel", _box(Color("efe2c6"), Color("d9c09a"), 6, 1, 8))
	vb.add_child(log_card)
	var log_box := VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 2)
	log_card.add_child(log_box)
	log_box.add_child(_title_label("客栈日志", 15, Color("8b5a2b")))
	lbl_log = RichTextLabel.new()
	lbl_log.bbcode_enabled = true
	lbl_log.scroll_active = false
	lbl_log.custom_minimum_size = Vector2(340, 108)
	lbl_log.add_theme_font_size_override("normal_font_size", 12)
	lbl_log.add_theme_color_override("default_color", Color("3b2a1a"))
	log_box.add_child(lbl_log)

	_build_settings(root)
	_build_calc(root)
	_build_ledger(root)
	_build_calendar(root)
	_build_status(root)

	# 弹窗
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.hide()
	root.add_child(dim)
	popup = PanelContainer.new()
	var pop_sb := _box(Color("f6ead2"), Color("c8963e"), 10, 3, 0)
	pop_sb.shadow_color = Color(0, 0, 0, 0.45)
	pop_sb.shadow_size = 14
	pop_sb.shadow_offset = Vector2(0, 6)
	popup.add_theme_stylebox_override("panel", pop_sb)
	popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popup.grow_vertical = Control.GROW_DIRECTION_BOTH
	popup.hide()
	root.add_child(popup)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	popup.add_child(outer)
	# 朱红题头，像一块横匾
	var head := PanelContainer.new()
	var head_sb := _box(Color("8c2f39"), Color("d4a640"), 0, 0, 12)
	head_sb.corner_radius_top_left = 8
	head_sb.corner_radius_top_right = 8
	head_sb.border_width_bottom = 3
	head.add_theme_stylebox_override("panel", head_sb)
	outer.add_child(head)
	popup_title = _title_label("", 30, Color("ffe9b0"))
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(popup_title)
	var body_margin := MarginContainer.new()
	for side_name in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		body_margin.add_theme_constant_override(side_name, 22)
	outer.add_child(body_margin)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 16)
	body_margin.add_child(pv)
	var pbox := HBoxContainer.new()
	pbox.add_theme_constant_override("separation", 16)
	pv.add_child(pbox)
	popup_portrait = TextureRect.new()
	popup_portrait.custom_minimum_size = Vector2(160, 213)
	popup_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	popup_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pbox.add_child(popup_portrait)
	popup_body = _wrap(_label("", 16), 480.0)
	pbox.add_child(popup_body)
	var pb := HBoxContainer.new()
	pb.alignment = BoxContainer.ALIGNMENT_CENTER
	pb.add_theme_constant_override("separation", 20)
	pv.add_child(pb)
	popup_button = _button("", _on_popup_button)
	popup_button.custom_minimum_size = Vector2(180, 46)
	popup_button.add_theme_font_size_override("font_size", 17)
	pb.add_child(popup_button)
	popup_button2 = _button("", _on_popup_button2, "SecondaryButton")
	popup_button2.custom_minimum_size = Vector2(140, 46)
	popup_button2.add_theme_font_size_override("font_size", 17)
	pb.add_child(popup_button2)


func _build_menu_tab() -> Control:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	lbl_research = _wrap(_label("", 14, Color("8c2f39")))
	list.add_child(lbl_research)
	bar_research = ProgressBar.new()
	bar_research.show_percentage = false
	bar_research.custom_minimum_size = Vector2(0, 8)
	list.add_child(bar_research)
	for ci in Data.CATEGORIES.size():
		var card := _card()
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 3)
		card.add_child(cv)
		cv.add_child(_title_label(Data.CATEGORIES[ci].name, 19, Color("8b5a2b")))
		for d in dishes:
			if int(d.cat) == ci:
				cv.add_child(_build_dish_row(d))
		list.add_child(card)
	list.add_child(_hint("客人会挑预算内、店里有食材的菜。菜越好吃，客人越满意；价高赚得多，但满意度会降。研发由厨师在营业日慢慢琢磨，厨艺越高越快。"))
	return _scroll(list)


func _build_dish_row(d: Dictionary) -> Control:
	var taste := int(d.taste)
	var box := VBoxContainer.new()
	var on_box := HBoxContainer.new()
	box.add_child(on_box)
	on_box.add_child(_label(d.name, 15))
	on_box.add_child(_label("★".repeat(taste) + "☆".repeat(5 - taste), 12, Color("d4882a")))
	on_box.add_child(_spacer())
	var minus := _button("－", _change_price.bind(d, -1), "SecondaryButton")
	minus.custom_minimum_size = Vector2(28, 0)
	var price_lbl := _label("", 14, Color("8c2f39"))
	price_lbl.custom_minimum_size = Vector2(92, 0)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := _button("＋", _change_price.bind(d, 1), "SecondaryButton")
	plus.custom_minimum_size = Vector2(28, 0)
	on_box.add_child(minus)
	on_box.add_child(price_lbl)
	on_box.add_child(plus)
	var off_box := HBoxContainer.new()
	box.add_child(off_box)
	off_box.add_child(_label("下一道：%s" % d.name, 14, Color("8a7560")))
	off_box.add_child(_spacer())
	var research_btn := _button("研发（%d 文）" % d.research_cost, _start_research.bind(d))
	off_box.add_child(research_btn)
	dish_rows.append({"dish": d, "box": box, "on": on_box, "off": off_box, "price": price_lbl, "minus": minus, "plus": plus, "research": research_btn})
	return box


func _build_staff_tab() -> Control:
	staff_box = VBoxContainer.new()
	staff_box.add_theme_constant_override("separation", 6)
	return _scroll(staff_box)


func _rebuild_staff_list() -> void:
	if staff_box == null:
		return
	for ch in staff_box.get_children():
		ch.queue_free()
	staff_rows.clear()
	staff_box.add_child(_hint("营业日可以加薪；调职、辞退、招人要等休假日。选中一个伙计后，可以在城镇杂货铺给他买道具。"))
	for w in staff:
		var card := _card()
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		card.add_child(cv)
		var head := HBoxContainer.new()
		cv.add_child(head)
		head.add_child(_title_label(w.info.name, 19, Color("3b2a1a")))
		var role_lbl := _label("", 14, Color(Data.ROLE_COLOR[w.role()]))
		head.add_child(role_lbl)
		var tr: String = w.info.get("trait", "")
		if tr != "":
			var tr_lbl := _label("　「%s」" % tr, 13, Color("8c2f39"))
			for t in Data.TRAITS:
				if t.name == tr:
					tr_lbl.tooltip_text = t.desc
					tr_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
			head.add_child(tr_lbl)
		head.add_child(_spacer())
		var wage_lbl := _label("", 13, Color("8a7560"))
		head.add_child(wage_lbl)
		var stat_lbl := _label("", 12, Color("5a4030"))
		cv.add_child(stat_lbl)
		var btns := HBoxContainer.new()
		btns.add_theme_constant_override("separation", 6)
		cv.add_child(btns)
		var sel := _button("选中", _select_staff.bind(w), "SecondaryButton")
		var role_btn := _button("调职", _change_role.bind(w), "SecondaryButton")
		var raise_btn := _button("加薪", _raise_wage.bind(w))
		var fire_btn := _button("辞退", _fire.bind(w), "SecondaryButton")
		for b in [sel, role_btn, raise_btn, fire_btn]:
			b.custom_minimum_size = Vector2(60, 0)
			btns.add_child(b)
		staff_box.add_child(card)
		staff_rows.append({"w": w, "role": role_lbl, "wage": wage_lbl, "stats": stat_lbl, "sel": sel, "role_btn": role_btn, "fire": fire_btn})
	staff_box.add_child(_hint("掌柜：" + Data.ROLE_HINT["掌柜"]))
	staff_box.add_child(_hint("厨师：" + Data.ROLE_HINT["厨师"]))
	staff_box.add_child(_hint("跑堂：" + Data.ROLE_HINT["跑堂"]))
	staff_box.add_child(_hint("杂役：" + Data.ROLE_HINT["杂役"]))
	staff_box.add_child(_hint("毅力低的伙计会偷懒；工钱低于本事，向心力会掉，掉到很低就会在休假日辞工。"))
	_refresh_ui()


func _build_town_tab() -> Control:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	lbl_town_status = _wrap(_label("", 14, Color("8c2f39")))
	list.add_child(lbl_town_status)
	btn_open_shop = _button("休假结束，开张营业", _end_rest_day)
	btn_open_shop.custom_minimum_size = Vector2(0, 40)
	list.add_child(btn_open_shop)

	town_sections["grain"] = _section("粮行")
	list.add_child(town_sections["grain"])
	btn_auto_food = _button("", _toggle_auto_food, "SecondaryButton")
	list.add_child(btn_auto_food)
	for k in Data.FOOD_KINDS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var fr := {"lbl": _label("", 14), "buy": []}
		fr.lbl.custom_minimum_size = Vector2(150, 0)
		row.add_child(fr.lbl)
		for amount in FOOD_PACKS:
			var b := _button("+%d" % amount, _buy_food.bind(k, amount))
			row.add_child(b)
			fr.buy.append(b)
		fr["calc"] = _button("算盘…", _open_calc.bind(k), "SecondaryButton")
		row.add_child(fr.calc)
		fr["rush"] = _button("急购 %d" % RUSH_FOOD, _rush_food.bind(k))
		row.add_child(fr.rush)
		list.add_child(row)
		# 自动补货：每个休假日把这类食材补到设定的数
		var auto_row := HBoxContainer.new()
		auto_row.add_theme_constant_override("separation", 4)
		fr["auto"] = _label("", 13, Color("6b5a44"))
		fr.auto.custom_minimum_size = Vector2(150, 0)
		auto_row.add_child(fr.auto)
		auto_row.add_child(_button("－", _change_auto_food.bind(k, -AUTO_FOOD_STEP), "SecondaryButton"))
		auto_row.add_child(_button("＋", _change_auto_food.bind(k, AUTO_FOOD_STEP), "SecondaryButton"))
		fr["smart"] = _button("改回智能", _smart_food.bind(k), "SecondaryButton")
		auto_row.add_child(fr.smart)
		list.add_child(auto_row)
		food_rows.append(fr)

	town_sections["labor"] = _section("人力市场")
	list.add_child(town_sections["labor"])
	for i in 3:
		var row := HBoxContainer.new()
		var l := _wrap(_label("", 13), 250.0)
		row.add_child(l)
		row.add_child(_spacer())
		var b := _button("雇用", _hire_candidate.bind(i))
		row.add_child(b)
		list.add_child(row)
		market_rows.append({"label": l, "button": b})

	list.add_child(_section("木工坊"))
	list.add_child(_hint("添桌子、装修、换桌椅、升级灶台、买摆件，都在「店面」页里。"))

	town_sections["grocer"] = _section("杂货铺")
	list.add_child(town_sections["grocer"])
	lbl_item_target = _wrap(_label("", 13, Color("8a7560")))
	list.add_child(lbl_item_target)
	for k in Data.ITEMS.size():
		var it: Dictionary = Data.ITEMS[k]
		var row := HBoxContainer.new()
		var desc := "%s：%s +%d" % [it.name, it.stat, it.amount]
		if int(it.loyal) > 0:
			desc += "、向心力 +%d" % it.loyal
		row.add_child(_label(desc, 13))
		row.add_child(_spacer())
		var b := _button("%d 文" % it.price, _buy_item.bind(k))
		row.add_child(b)
		list.add_child(row)
		item_buttons.append(b)
	town_scroll = _scroll(list)
	return town_scroll


func _build_shop_tab() -> Control:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.add_child(_hint("店面的活儿都归木工坊，只有休假日能做。装修、桌椅、灶台、摆件都会直接显示在大堂里。"))
	btn_arrange = _button("", _toggle_arrange)
	btn_arrange.custom_minimum_size = Vector2(0, 38)
	list.add_child(btn_arrange)

	list.add_child(_section("桌位"))
	lbl_tables = _label("", 14)
	list.add_child(lbl_tables)
	btn_expand = _button("", _expand)
	list.add_child(btn_expand)
	btn_table = _button("", _buy_table)
	list.add_child(btn_table)

	list.add_child(_section("整体装修"))
	lbl_decor = _wrap(_label("", 14))
	list.add_child(lbl_decor)
	btn_decor = _button("", _buy_decor)
	list.add_child(btn_decor)

	list.add_child(_section("桌椅"))
	lbl_table_grade = _wrap(_label("", 14))
	list.add_child(lbl_table_grade)
	btn_table_grade = _button("", _upgrade_tables)
	list.add_child(btn_table_grade)

	list.add_child(_section("收银柜台"))
	lbl_counter = _wrap(_label("", 14))
	list.add_child(lbl_counter)
	btn_counter = _button("", _upgrade_counter)
	list.add_child(btn_counter)

	list.add_child(_section("后厨灶台"))
	lbl_stove = _wrap(_label("", 14))
	list.add_child(lbl_stove)
	btn_stove = _button("", _upgrade_stove)
	list.add_child(btn_stove)

	list.add_child(_section("摆件"))
	list.add_child(_hint("每样只能买一件，摆在大堂的摆件位上（共 %d 个位置），点「换位置」挪到下一个空位。" % DECOR_SLOTS.size()))
	for k in Data.DECOR_ITEMS.size():
		var it: Dictionary = Data.DECOR_ITEMS[k]
		var card := _card()
		var cv := VBoxContainer.new()
		card.add_child(cv)
		var head := HBoxContainer.new()
		cv.add_child(head)
		head.add_child(_title_label(it.name, 17, Color("3b2a1a")))
		head.add_child(_spacer())
		head.add_child(_label(it.desc, 13, Color("3f7d3a")))
		var row := HBoxContainer.new()
		cv.add_child(row)
		var state_lbl := _label("", 13, Color("8a7560"))
		row.add_child(state_lbl)
		row.add_child(_spacer())
		var move_btn := _button("换位置", _move_ornament.bind(String(it.id)), "SecondaryButton")
		row.add_child(move_btn)
		var buy_btn := _button("买（%d 文）" % it.cost, _buy_ornament.bind(String(it.id)))
		row.add_child(buy_btn)
		list.add_child(card)
		ornament_rows.append({"id": it.id, "state": state_lbl, "move": move_btn, "buy": buy_btn})
	return _scroll(list)


func _build_contest_tab() -> Control:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	lbl_rivals = _wrap(_label("", 13, Color("5a4030")))
	list.add_child(lbl_rivals)
	list.add_child(_hint("比赛要依次参加。休假日报名，下一周六个营业日比成绩，达到目标就赢。没赢可以再报。"))
	for i in Data.CONTESTS.size():
		var c: Dictionary = Data.CONTESTS[i]
		var card := _card()
		var cv := VBoxContainer.new()
		card.add_child(cv)
		var name_lbl := _title_label("", 18, Color("3b2a1a"))
		cv.add_child(name_lbl)
		var detail := "比：%s，目标 %d\n条件：声望 %d、桌子 %d 张　报名费 %d 文　奖金 %d 文" % [
			Data.CONTEST_TYPES[c.type], c.target, c.rep, c.tables, c.fee, c.prize]
		cv.add_child(_wrap(_label(detail, 12, Color("5a4030")), 320.0))
		list.add_child(card)
		contest_labels.append(name_lbl)
	lbl_contest = _wrap(_label("", 14, Color("8c2f39")))
	list.add_child(lbl_contest)
	btn_contest = _button("", _sign_contest)
	btn_contest.custom_minimum_size = Vector2(0, 38)
	list.add_child(btn_contest)
	return _scroll(list)


func _refresh_ui() -> void:
	if lbl_day == null:
		return
	_fill_status()
	lbl_day.text = "%s %s%s　%s%s" % [season().name, _date_text(), "·" + festival_today if festival_today != "" else "", _clock_text(), "　已打烊" if (not is_open and not is_rest_day) else ""]
	bar_day.value = 1.0 if is_rest_day else clampf(day_time / ((CLOSE_HOUR - OPEN_HOUR) * SECONDS_PER_HOUR), 0.0, 1.0)
	lbl_money.text = "%d 文" % money
	lbl_food.text = "食材 %d" % _food_total()
	lbl_food.tooltip_text = _food_text()
	lbl_food.add_theme_color_override("font_color", Color("cfe8b0") if food.min() >= LOW_FOOD else Color("ff8a6a"))
	bar_rep.value = reputation
	lbl_rep.text = "声望 %d" % int(reputation)

	# 菜谱
	if research != null:
		var rd: Dictionary = research.dish
		lbl_research.text = "正在研发「%s」：%d / %d" % [rd.name, int(research.points), int(rd.research_need)]
		bar_research.max_value = float(rd.research_need)
		bar_research.value = research.points
	else:
		lbl_research.text = "眼下没在研发新菜。"
		bar_research.value = 0.0
	var next_locked := {}
	for ci in Data.CATEGORIES.size():
		next_locked[ci] = _next_locked(ci)
	for row in dish_rows:
		var d: Dictionary = row.dish
		var ratio: float = d.ratio
		row.on.visible = d.unlocked
		row.off.visible = not d.unlocked and next_locked[int(d.cat)] == d
		row.price.text = "%d 文 %d%%" % [price_of(d), int(round(ratio * 100.0))]
		row.minus.disabled = ratio <= 0.601
		row.plus.disabled = ratio >= 1.999
		row.research.disabled = research != null or money < int(d.research_cost)

	# 伙计
	for row in staff_rows:
		var w = row.w
		if not is_instance_valid(w):
			continue
		var key: String = Data.ROLE_STAT[w.role()]
		row.role.text = w.role()
		row.wage.text = "工钱 %d 文/天" % int(w.info.wage)
		var parts := PackedStringArray()
		for s in Data.SKILL_STATS:
			parts.append(("【%s %d】" if s == key else "%s %d") % [s, w.stat(s)])
		row.stats.text = "　".join(parts) + "\n魅力 %d　毅力 %d　向心力 %d" % [w.stat("魅力"), w.stat("毅力"), w.stat("向心力")]
		row.sel.text = "已选" if selected_staff == w else "选中"
		row.role_btn.disabled = not is_rest_day
		row.fire.disabled = not is_rest_day

	# 城镇
	if is_rest_day:
		lbl_town_status.text = "今天是休假日，城里各处都能去。"
	else:
		lbl_town_status.text = "今天营业，进不了城。粮行只能急购（价格翻倍），其他要等休假日。"
	btn_open_shop.visible = is_rest_day
	btn_auto_food.text = "休假日自动补货：开" if auto_food_on else "休假日自动补货：关"
	for k in food_rows.size():
		var fr: Dictionary = food_rows[k]
		var kind: Dictionary = Data.FOOD_KINDS[k]
		fr.lbl.text = "%s %d　价×%.2f" % [kind.name, food[k], _food_mult(k)]
		fr.lbl.add_theme_color_override("font_color", Color("3b2a1a") if food[k] >= LOW_FOOD else Color("b03a2a"))
		fr.lbl.tooltip_text = "每天放坏 %d%%" % int(float(kind.spoil) * 100) if float(kind.spoil) > 0 else "放得住，不会坏"
		for i in fr.buy.size():
			fr.buy[i].visible = is_rest_day
			fr.buy[i].disabled = money < _food_cost(k, FOOD_PACKS[i])
			fr.buy[i].tooltip_text = "%d 文" % _food_cost(k, FOOD_PACKS[i])
		fr.rush.visible = not is_rest_day
		fr.calc.visible = is_rest_day
		fr.rush.disabled = money < _food_cost(k, RUSH_FOOD) * 2
		fr.rush.tooltip_text = "营业日急购价翻倍：%d 文" % (_food_cost(k, RUSH_FOOD) * 2)
		fr.auto.text = "　%s补到 %d" % ["固定 " if food_fixed[k] else "智能 ", auto_food_target[k]]
		fr.smart.visible = food_fixed[k]
	for i in market_rows.size():
		var row: Dictionary = market_rows[i]
		if i >= market.size():
			row.label.text = ""
			row.button.disabled = true
			continue
		var cand: Dictionary = market[i]
		if cand.get("hired", false):
			row.label.text = "%s 已经雇下了" % cand.name
			row.button.disabled = true
		else:
			row.label.text = "%s　想当%s　工钱 %d 文/天\n签约费 %d 文　本事：雇了才知道" % [cand.name, cand.role, cand.wage, cand.fee]
			row.button.disabled = not is_rest_day or money < int(cand.fee) or staff.size() >= MAX_STAFF
	lbl_tables.text = "长方桌 %d 张，座位 %d 个（大堂：%s）" % [pieces.size(), tables.size(), Data.EXPANSIONS[expand_level].name]
	if expand_level >= Data.EXPANSIONS.size() - 1:
		btn_expand.text = "大堂已经全部打通"
		btn_expand.disabled = true
	else:
		var ne: Dictionary = Data.EXPANSIONS[expand_level + 1]
		btn_expand.text = "扩建：%s（%d 文）" % [ne.name, ne.cost]
		btn_expand.disabled = not is_rest_day or money < int(ne.cost)
	if _free_piece_cell().x < 0:
		btn_table.text = "大堂摆满了，先扩建"
		btn_table.disabled = true
	else:
		btn_table.text = "添一张长方桌（%d 文）" % _table_cost()
		btn_table.disabled = not is_rest_day or money < _table_cost()
	lbl_decor.text = "装修：%s（%d / %d）" % [DECOR_NAMES[decor_level], decor_level, DECOR_COSTS.size()]
	if decor_level >= DECOR_COSTS.size():
		btn_decor.text = "已经是最高档了"
		btn_decor.disabled = true
	else:
		btn_decor.text = "装修成「%s」（%d 文）" % [DECOR_NAMES[decor_level + 1], DECOR_COSTS[decor_level]]
		btn_decor.disabled = not is_rest_day or money < int(DECOR_COSTS[decor_level])
	lbl_decor.text += "\n每档：客人更满意、更有耐心，来客更多"
	var tg: Dictionary = Data.TABLE_GRADES[table_level]
	lbl_table_grade.text = "现在用的是%s（满意度 +%d%%）" % [tg.name, int(float(tg.sat) * 100.0)]
	if table_level >= Data.TABLE_GRADES.size() - 1:
		btn_table_grade.text = "已经是最好的桌椅了"
		btn_table_grade.disabled = true
	else:
		var ng: Dictionary = Data.TABLE_GRADES[table_level + 1]
		btn_table_grade.text = "换成%s（%d 文）" % [ng.name, ng.cost]
		btn_table_grade.disabled = not is_rest_day or money < int(ng.cost)
	var cg: Dictionary = Data.COUNTER_GRADES[counter_level]
	lbl_counter.text = "现在用的是%s（结账速度 ×%.2f）" % [cg.name, float(cg.speed)]
	if counter_level >= Data.COUNTER_GRADES.size() - 1:
		btn_counter.text = "已经是最好的柜台了"
		btn_counter.disabled = true
	else:
		var nc: Dictionary = Data.COUNTER_GRADES[counter_level + 1]
		btn_counter.text = "换成%s（%d 文）" % [nc.name, nc.cost]
		btn_counter.disabled = not is_rest_day or money < int(nc.cost)
	var sg: Dictionary = Data.STOVE_GRADES[stove_level]
	lbl_stove.text = "现在用的是%s（做菜速度 ×%.2f）" % [sg.name, float(sg.speed)]
	if stove_level >= Data.STOVE_GRADES.size() - 1:
		btn_stove.text = "已经是最好的灶台了"
		btn_stove.disabled = true
	else:
		var ns: Dictionary = Data.STOVE_GRADES[stove_level + 1]
		btn_stove.text = "砌%s（%d 文）" % [ns.name, ns.cost]
		btn_stove.disabled = not is_rest_day or money < int(ns.cost)
	var slot_names := ["左墙上", "右墙上", "左墙下", "右墙下", "门口左", "门口右"]
	for row in ornament_rows:
		var owned: bool = ornaments.has(row.id)
		var wall := _is_wall(row.id)
		var where: String = ("隔墙第 %d 位" % (int(ornaments[row.id]) + 1)) if wall and owned else (slot_names[int(ornaments[row.id])] if owned else "")
		row.state.text = ("摆在%s" % where) if owned else "还没买"
		row.move.visible = owned
		row.move.disabled = not is_rest_day
		row.buy.visible = not owned
		var cost := 0
		for it in Data.DECOR_ITEMS:
			if it.id == row.id:
				cost = int(it.cost)
		row.buy.disabled = not is_rest_day or money < cost or _free_slot(-1, wall) < 0
	var target_ok: bool = selected_staff != null and is_instance_valid(selected_staff)
	lbl_item_target.text = ("买给：%s（在「伙计」里选人）" % selected_staff.info.name) if target_ok else "先在「伙计」里选中一个伙计，再给他买道具。"
	for k in item_buttons.size():
		item_buttons[k].disabled = not is_rest_day or not target_ok or money < int(Data.ITEMS[k].price)

	# 比赛
	for i in contest_labels.size():
		var c: Dictionary = Data.CONTESTS[i]
		var status := "未开放"
		if i < contest_idx:
			status = "已获胜"
		elif i == contest_idx:
			status = "比赛中" if contest_active else "下一场"
		contest_labels[i].text = "%d. %s　【%s】" % [i + 1, c.name, status]
	if contest_active:
		lbl_contest.text = "「%s」第 %d / 6 天\n%s" % [Data.CONTESTS[contest_idx].name, contest_days, _contest_progress_text()]
	elif contest_idx >= Data.CONTESTS.size():
		lbl_contest.text = "五场比赛全部赢下，云来客栈名扬天下！"
	else:
		lbl_contest.text = ""
	var reason := _contest_block_reason()
	lbl_rivals.text = _rivals_text()
	btn_arrange.visible = is_rest_day
	btn_arrange.text = "布置好了，回集市" if arranging else "进店布置（拖动桌子、摆件、字画）"
	btn_contest.text = "报名参加下一场" if reason == "" else reason
	btn_contest.disabled = reason != ""
	btn_contest.visible = is_rest_day and contest_idx < Data.CONTESTS.size()  # 只在休假日（集市告示牌）报名


func _toggle_settings() -> void:
	_show_window(settings_panel)


# ---------------- 浮动小窗：算盘（进货数量）、账本、日历 ----------------

## 做一个带标题和「关闭」的浮动小窗，返回 [窗口, 内容容器]。
func _make_window(root: Control, title: String, pos: Vector2, width: float) -> Array:
	var panel := PanelContainer.new()
	var sb := _box(Color("f6ead2"), Color("c8963e"), 8, 2, 14)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = pos
	panel.custom_minimum_size = Vector2(width, 0)
	panel.hide()
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_child(_title_label(title, 22, Color("8c2f39")))
	head.add_child(_spacer())
	head.add_child(_button("关闭", panel.hide, "SecondaryButton"))
	vb.add_child(head)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	vb.add_child(body)
	return [panel, body]


## 只开一个小窗：开新的就把别的关掉。
func _show_window(panel: PanelContainer) -> void:
	for p in [calc_panel, ledger_panel, calendar_panel, settings_panel, status_panel]:
		if p != panel:
			p.hide()
	panel.visible = not panel.visible


# 算盘：休假日在粮行进货时输入任意数量。
# 键盘：数字键输入，退格删一位，+/- 加减 10，PageUp/PageDown 加减 100，
#       Home 填到买得起的最多，End 清零，/ 减半，* 翻倍，回车确定，Esc 取消。

func _build_calc(root: Control) -> void:
	var w := _make_window(root, "算盘 · 进货", Vector2(300, 150), 340)
	calc_panel = w[0]
	var body: VBoxContainer = w[1]
	calc_info = _wrap(_label("", 15), 310.0)
	body.add_child(calc_info)
	calc_qty_lbl = _title_label("", 34, Color("3b2a1a"))
	calc_qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var qbox := PanelContainer.new()
	qbox.add_theme_stylebox_override("panel", _box(Color("2a1a10"), Color("8b5a2b"), 4, 2, 8))
	calc_qty_lbl.add_theme_color_override("font_color", Color("ffd34d"))
	qbox.add_child(calc_qty_lbl)
	body.add_child(qbox)
	calc_cost_lbl = _label("", 15, Color("8c2f39"))
	body.add_child(calc_cost_lbl)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for spec in [["−100", "add", -100], ["−10", "add", -10], ["+10", "add", 10], ["+100", "add", 100],
			["减半", "half", 0], ["翻倍", "double", 0], ["最多", "max", 0], ["清零", "clear", 0]]:
		var b := _button(spec[0], _calc_op.bind(spec[1], spec[2]), "SecondaryButton")
		b.custom_minimum_size = Vector2(74, 32)
		grid.add_child(b)
	body.add_child(grid)
	body.add_child(_hint("键盘也能用：数字键输入、+ − 加减 10、PageUp/PageDown 加减 100、Home 最多、End 清零、/ 减半、* 翻倍、回车确定。"))
	calc_ok = _button("进货", _calc_confirm)
	calc_ok.custom_minimum_size = Vector2(0, 38)
	body.add_child(calc_ok)


func _open_calc(k: int) -> void:
	if not is_rest_day:
		return
	calc_kind = k
	calc_qty = 0
	_show_window(calc_panel)
	_calc_refresh()


func _calc_max() -> int:
	return clampi(int(floor(money / maxf(_food_mult(calc_kind), 0.01))), 0, 9999)


func _calc_op(op: String, n: int) -> void:
	match op:
		"add":
			calc_qty += n
		"half":
			calc_qty /= 2
		"double":
			calc_qty *= 2
		"max":
			calc_qty = _calc_max()
		"clear":
			calc_qty = 0
		"digit":
			calc_qty = calc_qty * 10 + n
		"back":
			calc_qty /= 10
	calc_qty = clampi(calc_qty, 0, 9999)
	_calc_refresh()


func _calc_refresh() -> void:
	var fk: Dictionary = Data.FOOD_KINDS[calc_kind]
	var mult := _food_mult(calc_kind)
	calc_info.text = "进「%s」：本周行情 %.2f 文/份\n库存 %d，自动补货目标 %d" % [fk.name, mult, food[calc_kind], auto_food_target[calc_kind]]
	calc_qty_lbl.text = "%d 份" % calc_qty
	var cost := _food_cost(calc_kind, calc_qty)
	calc_cost_lbl.text = "合计 %d 文（手头 %d 文，最多买得起 %d 份）" % [cost, money, _calc_max()]
	calc_ok.disabled = calc_qty <= 0 or cost > money
	calc_ok.text = "进货 %d 份" % calc_qty if calc_qty > 0 else "进货"


func _calc_confirm() -> void:
	if calc_qty <= 0 or _food_cost(calc_kind, calc_qty) > money:
		return
	_buy_food(calc_kind, calc_qty)
	sfx.play("coin", -4.0)
	calc_panel.hide()


## 算盘开着时的键盘操作，处理了返回 true。
func _calc_key(k: InputEventKey) -> bool:
	if not calc_panel.visible or not k.pressed:
		return false
	var code := k.keycode
	if code >= KEY_0 and code <= KEY_9:
		_calc_op("digit", code - KEY_0)
	elif code >= KEY_KP_0 and code <= KEY_KP_9:
		_calc_op("digit", code - KEY_KP_0)
	else:
		match code:
			KEY_BACKSPACE:
				_calc_op("back", 0)
			KEY_KP_ADD, KEY_EQUAL, KEY_PLUS:
				_calc_op("add", 10)
			KEY_KP_SUBTRACT, KEY_MINUS:
				_calc_op("add", -10)
			KEY_PAGEUP:
				_calc_op("add", 100)
			KEY_PAGEDOWN:
				_calc_op("add", -100)
			KEY_HOME:
				_calc_op("max", 0)
			KEY_END:
				_calc_op("clear", 0)
			KEY_KP_DIVIDE, KEY_SLASH:
				_calc_op("half", 0)
			KEY_KP_MULTIPLY, KEY_ASTERISK:
				_calc_op("double", 0)
			KEY_ENTER, KEY_KP_ENTER:
				_calc_confirm()
			KEY_ESCAPE:
				calc_panel.hide()
			_:
				return false
	return true


# 账本：本周（进行中）和前三周的现金流水，按类别列出。

const LEDGER_ORDER := ["营业", "比赛", "事件", "工钱", "租金", "常规采购", "急购本金", "急购加价", "店面", "研发", "招人", "税与失窃", "其他"]


func _build_ledger(root: Control) -> void:
	var w := _make_window(root, "账本", Vector2(240, 80), 600)
	ledger_panel = w[0]
	ledger_body = w[1]


func _open_ledger() -> void:
	_show_window(ledger_panel)
	if not ledger_panel.visible:
		return
	for ch in ledger_body.get_children():
		ch.queue_free()
	var cols: Array = [{"title": "本周（进行中）", "start": week_cash_start, "end": money, "items": ledger}]
	for h in ledger_history:
		cols.append({"title": "第 %d 周" % int(h.week), "start": int(h.start), "end": int(h.end), "items": h["items"]})
	var grid := GridContainer.new()
	grid.columns = cols.size() + 1
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 3)
	grid.add_child(_label("", 14))
	for c in cols:
		grid.add_child(_title_label(c.title, 15, Color("8b5a2b")))
	var rows := [["期初银钱", "start"]]
	for cat in LEDGER_ORDER:
		rows.append([cat, cat])
	rows.append(["期末银钱", "end"])
	for r in rows:
		var key: String = r[1]
		var is_edge := key == "start" or key == "end"
		grid.add_child(_label(r[0], 14, Color("3b2a1a") if is_edge else Color("5a4030")))
		for c in cols:
			var v := int(c[key]) if is_edge else int(c["items"].get(key, 0))
			var col := Color("3b2a1a")
			if not is_edge:
				col = Color("3f7d3a") if v > 0 else (Color("a8392a") if v < 0 else Color("b0a08a"))
			var txt := "%d" % v if is_edge else ("%+d" % v if v != 0 else "—")
			var l := _label(txt, 14, col)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			grid.add_child(l)
	ledger_body.add_child(grid)
	ledger_body.add_child(_hint("每个休假日结一次账，账本最多留前三周。「其他」是没单独记账的零碎进出（比如书生还的谢礼）。"))


## 休假日结账：把这周的流水存进账本，开始记下一周。
func _close_week_ledger() -> void:
	var known := 0
	for k in ledger:
		known += int(ledger[k])
	ledger["其他"] = money - week_cash_start - known
	ledger_history.push_front({"week": week(), "start": week_cash_start, "end": money, "items": ledger.duplicate()})
	while ledger_history.size() > 3:
		ledger_history.pop_back()
	ledger = {}
	week_cash_start = money


# 店况：一眼看清客栈眼下怎么样。开着的时候随营业实时刷新。

func _build_status(root: Control) -> void:
	var w := _make_window(root, "店况", Vector2(30, 70), 360)
	status_panel = w[0]
	status_body = w[1]


func _open_status() -> void:
	_show_window(status_panel)
	_fill_status()


func _fill_status() -> void:
	if status_panel == null or not status_panel.visible:
		return
	for ch in status_body.get_children():
		ch.queue_free()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var face: Texture2D = art.staff("掌柜", int(staff_of("掌柜")[0].info.get("look", 0))) if not staff_of("掌柜").is_empty() else null
	if face != null:
		var tr := TextureRect.new()
		tr.texture = face
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(70, 90)
		top.add_child(tr)
	var head := VBoxContainer.new()
	head.add_child(_title_label("%s季 · %s" % [season().name, _date_text()], 17, Color("3b2a1a")))
	head.add_child(_label(_clock_text() + ("　营业中" if (is_open and not is_rest_day) else "　歇业"), 14, Color("6b5a44")))
	head.add_child(_label(Data.CHAPTERS[mini(chapter, Data.CHAPTERS.size() - 1)].title, 14, Color("8c2f39")))
	top.add_child(head)
	status_body.add_child(top)
	var served: int = stats.get("served", 0)
	var rows := [
		["银钱", "%d 文" % money],
		["声望", "%d / 100" % int(reputation)],
		["今日来客", "%d 位（招待 %d，气走 %d，客满错过 %d）" % [stats.get("visitors", 0), served, stats.get("angry", 0), stats.get("lost_full", 0)]],
		["今日营收", "%d 文" % int(stats.get("income", 0))],
		["今日满意度", ("%d%%" % int(float(stats.get("sat_sum", 0.0)) / served * 100.0)) if served > 0 else "—"],
		["伙计 / 座位", "%d 人 / %d 座" % [staff.size(), tables.size()]],
		["比赛奖杯", "%d / %d" % [contest_idx, Data.CONTESTS.size()]],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 4)
	for r in rows:
		grid.add_child(_label(r[0], 14, Color("8b5a2b")))
		grid.add_child(_wrap(_label(r[1], 14, Color("3b2a1a")), 230.0))
	status_body.add_child(grid)


# 日历：这一季的四周，标出今天、休假日、节庆和比赛周。

func _build_calendar(root: Control) -> void:
	var w := _make_window(root, "日历", Vector2(250, 90), 560)
	calendar_panel = w[0]
	calendar_body = w[1]


func _open_calendar() -> void:
	_show_window(calendar_panel)
	if not calendar_panel.visible:
		return
	for ch in calendar_body.get_children():
		ch.queue_free()
	var si := season_of_week(week())
	var se: Dictionary = Data.SEASONS[si]
	var first_week := ((week() - 1) / Data.WEEKS_PER_SEASON) * Data.WEEKS_PER_SEASON + 1
	calendar_body.add_child(_title_label("%s季（第 %d～%d 周）" % [se.name, first_week, first_week + Data.WEEKS_PER_SEASON - 1], 18, Color("3b2a1a")))
	calendar_body.add_child(_wrap(_label(se.desc, 13, Color("6b5a44")), 530.0))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for wd in Data.WEEKDAYS:
		var h := _label(wd, 13, Color("8b5a2b"))
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.custom_minimum_size = Vector2(72, 0)
		grid.add_child(h)
	# 休假日报的名，比的是下一周；营业日里比的就是这一周
	var contest_week := (week() + (1 if is_rest_day else 0)) if contest_active else -1
	for wi in Data.WEEKS_PER_SEASON:
		var wk := first_week + wi
		for wd in 7:
			var d := (wk - 1) * 7 + wd + 1
			var lines := PackedStringArray(["%d 日" % d])
			var fest := ""
			for f in Data.FESTIVALS:
				if int(f.season) == si and int(f.week) == wi and int(f.weekday) == wd:
					fest = f.name
			if fest != "":
				lines.append(fest)
			elif wd == 6:
				lines.append("逛集市")
			if wk == contest_week and wd < 6:
				lines.append("比赛")
			var bg := Color("fffaf0")
			if wd == 6:
				bg = Color("e8dcc0")
			if fest != "":
				bg = Color("f6d2c0")
			if wk == contest_week and wd < 6:
				bg = Color("f3e2a8")
			if d < day:
				bg = bg.darkened(0.12)
			var border := Color("8c2f39") if d == day else Color("d9c09a")
			var cell := PanelContainer.new()
			cell.add_theme_stylebox_override("panel", _box(bg, border, 4, 3 if d == day else 1, 4))
			cell.custom_minimum_size = Vector2(72, 52)
			var l := _label("\n".join(lines), 12, Color("3b2a1a") if d >= day else Color("8a7a6a"))
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(l)
			grid.add_child(cell)
	calendar_body.add_child(grid)
	var next_se: Dictionary = Data.SEASONS[(si + 1) % Data.SEASONS.size()]
	calendar_body.add_child(_hint("红框是今天。下一季是%s季：%s" % [next_se.name, next_se.desc]))


## 设置面板：总音量 + 四类声音各自开关。改了就生效、自动保存。
func _build_settings(root: Control) -> void:
	settings_panel = PanelContainer.new()
	var sb := _box(Color("f6ead2"), Color("c8963e"), 8, 2, 16)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	settings_panel.add_theme_stylebox_override("panel", sb)
	settings_panel.position = Vector2(560, 66)
	settings_panel.custom_minimum_size = Vector2(320, 0)
	settings_panel.hide()
	root.add_child(settings_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	settings_panel.add_child(vb)
	vb.add_child(_title_label("声音设置", 22, Color("8c2f39")))
	var vol_row := HBoxContainer.new()
	vol_row.add_child(_label("总音量", 15))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = sfx.volume
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(_on_volume)
	vol_row.add_child(slider)
	vb.add_child(vol_row)
	var music_hint := "" if sfx.has_music() else "（还没有音乐文件）"
	var voice_hint := "" if sfx.has_voices() else "（还没有录音）"
	for opt in [
		["sfx_on", "音效：切菜、收钱、上菜、门铃"],
		["voice_on", "店小二吆喝" + voice_hint],
		["ambient_on", "炒菜的滋滋背景声"],
		["music_on", "背景音乐" + music_hint],
	]:
		var cb := CheckBox.new()
		cb.text = opt[1]
		cb.button_pressed = sfx.get(opt[0])
		cb.focus_mode = Control.FOCUS_NONE
		cb.add_theme_color_override("font_color", Color("3b2a1a"))
		cb.add_theme_color_override("font_hover_color", Color("8c2f39"))
		cb.add_theme_color_override("font_pressed_color", Color("3b2a1a"))
		cb.add_theme_color_override("font_hover_pressed_color", Color("8c2f39"))
		cb.toggled.connect(_on_sound_option.bind(opt[0]))
		vb.add_child(cb)
	vb.add_child(_hint("想换成好听的录音或配乐：把文件放进游戏的 sfx 文件夹（背景音乐命名为 bgm.mp3），见 sfx/音效说明.txt。"))
	var close := _button("关闭", _toggle_settings)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	vb.add_child(close)


func _on_volume(v: float) -> void:
	sfx.volume = v
	sfx.apply()


func _on_sound_option(on: bool, key: String) -> void:
	sfx.set(key, on)
	sfx.apply()
	if on and key == "sfx_on":
		sfx.play("ding")


func _set_speed(s: float) -> void:
	speed = s
	if s > 0.0:
		last_speed = s
	if not popup.visible:
		Engine.time_scale = s
	for i in speed_buttons.size():
		speed_buttons[i].set_pressed_no_signal(i == int(s))


func _show_popup(title: String, body: String, button_text: String, action: Callable, button2_text := "", action2 := Callable()) -> void:
	popup_title.text = title
	popup_body.text = body
	popup_portrait.texture = art.tex(popup_portrait_key) if popup_portrait_key != "" else null
	popup_portrait.visible = popup_portrait.texture != null
	popup_portrait_key = ""
	popup_button.text = button_text
	popup_action = action
	popup_button2.text = button2_text
	popup_button2.visible = button2_text != ""
	popup_action2 = action2
	sfx.set_sizzle(false)
	dim.show()
	popup.show()
	popup.reset_size()
	popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	Engine.time_scale = 0.0
	if autotest:
		_autotest_popup.call_deferred(title)
	elif autoplay_weeks > 0:
		_autoplay_popup.call_deferred(title)


func _close_popup() -> void:
	dim.hide()
	popup.hide()
	popup_event = ""
	Engine.time_scale = speed


func _on_popup_button() -> void:
	var action := popup_action
	_close_popup()
	if action.is_valid():
		action.call()


func _on_popup_button2() -> void:
	var action := popup_action2
	_close_popup()
	if action.is_valid():
		action.call()


# ---------------- 自动测试 ----------------
# 跑两周：第一周正常经营并触发几个访客事件，休假日把城镇、伙计、研发、比赛都操作一遍，
# 第二周比赛，第二个休假日看比赛结果，最后直接检查通关弹窗。

const AUTO_EVENTS := {2: "storyteller", 3: "bully", 4: "critic", 5: "scholar", 8: "doctor", 9: "acrobat", 10: "master_chef"}


func _can_shoot() -> bool:
	return shots_dir != "" and DisplayServer.get_name() != "headless"


func _autotest_tick() -> void:
	for k in food.size():
		if food[k] < 80:
			_rush_food(k)
	if AUTO_EVENTS.has(day) and day_time > 40.0 and not auto_done.has("ev%d" % day):
		auto_done["ev%d" % day] = true
		event_hour = -1.0
		for ev in Data.EVENTS:
			if ev.id == AUTO_EVENTS[day]:
				_trigger_event(ev)
	if day == 2 and not auto_done.has("shot_eat"):
		for c in customers:
			if c.state == Customer.S.EATING and fmod(c.anim, Customer.EAT_CYCLE) / Customer.EAT_CYCLE > 0.5:
				auto_done["shot_eat"] = true
				_shot("eating")
				break
	if day == 3 and day_time > 100.0 and not auto_done.has("shot_d3"):
		auto_done["shot_d3"] = true
		_shot("d3_busy")
	if day == 3 and current_hour() > 19.3 and not auto_done.has("shot_night"):
		auto_done["shot_night"] = true
		_open_status()
		print("[autotest] night=%.2f status_visible=%s" % [night_amount(), status_panel.visible])
		await _shot("d3_night")
		status_panel.hide()
	if day == 9 and day_time > 100.0 and not auto_done.has("shot_d9"):
		auto_done["shot_d9"] = true
		tabs.current_tab = 4
		_shot("d9_contest")


func _autotest_popup(title: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not popup.visible:
		return
	if title == "说书先生来访":
		await _shot("event")
	elif title.contains("周结束") and day == 7:
		await _shot("week1_summary")
	elif title.begins_with("结局"):
		await _shot("ending")
		print("[autotest] ending shown, contests=%d finished=%s" % [contest_idx, game_finished])
		print("[autotest] OK")
		get_tree().quit()
		return
	elif is_rest_day and day == 14:
		await _shot("contest_result")
	print("[autotest] popup: ", title)
	if popup_event == "bully":
		_on_popup_button2()
	else:
		_on_popup_button()


func _autotest_rest_day() -> void:
	await get_tree().process_frame
	if day == 7:
		money += 18000  # 测试资金，把各种操作都走一遍
		for k in food.size():
			_buy_food(k, 300)
		for i in 3:
			_hire_candidate(i)
		_select_staff(staff[0])
		_buy_item(1)
		_buy_item(4)
		_raise_wage(staff[1])
		# 像玩家一样调配：跑堂不够就把多出来的人调去当跑堂
		for w in staff.duplicate():
			if staff_of("跑堂").size() >= 2:
				break
			if w.role() != "跑堂" and staff_of(w.role()).size() > 1:
				while w.role() != "跑堂":
					_change_role(w)
		_start_research(_next_locked(2))
		_buy_table()
		_buy_table()
		_buy_decor()
		_upgrade_tables()
		_upgrade_stove()
		_upgrade_counter()
		for id in ["screen", "fish", "flower", "censer", "curio", "scroll", "wall_landscape", "wall_tiger"]:
			_buy_ornament(id)
		_move_ornament("fish")
		_toggle_arrange()
		_expand()
		_drop({"kind": "table", "i": 0}, cell_center(Vector2i(4, 5)))
		_drop({"kind": "orn", "id": "wall_tiger"}, WALL_SLOTS[5])
		print("[autotest] arrange: pieces=%s seats=%d expand=%d wall_tiger=%s pick=%s wall_of_tables_ok=%s" % [pieces, tables.size(), expand_level, ornaments.wall_tiger, _pick_at(cell_center(pieces[1])), _layout_ok([Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2), Vector2i(12, 2), Vector2i(13, 2)])])
		await _shot("arrange")
		_toggle_arrange()
		_sign_contest()
		print("[autotest] rest day 1: staff=%d tables=%d decor=%d research=%s contest=%s money=%d" % [
			staff.size(), tables.size(), decor_level, research != null, contest_active, money])
		for w in staff:
			print("[autotest]   %s %s %s wage=%d" % [w.info.name, w.role(), str(w.info.stats), w.info.wage])
		print("[autotest] shop: table_level=%d stove_level=%d ornaments=%s" % [table_level, stove_level, str(ornaments)])
		for id in ["grain", "labor", "grocer", "carpenter", "notice"]:
			_open_shop(id)
		print("[autotest] market: food=%s auto=%s target=%s shop_at(130,250)=%s shop_at(770,540)=%s" % [
			food, auto_food_on, auto_food_target, _shop_at(Vector2(130, 250)), _shop_at(Vector2(770, 540))])
		hover_shop = "grain"
		_toggle_settings()
		print("[autotest] settings: vol=%.2f sfx=%s voice=%s ambient=%s music=%s has_music=%s" % [
			sfx.volume, sfx.sfx_on, sfx.voice_on, sfx.ambient_on, sfx.music_on, sfx.has_music()])
		await _shot("settings")
		_toggle_settings()
		_open_calc(0)
		for key in [KEY_3, KEY_0, KEY_PAGEUP, KEY_KP_MULTIPLY]:  # 30 → 130 → 260
			var ev := InputEventKey.new()
			ev.keycode = key
			ev.pressed = true
			_calc_key(ev)
		print("[autotest] calc qty=%d (expect 260)" % calc_qty)
		await _shot("calc")
		var food_before: int = food[0]
		_calc_confirm()
		print("[autotest] calc bought: %d -> %d" % [food_before, food[0]])
		_open_ledger()
		print("[autotest] ledger weeks=%d last_end=%d" % [ledger_history.size(), int(ledger_history[0].end) if not ledger_history.is_empty() else -1])
		await _shot("ledger")
		_open_calendar()
		await _shot("calendar")
		calendar_panel.hide()
		_save_game()
		var before := "%d|%d|%s|%s|%s|%s|%s|%s" % [money, staff.size(), research.points, str(ornaments), staff[0].info.stats, food, food_price, pieces]
		_load_game()
		var after := "%d|%d|%s|%s|%s|%s|%s|%s" % [money, staff.size(), research.points, str(ornaments), staff[0].info.stats, food, food_price, pieces]
		print("[autotest] save/load roundtrip: ", "same" if before == after else "DIFF %s vs %s" % [before, after])
		assert(before == after)
		money += 5000
		for ev in Data.STORY:
			print("[autotest] story %s: %s | rival=%s cooks=%d" % [ev.id, _story_effect(ev, true).replace("\n", " "), rivals[1].open, staff_of("厨师").size()])
		story_step = 0
		story_wait_week = 0
		rivals[1].open = false
		rivals[1].closed = false
		for ev in Data.DISASTERS:
			_event_accept(ev)
			_event_decline(ev)
		print("[autotest] rivals: %s | mult=%.2f | update=%s" % [_rivals_text().replace("\n", " / "), _rival_mult(), _update_rivals()])
		print("[autotest] chapter0 done=%s ending=%s" % [_chapter_done(0), _ending()])
		print("[autotest] season w1=%s w5=%s festival_day3=%s" % [season().name, Data.SEASONS[season_of_week(5)].name, Data.FESTIVALS[0].name])
		for t in [3, 2, 1, 0, 4]:
			tabs.current_tab = t
			await _shot("rest_tab%d" % t)
		_end_rest_day()
	else:
		print("[autotest] rest day 2: contest_idx=%d active=%s money=%d rep=%.1f" % [contest_idx, contest_active, money, reputation])
		# 直接检查通关：假装前四场已赢，最后一场达标
		contest_idx = Data.CONTESTS.size() - 1
		contest_active = true
		contest_days = 6
		contest_value = 999.0
		is_rest_day = false
		day += 6
		_enter_rest_day()


func _shot(shot_name: String) -> void:
	if not _can_shoot():
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shots_dir.path_join(shot_name + ".png"))
	print("[autotest] saved ", shot_name)


# ---------------- 自动玩家 ----------------
# 命令行加 -- --play=周数：按普通玩家的思路连续经营，每周打印一行经营数据，用来看数值平衡。

var autoplay_weeks := 0
var week_sum := {}  # 本周累计
var ledger := {}  # 本周现金流水，按类别
var week_cash_start := 0


func _book(cat: String, amount: int) -> void:
	ledger[cat] = int(ledger.get(cat, 0)) + amount


func _autoplay_day_end() -> void:
	for k in ["visitors", "served", "angry", "lost_full", "lost_price", "income", "food_bought"]:
		week_sum[k] = int(week_sum.get(k, 0)) + int(stats[k])
	week_sum["sat"] = float(week_sum.get("sat", 0.0)) + float(stats.sat_sum)


func _autoplay_popup(title: String) -> void:
	await get_tree().process_frame
	if not popup.visible:
		return
	var take := true
	if popup_button2.visible:
		take = money > 3000 and popup_event != "bully"  # 宽裕才接；地痞不给钱
		if popup_event == "critic" or popup_event == "inspect":
			take = popup_event == "critic" or money > 2000
	print("[play] popup: %s -> %s" % [title.replace("\n", " "), "yes" if take else "no"])
	if take:
		_on_popup_button()
	else:
		_on_popup_button2()


func _autoplay_tick() -> void:
	if week() % 4 == 0 and weekday() == 2 and day_time > 100.0 and not auto_done.has("w%d" % week()):
		auto_done["w%d" % week()] = true
		_shot("play_w%02d" % week())
	for d in dishes:  # 只急购菜单上用得到的食材
		var k: int = d.food
		if d.unlocked and food[k] < LOW_FOOD and money > 400:
			_rush_food(k)


## 休假日按优先级办事（花完都至少留 CASH_RESERVE 周转），办完打印这一周的账，然后开张。
func _autoplay_rest_day() -> void:
	await get_tree().process_frame
	var w := week_sum
	var full_rate := float(w.get("lost_full", 0)) / maxf(1.0, float(w.get("served", 0)) + float(w.get("angry", 0)) + float(w.get("lost_full", 0)))
	# 1. 桌子优先：不到 8 座就每个休假日买一张；8 座以后看上周客满流失
	var c := _free_piece_cell()
	if c.x >= 0 and money - _table_cost() >= CASH_RESERVE and (tables.size() < 8 or full_rate > 0.3):
		_buy_table()
	if _free_piece_cell().x < 0 and expand_level < Data.EXPANSIONS.size() - 1 and money - int(Data.EXPANSIONS[expand_level + 1].cost) >= CASH_RESERVE and full_rate > 0.3:
		_expand()
	# 2. 缺人就招：跑堂按座位配，厨师按座位配
	var want := {"跑堂": maxi(1, tables.size() / 4), "厨师": maxi(1, tables.size() / 6), "杂役": 1 if tables.size() >= 8 else 0, "掌柜": 1}
	for i in market.size():
		var cand: Dictionary = market[i]
		if not cand.get("hired", false) and staff_of(cand.role).size() < int(want.get(cand.role, 0)) and money - int(cand.fee) >= CASH_RESERVE:
			_hire_candidate(i)
	# 3. 研发
	if research == null:
		for ci in Data.CATEGORIES.size():
			var d = _next_locked(ci)
			if d != null and money - int(d.research_cost) >= CASH_RESERVE + 500:
				_start_research(d)
				break
	# 4. 升级：灶台 > 桌椅 > 柜台 > 装修
	for pair in [[Data.STOVE_GRADES, stove_level, _upgrade_stove], [Data.TABLE_GRADES, table_level, _upgrade_tables], [Data.COUNTER_GRADES, counter_level, _upgrade_counter]]:
		if int(pair[1]) < pair[0].size() - 1 and money - int(pair[0][int(pair[1]) + 1].cost) >= CASH_RESERVE * 2:
			pair[2].call()
	if decor_level < DECOR_COSTS.size() and money - int(DECOR_COSTS[decor_level]) >= CASH_RESERVE * 2:
		_buy_decor()
	# 5. 比赛
	if _contest_block_reason() == "" and money - int(Data.CONTESTS[contest_idx].fee) >= CASH_RESERVE:
		_sign_contest()
	# 周报：本周现金流（期初 → 期末，各类相加，对不上的部分记「其他」）
	var last_week: Dictionary = ledger_history[0] if not ledger_history.is_empty() else {"start": money, "items": {}}
	print("[play] W%02d %s cash %d->%d rep=%d seats_next=%d staff=%d | visit=%d served=%d full=%d(%d%%) angry=%d price=%d sat=%d%% | ch=%d contest=%d exp=%d decor=%d tbl=%d stove=%d ctr=%d | rivals=%s | %s" % [
		week(), season().name, int(last_week.start), money, int(reputation), tables.size(), staff.size(),
		w.get("visitors", 0), w.get("served", 0), w.get("lost_full", 0), int(full_rate * 100.0), w.get("angry", 0), w.get("lost_price", 0),
		int(float(w.get("sat", 0.0)) / maxf(1.0, float(w.get("served", 0))) * 100.0),
		chapter, contest_idx, expand_level, decor_level, table_level, stove_level, counter_level,
		rivals.map(func(x): return "%d%s" % [int(x.rep), "" if x.open else ("x" if x.closed else "-")]), str(last_week["items"])])
	week_sum = {}
	if week() >= autoplay_weeks:
		print("[play] done")
		get_tree().quit()
		return
	_end_rest_day()
