class_name DrawSystem

# BattleScene.gd から分離した描画フェーズ・厚塗り評価ロジック（挙動は変更していない）。
# EnemySpawner.gd/WeaponSystem.gdと同じ方式で、.tscnには手を加えず、BattleScene自身への
# 参照（battle、無型）を持つ素のオブジェクトにした。
#
# 召喚結果画面（_show_summon_result）・召喚演出（_summon_burst等）・仲間生成（_add_ally等）は
# 「召喚」寄りの機能のためBattleScene.gd側に残し、battle経由で呼び出す。

const _Data = preload("res://scripts/BattleData.gd")
const _Shapes = preload("res://scripts/Shapes.gd")
const _Sigils = preload("res://scripts/Sigils.gd")

var battle

func _init(battle_scene) -> void:
	battle = battle_scene

func start_countdown(attr: String) -> void:
	battle.game_state = "countdown"
	var layer := CanvasLayer.new()
	layer.layer = 10
	battle.add_child(layer)

	var lbl := battle._make_label("3", 80, Vector2(battle.W * 0.5 - 30, battle.H * 0.4))
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	layer.add_child(lbl)

	var texts := ["3", "2", "1"]
	var tw := lbl.create_tween()
	for t in texts:
		tw.tween_callback(func(): lbl.text = t)
		tw.tween_interval(2.0 / 3.0)
	tw.tween_callback(func():
		layer.queue_free()
		start_drawing(attr)
	)

func start_drawing(suggested_shape: String) -> void:
	battle.game_state = "drawing"
	battle.draw_shape = suggested_shape
	battle.draw_sigil_id = GameData.get_equipped_sigil(suggested_shape)
	battle.draw_timer = _Data.DRAW_DURATION + battle.draw_time_bonus
	battle.coating_count = 0
	battle.coating_power = 0
	battle.trace_pts.clear()
	battle.trace_line.clear_points()
	battle.trace_line.modulate = Color.WHITE
	battle.draw_touch_id = -1
	battle.guide_line.visible = true
	battle.guide_glow.visible = true
	battle.guide_rune_root.visible = true
	battle.trace_line.visible = true
	battle.draw_timer_lbl.visible = true
	battle.cov_lbl.visible = true
	battle.coating_lbl.visible = true
	battle.confirm_btn.visible = true
	refresh_draw_guide()
	battle.draw_layer.visible = true

func refresh_draw_guide() -> void:
	var cx := battle.W * 0.5
	var cy := battle.H * 0.5
	var sigil_data := _Sigils.get_data(battle.draw_sigil_id)
	var contour_defs: Array = sigil_data.get("contours", [{"shape": battle.draw_shape, "radius_ratio": 1.0, "weight": 1.0}])
	var guide_scale: float = sigil_data.get("guide_scale", 1.0)
	battle.current_guide_r = _Data.DRAW_GUIDE_R * guide_scale

	battle.contour_weights.clear()
	for c in contour_defs:
		battle.contour_weights.append((c as Dictionary).get("weight", 1.0) as float)

	battle.sample_contours = _Shapes.make_sample_contours(contour_defs, cx, cy, battle.current_guide_r)
	var contours := _Shapes.make_guide_contours(contour_defs, cx, cy, battle.current_guide_r)

	battle.guide_line.clear_points()
	battle.guide_glow.clear_points()
	for p in contours[0]:
		battle.guide_line.add_point(p)
		battle.guide_glow.add_point(p)

	if contours.size() > 1:
		battle.guide_line_inner.clear_points()
		battle.guide_glow_inner.clear_points()
		for p in contours[1]:
			battle.guide_line_inner.add_point(p)
			battle.guide_glow_inner.add_point(p)
		battle.guide_line_inner.visible = true
		battle.guide_glow_inner.visible = true
	else:
		battle.guide_line_inner.visible = false
		battle.guide_glow_inner.visible = false

	if contours.size() > 2:
		battle.guide_line_2.clear_points()
		battle.guide_glow_2.clear_points()
		for p in contours[2]:
			battle.guide_line_2.add_point(p)
			battle.guide_glow_2.add_point(p)
		battle.guide_line_2.visible = true
		battle.guide_glow_2.visible = true
	else:
		battle.guide_line_2.visible = false
		battle.guide_glow_2.visible = false

	var shape_colors := {
		"circle":   Color(0.5, 0.7, 1.0, 0.8),
		"triangle": Color(1.0, 0.5, 0.5, 0.8),
		"square":   Color(0.85, 0.6, 0.2, 0.8),
	}
	var sc: Color = shape_colors.get(battle.draw_shape, Color(1, 1, 1, 0.65))
	battle.guide_base_color = sc

	for i in range(battle.guide_rune_marks.size()):
		var ang := float(i) / float(battle.guide_rune_marks.size()) * TAU
		battle.guide_rune_marks[i].position = Vector2(cos(ang), sin(ang)) * battle.current_guide_r

	apply_guide_intensity()

func apply_guide_intensity() -> void:
	# 周回を重ねるほどガイド自体が明るく・太くなり、強くなっていく実感を描画中に出す
	var boost := clampf(float(battle.coating_count) * 0.15, 0.0, 1.0)
	battle.guide_line.default_color = battle.guide_base_color.lerp(Color.WHITE, boost)
	battle.guide_line.width = 6.0 + boost * 8.0
	battle.guide_glow.default_color = Color(battle.guide_base_color.r, battle.guide_base_color.g, battle.guide_base_color.b, 0.18 + boost * 0.35)
	battle.guide_glow.width = 22.0 + boost * 24.0
	if battle.guide_line_inner.visible:
		battle.guide_line_inner.default_color = battle.guide_line.default_color
		battle.guide_line_inner.width = battle.guide_line.width
		battle.guide_glow_inner.default_color = battle.guide_glow.default_color
		battle.guide_glow_inner.width = battle.guide_glow.width
	if battle.guide_line_2.visible:
		battle.guide_line_2.default_color = battle.guide_line.default_color
		battle.guide_line_2.width = battle.guide_line.width
		battle.guide_glow_2.default_color = battle.guide_glow.default_color
		battle.guide_glow_2.width = battle.guide_glow.width

	var rune_col := battle.guide_base_color.lerp(Color.WHITE, boost)
	var rune_scale := 1.0 + boost * 0.6
	for mark in battle.guide_rune_marks:
		mark.color = rune_col
		mark.scale = Vector2.ONE * rune_scale

# ブラシの判定半径。紋章サイズ（tier・輪郭）に関わらず絶対px固定（2026-07-27）
func brush_radius() -> float:
	return _Data.DRAW_BRUSH_R * battle.brush_ratio_mult

func update_drawing(delta: float) -> void:
	battle.draw_timer -= delta
	battle.draw_timer_lbl.text = "%.1f" % maxf(0.0, battle.draw_timer)

	if not battle.trace_pts.is_empty() and not battle.sample_contours.is_empty():
		var cov := calc_coverage_contours(battle.trace_pts, battle.sample_contours)
		battle.cov_lbl.text = "%d%%" % int(cov * 100)
		battle.trace_line.modulate = cov_color(cov)
	else:
		battle.cov_lbl.text = "0%"

	if battle.draw_timer <= 0.0:
		battle._show_summon_result()

func cov_color(cov: float) -> Color:
	if cov >= 0.90: return Color(1.0, 1.0, 0.3)   # 黄：PERFECT
	if cov >= 0.75: return Color(0.4, 1.0, 0.9)   # シアン：GREAT
	if cov >= 0.55: return Color(0.4, 0.6, 1.0)   # 青：まあまあ
	if cov >= 0.30: return Color(1.0, 0.65, 0.3)  # 橙：微妙
	return Color(1.0, 0.4, 0.4)                   # 赤：ずれてる

func handle_draw_input(event: InputEvent) -> void:
	# ボタン領域（上部100px）のタッチはボタンに任せてトレースに追加しない
	var pos: Vector2
	if event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventScreenDrag:
		pos = (event as InputEventScreenDrag).position
	else:
		return
	if pos.y < 100.0:
		return

	if event is InputEventScreenTouch:
		if event.pressed and battle.draw_touch_id == -1:
			battle.draw_touch_id = event.index
			add_to_trace(event.position)
		elif not event.pressed and event.index == battle.draw_touch_id:
			battle.draw_touch_id = -1
	elif event is InputEventScreenDrag and event.index == battle.draw_touch_id:
		add_to_trace(event.position)

func evaluate_lap() -> void:
	if battle.trace_pts.is_empty() or battle.sample_contours.is_empty(): return
	var cov := calc_coverage_contours(battle.trace_pts, battle.sample_contours)
	battle.trace_pts.clear()
	battle.trace_line.clear_points()
	battle.trace_line.modulate = Color.WHITE
	battle.cov_lbl.text = "0%"

	var lap_gain: Dictionary = _Sigils.get_data(battle.draw_sigil_id).get("lap_gain", {"perfect": 35, "great": 20, "good": 10})
	var gain := 0
	var label := ""
	var col := Color.WHITE
	var grade := ""
	if cov >= 0.90:
		gain = lap_gain["perfect"] as int; label = "PERFECT!!"; col = Color(1.0, 1.0, 0.3); grade = "perfect"
	elif cov >= 0.75:
		gain = lap_gain["great"] as int;   label = "GREAT!";    col = Color(0.4, 1.0, 0.9); grade = "great"
	elif cov >= 0.70:
		gain = lap_gain["good"] as int;    label = "GOOD";      col = Color(0.5, 0.7, 1.0); grade = "good"
	else:
		gain = _Data.MISS_GAIN; label = "MISS..."; col = Color(0.8, 0.4, 0.4); grade = "miss"

	var pitch := 1.0 + minf(0.5, float(battle.coating_count) * 0.08)
	Sfx.play_lap(grade, pitch)
	battle.coating_power += gain
	if grade != "miss":
		battle.coating_count += 1
		battle.coating_lbl.text = "×%d" % battle.coating_count
		apply_guide_intensity()
		spawn_lap_pulse(col)
		show_combo_flash(battle.coating_count)
	show_lap_flash(label, col)
	flash_confirm_btn(col)

# 2026-08-07：ボタンが小さく押しにくかった件の対処と合わせて、押した直後にボタン自体も
# 判定色でパッと光らせて「押せた・1周終わった」がその場でわかるようにする
func flash_confirm_btn(col: Color) -> void:
	battle.confirm_btn.modulate = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6)
	var tw := battle.confirm_btn.create_tween()
	tw.tween_property(battle.confirm_btn, "modulate", Color.WHITE, 0.35)

func show_combo_flash(count: int) -> void:
	# 連続成功回数そのものを大きく見せて「積み上がってる」実感を明示する
	if count < 2: return
	var size := 24 + mini(24, (count - 1) * 4)
	var t := clampf(float(count) / 8.0, 0.0, 1.0)
	var col := Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.85, 0.3), t)
	var lbl := battle._make_label("%d連続！" % count, size, Vector2(battle.W * 0.5 - 70, battle.H * 0.5 + 22))
	lbl.custom_minimum_size = Vector2(140, size + 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", col)
	battle.draw_layer.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)
	battle.shake_power = maxf(battle.shake_power, 4.0 + minf(10.0, float(count) * 1.0))

func spawn_lap_pulse(col: Color) -> void:
	# 成功ラップのたびにガイドの輪から光の輪が広がる。周回を重ねるほど大きく広がる
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = col
	for p in battle._make_ring_points(_Data.DRAW_GUIDE_R, 1.0):
		ring.add_point(p)
	ring.position = Vector2(battle.W * 0.5, battle.H * 0.5)
	battle.draw_layer.add_child(ring)
	var grow := 1.15 + minf(0.6, float(battle.coating_count) * 0.08)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2.ONE * grow, 0.4)
	tw.tween_property(ring, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(ring.queue_free)

func show_lap_flash(label: String, col: Color) -> void:
	var lbl := battle._make_label(label, 40, Vector2(battle.W * 0.5 - 80, battle.H * 0.5 - 30))
	lbl.add_theme_color_override("font_color", col)
	if battle.jp_font:
		lbl.add_theme_font_override("font", battle.jp_font)
	battle.draw_layer.add_child(lbl)
	var tween := battle.create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tween.tween_callback(lbl.queue_free)

func add_to_trace(pos: Vector2) -> void:
	battle.trace_line.add_point(pos)
	if not battle.trace_pts.is_empty():
		var prev: Vector2 = battle.trace_pts.back()
		var dist: float   = prev.distance_to(pos)
		var step: float   = _Data.DRAW_BRUSH_R * 0.7
		if dist > step:
			var n: int = int(dist / step)
			for i in range(1, n):
				battle.trace_pts.append(prev.lerp(pos, float(i) / float(n)))
	battle.trace_pts.append(pos)

func calc_coverage(t_pts: Array[Vector2], s_pts: Array[Vector2], brush_r: float) -> float:
	if s_pts.is_empty() or t_pts.is_empty(): return 0.0
	var covered := 0
	for sp in s_pts:
		for tp in t_pts:
			if tp.distance_to(sp) < brush_r:
				covered += 1
				break
	return float(covered) / float(s_pts.size())

# 輪郭ごとに個別採点し、重み付き平均を取る（2026-07-27：最小値方式から変更）。
# 片方の輪郭だけ失敗しても即座に総合スコアが崩れないようにしつつ、内側を無視して
# 外形だけで稼ぐこともできないよう、輪郭ごとの重み（Sigils.gdのcontours定義）で調整する
func calc_coverage_contours(t_pts: Array[Vector2], contours: Array) -> float:
	if contours.is_empty(): return 0.0
	var brush_r := brush_radius()
	var total := 0.0
	for i in contours.size():
		var w: float = battle.contour_weights[i] if i < battle.contour_weights.size() else 1.0
		total += calc_coverage(t_pts, contours[i], brush_r) * w
	return total
