extends Node2D

const _Characters = preload("res://scripts/Characters.gd")
const _Shapes     = preload("res://scripts/Shapes.gd")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 定数
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const TARGET_R    := 140.0
const TURN_TIME   := 10.0   # seconds

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 画面
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var W: float; var H: float
var tx: float; var ty: float   # target center

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# パーティ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var party          : Array = []
var selected_techs : Array = []
var party_index    : int   = 0
var next_index     : int   = 0
var character      : Dictionary = {}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# バトル状態
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var game_state    : String = "pre_select"
var boss_max_hp   : int    = 1000
var boss_hp       : int    = 1000
var player_max_hp : int    = 300
var player_hp     : int    = 300
var round_num     : int    = 1
var max_rounds    : int    = 3

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ターン
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var turn_active      : bool  = false
var turn_time_limit  : float = TURN_TIME
var turn_start_sec   : float = 0.0
var fio_frozen_sec   : float = 0.0
var fio_freeze_start : float = -1.0
var stored_attacks   : Array = []
var current_shape    : String = "circle"
var sample_pts       : Array[Vector2] = []
var fio_guide_r      : float = TARGET_R
var fio_tween        : Tween = null
var guide_tween      : Tween = null   # アギのフェード

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var trace_pts      : Array[Vector2] = []
var draw_start_sec : float  = 0.0
var round_start_sec: float  = 0.0   # アギの早描きボーナス用
var active_touches : Dictionary = {}
var pending_timer  : SceneTreeTimer = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ノード参照
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var camera         : Camera2D
var guide_rail     : Line2D
var guide_line     : Line2D
var trace_line     : Line2D
var ui_layer       : CanvasLayer

var boss_hp_fill   : ColorRect; var boss_hp_lbl    : Label
var boss_name_lbl  : Label;     var round_lbl      : Label
var player_hp_fill : ColorRect; var player_hp_lbl  : Label
var timer_lbl      : Label;     var combo_lbl      : Label
var result_lbl     : Label;     var power_lbl      : Label
var hint_lbl       : Label;     var tech_lbl       : Label
var next_lbl       : Label
var party_slots    : Array = []   # [{bg, lbl}]

var pre_sel_root   : Control = null
var tech_btns      : Array   = []   # [{btn, lbl, char_idx, tech_idx}]

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 初期化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _ready() -> void:
	var cl = CanvasLayer.new()
	add_child(cl)
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	var lbl = Label.new()
	lbl.text = "BattleScene OK"
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cl.add_child(lbl)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ノード構築
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _build_nodes() -> void:
	# カメラ（シェイク用）
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	# 背景
	var bg = ColorRect.new()
	bg.color = Color8(15, 15, 35); bg.size = Vector2(W, H)
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

func _build_top_ui() -> void:
	# ヘッダー
	_lbl(W/2, 18,  "MAGIC CIRCLE", 14, Color(0.53, 0.53, 0.8)).set_h_size_flags(Control.SIZE_SHRINK_CENTER)
	boss_name_lbl = _lbl(W/2, 38, "Dark Dragon", 18, Color(1.0, 0.67, 0.27))

	# ボスHPバー
	var bp_bg = ColorRect.new()
	bp_bg.color = Color8(50,50,50); bp_bg.size = Vector2(W-24, 14)
	bp_bg.position = Vector2(12, 52); ui_layer.add_child(bp_bg)
	boss_hp_fill = ColorRect.new()
	boss_hp_fill.color = Color8(233,69,96); boss_hp_fill.size = Vector2(W-24, 14)
	boss_hp_fill.position = Vector2(12, 52); ui_layer.add_child(boss_hp_fill)
	boss_hp_lbl = _lbl(W/2, 59, "", 10, Color.WHITE)

	round_lbl = _lbl(W/2, 76, "Round 1 / 3", 13, Color(0.53, 0.53, 0.8))

	# パーティスロット（3つ）
	var slot_w := (W - 20.0) / 3.0
	for i in range(3):
		var sx := 10.0 + slot_w * i
		var bg = ColorRect.new()
		bg.color = Color8(34, 34, 68); bg.size = Vector2(slot_w - 4, 22)
		bg.position = Vector2(sx, 90); ui_layer.add_child(bg)
		var lbl = _lbl(sx + (slot_w-4)/2, 101, "", 11, Color.WHITE)
		party_slots.append({"bg": bg, "lbl": lbl})

	tech_lbl = _lbl(W/2, 120, "", 12, Color(0.67, 0.67, 0.8))
	next_lbl = _lbl(W/2, 136, "", 10, Color(0.27, 0.35, 0.45))

func _build_bottom_ui() -> void:
	result_lbl = _lbl(W/2, H-128, "", 28, Color.WHITE)
	power_lbl  = _lbl(W/2, H-88,  "", 18, Color(1.0, 0.87, 0.0))
	hint_lbl   = _lbl(W/2, H-52,  "Fill the shape!!", 13, Color(0.4, 0.4, 0.55))
	timer_lbl  = _lbl(W-16, H-52, "", 20, Color.WHITE)
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_lbl  = _lbl(16, H-52,   "", 15, Color(1.0, 0.67, 0.27))
	combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# プレイヤーHPバー
	_lbl(16, H-18, "YOU", 10, Color(0.53, 0.67, 1.0)).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var phb_bg = ColorRect.new()
	phb_bg.color = Color8(50,50,50); phb_bg.size = Vector2(W-70, 12)
	phb_bg.position = Vector2(42, H-25); ui_layer.add_child(phb_bg)
	player_hp_fill = ColorRect.new()
	player_hp_fill.color = Color8(68, 136, 255); player_hp_fill.size = Vector2(W-70, 12)
	player_hp_fill.position = Vector2(42, H-25); ui_layer.add_child(player_hp_fill)
	player_hp_lbl = _lbl(42 + (W-70)/2, H-18, "", 10, Color.WHITE)

	_update_boss_hp_bar()
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
# 技選択UI (PreSelect)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _build_pre_select() -> void:
	pre_sel_root = Control.new()
	pre_sel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(pre_sel_root)

	# 半透明オーバーレイ
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.size = Vector2(W, H)
	pre_sel_root.add_child(overlay)

	var title_lbl = Label.new()
	title_lbl.text = "── 技選択 ──"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size = Vector2(W, 30); title_lbl.position = Vector2(0, H * 0.06)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	pre_sel_root.add_child(title_lbl)

	tech_btns = []
	for ci in range(party.size()):
		var ch   := party[ci]
		var row_y := H * 0.16 + ci * H * 0.23

		var char_lbl = Label.new()
		char_lbl.text = ch["emoji"] + " " + ch["name"]
		char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		char_lbl.size = Vector2(W * 0.6, 20)
		char_lbl.position = Vector2(W * 0.07, row_y)
		char_lbl.add_theme_font_size_override("font_size", 14)
		char_lbl.add_theme_color_override("font_color", ch["color"])
		pre_sel_root.add_child(char_lbl)

		var techs: Array = ch["techniques"]
		for ti in range(techs.size()):
			var t     := techs[ti]
			var btn_w := W * 0.41
			var btn_x := W * 0.07 + ti * (btn_w + W * 0.04)
			var btn_y := row_y + H * 0.065

			var btn = Button.new()
			btn.text = t["name"]
			btn.size = Vector2(btn_w, 36); btn.position = Vector2(btn_x, btn_y)
			btn.add_theme_font_size_override("font_size", 13)
			btn.pressed.connect(_on_tech_btn.bind(ci, ti))
			pre_sel_root.add_child(btn)
			tech_btns.append({"btn": btn, "char_idx": ci, "tech_idx": ti})

	var start_btn = Button.new()
	start_btn.text = "▶  BATTLE START"
	start_btn.size = Vector2(W * 0.55, 50)
	start_btn.position = Vector2(W * 0.225, H * 0.865)
	start_btn.add_theme_font_size_override("font_size", 16)
	start_btn.pressed.connect(_hide_pre_select)
	pre_sel_root.add_child(start_btn)

func _on_tech_btn(ci: int, ti: int) -> void:
	selected_techs[ci] = party[ci]["techniques"][ti]
	_refresh_tech_btns()

func _refresh_tech_btns() -> void:
	for b in tech_btns:
		var sel: bool = selected_techs[b["char_idx"]] == party[b["char_idx"]]["techniques"][b["tech_idx"]]
		var btn: Button = b["btn"]
		var ch := party[b["char_idx"]]
		if sel:
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_stylebox_override("normal", _colored_stylebox(ch["color"], 0.7))
		else:
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_stylebox_override("normal")

func _colored_stylebox(color: Color, alpha: float) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, alpha)
	sb.set_corner_radius_all(4)
	return sb

func _show_pre_select() -> void:
	game_state = "pre_select"
	pre_sel_root.visible = true
	next_lbl.text = ""
	_refresh_tech_btns()

func _hide_pre_select() -> void:
	pre_sel_root.visible = false
	party_index   = randi() % party.size()
	next_index    = randi() % party.size()
	turn_active   = false
	turn_time_limit = TURN_TIME
	fio_frozen_sec  = 0.0; fio_freeze_start = -1.0
	stored_attacks  = []
	trace_pts       = []
	if fio_tween:   fio_tween.kill();   fio_tween = null
	if guide_tween: guide_tween.kill(); guide_tween = null
	fio_guide_r = TARGET_R
	_clear_display()
	game_state = "idle"
	_update_current_char()

func _clear_display() -> void:
	trace_line.clear_points()
	result_lbl.text = ""; power_lbl.text = ""
	hint_lbl.text = "Fill the shape!!"; hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.55))
	timer_lbl.text = ""; combo_lbl.text = ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# パーティ管理
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _update_current_char() -> void:
	character     = party[party_index]
	current_shape = selected_techs[party_index]["shape"]
	fio_guide_r   = TARGET_R
	if fio_tween: fio_tween.kill(); fio_tween = null
	sample_pts    = _Shapes.make_sample_pts(current_shape, tx, ty, TARGET_R)
	_redraw_guide()
	_apply_guide_style()
	if character["id"] == "fio" and turn_active:
		_start_fio_shrink()
	_update_party_display()
	_update_next_display()
	var tech := selected_techs[party_index]
	tech_lbl.text = character["emoji"] + " " + tech["name"]
	tech_lbl.add_theme_color_override("font_color", character["color"])

func _update_party_display() -> void:
	for i in range(party.size()):
		var slot = party_slots[i]
		var ch   = party[i]
		var cur  := i == party_index
		slot["bg"].color = ch["color"] if cur else Color8(34, 34, 68)
		slot["lbl"].text = ch["emoji"] + " " + ch["name"]
		slot["lbl"].add_theme_font_size_override("font_size", 11 if cur else 9)
		slot["lbl"].add_theme_color_override("font_color", Color.WHITE if cur else ch["color"])

func _update_next_display() -> void:
	var nch  := party[next_index]
	var nt   := selected_techs[next_index]
	var smap := {"circle": "円", "triangle": "三角", "star": "星"}
	next_lbl.text = "NEXT → " + nch["emoji"] + " " + nt["name"] + "（" + smap.get(nt["shape"], nt["shape"]) + "）"

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
	if game_state == "pre_select" or game_state == "chaining" or game_state == "result":
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
		if event.index == 0 and game_state == "drawing":
			_add_point(event.position)
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
		if not active_touches.is_empty() and game_state == "drawing":
			_add_point(event.position)

func _on_single_touch(pos: Vector2) -> void:
	match game_state:
		"idle":
			_start_drawing(pos)
		"drawing":
			pass   # ドラッグは InputEventScreenDrag で処理
		"drawn":
			if pending_timer:
				pending_timer = null
			_start_drawing(pos)

func _on_two_finger() -> void:
	match game_state:
		"drawing":
			_store_combo()
		"drawn":
			if pending_timer: pending_timer = null
			_store_combo()
		"final_tap":
			_fire_chain()

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

	if not turn_active:
		_start_turn()
		if character["id"] == "fio":
			_start_fio_shrink()

	# サンプル点をフィオの現在半径でスナップ
	var r := fio_guide_r if character["id"] == "fio" else TARGET_R
	sample_pts = _Shapes.make_sample_pts(current_shape, tx, ty, r)

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
	pending_timer = get_tree().create_timer(0.2)
	pending_timer.timeout.connect(func():
		pending_timer = null
		if game_state == "drawn": game_state = "idle"
	)

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
	        "char": character, "tech": selected_techs[party_index]}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ターン管理
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _start_turn() -> void:
	turn_active    = true
	turn_time_limit = TURN_TIME
	turn_start_sec = Time.get_ticks_msec() / 1000.0
	fio_frozen_sec = 0.0; fio_freeze_start = -1.0

func _get_remaining() -> float:
	if not turn_active: return 0.0
	var frozen := fio_frozen_sec + (Time.get_ticks_msec() / 1000.0 - fio_freeze_start if fio_freeze_start >= 0.0 else 0.0)
	return maxf(0.0, turn_time_limit - (Time.get_ticks_msec() / 1000.0 - turn_start_sec) + frozen)

func _process(_delta: float) -> void:
	if not turn_active: return
	var rem := _get_remaining()
	var frozen := character["id"] == "fio" and fio_freeze_start >= 0.0
	timer_lbl.text = "%.1fs" % rem
	if frozen:
		timer_lbl.add_theme_color_override("font_color", Color(0.27, 0.67, 1.0))
	elif rem <= 2.0:
		timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.27, 0.27))
	else:
		timer_lbl.add_theme_color_override("font_color", Color.WHITE)

	if rem <= 0.0 and game_state in ["drawing", "idle"]:
		_end_turn()

func _end_turn() -> void:
	if character["id"] == "fio" and fio_freeze_start >= 0.0:
		fio_frozen_sec += Time.get_ticks_msec() / 1000.0 - fio_freeze_start
		fio_freeze_start = -1.0
	turn_active = false
	timer_lbl.text = ""
	# 描きかけがあればスコア
	if game_state == "drawing" and trace_pts.size() > 5:
		var sc := _score_drawing()
		sc["char"] = character; sc["tech"] = selected_techs[party_index]
		stored_attacks.append(sc)
		_update_combo_display()
	trace_line.clear_points(); trace_pts = []
	result_lbl.text = ""
	game_state = "final_tap"
	hint_lbl.text = "FINAL TAP !!"
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.27))
	_blink_hint()

func _blink_hint() -> void:
	var tw = create_tween().set_loops()
	tw.tween_property(hint_lbl, "modulate:a", 0.2, 0.4)
	tw.tween_property(hint_lbl, "modulate:a", 1.0, 0.4)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# コンボ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _store_combo() -> void:
	if character["id"] == "fio" and fio_freeze_start >= 0.0:
		fio_frozen_sec += Time.get_ticks_msec() / 1000.0 - fio_freeze_start
		fio_freeze_start = -1.0

	if trace_pts.size() > 10:
		var sc := _score_drawing()
		var tech: Dictionary = selected_techs[party_index]
		sc["char"] = character; sc["tech"] = tech
		# 時雷陣：タイマー延長
		if tech["effect"] == "time" and sc["accuracy"] >= 55:
			turn_time_limit += tech.get("value", 3.0)
		stored_attacks.append(sc)
		_show_combo_flash(sc)
		_update_combo_display()

	# 次のキャラ（ランダム）
	party_index = next_index
	next_index  = randi() % party.size()
	_update_current_char()

	trace_pts = []; trace_line.clear_points()
	hint_lbl.text = ""; hint_lbl.modulate.a = 1.0
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.55))
	draw_start_sec = Time.get_ticks_msec() / 1000.0
	game_state = "drawing"

	if character["id"] == "fio" and fio_freeze_start < 0.0:
		fio_freeze_start = Time.get_ticks_msec() / 1000.0
	sample_pts = _Shapes.make_sample_pts(current_shape, tx, ty,
		fio_guide_r if character["id"] == "fio" else TARGET_R)

func _show_combo_flash(sc: Dictionary) -> void:
	result_lbl.text = sc["rank"]
	result_lbl.add_theme_color_override("font_color", sc["color"])
	get_tree().create_timer(0.4).timeout.connect(func():
		if game_state == "drawing": result_lbl.text = ""
	)

func _update_combo_display() -> void:
	var n := stored_attacks.size()
	combo_lbl.text = "⚡ %d combo" % n if n > 0 else ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# チェーン発動
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _fire_chain() -> void:
	hint_lbl.modulate.a = 1.0; hint_lbl.text = ""
	combo_lbl.text = ""
	game_state = "chaining"
	if stored_attacks.is_empty():
		_advance_round(); return

	# 最後のコンボがFORBIDDEN対象かチェック
	var last  := stored_attacks[-1]
	var ch    := last.get("char", party[0]) as Dictionary
	var limit := 0.5 if ch["id"] == "fio" else 0.3
	if last["accuracy"] < 30 and randf() < limit:
		last["rank"]        = "FORBIDDEN!!"
		last["color"]       = ch["color"]
		last["damage"]      = randi_range(100, 250)
		last["is_forbidden"] = true

	if last.get("is_forbidden", false):
		result_lbl.text = "FORBIDDEN!!"
		result_lbl.add_theme_color_override("font_color", ch["color"])
		power_lbl.text = "something incredible..."
		_camera_shake(18.0, 0.6)
		get_tree().create_timer(0.9).timeout.connect(func():
			result_lbl.text = ""; power_lbl.text = ""
			_fire_next(0)
		)
	else:
		_fire_next(0)

func _fire_next(idx: int) -> void:
	if idx >= stored_attacks.size():
		get_tree().create_timer(0.9).timeout.connect(func():
			if boss_hp <= 0: _boss_defeated()
			else: _advance_round()
		)
		return

	var atk  := stored_attacks[idx]
	var tech := atk.get("tech", {}) as Dictionary
	var delay := 0.9 if atk.get("is_forbidden", false) else 0.45

	# 回復技
	if tech.get("effect") == "heal" and atk["accuracy"] >= 55:
		var heal := int(tech.get("value", 30) * atk["accuracy"] / 100.0)
		player_hp = mini(player_max_hp, player_hp + heal)
		_update_player_hp_bar()
		result_lbl.text = atk["rank"]
		result_lbl.add_theme_color_override("font_color", atk["color"])
		power_lbl.text = "+%d HP ✨" % heal
		power_lbl.add_theme_color_override("font_color", Color(0.27, 1.0, 0.67))
		get_tree().create_timer(delay).timeout.connect(func(): _fire_next(idx + 1))
		return

	# ダメージ技
	result_lbl.text = atk["rank"]
	result_lbl.add_theme_color_override("font_color", atk["color"])
	_show_float_text(tx, ty - TARGET_R - 20, "-%d" % atk["damage"], Color(1.0, 0.87, 0.0), 48)
	boss_hp = maxi(0, boss_hp - atk["damage"])
	_update_boss_hp_bar()
	_camera_shake(10.0 if atk.get("is_forbidden") else 5.0, 0.3)
	_boss_flinch()
	get_tree().create_timer(delay).timeout.connect(func(): _fire_next(idx + 1))

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ラウンド・HP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _boss_attack() -> void:
	var dmg := 20 + round_num * 12
	player_hp = maxi(0, player_hp - dmg)
	_update_player_hp_bar()
	_show_float_text(W/2, H - 60, "-%d" % dmg, Color(1.0, 0.27, 0.27), 36)
	if player_hp <= 0:
		get_tree().create_timer(0.8).timeout.connect(_player_defeated)

func _advance_round() -> void:
	_boss_attack()
	if round_num >= max_rounds:
		get_tree().create_timer(1.0).timeout.connect(_round_end)
	else:
		get_tree().create_timer(1.0).timeout.connect(func():
			round_num += 1
			round_lbl.text = "Round %d / %d" % [round_num, max_rounds]
			_show_pre_select()
		)

func _update_boss_hp_bar() -> void:
	var ratio := float(boss_hp) / float(boss_max_hp)
	boss_hp_fill.size.x = (W - 24) * ratio
	boss_hp_lbl.text = "BOSS  %d / %d" % [boss_hp, boss_max_hp]
	boss_hp_fill.color = Color8(255, 102, 0) if ratio < 0.3 else Color8(233, 69, 96)

func _update_player_hp_bar() -> void:
	var ratio := float(player_hp) / float(player_max_hp)
	player_hp_fill.size.x = (W - 70) * ratio
	player_hp_lbl.text = "%d / %d" % [player_hp, player_max_hp]
	player_hp_fill.color = Color8(255, 68, 68) if ratio < 0.3 else Color8(68, 136, 255)

func _boss_defeated() -> void:
	game_state = "result"
	result_lbl.text = "BOSS DEFEATED!!"
	result_lbl.add_theme_color_override("font_color", Color(1.0, 0.87, 0.0))
	power_lbl.text = "Tap to restart"
	hint_lbl.text = ""
	get_tree().create_timer(0.5).timeout.connect(func():
		get_tree().process_frame.connect(func():
			if Input.is_action_just_pressed("ui_accept") or _any_touch_pressed():
				get_tree().reload_current_scene()
		, CONNECT_ONE_SHOT)
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

func _round_end() -> void:
	game_state = "result"
	result_lbl.text = "Round Over..."
	result_lbl.add_theme_color_override("font_color", Color(0.53, 0.53, 0.8))
	power_lbl.text = "Boss HP: %d\nTap to retry" % boss_hp
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

func _boss_flinch() -> void:
	var tw = create_tween()
	tw.tween_property(boss_name_lbl, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(boss_name_lbl, "scale", Vector2(1.0, 1.0), 0.08)

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
