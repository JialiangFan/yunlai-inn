extends Control
## 剧情对话：屏幕下方一个对话框，左边头像和名字牌，右边台词一个字一个字地出来。
## 点一下鼠标（或按空格、回车）：字还没出完就先全出来，出完了就翻到下一句。右上角「跳过」直接演完。
## 每句台词是 {"who": 名字, "pic": 头像贴图或 null, "color": 没头像时名字牌的底色, "text": 台词}。
## 游戏的暂停/恢复由 main.gd 的 _play_dialog 负责，这里只管演。

const CHARS_PER_SEC := 30.0

var lines: Array = []
var idx := 0
var on_done := Callable()
var start_ms := 0  # 这句开始打字的时刻；暂停时 delta 是 0，所以按真实时间算
var full := false

var face: TextureRect
var face_char: Label  # 没有头像图时，用名字的第一个字顶上
var face_box: PanelContainer
var name_lbl: Label
var text_lbl: Label
var hint: Label


func build(font: Font, title_font: Font) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # 盖住整个画面，点哪里都算翻页
	hide()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.25)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2b3a5c").lerp(Color("1d2740"), 0.3)
	sb.border_color = Color("d4a640")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -470
	panel.offset_right = 470
	panel.offset_top = -236
	panel.offset_bottom = -24
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)

	# 头像框 + 名字牌
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(left)
	face_box = PanelContainer.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color("f3e3c0")
	fsb.border_color = Color("d4a640")
	fsb.set_border_width_all(3)
	fsb.set_corner_radius_all(6)
	face_box.add_theme_stylebox_override("panel", fsb)
	face_box.custom_minimum_size = Vector2(132, 132)
	face_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(face_box)
	face = TextureRect.new()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.clip_contents = true
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_box.add_child(face)
	face_char = Label.new()
	face_char.add_theme_font_override("font", title_font)
	face_char.add_theme_font_size_override("font_size", 64)
	face_char.add_theme_color_override("font_color", Color("fff6e0"))
	face_char.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face_char.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face_box.add_child(face_char)
	var plate := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("8c2f39")
	psb.border_color = Color("d4a640")
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(4)
	psb.content_margin_top = 3
	psb.content_margin_bottom = 3
	plate.add_theme_stylebox_override("panel", psb)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(plate)
	name_lbl = Label.new()
	name_lbl.add_theme_font_override("font", title_font)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color("ffe9b0"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(name_lbl)

	# 台词
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(right)
	text_lbl = Label.new()
	text_lbl.add_theme_font_override("font", font)
	text_lbl.add_theme_font_size_override("font_size", 21)
	text_lbl.add_theme_color_override("font_color", Color("f4ecd8"))
	text_lbl.add_theme_constant_override("line_spacing", 6)
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_lbl.custom_minimum_size = Vector2(700, 0)
	right.add_child(text_lbl)
	hint = Label.new()
	hint.add_theme_font_override("font", font)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("d4a640"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.text = "▼ 点击继续"
	right.add_child(hint)

	var skip := Button.new()
	skip.text = "跳过 ▶▶"
	skip.theme_type_variation = "SecondaryButton"
	skip.focus_mode = Control.FOCUS_NONE
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -120
	skip.offset_right = -20
	skip.offset_top = 70
	skip.offset_bottom = 104
	skip.pressed.connect(skip_all)
	add_child(skip)


func play(new_lines: Array, done: Callable) -> void:
	lines = new_lines
	on_done = done
	idx = 0
	# 父节点挂在 CanvasLayer 下，锚点不一定撑得开，直接按画面大小铺满
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	show()
	_show_line()


func _show_line() -> void:
	var ln: Dictionary = lines[idx]
	name_lbl.text = String(ln.get("who", ""))
	var pic: Texture2D = ln.get("pic", null)
	face.texture = pic
	face.visible = pic != null
	face_char.visible = pic == null
	face_char.text = name_lbl.text.left(1)
	var fsb: StyleBoxFlat = face_box.get_theme_stylebox("panel")
	fsb.bg_color = Color("f3e3c0") if pic != null else Color(ln.get("color", Color("6a5a48")))
	text_lbl.text = String(ln.get("text", ""))
	text_lbl.visible_characters = 0
	full = false
	hint.modulate.a = 0.0
	start_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if not visible or full:
		if visible:
			hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 220.0)
		return
	var n := int((Time.get_ticks_msec() - start_ms) / 1000.0 * CHARS_PER_SEC)
	if n >= text_lbl.text.length():
		_finish_line()
	else:
		text_lbl.visible_characters = n


func _finish_line() -> void:
	text_lbl.visible_characters = -1
	full = true


func advance() -> void:
	if not visible:
		return
	if not full:
		_finish_line()
		return
	idx += 1
	if idx >= lines.size():
		_end()
	else:
		_show_line()


func skip_all() -> void:
	if visible:
		_end()


func _end() -> void:
	hide()
	lines = []
	var cb := on_done
	on_done = Callable()
	if cb.is_valid():
		cb.call()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		advance()
		accept_event()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			advance()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			skip_all()
			get_viewport().set_input_as_handled()
