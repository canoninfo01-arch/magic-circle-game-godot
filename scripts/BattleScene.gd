extends Node2D

const _Characters = preload("res://scripts/Characters.gd")
const _Shapes     = preload("res://scripts/Shapes.gd")
const _Cards      = preload("res://scripts/Cards.gd")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 定数
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const TARGET_R    := 140.0
const MANA_MAX           := 100.0
const MANA_COST          := 30.0
const MANA_REGEN_PER_SEC := 6.0
const MAX_WAVES   := 3
const WAVE_TIME    := 20.0
const ENEMY_SPAWN_Y     := 150.0
const ENEMY_CLUSTER_N   := 8
const ENEMY_APPROACH_SMOOTH := 3.0
const MANA_PARTICLE_MAX := 12

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 画面
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var W: float; var H: float
var tx: float; var ty: float   # target center
var jp_font: Font = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# パーティ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var party          : Array = []
var party_index    : int   = 0
var intro_layer    : CanvasLayer = null
var character      : Dictionary = {}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# バトル状態
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var game_state    : String = "idle"
var player_max_hp : int    = 300
var player_hp     : int    = 300
var wave_num      : int    = 1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 魔素（マナ）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var mana := {"fire": MANA_MAX, "thunder": MANA_MAX, "ice": MANA_MAX}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ウェーブ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var enemy_queue      : Array[Dictionary] = []
var enemy_clusters   : Array[Dictionary] = []
var wave_active      : bool  = false
var wave_time_limit  : float = WAVE_TIME
var wave_start_sec   : float = 0.0
var fio_frozen_sec   : float = 0.0
var fio_freeze_start : float = -1.0
var current_shape    : String = "circle"
var sample_pts       : Array[Vector2] = []
var fio_guide_r      : float = TARGET_R
var fio_tween        : Tween = null
var guide_tween      : Tween = null   # アギのフェード
var blink_tween      : Tween = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var trace_pts      : Array[Vector2] = []
var draw_start_sec : float  = 0.0
var round_start_sec: float  = 0.0   # アギの早描きボーナス用
var active_touches : Dictionary = {}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ノード参照
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var camera         : Camera2D
var guide_rail     : Line2D
var guide_line     : Line2D
var trace_line     : Line2D
var ui_layer       : CanvasLayer

var enemy_hp_fill  : ColorRect; var enemy_hp_lbl   : Label
var enemy_name_lbl : Label;     var wave_lbl       : Label
var player_hp_fill : ColorRect; var player_hp_lbl  : Label
var timer_lbl      : Label;     var tech_lbl       : Label
var result_lbl     : Label;     var power_lbl      : Label
var hint_lbl       : Label
var element_btns    : Dictionary = {}   # element -> Button
var mana_particles  : Dictionary = {}   # element -> Array[Node2D]
var mana_anchor_pos : Dictionary = {}   # element -> Vector2

# ドロップ画面
var drop_layer     : CanvasLayer = null
var drop_card_bg   : ColorRect   = null
var drop_name_lbl  : Label       = null
var drop_rarity_lbl: Label       = null
var drop_tap_lbl   : Label       = null
var drop_flash     : ColorRect   = null

# コレクション画面
var coll_layer     : CanvasLayer = null


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 初期化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _ready() -> void:
	await get_tree().process_frame
	var sz  = get_viewport_rect().size
	W = sz.x; H = sz.y
	tx = W / 2.0; ty = H * 0.62

	party          = _Characters.get_all()
	party_index    = 0
	character      = party[party_index]
	current_shape  = party[party_index]["techniques"][0]["shape"]  # _get_tech未初期化のため固定
	sample_pts     = _Shapes.make_sample_pts(current_shape, tx, ty, TARGET_R)

	_build_nodes()
	_build_intro()
	_build_drop_screen()
	_build_collection_screen()

	jp_font = load("res://fonts/jp_font.ttf")
	if jp_font:
		_apply_font(self, jp_font)

	_show_intro()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ノード構築
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _apply_font(node: Node, font: Font) -> void:
	if node is Label or node is Button:
		node.add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_font(child, font)

func _build_nodes() -> void:
	# カメラ（シェイク用）
	camera = Camera2D.new()
	camera.position = Vector2(W / 2.0, H / 2.0)
	add_child(camera)
	camera.make_current()

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.059, 0.059, 0.137); bg.size = Vector2(W, H)
	add_child(bg)

	# ガイド
	guide_rail = _make_line(44.0, Color(0,0,0,0))
	add_child(guide_rail)
	guide_line = _make_line(2.0, Color(0,0,0,0))
	add_child(guide_line)
	_redraw_guide()

	# 描画軌跡
	trace_line = _make_line(12.0 * 2.0, Color(0.267, 0.667, 1.0, 0.75))
	trace_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trace_line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	add_child(trace_line)

	# UI レイヤー
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	_build_top_ui()
	_build_bottom_ui()

func _make_line(w: float, col: Color) -> Line2D:
	var l = Line2D.new()
	l.width = w; l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	return l

func _char_for_element(el: String) -> Dictionary:
	for ch in party:
		if ch["element"] == el:
			return ch
	return party[0]

func _build_top_ui() -> void:
	# ヘッダー
	_lbl(W/2, 18,  "MAGIC CIRCLE", 14, Color(0.53, 0.53, 0.8)).set_h_size_flags(Control.SIZE_SHRINK_CENTER)
	enemy_name_lbl = _lbl(W/2, 38, "", 18, Color(1.0, 0.67, 0.27))

	# 敵HPバー
	var ep_bg = ColorRect.new()
	ep_bg.color = Color(0.196, 0.196, 0.196); ep_bg.size = Vector2(W-24, 14)
	ep_bg.position = Vector2(12, 52); ui_layer.add_child(ep_bg)
	enemy_hp_fill = ColorRect.new()
	enemy_hp_fill.color = Color(0.67, 0.4, 0.85); enemy_hp_fill.size = Vector2(W-24, 14)
	enemy_hp_fill.position = Vector2(12, 52); ui_layer.add_child(enemy_hp_fill)
	enemy_hp_lbl = _lbl(W/2, 59, "", 10, Color.WHITE)

	wave_lbl = _lbl(W/2, 76, "WAVE 1 / %d" % MAX_WAVES, 13, Color(0.53, 0.53, 0.8))

	# 属性選択ボタン（3つ）＋魔素ゲージ
	var slot_w := (W - 20.0) / 3.0
	var elements : Array[String] = ["fire", "thunder", "ice"]
	for i in range(3):
		var el : String = elements[i]
		var ch  := _char_for_element(el)
		var sx  := 10.0 + slot_w * i

		var btn := Button.new()
		btn.text     = ch["emoji"] + " " + ch["name"]
		btn.size     = Vector2(slot_w - 4, 26)
		btn.position = Vector2(sx, 90)
		btn.add_theme_font_size_override("font_size", 12)
		var sbox := StyleBoxFlat.new()
		sbox.bg_color = Color(ch["color"].r * 0.25, ch["color"].g * 0.25, ch["color"].b * 0.25)
		sbox.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal",  sbox)
		btn.add_theme_stylebox_override("hover",   sbox)
		btn.add_theme_stylebox_override("pressed", sbox)
		btn.add_theme_color_override("font_color", ch["color"])
		btn.pressed.connect(_on_element_chosen.bind(el))
		ui_layer.add_child(btn)
		element_btns[el] = btn

		var anchor := Vector2(sx + (slot_w - 4) / 2.0, 122.0)
		mana_anchor_pos[el] = anchor
		_build_mana_particles(el, anchor, ch["color"])

	tech_lbl = _lbl(W/2, 136, "", 12, Color(0.67, 0.67, 0.8))

func _make_circle_polygon(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(8):
		var a := float(i) / 8.0 * TAU
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

func _build_mana_particles(el: String, anchor: Vector2, color: Color) -> void:
	var pts : Array[Node2D] = []
	for i in range(MANA_PARTICLE_MAX):
		var dot := Polygon2D.new()
		dot.polygon  = _make_circle_polygon(2.5)
		dot.color    = color
		dot.visible  = false
		var off := Vector2(randf_range(-16.0, 16.0), randf_range(-7.0, 7.0))
		dot.position = anchor + off
		ui_layer.add_child(dot)
		pts.append(dot)

		var tw := create_tween().set_loops()
		var off2 := Vector2(randf_range(-16.0, 16.0), randf_range(-7.0, 7.0))
		var dur := randf_range(1.4, 2.2)
		tw.tween_property(dot, "position", anchor + off2, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(dot, "position", anchor + off, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	mana_particles[el] = pts

func _build_bottom_ui() -> void:
	result_lbl = _lbl(W/2, H-128, "", 28, Color.WHITE)
	power_lbl  = _lbl(W/2, H-88,  "", 18, Color(1.0, 0.87, 0.0))
	hint_lbl   = _lbl(W/2, H-52,  "Fill the shape!!", 13, Color(0.4, 0.4, 0.55))
	timer_lbl  = _lbl(W-16, H-52, "", 20, Color.WHITE)
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# プレイヤーHPバー
	_lbl(16, H-18, "YOU", 10, Color(0.53, 0.67, 1.0)).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var phb_bg = ColorRect.new()
	phb_bg.color = Color(0.196, 0.196, 0.196); phb_bg.size = Vector2(W-70, 12)
	phb_bg.position = Vector2(42, H-25); ui_layer.add_child(phb_bg)
	player_hp_fill = ColorRect.new()
	player_hp_fill.color = Color(0.267, 0.533, 1.000); player_hp_fill.size = Vector2(W-70, 12)
	player_hp_fill.position = Vector2(42, H-25); ui_layer.add_child(player_hp_fill)
	player_hp_lbl = _lbl(42 + (W-70)/2, H-18, "", 10, Color.WHITE)

	_update_player_hp_bar()

func _lbl(x: float, y: float, text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(W, size + 8)
	l.position = Vector2(0, y - (size + 8) / 2.0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	ui_layer.add_child(l)
	# Store x hint for centering — label spans full width so origin is fine
	return l

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# キャラ紹介画面 (Intro)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _build_intro() -> void:
	intro_layer = CanvasLayer.new()
	intro_layer.layer = 2
	intro_layer.visible = false
	add_child(intro_layer)

	var bg = ColorRect.new()
	bg.color        = Color(0.04, 0.04, 0.12)
	bg.size         = Vector2(W, H)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_layer.add_child(bg)

	var title_lbl = Label.new()
	title_lbl.text = "パーティ紹介"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size     = Vector2(W, 36)
	title_lbl.position = Vector2(0, 20)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	intro_layer.add_child(title_lbl)

	var card_h  := 128.0
	var card_gap := 12.0
	var top_y   := 68.0
	var smap    := {"circle": "円", "triangle": "三角", "star": "星"}

	for i in range(party.size()):
		var ch   = party[i]
		var tech = ch["techniques"][0]
		var cy   := top_y + i * (card_h + card_gap)
		var col  : Color = ch["color"]

		var card_bg = ColorRect.new()
		card_bg.color        = Color(col.r * 0.22, col.g * 0.22, col.b * 0.22)
		card_bg.size         = Vector2(W - 32, card_h)
		card_bg.position     = Vector2(16, cy)
		card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		intro_layer.add_child(card_bg)

		var accent = ColorRect.new()
		accent.color        = col
		accent.size         = Vector2(5, card_h)
		accent.position     = Vector2(16, cy)
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		intro_layer.add_child(accent)

		var name_lbl = Label.new()
		name_lbl.text = ch["emoji"] + "  " + ch["name"] + "  【" + ch["attr"] + "】"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_lbl.size     = Vector2(W - 52, 28)
		name_lbl.position = Vector2(30, cy + 8)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", col)
		intro_layer.add_child(name_lbl)

		var tname_lbl = Label.new()
		tname_lbl.text = "技：" + tech["name"] + "（" + smap.get(tech["shape"], tech["shape"]) + "）"
		tname_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		tname_lbl.size     = Vector2(W - 52, 22)
		tname_lbl.position = Vector2(30, cy + 42)
		tname_lbl.add_theme_font_size_override("font_size", 13)
		tname_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
		intro_layer.add_child(tname_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = ch["desc"]
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		desc_lbl.size     = Vector2(W - 52, 56)
		desc_lbl.position = Vector2(30, cy + 68)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
		intro_layer.add_child(desc_lbl)

	var tap_lbl = Label.new()
	tap_lbl.text = "▶  タップしてスタート"
	tap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_lbl.size     = Vector2(W, 36)
	tap_lbl.position = Vector2(0, H - 72)
	tap_lbl.add_theme_font_size_override("font_size", 18)
	tap_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	intro_layer.add_child(tap_lbl)

	# 全画面スタートボタン（透明・最下層）
	var start_btn = Button.new()
	start_btn.flat     = true
	start_btn.size     = Vector2(W, H)
	start_btn.position = Vector2.ZERO
	var empty = StyleBoxEmpty.new()
	start_btn.add_theme_stylebox_override("normal",  empty)
	start_btn.add_theme_stylebox_override("hover",   empty)
	start_btn.add_theme_stylebox_override("pressed", empty)
	start_btn.add_theme_stylebox_override("focus",   empty)
	start_btn.pressed.connect(_on_intro_start)
	intro_layer.add_child(start_btn)

	# コレクションボタン（上に重ねて優先取得）
	var coll_btn = Button.new()
	coll_btn.name = "CollBtn"
	coll_btn.text = "📦 コレクション"
	coll_btn.size     = Vector2(200, 44)
	coll_btn.position = Vector2(W / 2.0 - 100, H - 122)
	coll_btn.add_theme_font_size_override("font_size", 15)
	coll_btn.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.08, 0.12, 0.22)
	sbox.border_color = Color(0.4, 0.6, 1.0)
	sbox.set_border_width_all(2)
	sbox.set_corner_radius_all(8)
	coll_btn.add_theme_stylebox_override("normal",  sbox)
	coll_btn.add_theme_stylebox_override("hover",   sbox)
	coll_btn.add_theme_stylebox_override("pressed", sbox)
	coll_btn.pressed.connect(_open_collection)
	intro_layer.add_child(coll_btn)

func _show_intro() -> void:
	game_state = "intro"
	intro_layer.visible = true

func _on_intro_start() -> void:
	intro_layer.visible = false
	wave_num = 1
	_start_wave()

func _build_drop_screen() -> void:
	drop_layer = CanvasLayer.new()
	drop_layer.layer = 3
	drop_layer.visible = false
	add_child(drop_layer)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.size  = Vector2(W, H)
	drop_layer.add_child(overlay)

	var get_lbl = Label.new()
	get_lbl.text = "CARD GET !!"
	get_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_lbl.size     = Vector2(W, 48)
	get_lbl.position = Vector2(0, H * 0.15)
	get_lbl.add_theme_font_size_override("font_size", 30)
	get_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.1))
	drop_layer.add_child(get_lbl)

	drop_card_bg = ColorRect.new()
	drop_card_bg.size         = Vector2(220, 290)
	drop_card_bg.position     = Vector2(W / 2.0 - 110, H * 0.28)
	drop_card_bg.pivot_offset = drop_card_bg.size / 2.0
	drop_layer.add_child(drop_card_bg)

	drop_name_lbl = Label.new()
	drop_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_name_lbl.size     = Vector2(200, 120)
	drop_name_lbl.position = Vector2(W / 2.0 - 100, H * 0.28 + 80)
	drop_name_lbl.add_theme_font_size_override("font_size", 26)
	drop_layer.add_child(drop_name_lbl)

	drop_rarity_lbl = Label.new()
	drop_rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_rarity_lbl.size     = Vector2(200, 40)
	drop_rarity_lbl.position = Vector2(W / 2.0 - 100, H * 0.28 + 210)
	drop_rarity_lbl.add_theme_font_size_override("font_size", 22)
	drop_layer.add_child(drop_rarity_lbl)

	drop_tap_lbl = Label.new()
	drop_tap_lbl.text = "▶  タップして続ける"
	drop_tap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_tap_lbl.size     = Vector2(W, 36)
	drop_tap_lbl.position = Vector2(0, H - 72)
	drop_tap_lbl.add_theme_font_size_override("font_size", 18)
	drop_tap_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	drop_layer.add_child(drop_tap_lbl)

	drop_flash = ColorRect.new()
	drop_flash.color = Color(1, 1, 1, 0)
	drop_flash.size  = Vector2(W, H)
	drop_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_layer.add_child(drop_flash)

func _flash_screen(alpha: float, duration: float) -> void:
	drop_flash.color.a = alpha
	var tw := create_tween()
	tw.tween_property(drop_flash, "color:a", 0.0, duration)

func _make_star_polygon(r: float) -> PackedVector2Array:
	var inner := r * 0.4
	var pts := PackedVector2Array()
	for i in range(10):
		var a := float(i) / 10.0 * TAU - PI / 2.0
		var d := r if i % 2 == 0 else inner
		pts.append(Vector2(cos(a) * d, sin(a) * d))
	return pts

func _spawn_sparkle_burst(center: Vector2, count: int, rainbow: bool, color: Color) -> void:
	var star_pts := _make_star_polygon(7.0)
	for i in range(count):
		var poly := Polygon2D.new()
		poly.polygon  = star_pts
		poly.color    = color
		poly.position = center
		drop_layer.add_child(poly)

		var angle := randf_range(0.0, TAU)
		var dist  := randf_range(60.0, 160.0)
		var dest  := center + Vector2(cos(angle), sin(angle)) * dist
		var dur   := randf_range(0.5, 0.8)

		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(poly, "position", dest, dur).set_ease(Tween.EASE_OUT)
		tw.tween_property(poly, "rotation", randf_range(-4.0, 4.0), dur)
		tw.tween_property(poly, "modulate:a", 0.0, dur).set_delay(dur * 0.3)
		if rainbow:
			tw.tween_method(func(h): poly.color = Color.from_hsv(h, 0.8, 1.0), 0.0, 1.0, dur)
		tw.chain().tween_callback(poly.queue_free)

func _show_drop_screen(card: Dictionary) -> void:
	GameData.add_card(card["id"])
	var col    : Color = card["color"]
	var rarity : int   = card["rarity"]
	var base_pos := drop_card_bg.position
	var center   := base_pos + drop_card_bg.size / 2.0

	drop_card_bg.color    = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25)
	drop_name_lbl.text    = card["name"]
	drop_name_lbl.add_theme_color_override("font_color", col)
	drop_rarity_lbl.text  = _Cards.rarity_label(rarity)
	drop_rarity_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.1))

	drop_layer.visible = true
	game_state = "drop"
	Sfx.play_card_get(rarity)

	match rarity:
		1:
			_spawn_sparkle_burst(center, 3, false, Color(1.0, 1.0, 0.8))
		2:
			_flash_screen(0.5, 0.25)
			_spawn_sparkle_burst(center, 7, false, Color(1.0, 0.85, 0.2))
		3:
			drop_card_bg.modulate.a   = 0.0
			drop_name_lbl.modulate.a  = 0.0
			drop_rarity_lbl.modulate.a = 0.0
			_flash_screen(0.9, 0.4)
			get_tree().create_timer(0.35).timeout.connect(func():
				if not is_instance_valid(drop_card_bg): return
				drop_card_bg.modulate.a   = 1.0
				drop_name_lbl.modulate.a  = 1.0
				drop_rarity_lbl.modulate.a = 1.0
				_spawn_sparkle_burst(center, 16, true, Color(1.0, 0.3, 0.3))

				var jt := create_tween()
				for i in range(6):
					var off := Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
					jt.tween_property(drop_card_bg, "position", base_pos + off, 1.0 / 30.0)
				jt.tween_property(drop_card_bg, "position", base_pos, 1.0 / 30.0)

				var pop := create_tween()
				pop.tween_property(drop_card_bg, "scale", Vector2(1.12, 1.12), 0.12).from(Vector2(0.7, 0.7))
				pop.tween_property(drop_card_bg, "scale", Vector2.ONE, 0.12)
			)

func _build_collection_screen() -> void:
	coll_layer = CanvasLayer.new()
	coll_layer.layer = 4
	coll_layer.visible = false
	add_child(coll_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.10)
	bg.size  = Vector2(W, H)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coll_layer.add_child(bg)

	var title = Label.new()
	title.name = "CollTitle"
	title.text = "コレクション"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size     = Vector2(W, 36)
	title.position = Vector2(0, 16)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	coll_layer.add_child(title)

	var grid_root = Node2D.new()
	grid_root.name = "GridRoot"
	coll_layer.add_child(grid_root)

	var back_lbl = Label.new()
	back_lbl.text = "✕  閉じる"
	back_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_lbl.size     = Vector2(W, 36)
	back_lbl.position = Vector2(0, H - 60)
	back_lbl.add_theme_font_size_override("font_size", 18)
	back_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	coll_layer.add_child(back_lbl)

func _refresh_collection() -> void:
	if coll_layer == null: return
	var grid_root = coll_layer.get_node("GridRoot")
	for child in grid_root.get_children():
		child.queue_free()

	var all_cards = _Cards.get_all()
	var cols      := 3
	var cell_w    := (W - 16) / cols
	var cell_h    := 90.0
	var start_y   := 62.0

	for i in range(all_cards.size()):
		var card   = all_cards[i]
		var col_i  = i % cols
		var row_i  = i / cols
		var cx     = 8 + col_i * cell_w
		var cy     = start_y + row_i * cell_h
		var owned  = GameData.has_card(card["id"])
		var col : Color = card["color"] if owned else Color(0.2, 0.2, 0.22)

		var cell_bg = ColorRect.new()
		cell_bg.color    = Color(col.r * 0.2, col.g * 0.2, col.b * 0.2) if owned \
		                   else Color(0.1, 0.1, 0.12)
		cell_bg.size     = Vector2(cell_w - 6, cell_h - 6)
		cell_bg.position = Vector2(cx, cy)
		cell_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid_root.add_child(cell_bg)

		var name_lbl = Label.new()
		name_lbl.text = card["name"] if owned else "？？？"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size     = Vector2(cell_w - 6, 36)
		name_lbl.position = Vector2(cx, cy + 8)
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", col)
		grid_root.add_child(name_lbl)

		var rar_lbl = Label.new()
		rar_lbl.text = _Cards.rarity_label(card["rarity"]) if owned else "☆☆☆"
		rar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rar_lbl.size     = Vector2(cell_w - 6, 24)
		rar_lbl.position = Vector2(cx, cy + 50)
		rar_lbl.add_theme_font_size_override("font_size", 12)
		rar_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.1) if owned else Color(0.3, 0.3, 0.3))
		grid_root.add_child(rar_lbl)

		if owned and GameData.get_equipped(card["char_id"]) == card["id"]:
			var eq_lbl = Label.new()
			eq_lbl.text = "▶装備中"
			eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			eq_lbl.size     = Vector2(cell_w - 6, 18)
			eq_lbl.position = Vector2(cx, cy + 68)
			eq_lbl.add_theme_font_size_override("font_size", 10)
			eq_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
			grid_root.add_child(eq_lbl)

	if jp_font:
		_apply_font(grid_root, jp_font)

func _open_collection() -> void:
	_refresh_collection()
	coll_layer.visible = true

func _close_collection() -> void:
	coll_layer.visible = false

func _try_equip_at(tp: Vector2) -> void:
	var cols_n  := 3
	var cell_w  := (W - 16) / cols_n
	var cell_h  := 90.0
	var start_y := 62.0
	var col_i   := int((tp.x - 8) / cell_w)
	var row_i   := int((tp.y - start_y) / cell_h)
	if col_i < 0 or col_i >= cols_n or row_i < 0: return
	var idx  := row_i * cols_n + col_i
	var all  : Array = _Cards.get_all()
	if idx >= all.size(): return
	var card : Dictionary = all[idx]
	if not GameData.has_card(card["id"]): return
	if GameData.get_equipped(card["char_id"]) == card["id"]:
		GameData.equip_card(card["char_id"], "")   # はずす
	else:
		GameData.equip_card(card["char_id"], card["id"])
	_refresh_collection()

func _generate_wave(n: int) -> Array[Dictionary]:
	var count := 2 + n
	var hp    := 40 + n * 15
	var enemies : Array[Dictionary] = []
	for i in range(count):
		enemies.append({"hp": hp, "max_hp": hp})
	return enemies

func _start_wave() -> void:
	enemy_queue   = _generate_wave(wave_num)
	_spawn_enemy_clusters()
	mana          = {"fire": MANA_MAX, "thunder": MANA_MAX, "ice": MANA_MAX}
	wave_time_limit = WAVE_TIME
	wave_start_sec  = Time.get_ticks_msec() / 1000.0
	wave_active     = true
	fio_frozen_sec  = 0.0; fio_freeze_start = -1.0
	trace_pts       = []
	active_touches.clear()
	if fio_tween:   fio_tween.kill();   fio_tween = null
	if guide_tween: guide_tween.kill(); guide_tween = null
	fio_guide_r = TARGET_R
	_clear_display()
	wave_lbl.text = "WAVE %d / %d" % [wave_num, MAX_WAVES]
	game_state = "idle"
	_update_enemy_ui()
	_update_mana_ui()
	_on_element_chosen(character.get("element", "fire"))

func _clear_display() -> void:
	trace_line.clear_points()
	result_lbl.text = ""; power_lbl.text = ""
	hint_lbl.text = "Fill the shape!!"; hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.55))
	timer_lbl.text = ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# パーティ管理
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _get_tech(ch: Dictionary) -> Dictionary:
	var eq_id = GameData.get_equipped(ch["id"])
	if eq_id != "":
		var tech_id = eq_id.left(eq_id.rfind("_"))
		for tech in ch["techniques"]:
			if tech["id"] == tech_id:
				return tech
	return ch["techniques"][0]

func _update_current_char() -> void:
	character     = party[party_index]
	current_shape = _get_tech(party[party_index])["shape"]
	fio_guide_r   = TARGET_R
	if fio_tween: fio_tween.kill(); fio_tween = null
	sample_pts    = _Shapes.make_sample_pts(current_shape, tx, ty, TARGET_R)
	_redraw_guide()
	_apply_guide_style()
	if character["id"] == "fio" and wave_active:
		_start_fio_shrink()
	_update_element_buttons()
	var tech = _get_tech(party[party_index])
	tech_lbl.text = character["emoji"] + " " + tech["name"]
	tech_lbl.add_theme_color_override("font_color", character["color"])

func _on_element_chosen(el: String) -> void:
	if game_state != "idle": return
	if mana.get(el, 0.0) < MANA_COST: return
	for i in range(party.size()):
		if party[i]["element"] == el:
			party_index = i
			break
	_update_current_char()

func _update_element_buttons() -> void:
	for el in element_btns.keys():
		var btn  : Button     = element_btns[el]
		var ch   := _char_for_element(el)
		var cur  : bool = character.get("element", "") == el
		btn.disabled = float(mana.get(el, 0.0)) < MANA_COST
		var sbox := StyleBoxFlat.new()
		var base_a := 0.45 if cur else 0.25
		sbox.bg_color = Color(ch["color"].r * base_a, ch["color"].g * base_a, ch["color"].b * base_a) \
			if not btn.disabled else Color(0.12, 0.12, 0.14)
		sbox.set_corner_radius_all(6)
		if cur:
			sbox.set_border_width_all(2)
			sbox.border_color = ch["color"]
		btn.add_theme_stylebox_override("normal",  sbox)
		btn.add_theme_stylebox_override("hover",   sbox)
		btn.add_theme_stylebox_override("pressed", sbox)
		btn.add_theme_stylebox_override("disabled", sbox)

func _update_mana_ui() -> void:
	for el in mana_particles.keys():
		var dots  : Array     = mana_particles[el]
		var count := int(floor(clampf(mana[el] / MANA_MAX, 0.0, 1.0) * MANA_PARTICLE_MAX))
		for i in range(dots.size()):
			dots[i].visible = i < count
	_update_element_buttons()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ガイド描画・キャラ固有能力
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _redraw_guide(r: float = -1.0) -> void:
	var rad := r if r > 0.0 else fio_guide_r if character.get("id") == "fio" else TARGET_R
	var pts := _Shapes.make_guide_pts(current_shape, tx, ty, rad)
	var col  : Color = character.get("color", Color(0.267, 0.667, 1.0))
	guide_rail.points = pts; guide_rail.default_color = Color(col.r, col.g, col.b, 0.14)
	guide_line.points = pts; guide_line.default_color = Color(col.r, col.g, col.b, 0.9)

func _apply_guide_style() -> void:
	if guide_tween: guide_tween.kill(); guide_tween = null
	if character["id"] == "agi":
		guide_line.modulate.a = 0.0; guide_rail.modulate.a = 0.0
		round_start_sec = Time.get_ticks_msec() / 1000.0
		guide_tween = create_tween()
		guide_tween.tween_property(guide_line, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN)
		guide_tween.parallel().tween_property(guide_rail, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN)
	else:
		guide_line.modulate.a = 1.0; guide_rail.modulate.a = 1.0

func _start_fio_shrink() -> void:
	if fio_tween: fio_tween.kill()
	fio_guide_r = TARGET_R
	fio_tween = create_tween()
	fio_tween.tween_method(_on_fio_r_changed, TARGET_R, TARGET_R * 0.38, 8.5)
	fio_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

func _on_fio_r_changed(r: float) -> void:
	fio_guide_r = r
	if game_state in ["idle", "drawing", "drawn"]:
		_redraw_guide(r)
		if game_state == "drawing":
			_update_trace_color()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 入力
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _input(event: InputEvent) -> void:
	var tapped : bool = (event is InputEventScreenTouch and event.pressed) or \
	                     (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)

	if game_state == "wave_break":
		return
	if coll_layer != null and coll_layer.visible:
		# emulate_touch_from_mouseでMouseButtonとScreenTouchが二重発火するため
		# ScreenTouchのみを採用し、トグル操作が1タップで2回走るのを防ぐ
		if event is InputEventScreenTouch and event.pressed:
			var tp : Vector2 = event.position
			if tp.y > H - 65:
				_close_collection()
			else:
				_try_equip_at(tp)
		return
	if game_state == "intro":
		return  # Buttonが処理するので_inputでは何もしない
	if game_state == "result":
		if tapped:
			get_tree().reload_current_scene()
		return
	if game_state == "drop":
		if tapped:
			drop_layer.visible = false
			get_tree().reload_current_scene()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			if active_touches.size() == 1 and event.index == 0:
				_on_single_touch(event.position)
			elif active_touches.size() >= 2:
				_on_two_finger()
		else:
			active_touches.erase(event.index)
			if active_touches.is_empty() and game_state == "drawing":
				_end_drawing()
	elif event is InputEventScreenDrag:
		if event.index == 0:
			if game_state == "drawing":
				_add_point(event.position)
			elif game_state == "drawn":
				_resume_drawing(event.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_single_touch(mb.position)
			else:
				if game_state == "drawing": _end_drawing()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_on_two_finger()   # PC での2本指シミュレーション
	elif event is InputEventMouseMotion:
		if not active_touches.is_empty():
			if game_state == "drawing":
				_add_point(event.position)
			elif game_state == "drawn":
				_resume_drawing(event.position)

func _pos_over_element_btn(pos: Vector2) -> bool:
	for el in element_btns.keys():
		var btn : Button = element_btns[el]
		if Rect2(btn.position, btn.size).has_point(pos):
			return true
	return false

func _on_single_touch(pos: Vector2) -> void:
	match game_state:
		"idle":
			if _pos_over_element_btn(pos): return
			_start_drawing(pos)
		"drawing":
			pass   # ドラッグは InputEventScreenDrag で処理
		"drawn":
			pass   # タッチダウン直後は2本指タップ確定との区別がつかないため、
			       # ドラッグ(InputEventScreenDrag)が来てから_resume_drawing()する

func _on_two_finger() -> void:
	match game_state:
		"drawing", "drawn":
			_resolve_cast()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _start_drawing(pos: Vector2) -> void:
	game_state    = "drawing"
	trace_pts     = [pos]
	draw_start_sec = Time.get_ticks_msec() / 1000.0
	trace_line.clear_points()
	trace_line.add_point(pos)
	hint_lbl.text = ""
	result_lbl.text = ""

	if character["id"] == "fio":
		_start_fio_shrink()

	# サンプル点をフィオの現在半径でスナップ
	var r := fio_guide_r if character["id"] == "fio" else TARGET_R
	sample_pts = _Shapes.make_sample_pts(current_shape, tx, ty, r)

	if character["id"] == "fio" and fio_freeze_start < 0.0:
		fio_freeze_start = Time.get_ticks_msec() / 1000.0

func _resume_drawing(pos: Vector2) -> void:
	game_state = "drawing"
	trace_pts.append(pos)
	trace_line.add_point(pos)
	_update_trace_color()
	if character["id"] == "fio" and fio_freeze_start < 0.0:
		fio_freeze_start = Time.get_ticks_msec() / 1000.0

func _add_point(pos: Vector2) -> void:
	trace_pts.append(pos)
	trace_line.add_point(pos)
	_update_trace_color()

func _end_drawing() -> void:
	if not (game_state == "drawing"): return
	game_state = "drawn"
	if character["id"] == "fio" and fio_freeze_start >= 0.0:
		fio_frozen_sec   += Time.get_ticks_msec() / 1000.0 - fio_freeze_start
		fio_freeze_start  = -1.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# スコアリング
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func calc_coverage(pts: Array[Vector2], br: float) -> float:
	if pts.is_empty() or sample_pts.is_empty(): return 0.0
	var grid: Dictionary = {}
	for tp in pts:
		var gx := int(tp.x / br); var gy := int(tp.y / br)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				grid[Vector2i(gx+dx, gy+dy)] = true
	var covered := 0
	for sp in sample_pts:
		if grid.has(Vector2i(int(sp.x / br), int(sp.y / br))):
			covered += 1
	return float(covered) / float(sample_pts.size())

func get_accuracy() -> int:
	if trace_pts.size() < 3: return 0
	return int(calc_coverage(trace_pts, character.get("brush_radius", 12.0)) * 100.0)

func _update_trace_color() -> void:
	var acc := get_accuracy()
	var col: Color
	if   acc >= 90: col = Color(1.0,  0.87, 0.0,  0.75)
	elif acc >= 75: col = Color(0.27, 0.93, 0.67, 0.75)
	elif acc >= 55: col = Color(0.27, 0.53, 1.0,  0.75)
	elif acc >= 30: col = Color(0.67, 0.67, 0.67, 0.75)
	else:           col = Color(1.0,  0.27, 0.27, 0.75)
	trace_line.default_color = col

	# FORBIDDENゲージ
	if acc < 30 and trace_pts.size() > 10:
		var risk := (30.0 - acc) / 30.0
		hint_lbl.text = "⚠  F O R B I D D E N  ?"
		hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.27, 0.27, 0.5 + risk * 0.5))
	else:
		hint_lbl.text = ""

func _score_drawing() -> Dictionary:
	var br      := character.get("brush_radius", 12.0) as float
	var acc     := int(calc_coverage(trace_pts, br) * 100.0)
	var elapsed := maxf(Time.get_ticks_msec() / 1000.0 - draw_start_sec, 0.1)
	var spd_cap := 3.0 if character["id"] == "agi" else 2.0
	var spd     := clampf(3.0 / elapsed, 0.5, spd_cap)

	# アギ：早描きボーナス（ガイドが出る前に描いた分）
	var early_bonus := 1.0
	if character["id"] == "agi":
		var blind := maxf(0.0, 2.0 - (draw_start_sec - round_start_sec))
		if blind > 0.0: early_bonus = 1.0 + (blind / 2.0) * 0.8

	var rank: String; var color: Color; var damage: int
	var rai_bonus := 1.2 if character["id"] == "rai" else 1.0
	if   acc >= 90: rank="PERFECT!!"; color=Color(1.0,0.87,0.0);   damage=int(acc * spd * rai_bonus)
	elif acc >= 75: rank="GREAT!";    color=Color(0.27,0.93,0.67); damage=int(acc * spd * 0.8)
	elif acc >= 55: rank="GOOD";      color=Color(0.27,0.53,1.0);  damage=int(acc * spd * 0.5)
	elif acc >= 30: rank="MISS...";   color=Color(0.67,0.67,0.67); damage=int(acc * spd * 0.2)
	else:           rank="FAIL";      color=Color(0.33,0.33,0.33); damage=0

	if early_bonus > 1.0: damage = int(damage * early_bonus)
	return {"rank": rank, "color": color, "damage": damage, "accuracy": acc,
	        "char": character, "tech": _get_tech(character)}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ウェーブ・魔素タイマー
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _get_wave_remaining() -> float:
	if not wave_active: return 0.0
	var frozen := fio_frozen_sec + (Time.get_ticks_msec() / 1000.0 - fio_freeze_start if fio_freeze_start >= 0.0 else 0.0)
	return maxf(0.0, wave_time_limit - (Time.get_ticks_msec() / 1000.0 - wave_start_sec) + frozen)

func _process(delta: float) -> void:
	if not wave_active: return

	for el in mana.keys():
		mana[el] = minf(MANA_MAX, mana[el] + MANA_REGEN_PER_SEC * delta)
	_update_mana_ui()
	_update_enemy_cluster_positions(delta)

	var rem := _get_wave_remaining()
	var frozen = character["id"] == "fio" and fio_freeze_start >= 0.0
	timer_lbl.text = "%.1fs" % rem
	if frozen:
		timer_lbl.add_theme_color_override("font_color", Color(0.27, 0.67, 1.0))
	elif rem <= 2.0:
		timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.27, 0.27))
	else:
		timer_lbl.add_theme_color_override("font_color", Color.WHITE)

	if rem <= 0.0 and game_state in ["drawing", "idle", "drawn"]:
		_wave_timeout()

func _wave_timeout() -> void:
	if character["id"] == "fio" and fio_freeze_start >= 0.0:
		fio_frozen_sec += Time.get_ticks_msec() / 1000.0 - fio_freeze_start
		fio_freeze_start = -1.0
	wave_active = false
	timer_lbl.text = ""
	trace_line.clear_points(); trace_pts = []
	result_lbl.text = ""

	var remaining := enemy_queue.size()
	if remaining > 0:
		var dmg := remaining * 15
		player_hp = maxi(0, player_hp - dmg)
		_update_player_hp_bar()
		_show_float_text(W / 2.0, H - 60, "-%d" % dmg, Color(1.0, 0.27, 0.27), 36)

	if player_hp <= 0:
		get_tree().create_timer(0.8).timeout.connect(_player_defeated)
		return

	game_state = "wave_break"
	hint_lbl.text = "WAVE OVER..."
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.27))
	get_tree().create_timer(1.4).timeout.connect(func():
		if wave_num >= MAX_WAVES:
			_run_complete()
		else:
			wave_num += 1
			_start_wave()
	)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 発動・敵
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _resolve_cast() -> void:
	if character["id"] == "fio" and fio_freeze_start >= 0.0:
		fio_frozen_sec += Time.get_ticks_msec() / 1000.0 - fio_freeze_start
		fio_freeze_start = -1.0

	if trace_pts.size() <= 10:
		trace_pts = []; trace_line.clear_points()
		game_state = "idle"
		return

	var sc      := _score_drawing()
	var tech    : Dictionary = _get_tech(character)
	var element : String     = character["element"]
	var power_mult : float = float(mana.get(element, 0.0)) / MANA_MAX
	mana[element] = maxf(0.0, mana[element] - MANA_COST)
	_update_mana_ui()

	trace_pts = []; trace_line.clear_points()
	game_state = "idle"
	result_lbl.text = sc["rank"]
	result_lbl.add_theme_color_override("font_color", sc["color"])
	get_tree().create_timer(0.5).timeout.connect(func():
		if game_state == "idle": result_lbl.text = ""
	)

	match tech.get("effect"):
		"heal":
			if sc["accuracy"] >= 55:
				var heal := int(tech.get("value", 30) * sc["accuracy"] / 100.0 * power_mult)
				player_hp = mini(player_max_hp, player_hp + heal)
				_update_player_hp_bar()
				power_lbl.text = "+%d HP ✨" % heal
				power_lbl.add_theme_color_override("font_color", Color(0.27, 1.0, 0.67))
				get_tree().create_timer(0.5).timeout.connect(func(): power_lbl.text = "")
		"time":
			if sc["accuracy"] >= 55:
				var ext : float = float(tech.get("value", 3.0)) * power_mult
				wave_time_limit += ext
				power_lbl.text = "+%.1fs ⏱" % ext
				power_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
				get_tree().create_timer(0.5).timeout.connect(func(): power_lbl.text = "")
		_:
			var dmg := int(sc["damage"] * power_mult)
			power_lbl.text = "-%d" % dmg
			power_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.0))
			get_tree().create_timer(0.5).timeout.connect(func(): power_lbl.text = "")
			_damage_enemy(dmg)

func _damage_enemy(dmg: int) -> void:
	if enemy_queue.is_empty(): return
	_show_float_text(tx, ty - TARGET_R - 20, "-%d" % dmg, Color(1.0, 0.87, 0.0), 48)
	enemy_queue[0]["hp"] = maxi(0, enemy_queue[0]["hp"] - dmg)
	Sfx.play_hit()
	_camera_shake(5.0, 0.3)
	_enemy_flinch()
	if enemy_queue[0]["hp"] <= 0:
		enemy_queue.pop_front()
		_remove_front_enemy_cluster()
		if enemy_queue.is_empty():
			_wave_cleared()
			return
	_update_enemy_ui()

func _update_enemy_ui() -> void:
	if enemy_queue.is_empty():
		enemy_hp_fill.size.x = 0
		enemy_hp_lbl.text = ""
		enemy_name_lbl.text = ""
		return
	var e := enemy_queue[0]
	var ratio := float(e["hp"]) / float(e["max_hp"])
	enemy_hp_fill.size.x = (W - 24) * ratio
	enemy_hp_lbl.text = "%d / %d" % [e["hp"], e["max_hp"]]
	enemy_hp_fill.color = Color(1.000, 0.400, 0.000) if ratio < 0.3 else Color(0.67, 0.4, 0.85)
	enemy_name_lbl.text = "残り %d体" % enemy_queue.size()

func _spawn_enemy_clusters() -> void:
	for cluster in enemy_clusters:
		for dot in (cluster["dots"] as Array):
			dot.queue_free()
	enemy_clusters.clear()
	for i in range(enemy_queue.size()):
		var n       := ENEMY_CLUSTER_N + (4 if i == 0 else 0)
		var dots    : Array[Polygon2D] = []
		var offsets : Array[Vector2]   = []
		var phases  : Array[float]     = []
		var col     := Color(0.85, 0.55, 1.0) if i == 0 else Color(0.55, 0.3, 0.7)
		for j in range(n):
			var dot := Polygon2D.new()
			dot.polygon = _make_circle_polygon(randf_range(5.0, 9.0))
			dot.color   = col
			add_child(dot)
			move_child(dot, guide_rail.get_index())
			dots.append(dot)
			offsets.append(Vector2(randf_range(-28.0, 28.0), randf_range(-18.0, 18.0)))
			phases.append(randf_range(0.0, TAU))
		enemy_clusters.append({
			"pos": Vector2(tx, ENEMY_SPAWN_Y), "dots": dots,
			"offsets": offsets, "phases": phases, "scale": 0.7 if i > 0 else 0.9
		})

func _remove_front_enemy_cluster() -> void:
	if enemy_clusters.is_empty(): return
	var cluster = enemy_clusters.pop_front()
	for dot in (cluster["dots"] as Array):
		dot.queue_free()
	if not enemy_clusters.is_empty():
		var front = enemy_clusters[0]
		front["scale"] = 0.9
		for dot in (front["dots"] as Array):
			dot.color = Color(0.85, 0.55, 1.0)

func _update_enemy_cluster_positions(delta: float) -> void:
	if enemy_clusters.is_empty(): return
	var rem       := _get_wave_remaining()
	var raw       := clampf(1.0 - (rem / wave_time_limit), 0.0, 1.0)
	var progress  := pow(raw, 0.55)   # 序盤から動きが分かるようイージング
	var t         := clampf(delta * ENEMY_APPROACH_SMOOTH, 0.0, 1.0)
	var time      := Time.get_ticks_msec() / 1000.0
	var spawn_pt  := Vector2(tx, ENEMY_SPAWN_Y)
	var target_pt := Vector2(tx, ty)
	for cluster in enemy_clusters:
		var dest : Vector2 = spawn_pt.lerp(target_pt, progress)
		cluster["pos"] = (cluster["pos"] as Vector2).lerp(dest, t)
		var scl     : float = lerpf(cluster["scale"], (cluster["scale"] as float) * 4.0, progress)
		var dots    : Array  = cluster["dots"]
		var offsets : Array  = cluster["offsets"]
		var phases  : Array  = cluster["phases"]
		for j in range(dots.size()):
			var wander := Vector2(sin(time * 1.3 + (phases[j] as float)), cos(time * 1.7 + (phases[j] as float))) * 4.0
			dots[j].position = (cluster["pos"] as Vector2) + (offsets[j] as Vector2) * scl + wander
			dots[j].scale    = Vector2.ONE * scl

func _update_player_hp_bar() -> void:
	var ratio := float(player_hp) / float(player_max_hp)
	player_hp_fill.size.x = (W - 70) * ratio
	player_hp_lbl.text = "%d / %d" % [player_hp, player_max_hp]
	player_hp_fill.color = Color(1.000, 0.267, 0.267) if ratio < 0.3 else Color(0.267, 0.533, 1.000)

func _wave_cleared() -> void:
	wave_active = false
	if wave_num >= MAX_WAVES:
		_run_complete()
		return
	game_state = "wave_break"
	result_lbl.text = "WAVE CLEAR!!"
	result_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.0))
	get_tree().create_timer(1.0).timeout.connect(func():
		result_lbl.text = ""
		wave_num += 1
		_start_wave()
	)

func _run_complete() -> void:
	wave_active = false
	game_state = "result"
	result_lbl.text = "ALL WAVES CLEAR!!"
	result_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.0))
	power_lbl.text = ""
	hint_lbl.text = ""
	get_tree().create_timer(1.2).timeout.connect(func():
		var card = _Cards.roll_drop()
		_show_drop_screen(card)
	)

func _player_defeated() -> void:
	game_state = "result"
	result_lbl.text = "DEFEATED..."
	result_lbl.add_theme_color_override("font_color", Color(1.0, 0.27, 0.27))
	power_lbl.text = "Tap to retry"
	hint_lbl.text = ""
	get_tree().create_timer(1.0).timeout.connect(func():
		get_tree().reload_current_scene()
	)

func _any_touch_pressed() -> bool:
	return not active_touches.is_empty()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# エフェクト
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _camera_shake(intensity: float, duration: float) -> void:
	var steps := int(duration * 30)
	var tw    := create_tween()
	for i in range(steps):
		var off := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_callback(func(): camera.offset = off)
		tw.tween_interval(1.0 / 30.0)
	tw.tween_callback(func(): camera.offset = Vector2.ZERO)

func _enemy_flinch() -> void:
	var tw = create_tween()
	tw.tween_property(enemy_name_lbl, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(enemy_name_lbl, "scale", Vector2(1.0, 1.0), 0.08)

func _show_float_text(x: float, y: float, text: String, color: Color, size: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(200, size + 8)
	lbl.position = Vector2(x - 100, y)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	ui_layer.add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", y - 90, 0.9).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.tween_callback(lbl.queue_free)