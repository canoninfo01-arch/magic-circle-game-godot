extends Node2D

# ── 定数 ────────────────────────────────────────────────────────
const BRUSH_RADIUS  := 12.0
const TARGET_RADIUS := 140.0
const SHAPE         := "circle"

# ── 画面サイズ ───────────────────────────────────────────────────
var W: float
var H: float
var target_x: float
var target_y: float

# ── 状態 ────────────────────────────────────────────────────────
var is_drawing    := false
var trace_points  : Array[Vector2] = []
var draw_start_ms : float = 0.0
var sample_points : Array[Vector2] = []

# ── ノード ───────────────────────────────────────────────────────
var guide_rail   : Line2D
var guide_line   : Line2D
var trace_line   : Line2D
var result_label : Label
var hint_label   : Label

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 初期化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _ready() -> void:
	var size = get_viewport_rect().size
	W        = size.x
	H        = size.y
	target_x = W / 2.0
	target_y = H / 2.0 + 15.0

	sample_points = _make_sample_points(SHAPE, target_x, target_y, TARGET_RADIUS)
	_build_nodes()

func _build_nodes() -> void:
	# 背景
	var bg    = ColorRect.new()
	bg.color  = Color8(15, 15, 35)
	bg.size   = Vector2(W, H)
	add_child(bg)

	# ガイド（太いレール）
	guide_rail               = Line2D.new()
	guide_rail.width         = 44.0
	guide_rail.joint_mode    = Line2D.LINE_JOINT_ROUND
	guide_rail.default_color = Color(0.267, 0.667, 1.0, 0.14)
	guide_rail.points        = _make_guide_points(SHAPE, target_x, target_y, TARGET_RADIUS)
	add_child(guide_rail)

	# ガイド（正確な中心線）
	guide_line               = Line2D.new()
	guide_line.width         = 2.0
	guide_line.joint_mode    = Line2D.LINE_JOINT_ROUND
	guide_line.default_color = Color(0.267, 0.667, 1.0, 0.9)
	guide_line.points        = guide_rail.points
	add_child(guide_line)

	# 描画軌跡
	trace_line                = Line2D.new()
	trace_line.width          = BRUSH_RADIUS * 2.0
	trace_line.joint_mode     = Line2D.LINE_JOINT_ROUND
	trace_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trace_line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	trace_line.default_color  = Color(0.267, 0.667, 1.0, 0.75)
	add_child(trace_line)

	# UI（CanvasLayer にすると解像度変換の影響を受けない）
	var ui = CanvasLayer.new()
	add_child(ui)

	result_label                       = Label.new()
	result_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	result_label.size                  = Vector2(W, 60)
	result_label.position              = Vector2(0, H - 130)
	result_label.add_theme_font_size_override("font_size", 32)
	ui.add_child(result_label)

	hint_label                         = Label.new()
	hint_label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.size                    = Vector2(W, 40)
	hint_label.position                = Vector2(0, H - 55)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.55))
	hint_label.text                    = "Fill the shape!!"
	ui.add_child(hint_label)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 図形データ生成
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _make_guide_points(shape: String, cx: float, cy: float, r: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	match shape:
		"circle":
			for i in range(301):
				var a = (float(i) / 300.0) * TAU
				pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
		"triangle":
			var verts: Array[Vector2] = []
			for i in range(3):
				var a = (float(i) / 3.0) * TAU - PI / 2.0
				verts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
			verts.append(verts[0])
			for e in range(3):
				for i in range(101):
					pts.append(verts[e].lerp(verts[e + 1], float(i) / 100.0))
		"star":
			var inner := r * 0.4
			var verts: Array[Vector2] = []
			for i in range(10):
				var a = (float(i) / 10.0) * TAU - PI / 2.0
				var d = r if i % 2 == 0 else inner
				verts.append(Vector2(cx + cos(a) * d, cy + sin(a) * d))
			verts.append(verts[0])
			for i in range(10):
				for j in range(31):
					pts.append(verts[i].lerp(verts[i + 1], float(j) / 30.0))
	return pts

func _make_sample_points(shape: String, cx: float, cy: float, r: float) -> Array[Vector2]:
	var raw  = _make_guide_points(shape, cx, cy, r)
	var result: Array[Vector2] = []
	for p in raw:
		result.append(p)
	return result

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 入力処理
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _input(event: InputEvent) -> void:
	# タッチ（スマホ）と マウス（PC テスト）を両方サポート
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drawing(event.position)
		else:
			_end_drawing()
	elif event is InputEventScreenDrag and is_drawing:
		_add_point(event.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_drawing(mb.position)
			else:
				_end_drawing()
	elif event is InputEventMouseMotion and is_drawing:
		_add_point(event.position)

func _start_drawing(pos: Vector2) -> void:
	is_drawing    = true
	trace_points  = [pos]
	draw_start_ms = Time.get_ticks_msec()
	trace_line.clear_points()
	trace_line.add_point(pos)
	result_label.text = ""
	hint_label.text   = ""

func _add_point(pos: Vector2) -> void:
	trace_points.append(pos)
	trace_line.add_point(pos)
	_update_trace_color()

func _end_drawing() -> void:
	if not is_drawing:
		return
	is_drawing = false
	_score_and_show()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# カバー率計算
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func calc_coverage(points: Array[Vector2], br: float) -> float:
	if points.is_empty() or sample_points.is_empty():
		return 0.0
	var grid: Dictionary = {}
	for tp in points:
		var gx := int(tp.x / br)
		var gy := int(tp.y / br)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				grid[Vector2i(gx + dx, gy + dy)] = true
	var covered := 0
	for sp in sample_points:
		var gx := int(sp.x / br)
		var gy := int(sp.y / br)
		if grid.has(Vector2i(gx, gy)):
			covered += 1
	return float(covered) / float(sample_points.size())

func get_accuracy() -> int:
	if trace_points.size() < 3:
		return 0
	return int(calc_coverage(trace_points, BRUSH_RADIUS) * 100.0)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# スコアリング・表示
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func _update_trace_color() -> void:
	var acc := get_accuracy()
	var col: Color
	if   acc >= 90: col = Color(1.0,  0.87, 0.0,  0.75)
	elif acc >= 75: col = Color(0.27, 0.93, 0.67, 0.75)
	elif acc >= 55: col = Color(0.27, 0.53, 1.0,  0.75)
	elif acc >= 30: col = Color(0.67, 0.67, 0.67, 0.75)
	else:           col = Color(1.0,  0.27, 0.27, 0.75)
	trace_line.default_color = col

func _score_and_show() -> void:
	if trace_points.size() < 10:
		hint_label.text = "Fill the shape!!"
		return

	var accuracy := get_accuracy()
	var elapsed  := (Time.get_ticks_msec() - draw_start_ms) / 1000.0
	var speed    := clampf(3.0 / maxf(elapsed, 0.1), 0.5, 2.0)

	var rank:   String
	var color:  Color
	var damage: int

	if accuracy >= 90:
		rank = "PERFECT!!" ; color = Color(1.0, 0.87, 0.0)  ; damage = int(accuracy * speed)
	elif accuracy >= 75:
		rank = "GREAT!"    ; color = Color(0.27, 0.93, 0.67) ; damage = int(accuracy * speed * 0.8)
	elif accuracy >= 55:
		rank = "GOOD"      ; color = Color(0.27, 0.53, 1.0)  ; damage = int(accuracy * speed * 0.5)
	elif accuracy >= 30:
		rank = "MISS..."   ; color = Color(0.67, 0.67, 0.67) ; damage = int(accuracy * speed * 0.2)
	else:
		rank = "FAIL"      ; color = Color(0.33, 0.33, 0.33) ; damage = 0

	result_label.text = rank
	result_label.add_theme_color_override("font_color", color)
	hint_label.text   = str(accuracy) + "% | " + str(damage) + " dmg"

	# 0.8秒後に軌跡をクリア
	await get_tree().create_timer(0.8).timeout
	trace_line.clear_points()
	trace_points = []
	result_label.text = ""
	hint_label.text   = "Fill the shape!!"
