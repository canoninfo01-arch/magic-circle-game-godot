class_name WeaponSystem

# BattleScene.gd から分離した属性武器（召喚獣ごとの6種の武器）の発動ロジック
# （挙動は変更していない）。EnemySpawner.gdと同じ理由・同じ方式で、.tscnには
# 手を加えず、BattleScene自身への参照（battle、無型）を持つ素のオブジェクトにした。
#
# _fire_bullet・_nearest_enemy・_make_ring_points・_make_star_pts・
# _spawn_death_particlesは、武器専用ではなく基本攻撃やUI演出とも共有する
# 低レベルユーティリティのためBattleScene.gd側に残し、battle経由で呼び出す。

const _Data = preload("res://scripts/BattleData.gd")
const _Sigils = preload("res://scripts/Sigils.gd")

var battle

func _init(battle_scene) -> void:
	battle = battle_scene

func update_ally_weapons(a: Dictionary, delta: float) -> void:
	var attr: String = _Data.SHAPE_TO_ATTR.get(a["shape"] as String, "") as String
	if attr.is_empty(): return
	if not a.has("weapon_timers"):
		a["weapon_timers"] = {}
	var timers: Dictionary = a["weapon_timers"]

	for id in _Data.ATTR_WEAPON_DATA:
		var wdata: Dictionary = _Data.ATTR_WEAPON_DATA[id]
		if (wdata["attr"] as String) != attr: continue
		var level: int = battle.weapon_levels[id] as int
		if level <= 0: continue

		if (wdata["pattern"] as String) == "orbit":
			update_ally_orbiter(a, id, wdata, level, delta)
			continue

		if not timers.has(id):
			timers[id] = randf_range(0.0, wdata["cooldown"] as float)
		timers[id] = (timers[id] as float) - delta
		if (timers[id] as float) <= 0.0:
			fire_attr_weapon(a, id, wdata, level)
			timers[id] = (wdata["cooldown"] as float) / (1.0 + float(level - 1) * 0.15)

# 属性武器ダメージのtier保証倍率×厚塗り係数（2026-07-27）。基礎弾攻撃には適用しない
func ally_weapon_tier_mult(a: Dictionary) -> float:
	var tier: int = a.get("tier", 1) as int
	var tier_mult: float = _Sigils.TIER_DMG_MULT.get(tier, 1.0) as float
	var coating: int = a.get("coating", 0) as int
	var coating_mult := 1.0 + float(coating) * _Data.COATING_DMG_K
	return tier_mult * coating_mult

func fire_attr_weapon(a: Dictionary, id: String, wdata: Dictionary, level: int) -> void:
	var ally_pos: Vector2 = a["node"].position
	var nearest: Dictionary = battle._nearest_enemy(ally_pos)
	if nearest.is_empty(): return
	var dmg := int(float(wdata["dmg"] as int) * (1.0 + float(level - 1) * 0.25) * (battle.weapon_stats["damage"] as float) * ally_weapon_tier_mult(a))
	var col: Color = wdata["col"]
	var attr: String = wdata["attr"] as String
	match wdata["pattern"] as String:
		"projectile":
			var dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()
			battle._fire_bullet(ally_pos, dir, dmg, col, wdata.get("pierce", false), wdata.get("homing", false), wdata.get("explode_r", 0.0) as float, attr, true)
			Sfx.play_weapon(id)
		"chain":
			fire_chain_lightning(ally_pos, dmg, wdata["jumps"] as int, wdata["range"] as float, col, attr, id)
		"pulse":
			# 2026-08-06：範囲攻撃はダメージだけでなくAoE半径もLvに連動させる（Lv1〜5、+8%/Lv）
			var pulse_r: float = (wdata["radius"] as float) * (1.0 + float(level - 1) * 0.08)
			fire_pulse(ally_pos, dmg, pulse_r, col, attr, id)
		"rain":
			var target := pick_rain_target(wdata["radius"] as float)
			if not target.is_empty():
				start_rain_strike(target["pos"] as Vector2, dmg, wdata["radius"] as float, col, attr, wdata.get("telegraph", 0.5) as float)
		"beam":
			# 2026-08-07：太さのある直線ビーム。Lvが上がるほど太さも伸びる（+10%/Lv）
			var dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()
			var beam_w: float = (wdata["width"] as float) * (1.0 + float(level - 1) * 0.1)
			fire_beam(ally_pos, dir, dmg, wdata["range"] as float, beam_w, col, attr, id)

func fire_beam(from: Vector2, dir: Vector2, dmg: int, length: float, width: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	var to := from + dir * length
	for e in battle.enemies:
		var epos: Vector2 = e["pos"] as Vector2
		# 線分(from-to)への垂直距離と、線分の範囲内かどうかを判定
		var seg: Vector2 = to - from
		var t := clampf(seg.dot(epos - from) / seg.length_squared(), 0.0, 1.0)
		var closest: Vector2 = from + seg * t
		if epos.distance_to(closest) < width * 0.5 + (e["radius"] as float):
			battle._damage_enemy(e, dmg, attr)
			e["flash"] = 0.12
			# 2026-08-31：「当たっても止まってない」との指摘。2026-08-07に旧「回転する紋章の盾」から
			# 作り替えた際、同属性の衝撃波と弾き合っていた反省からノックバックを完全に無くしていたが、
			# それだと命中しても敵の動きに何の変化もなく「効いてる感」が皆無だった。ビームの進行方向への
			# 軽いノックバックのみ加え、衝撃波（自分中心の放射状）と向きがぶつかりにくいよう弱めの
			# 力（150）にとどめて再発を防ぐ
			e["kb"] = (e["kb"] as Vector2) + dir * 150.0
	var beam := Line2D.new()
	beam.width = width
	beam.default_color = Color(col.r, col.g, col.b, 0.75)
	beam.add_point(from)
	beam.add_point(to)
	battle.add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "modulate:a", 0.0, 0.16)
	tw.tween_callback(beam.queue_free)
	Sfx.play_weapon(weapon_id)

func update_ally_orbiter(a: Dictionary, id: String, wdata: Dictionary, level: int, delta: float) -> void:
	if not a.has("orbiters"):
		a["orbiters"] = {}
	var orbiters: Dictionary = a["orbiters"]
	if not orbiters.has(id):
		var node := Polygon2D.new()
		node.polygon = battle._make_star_pts(4, 8.0, 0.4)
		node.color = wdata["col"]
		battle.add_child(node)
		orbiters[id] = { "node": node, "angle": randf() * TAU, "hit_cd": 0.0 }

	var orb: Dictionary = orbiters[id]
	orb["angle"] = (orb["angle"] as float) + delta * (wdata["rotate_speed"] as float)
	var ally_pos: Vector2 = a["node"].position
	var offset := Vector2(cos(orb["angle"] as float), sin(orb["angle"] as float)) * (wdata["radius"] as float)
	var world_pos := ally_pos + offset
	(orb["node"] as Polygon2D).position = world_pos

	orb["hit_cd"] = maxf(0.0, (orb["hit_cd"] as float) - delta)
	if (orb["hit_cd"] as float) <= 0.0:
		var dmg := int(float(wdata["dmg"] as int) * (1.0 + float(level - 1) * 0.25) * (battle.weapon_stats["damage"] as float) * ally_weapon_tier_mult(a))
		for e in battle.enemies:
			if world_pos.distance_to(e["pos"] as Vector2) < (e["radius"] as float) + 10.0:
				battle._damage_enemy(e, dmg, wdata["attr"] as String)
				e["flash"] = 0.12
				# 2026-07-28：土は遠距離弾を持たないため、盾が弾かないと密着ダメージを避けられない指摘を受けて追加
				# 2026-07-29：さらに強めてほしいとの要望で180→300に増加
				var kb_dir: Vector2 = ((e["pos"] as Vector2) - world_pos).normalized()
				e["kb"] = (e["kb"] as Vector2) + kb_dir * 300.0
				orb["hit_cd"] = 0.35
				break

func fire_chain_lightning(from: Vector2, dmg: int, jumps: int, chain_range: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	var hit_enemies: Array = []
	var cur_pos := from
	var any_hit := false
	for _j in range(jumps):
		var target := {}
		var best_d := chain_range
		for e in battle.enemies:
			if hit_enemies.has(e): continue
			var d: float = cur_pos.distance_to(e["pos"] as Vector2)
			if d < best_d:
				best_d = d
				target = e
		if target.is_empty(): break
		battle._damage_enemy(target, dmg, attr)
		target["flash"] = 0.12
		draw_lightning_bolt(cur_pos, target["pos"] as Vector2, col)
		hit_enemies.append(target)
		cur_pos = target["pos"] as Vector2
		any_hit = true
	if any_hit:
		Sfx.play_weapon(weapon_id)

func draw_lightning_bolt(from: Vector2, to: Vector2, col: Color) -> void:
	var bolt := Line2D.new()
	bolt.width = 2.5
	bolt.default_color = col
	var steps := 5
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var base := from.lerp(to, t)
		var jitter := Vector2.ZERO if (s == 0 or s == steps) else Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		bolt.add_point(base + jitter)
	battle.add_child(bolt)
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "modulate:a", 0.0, 0.2)
	tw.tween_callback(bolt.queue_free)

func fire_pulse(pos: Vector2, dmg: int, radius: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	Sfx.play_weapon(weapon_id)
	for e in battle.enemies:
		if pos.distance_to(e["pos"] as Vector2) < radius:
			battle._damage_enemy(e, dmg, attr)
			e["flash"] = 0.12
			# 2026-07-28：衝撃波の名前通り、当てた敵を外側へ弾き飛ばす（土の武器は近接のみで弾かないと密着され続けるため）
			# 2026-07-29：さらに強めてほしいとの要望で220→400に増加
			var kb_dir: Vector2 = ((e["pos"] as Vector2) - pos).normalized()
			e["kb"] = (e["kb"] as Vector2) + kb_dir * 400.0
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = col
	for p in battle._make_ring_points(10.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	battle.add_child(ring)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * (radius / 10.0), 0.3)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.3)
	ring_tw.chain().tween_callback(ring.queue_free)

# 2026-08-05：水の「紋章の雨」用。密集地点ほど狙われやすくする（数体をサンプリングし、
# 周囲に一番仲間内...ではなく敵が多い地点を選ぶ）。密集対策（セパレーション緩和）と噛み合わせる狙い
func pick_rain_target(radius: float) -> Dictionary:
	if battle.enemies.is_empty(): return {}
	var best: Dictionary = {}
	var best_count := -1
	var sample_n: int = mini(6, battle.enemies.size())
	var tried_idx: Array[int] = []
	for _i in range(sample_n * 2):
		if tried_idx.size() >= sample_n: break
		var idx: int = randi() % battle.enemies.size()
		if tried_idx.has(idx): continue
		tried_idx.append(idx)
		var cand: Dictionary = battle.enemies[idx]
		var cnt := 0
		for other in battle.enemies:
			if (cand["pos"] as Vector2).distance_to(other["pos"] as Vector2) <= radius:
				cnt += 1
		if cnt > best_count:
			best_count = cnt
			best = cand
	return best

# 天から降り注ぐ範囲攻撃。着弾地点に予告リング＋落下する雨粒を表示してから、少し遅れてダメージを与える
func start_rain_strike(pos: Vector2, dmg: int, radius: float, col: Color, attr: String, telegraph: float) -> void:
	var warn := Line2D.new()
	warn.width = 2.5
	warn.default_color = Color(col.r, col.g, col.b, 0.75)
	for p in battle._make_ring_points(radius, 1.0):
		warn.add_point(p)
	warn.position = pos
	battle.add_child(warn)
	var warn_tw := warn.create_tween()
	warn_tw.tween_property(warn, "scale", Vector2.ONE * 0.75, telegraph).from(Vector2.ONE * 1.3).set_trans(Tween.TRANS_SINE)
	warn_tw.tween_callback(func():
		warn.queue_free()
		rain_impact(pos, dmg, radius, col, attr)
	)

	for _i in range(5):
		var drop := Polygon2D.new()
		drop.polygon = battle._make_star_pts(4, 5.0, 0.25)
		drop.color = Color(col.r, col.g, col.b, 0.85)
		var off := Vector2(randf_range(-radius * 0.6, radius * 0.6), randf_range(-radius * 0.6, radius * 0.6))
		var end_pos := pos + off
		var start_pos := end_pos + Vector2(0, -240.0 - randf() * 80.0)
		drop.position = start_pos
		battle.add_child(drop)
		var dtw := drop.create_tween()
		dtw.tween_interval(randf() * telegraph * 0.3)
		dtw.tween_property(drop, "position", end_pos, telegraph * randf_range(0.7, 1.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		dtw.tween_callback(drop.queue_free)

func rain_impact(pos: Vector2, dmg: int, radius: float, col: Color, attr: String) -> void:
	# 2026-08-25：旧仕様は進化ファンファーレ（play_evolve）を流用しておりミスマッチだったため専用音に変更
	Sfx.play_rain_impact()
	# 2026-08-14：敵が多いと着弾のたび画面が揺れて邪魔になるとの指摘で、揺れを大幅に弱めた（8.0→2.0）
	battle.shake_power = maxf(battle.shake_power, 2.0)
	for e in battle.enemies:
		var d := pos.distance_to(e["pos"] as Vector2)
		if d < radius:
			battle._damage_enemy(e, dmg, attr)
			e["flash"] = 0.12
			var kb_dir: Vector2 = ((e["pos"] as Vector2) - pos).normalized() if d > 1.0 else Vector2(0.0, -1.0)
			e["kb"] = (e["kb"] as Vector2) + kb_dir * 160.0
	battle._spawn_death_particles(pos, col, radius * 0.35)
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = col
	for p in battle._make_ring_points(10.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	battle.add_child(ring)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * (radius / 10.0), 0.3)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.3)
	ring_tw.chain().tween_callback(ring.queue_free)
