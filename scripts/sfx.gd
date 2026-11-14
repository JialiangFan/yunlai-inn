extends Node
## 声音：音效、吆喝、炒菜背景声、背景音乐，各自可开关，选择会存下来。
## 音效默认用代码合成（尽量柔和）；放同名文件进 sfx 文件夹就用文件：
##   音效 sfx/chop.wav 等，吆喝 sfx/voice/*.wav，背景音乐 sfx/bgm.mp3 / bgm.ogg / bgm.wav

const RATE := 22050
const VOICE_GAP := 1.8  # 两句吆喝之间至少隔这么久（秒，按真实时间）
const NAMES := ["chop", "coin", "bell", "ding", "angry", "click", "sizzle", "gong", "abacus"]
const SETTINGS_PATH := "user://settings.cfg"

# 设置（会保存）
var volume := 0.7
var sfx_on := true
var voice_on := false  # 电脑合成的吆喝比较生硬，默认关
var ambient_on := false  # 炒菜背景声默认关
var music_on := true

var _streams := {}
var _voices := {}
var _players: Array = []
var _sizzle: AudioStreamPlayer
var _bgm: AudioStreamPlayer
var _last_play := {}
var _last_voice := -100.0
var _want_sizzle := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	for n in NAMES:
		var s = _load_wav("res://sfx/%s.wav" % n)
		_streams[n] = s if s != null else _synth(n)
	for v in ["welcome", "order", "serve", "bye", "open"]:
		var s = _load_wav("res://sfx/voice/%s.wav" % v)
		if s != null:
			_voices[v] = s
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_sizzle = AudioStreamPlayer.new()
	_sizzle.stream = _streams["sizzle"]
	_sizzle.volume_db = -20.0
	add_child(_sizzle)
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = _load_music()
	_bgm.volume_db = -10.0
	_bgm.finished.connect(_bgm.play)  # 放完从头再放
	add_child(_bgm)
	apply()


func has_music() -> bool:
	return _bgm.stream != null


func has_voices() -> bool:
	return not _voices.is_empty()


## 设置改动后调用：音量、背景音乐、炒菜声立即生效，并保存。
func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	AudioServer.set_bus_mute(0, volume <= 0.001)
	if music_on and has_music():
		if not _bgm.playing:
			_bgm.play()
	else:
		_bgm.stop()
	set_sizzle(_want_sizzle)
	_save_settings()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func play(n: String, volume_db := 0.0) -> void:
	if not sfx_on or not _streams.has(n):
		return
	var t := _now()
	if t - float(_last_play.get(n, -100.0)) < 0.07:
		return
	_last_play[n] = t
	for p in _players:
		if not p.playing:
			p.stream = _streams[n]
			p.volume_db = volume_db - 4.0
			p.pitch_scale = randf_range(0.96, 1.04)
			p.play()
			return


## 吆喝：有冷却，免得一群人同时喊。
func voice(v: String, chance := 1.0) -> void:
	if not voice_on or not _voices.has(v) or randf() > chance:
		return
	var t := _now()
	if t - _last_voice < VOICE_GAP:
		return
	_last_voice = t
	for p in _players:
		if not p.playing:
			p.stream = _voices[v]
			p.volume_db = -4.0
			p.pitch_scale = 1.0
			p.play()
			return


func set_sizzle(on: bool) -> void:
	_want_sizzle = on
	on = on and ambient_on
	if on and not _sizzle.playing:
		_sizzle.play()
	elif not on and _sizzle.playing:
		_sizzle.stop()


# ---------------- 保存设置 ----------------

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	volume = float(cfg.get_value("sound", "volume", volume))
	sfx_on = bool(cfg.get_value("sound", "sfx", sfx_on))
	voice_on = bool(cfg.get_value("sound", "voice", voice_on))
	ambient_on = bool(cfg.get_value("sound", "ambient", ambient_on))
	music_on = bool(cfg.get_value("sound", "music", music_on))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("sound", "volume", volume)
	cfg.set_value("sound", "sfx", sfx_on)
	cfg.set_value("sound", "voice", voice_on)
	cfg.set_value("sound", "ambient", ambient_on)
	cfg.set_value("sound", "music", music_on)
	cfg.save(SETTINGS_PATH)


# ---------------- 读声音文件（不经过导入，直接读） ----------------

func _load_music() -> AudioStream:
	for ext in ["mp3", "ogg", "wav"]:
		var path := "res://sfx/bgm.%s" % ext
		if not FileAccess.file_exists(path):
			continue
		match ext:
			"mp3":
				var m := AudioStreamMP3.new()
				m.data = FileAccess.get_file_as_bytes(path)
				return m
			"ogg":
				return AudioStreamOggVorbis.load_from_buffer(FileAccess.get_file_as_bytes(path))
			"wav":
				return _load_wav(path)
	return null


func _load_wav(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var channels := 1
	var rate := RATE
	var bits := 16
	var pos := 12
	while pos + 8 <= bytes.size():
		var id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var size := bytes.decode_u32(pos + 4)
		if id == "fmt ":
			channels = bytes.decode_u16(pos + 10)
			rate = bytes.decode_u32(pos + 12)
			bits = bytes.decode_u16(pos + 22)
		elif id == "data":
			var s := AudioStreamWAV.new()
			s.format = AudioStreamWAV.FORMAT_16_BITS if bits == 16 else AudioStreamWAV.FORMAT_8_BITS
			s.mix_rate = rate
			s.stereo = channels == 2
			s.data = bytes.slice(pos + 8, pos + 8 + size)
			return s
		pos += 8 + size + (size % 2)
	return null


# ---------------- 合成音效（柔和版：只用正弦和低通过的噪声，音量都压低） ----------------

func _make(seconds: float, gen: Callable, loop := false) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	_lp = 0.0
	for i in n:
		var t := float(i) / RATE
		var v: float = gen.call(t)
		# 头尾各 5 毫秒淡入淡出，避免“咔哒”声
		v *= clampf(t / 0.005, 0.0, 1.0) * clampf((seconds - t) / 0.005, 0.0, 1.0) if not loop else 1.0
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = n
	return s


func _synth(n: String) -> AudioStreamWAV:
	match n:
		"chop":
			return _make(0.5, _gen_chop)
		"sizzle":
			return _make(2.0, _gen_sizzle, true)
		"coin":
			return _make(0.5, _gen_coin)
		"bell":
			return _make(1.2, _gen_bell)
		"ding":
			return _make(0.45, _gen_ding)
		"angry":
			return _make(0.35, _gen_angry)
		"click":
			return _make(0.05, _gen_click)
		"gong":
			return _make(1.8, _gen_gong)
		"abacus":
			return _make(1.1, _gen_abacus)
	return null


var _lp := 0.0  # 低通滤波的状态


## 低通过的白噪声：比直接的噪声柔和得多。k 越小越闷。
func _soft_noise(k: float) -> float:
	_lp += (randf_range(-1, 1) - _lp) * k
	return _lp


func _gen_chop(t: float) -> float:  # 木砧板上的“笃笃笃”
	var k := fmod(t, 0.16)
	return (sin(TAU * 150.0 * k) * 0.8 + _soft_noise(0.25) * 0.6) * exp(-k * 70.0) * 0.45


func _gen_sizzle(t: float) -> float:  # 小火慢炒，低而稳
	return _soft_noise(0.18) * (0.5 + 0.12 * sin(TAU * 0.7 * t)) * 0.35


func _gen_coin(t: float) -> float:  # 铜钱轻响
	var a := exp(-t * 18.0) * sin(TAU * 1568.0 * t)
	var t2 := t - 0.08
	var b := 0.0
	if t2 > 0.0:
		b = exp(-t2 * 18.0) * sin(TAU * 2093.0 * t2)
	return (a + b) * 0.22


func _gen_bell(t: float) -> float:  # 风铃：几个音轻轻叠在一起
	var v := 0.0
	var notes := [1046.5, 1318.5, 1568.0]
	for i in 3:
		var ti := t - i * 0.09
		if ti > 0.0:
			v += sin(TAU * notes[i] * ti) * exp(-ti * 5.0)
	return v * 0.16


func _gen_ding(t: float) -> float:  # 瓷碗轻碰
	return (sin(TAU * 1175.0 * t) + 0.3 * sin(TAU * 2350.0 * t)) * exp(-t * 14.0) * 0.2


func _gen_angry(t: float) -> float:  # 一声低低的叹气，不刺耳
	var f := 220.0 - t * 160.0
	return sin(TAU * f * t) * exp(-t * 7.0) * 0.18


func _gen_click(t: float) -> float:  # 轻轻的木头声
	return sin(TAU * 900.0 * t) * exp(-t * 90.0) * 0.18


# 拨算盘：一串木珠互相磕碰的“噼啪”，间隔不匀，有时两颗连着响
const ABACUS_HITS := [0.0, 0.11, 0.17, 0.33, 0.42, 0.47, 0.63, 0.78, 0.84, 0.95]


func _gen_abacus(t: float) -> float:
	var v := 0.0
	for i in ABACUS_HITS.size():
		var k: float = t - ABACUS_HITS[i]
		if k >= 0.0 and k < 0.06:
			var f := 2100.0 + (i % 3) * 380.0  # 每颗珠子音高略不同
			v += (sin(TAU * f * k) * 0.7 + sin(TAU * f * 1.62 * k) * 0.3) * exp(-k * 160.0)
	return (v + _soft_noise(0.6) * 0.15 * (1.0 if fmod(t, 0.11) < 0.01 else 0.0)) * 0.25


func _gen_gong(t: float) -> float:  # 远处的锣，柔和
	return (sin(TAU * 147.0 * t) * 0.6 + sin(TAU * 220.0 * t) * 0.25) * exp(-t * 2.5) * (1.0 - exp(-t * 40.0)) * 0.3
