class_name SummonSystem

# BattleScene.gd から分離した召喚まわり（召喚結果画面・仲間の生成・召喚演出・紋章リング/オーラ）。
# 挙動は変更していない。EnemySpawner.gd/WeaponSystem.gd/DrawSystem.gdと同じ方式で、.tscnには
# 手を加えず、BattleScene自身への参照（battle、無型）を持つ素のオブジェクトにした。
#
# 注意：battleが無型（Variant）のため、battle経由の戻り値を`var x := ...`で受けると型推論に
# 失敗してコンパイルエラーになる。必ず`var x: 型 = ...`と明示すること（Actionsのビルド成功では
# 検出できないので、実際にブラウザで開いて確認する）。

const _Data = preload("res://scripts/BattleData.gd")
const _Sigils = preload("res://scripts/Sigils.gd")

var battle

func _init(battle_scene) -> void:
	battle = battle_scene

func show_summon_result() -> void:
	battle.game_state = "summon_result"
	battle.guide_line.visible = false
	battle.guide_glow.visible = false
	battle.guide_rune_root.visible = false
	battle.trace_line.visible = false
	battle.draw_timer_lbl.visible = false
	battle.cov_lbl.visible = false
	battle.coating_lbl.visible = false
	battle.confirm_btn.visible = false

	var coating_power: int = battle.coating_power
	var coating_count: int = battle.coating_count
	var w: float = battle.W
	var h: float = battle.H

	var tier_name := ""
	var tier_col  := Color(0.6, 0.6, 0.6)
	var tier_frac := 0.0
	if coating_power >= 70:
		tier_name = "PERFECT召喚"; tier_col = Color(1.0, 0.95, 0.6); tier_frac = 1.0
	elif coating_power >= 30:
		tier_name = "GREAT召喚";   tier_col = Color(0.85, 0.85, 0.8); tier_frac = 0.85
	elif coating_power >= 10:
		tier_name = "GOOD召喚";    tier_col = Color(0.7, 0.7, 0.68);  tier_frac = 0.55
	else:
		tier_name = "召喚";        tier_col = Color(0.6, 0.6, 0.6);   tier_frac = 0.0

	var panel: Panel = battle._make_glow_panel(Vector2(w * 0.5 - 110, h * 0.28), Vector2(220, 230), tier_col)
	battle.draw_layer.add_child(panel)
	battle.summon_result_nodes.append(panel)

	var title: Label = battle._make_label(tier_name, 28, Vector2(w * 0.5 - 100, h * 0.28 + 16))
	title.custom_minimum_size = Vector2(200, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", tier_col)
	battle.draw_layer.add_child(title)
	battle.summon_result_nodes.append(title)

	var stat: Label = battle._make_label("パワー %d（%d周）" % [coating_power, coating_count], 16, Vector2(w * 0.5 - 100, h * 0.28 + 56))
	stat.custom_minimum_size = Vector2(200, 26)
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	battle.draw_layer.add_child(stat)
	battle.summon_result_nodes.append(stat)

	if tier_frac > 0.0:
		var preview := Line2D.new()
		preview.width = 3.0
		preview.default_color = tier_col
		for p in battle._make_ring_points(36.0, tier_frac):
			preview.add_point(p)
		preview.position = Vector2(w * 0.5, h * 0.28 + 130)
		battle.draw_layer.add_child(preview)
		battle.summon_result_nodes.append(preview)
		var preview_tw := preview.create_tween()
		preview_tw.set_loops()
		preview_tw.tween_property(preview, "rotation", TAU, 5.0).from(0.0)

	var btn := Button.new()
	btn.text = "召喚！"
	btn.size = Vector2(180, 56)
	btn.position = Vector2(w * 0.5 - 90, h * 0.28 + 170)
	if battle.jp_font:
		btn.add_theme_font_override("font", battle.jp_font)
	btn.add_theme_font_size_override("font_size", 20)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.11, 0.92)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = tier_col
	sb.shadow_color = Color(tier_col.r, tier_col.g, tier_col.b, 0.45)
	sb.shadow_size = 10
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.1, 0.1, 0.18, 0.96)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(confirm_summon)
	battle.draw_layer.add_child(btn)
	battle.summon_result_nodes.append(btn)

func confirm_summon() -> void:
	for n in battle.summon_result_nodes:
		n.queue_free()
	battle.summon_result_nodes.clear()
	end_drawing()

func end_drawing() -> void:
	battle.draw_layer.visible = false
	battle.game_state = "battle"
	var sigil_data: Dictionary = _Sigils.get_data(battle.draw_sigil_id)
	var spawn_shape: String = sigil_data.get("spawn_shape", battle.draw_shape)
	add_ally(spawn_shape, battle.coating_power)
	if (sigil_data.get("tier", 1) as int) >= 2:
		battle._show_evolve_flash(spawn_shape, battle.player_pos)

func add_ally(shape: String, power: int, burst: bool = true) -> void:
	if battle.allies.size() >= _Data.MAX_ALLIES:
		var worst: Dictionary = battle._most_damaged_ally()
		if not worst.is_empty():
			battle._remove_ally(worst)
	spawn_ally_at(shape, power, battle.player_pos, burst)

func spawn_ally_at(shape: String, power: int, pos: Vector2, burst: bool = true) -> void:
	var data: Dictionary = _Data.SHAPE_DATA[shape]
	var hp_base: int = data["hp_base"] as int
	var hp: int      = hp_base + power
	var dmg_reduction: float = data["dmg_reduction"] as float
	var col: Color = battle._ally_color(shape, power)
	var sz: float  = battle._ally_size(power)
	var node: Node2D
	if _Data.ALLY_SPRITE_TEXTURES.has(shape):
		var spr := Sprite2D.new()
		spr.texture = _Data.ALLY_SPRITE_TEXTURES[shape]
		var tex_size: Vector2 = spr.texture.get_size()
		var content_ratio: float = _Data.ALLY_SPRITE_CONTENT_RATIO[shape] as float
		var content_px: float = max(tex_size.x, tex_size.y) * content_ratio
		spr.scale = Vector2.ONE * ((sz * 2.8) / content_px)
		spr.modulate = col
		node = spr
	else:
		var poly := Polygon2D.new()
		poly.polygon = battle._make_shape_polygon(shape, sz)
		poly.color = col
		node = poly
	node.position = pos
	battle.add_child(node)
	attach_ally_idle_motion(node)
	attach_sigil_ring(node, sz, power)
	attach_power_aura(node, sz, power)
	battle.allies.append({
		"shape": shape, "hp": hp, "max_hp": hp, "coating": power,
		"node": node, "attack_timer": randf_range(0.0, _Data.ATTACK_INTERVAL),
		"dmg_reduction": dmg_reduction, "tier": _Data.SHAPE_TO_TIER.get(shape, 1)
	})
	if battle.allies.size() == 3:
		battle._show_hint("merge", "出撃前に装備した紋章で強さが決まる！", Vector2(battle.W * 0.5 - 110, battle.H * 0.20))
	if burst:
		summon_burst(pos, col, power, _Data.SHAPE_TO_ATTR.get(shape, "") as String)

# 2026-08-04追加：ドット絵の召喚獣が正面向き固定で静止して見える問題への対処。
# 絵そのものは変えず、わずかな左右の揺れ＋呼吸のような拡縮ループだけを足して「生きてる」感を出す
func attach_ally_idle_motion(node: Node2D) -> void:
	var base_scale := node.scale
	var phase := randf() * TAU

	var sway_tw := node.create_tween()
	sway_tw.set_loops()
	sway_tw.tween_interval(phase / TAU * 1.3)
	sway_tw.tween_property(node, "rotation", 0.05, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway_tw.tween_property(node, "rotation", -0.05, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var breathe_tw := node.create_tween()
	breathe_tw.set_loops()
	breathe_tw.tween_interval(phase / TAU * 1.6)
	breathe_tw.tween_property(node, "scale", base_scale * 1.05, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe_tw.tween_property(node, "scale", base_scale * 0.95, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func summon_burst(pos: Vector2, col: Color, power: int, attr: String = "") -> void:
	# 召喚の瞬間に周囲の敵へ範囲攻撃＋派手な演出を出し、「召喚した」実感を強める
	# 2026-08-26：GOOD/GREAT/PERFECTの4段階に離散化する案を一度試したが、「あくまで精度と周回に
	# 基づいた値で強さを判断してほしい、召喚獣本体と同じ基準じゃないとギャップが出る」との指摘で撤回。
	# 中心の数値（半径・太さ・パーティクル数・シェイク・ノックバック）は_ally_size()と同じ
	# 「minfで頭打ちする連続スケーリング」に戻し、可変幅そのものを大きく広げることで
	# 「完全にわかる」との両立を図った。2本目のリング・フラッシュ・電撃といった追加演出だけは
	# 既存のオーラ/紋章リングと同じ閾値（30/70）でオン/オフする
	Sfx.play_evolve()
	var t := clampf(float(power) / 120.0, 0.0, 1.0)  # power=120で頭打ち（PERFECT=70はt≈0.58）

	var burst_r: float    = _Data.SUMMON_BURST_R * (0.7 + 1.3 * t)
	var ring_width: float = 3.0 + 9.0 * t
	var particle_n: int   = 5 + int(22.0 * t)
	var shake_amt: float  = 6.0 + 22.0 * t
	var kb_force: float   = 180.0 + 320.0 * t
	var burst_col: Color  = col.lerp(Color(1.0, 0.95, 0.75), 0.5 * t)

	battle.shake_power = maxf(battle.shake_power, shake_amt)

	var dmg: int = _Data.SUMMON_BURST_DMG_BASE + int(float(power) * 0.15)
	for e in battle.enemies:
		var diff: Vector2 = (e["pos"] as Vector2) - pos
		var dist: float = diff.length()
		if dist < burst_r:
			battle._damage_enemy(e, dmg, attr)
			e["flash"] = 0.12
			var kb_dir: Vector2 = diff.normalized() if dist > 1.0 else Vector2(1.0, 0.0)
			e["kb"] = (e["kb"] as Vector2) + kb_dir * kb_force

	var ring := Line2D.new()
	ring.width = ring_width
	ring.default_color = burst_col
	for p in battle._make_ring_points(20.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	battle.add_child(ring)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * (burst_r / 20.0), 0.35)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.35)
	ring_tw.chain().tween_callback(ring.queue_free)

	if power >= 30:
		# GREAT相当以上は少し遅れて広がる2本目のリングを重ね、厚みのある衝撃波にする
		var ring2 := Line2D.new()
		ring2.width = ring_width * 0.6
		ring2.default_color = Color(burst_col.r, burst_col.g, burst_col.b, 0.7)
		for p in battle._make_ring_points(20.0, 1.0):
			ring2.add_point(p)
		ring2.position = pos
		battle.add_child(ring2)
		var ring2_tw := ring2.create_tween()
		ring2_tw.tween_interval(0.08)
		ring2_tw.set_parallel(true)
		ring2_tw.tween_property(ring2, "scale", Vector2.ONE * (burst_r * 1.3 / 20.0), 0.4)
		ring2_tw.tween_property(ring2, "modulate:a", 0.0, 0.4)
		ring2_tw.chain().tween_callback(ring2.queue_free)

	if power >= 70:
		# PERFECT相当だけ、中心が一瞬白く弾けるフラッシュを追加して他ランクと混同しないようにする
		var flash := Polygon2D.new()
		flash.polygon = battle._make_ngon(16, 34.0)
		flash.color = Color(1.0, 1.0, 0.95, 0.9)
		flash.position = pos
		battle.add_child(flash)
		var flash_tw := flash.create_tween()
		flash_tw.set_parallel(true)
		flash_tw.tween_property(flash, "scale", Vector2.ONE * 2.4, 0.22)
		flash_tw.tween_property(flash, "modulate:a", 0.0, 0.22)
		flash_tw.chain().tween_callback(flash.queue_free)

	spawn_summon_particles(pos, burst_col, particle_n)
	if power >= 30:
		spawn_lightning_crackle(pos, burst_r, 3 if power < 70 else 7)

func spawn_summon_particles(pos: Vector2, col: Color, count: int) -> void:
	for _i in range(count):
		var angle := randf() * TAU
		var spd   := randf_range(80.0, 220.0)
		var node  := Polygon2D.new()
		node.polygon = battle._make_ngon(3, randf_range(6.0, 9.0))
		node.color   = col
		node.position = pos
		battle.add_child(node)
		battle.particles.append({ "node": node, "vel": Vector2(cos(angle), sin(angle)) * spd, "life": 1.0 })

func spawn_lightning_crackle(pos: Vector2, visual_r: float, bolt_count: int = 6) -> void:
	# パワーが高い召喚だけ、電撃っぽいジグザグ線を放射状に走らせる（「バリバリ」演出）
	for i in range(bolt_count):
		var base_angle := (float(i) / float(bolt_count)) * TAU + randf_range(-0.2, 0.2)
		var bolt := Line2D.new()
		bolt.width = 2.0
		bolt.default_color = Color(0.9, 0.95, 1.0, 0.9)
		var steps := 4
		for s in range(steps + 1):
			var t := float(s) / float(steps)
			var r := visual_r * t
			var jitter := Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)) * (1.0 - t)
			bolt.add_point(Vector2(cos(base_angle), sin(base_angle)) * r + jitter)
		bolt.position = pos
		battle.add_child(bolt)
		var tw := bolt.create_tween()
		tw.tween_property(bolt, "modulate:a", 0.0, 0.18)
		tw.tween_callback(bolt.queue_free)

func attach_sigil_ring(parent: Node2D, sz: float, power: int) -> void:
	if power < 10: return
	var arc_frac := 0.0
	var ring_col := Color.WHITE
	# 2026-08-18：「うまく描けたときの強さが見えづらい」との指摘で、線を太くしてティア間の色差も広げた
	# （中位は白灰色止まりだと弱ティアと見分けづらかったため、水色寄りの色を割り当てて識別性を上げた）
	if power >= 70:
		arc_frac = 1.0;  ring_col = Color(1.0, 0.85, 0.3, 1.0)
	elif power >= 30:
		arc_frac = 0.85; ring_col = Color(0.75, 0.9, 1.0, 0.9)
	else:
		arc_frac = 0.55; ring_col = Color(0.65, 0.65, 0.7, 0.6)

	# 2026-09-25：このring・後述のオーラはparent（仲間のSprite2D）の子として追加しているが、
	# parentは元絵を表示サイズまで縮小するscaleを持つため、そのままだとリングもろとも二重に
	# 縮小されて実質見えなくなっていた（守さんの実機確認で「紋章リングが見えない」と発覚）。
	# 半径・太さをparent.scaleの逆数で打ち消し、parentの縮小率に関係なく絶対サイズで見せる
	var ring := Line2D.new()
	ring.width = 3.0 / parent.scale.x
	ring.default_color = ring_col
	for p in battle._make_ring_points((sz * 1.7) / parent.scale.x, arc_frac):
		ring.add_point(p)
	parent.add_child(ring)

	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", TAU, 6.0).from(0.0)

# 2026-08-07：厚塗りの強さがリング以外で伝わらないとの指摘を受け、強い仲間だけに柔らかいオーラを追加
# 2026-08-26：「見た目が変わらない」との指摘でサイズ・アルファを拡大、視認性の要になる輪郭線（Line2D）を
# 追加。色は独自の金/水色だと属性色（土＝茶黄など）と混同しかねないためattach_sigil_ringと統一。
# （この改修一式でバトル開始直後にグレー画面になる不具合が発生し、原因切り分けのためrevert→再適用を
# 繰り返した末、この関数だけが唯一「異なる型のノードを1つの配列にまとめてループで処理する」という
# コードベースに前例のない書き方をしていたため疑い、aura用・ring用でtween設定を別々に書く
# 従来通りのスタイルに書き直した）
func attach_power_aura(parent: Node2D, sz: float, power: int) -> void:
	if power < 30: return
	var strong := power >= 70
	var aura_r := sz * (3.2 if strong else 2.4)
	var col := Color(1.0, 0.85, 0.3) if strong else Color(0.75, 0.9, 1.0)

	# 2026-09-25：attach_sigil_ringと同じ理由（parentの縮小scaleを二重に受けて潰れる）で
	# aura_rをparent.scaleの逆数で打ち消す。2026-08-26時点の「サイズ・アルファ拡大」修正は
	# この根本原因に触れていなかったため、実質的には直っていなかったとみられる
	var aura := Polygon2D.new()
	aura.polygon = battle._make_ngon(24, aura_r / parent.scale.x)
	aura.color = Color(col.r, col.g, col.b, 0.5 if strong else 0.32)
	aura.z_index = -1
	parent.add_child(aura)

	var ring := Line2D.new()
	ring.width = (2.6 if strong else 1.8) / parent.scale.x
	ring.default_color = col
	for p in battle._make_ring_points(aura_r / parent.scale.x, 1.0):
		ring.add_point(p)
	ring.z_index = -1
	parent.add_child(ring)

	var aura_tw := aura.create_tween()
	aura_tw.set_loops()
	aura_tw.tween_property(aura, "scale", Vector2.ONE * 1.15, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	aura_tw.tween_property(aura, "scale", Vector2.ONE * 0.92, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var ring_tw := ring.create_tween()
	ring_tw.set_loops()
	ring_tw.tween_property(ring, "scale", Vector2.ONE * 1.15, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * 0.92, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
