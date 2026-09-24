class_name EnemySpawner

# BattleScene.gd から分離した敵スポーン・タイムライン制御ロジック（挙動は変更していない）。
# .tscnにノードを追加しない方針のため、シーンツリーで分離するのではなく、
# BattleScene自身への参照（battle）を持つ素のオブジェクトとして持たせている。
# battleはあえて無型（Variant）にしている——Node2D等で型を付けると、Node2Dが
# 知らないメンバ（enemies等のBattleScene固有プロパティ）へのアクセスで
# 静的解析エラーになるため。

const _Data = preload("res://scripts/BattleData.gd")

var battle

# 詠唱者（caster）が放つ遠距離弾。プレイヤーの弾・仲間の弾（battle.bullets）とは別枠で
# EnemySpawner自身が保持・更新する（既存のbulletsは「敵にダメージを与える」前提で
# 各所から参照されているため、プレイヤーにダメージを与える弾を混ぜず独立させた）
var enemy_bolts: Array[Dictionary] = []

func _init(battle_scene) -> void:
	battle = battle_scene

func spawn_tick(delta: float) -> void:
	var timeline := current_timeline()

	# ウェーブ（events）：時刻を迎えたら1回だけ包囲ウェーブを発生させる。全部消化したらloop_eventに切り替える
	var events: Array = timeline.get("events", []) as Array
	if battle.next_event_idx < events.size():
		var ev: Dictionary = events[battle.next_event_idx] as Dictionary
		if battle.elapsed_time >= (ev["t"] as float):
			battle.wave_count += 1
			spawn_ring_enemies(ev["count"] as int, ev.get("mix", { "shard": 1.0 }) as Dictionary)
			battle._show_wave_flash(battle.wave_count)
			battle.next_event_idx += 1
	else:
		var loop_event: Dictionary = timeline.get("loop_event", {}) as Dictionary
		if not loop_event.is_empty() and battle.elapsed_time >= battle.next_loop_event_time:
			var loop_mix: Dictionary = loop_event.get("mix", { "shard": 1.0 }) as Dictionary
			battle.wave_count += 1
			spawn_ring_enemies(loop_event.get("count", 8) as int, loop_mix)
			battle._show_wave_flash(battle.wave_count)
			battle.next_loop_event_time = battle.elapsed_time + (loop_event.get("period", 90.0) as float)

	# 通常スポーン（segments）：区間ごとの密度・敵構成に従う
	battle.enemy_spawn_timer -= delta
	if battle.enemy_spawn_timer > 0.0: return
	var seg := current_segment(timeline.get("segments", []) as Array)
	battle.enemy_spawn_timer = seg.get("interval", 1.5) as float
	var count: int = seg.get("count", 1) as int
	var mix: Dictionary = seg.get("mix", { "shard": 1.0 }) as Dictionary
	for _i in range(count):
		if battle.enemies.size() >= _Data.MAX_ENEMIES: break
		spawn_one_enemy(pick_type_from_mix(mix))

# ステージ4（エンドレス）はステージ3のタイムラインをそのまま流用する（900秒経過後はloop_eventに切り替わる）
func current_timeline() -> Dictionary:
	var key: int = mini(battle.current_stage, 3)
	return _Data.STAGE_TIMELINES.get(key, _Data.STAGE_TIMELINES[3]) as Dictionary

# 時刻tが経過時間以下の区間のうち、一番手前（最新）のものを採用する。segmentsは時刻昇順の前提
func current_segment(segments: Array) -> Dictionary:
	var chosen: Dictionary = segments[0] as Dictionary
	for seg in segments:
		if battle.elapsed_time >= ((seg as Dictionary)["t"] as float):
			chosen = seg as Dictionary
		else:
			break
	return chosen

func pick_type_from_mix(mix: Dictionary) -> String:
	var r := randf()
	var acc := 0.0
	for k in mix:
		acc += float(mix[k])
		if r < acc: return k as String
	return "shard"

# ウェーブ専用：プレイヤーを中心に画面外径で均等配置し、四方から一斉に迫る「包囲」を作る
# 2026-08-31：単一typeからmix対応に変更。ヴォイドマーク主体の包囲だけだと「山場なのに全員遅くて
# 逃げ切れる」との指摘を受け、シャード/フラクチャーの護衛を混ぜられるようにした
func spawn_ring_enemies(count: int, mix: Dictionary) -> void:
	if count <= 0: return
	# 2026-08-31：「包囲ウェーブが簡単に抜け出せる」との指摘。半径80のマージンだと敵同士の間隔が
	# 広く（特に敵数の少ないヴォイドマーク包囲は隙間が394pxにもなっていた）、湧いた直後にすり抜けられて
	# いたため、マージンを40に縮めて初期の隙間を詰めた
	var radius := maxf(_Data.W, _Data.H) * 0.5 + 40.0
	var start_a := randf() * TAU
	for i in range(count):
		if battle.enemies.size() >= _Data.MAX_ENEMIES: break
		var a := start_a + (float(i) / float(count)) * TAU + randf_range(-0.12, 0.12)
		var pos: Vector2 = battle.player_pos + Vector2(cos(a), sin(a)) * radius
		spawn_one_enemy(pick_type_from_mix(mix), pos)

func spawn_one_enemy(forced_type: String = "", forced_pos = null) -> void:
	var pos: Vector2  = forced_pos if forced_pos != null else random_edge_pos()
	# 2026-08-18：敵種の抽選はSTAGE_TIMELINESの区間ごとのmixに一本化したため、呼び出し元は
	# 常に解決済みの型を渡す想定。空文字が来た場合のみ雑魚のシャードにフォールバックする
	var etype: String = forced_type if forced_type != "" else "shard"
	# 2026-09-24追加：「詠唱者」への差し替え。STAGE_TIMELINESのmix比率は一切変えず独立抽選にすることで、
	# 既に何度も調整してきた既存3種のバランスを崩さずに新しい敵タイプを混ぜられるようにした
	if battle.current_stage >= 2:
		var caster_chance: float = _Data.CASTER_CHANCE_STAGE3 if battle.current_stage >= 3 else _Data.CASTER_CHANCE
		if randf() < caster_chance:
			etype = "caster"
	var edata: Dictionary = _Data.ENEMY_TYPES[etype]
	# 2026-08-10：HP・速度の時間経過スケーリングを廃止（見た目が変わらないまま個体が強くなるのは
	# プレイヤーに伝わらないとの指摘）。難易度上昇は「数が増える」「新しい敵タイプが混ざる」に一本化
	# （2026-08-18：どちらもSTAGE_TIMELINESの区間・イベントで制御するタイムライン方式に作り直した）
	var hp: int   = int(_Data.ENEMY_HP_BASE * (edata["hp_m"] as float))
	var spd: float = _Data.ENEMY_SPEED_BASE * (edata["spd_m"] as float)
	var r: float  = edata["radius"] as float

	var is_elite := false
	var elite_variant := ""
	if battle.elapsed_time >= _Data.ELITE_MIN_TIME:
		var elite_chance: float = _Data.ELITE_CHANCE_STAGE3 if battle.current_stage >= 3 else _Data.ELITE_CHANCE
		is_elite = randf() < elite_chance
	if is_elite:
		var variant_keys := _Data.ELITE_VARIANTS.keys()
		elite_variant = variant_keys[randi() % variant_keys.size()] as String
		var v: Dictionary = _Data.ELITE_VARIANTS[elite_variant] as Dictionary
		hp = int(float(hp) * (v["hp_mult"] as float))
		spd *= v["speed_mult"] as float
		r *= v["scale_mult"] as float

	var node := Sprite2D.new()
	node.texture = _Data.ENEMY_SPRITE_TEXTURES[etype]
	var tex_size: Vector2 = node.texture.get_size()
	var content_ratio: float = _Data.ENEMY_SPRITE_CONTENT_RATIO[etype] as float
	var content_px: float = max(tex_size.x, tex_size.y) * content_ratio
	node.scale = Vector2.ONE * ((r * 2.2) / content_px)
	node.position = pos
	node.material = battle._enemy_shader_mat
	battle.add_child(node)

	if is_elite:
		attach_elite_ring(node, r, (_Data.ELITE_VARIANTS[elite_variant] as Dictionary)["ring_color"] as Color)

	var ward := ""
	if battle.current_stage >= 2:
		var chance: float = _Data.PREDATOR_CHANCE_STAGE3 if battle.current_stage >= 3 else _Data.PREDATOR_CHANCE
		if randf() < chance:
			ward = _Data.PREDATOR_ATTRS[randi() % _Data.PREDATOR_ATTRS.size()]
			attach_predator_ring(node, r, ward)

	# 2026-09-24追加：先読みして進む「追跡者」。エリート・天敵ウォードとは独立に判定し、両方乗ることもある
	var hunter_chance: float = _Data.HUNTER_CHANCE_STAGE3 if battle.current_stage >= 3 else _Data.HUNTER_CHANCE
	var is_hunter := randf() < hunter_chance
	if is_hunter:
		attach_hunter_ring(node, r)

	if etype == "caster":
		attach_caster_ring(node, r)

	battle.enemies.append({ "hp": hp, "max_hp": hp, "pos": pos, "speed": spd, "radius": r, "node": node, "kb": Vector2.ZERO, "color": edata["color"] as Color, "flash": 0.0, "ward": ward, "elite": is_elite, "etype": etype, "hunter": is_hunter, "cast_cd": randf_range(0.6, _Data.CASTER_CAST_INTERVAL), "casting": false })

# デバッグ専用（2026-09-24追加）：確率任せにせず、追跡者・詠唱者をプレイヤーの目の前に確定で
# 湧かせて見た目・挙動をその場で確認するためのショートカット。DebugMode.enabled時のみ呼ばれる想定
func debug_force_spawn(kind: String) -> void:
	var pos: Vector2 = battle.player_pos + Vector2(0, -160)
	if kind == "caster":
		spawn_one_enemy("caster", pos)
	else:
		spawn_one_enemy("shard", pos)
		var e: Dictionary = battle.enemies[battle.enemies.size() - 1]
		if not (e.get("hunter", false) as bool):
			e["hunter"] = true
			attach_hunter_ring(e["node"] as Node2D, e["radius"] as float)

func random_edge_pos() -> Vector2:
	var hw := _Data.W * 0.5 + 60.0
	var hh := _Data.H * 0.5 + 60.0
	match randi() % 4:
		0: return battle.player_pos + Vector2(randf_range(-hw, hw), -hh)
		1: return battle.player_pos + Vector2(randf_range(-hw, hw),  hh)
		2: return battle.player_pos + Vector2(-hw, randf_range(-hh, hh))
		_: return battle.player_pos + Vector2( hw, randf_range(-hh, hh))

# エリート個体のリング表示（天敵ウォードと同じ発想。色でtough/swiftの系統が直感的にわかるようにする）
func attach_elite_ring(parent: Node2D, r: float, ring_color: Color) -> void:
	var ring := Line2D.new()
	ring.width = 2.6
	ring.default_color = ring_color
	for p in battle._make_ring_points(r * 1.35, 1.0):
		ring.add_point(p)
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", TAU, 2.2).from(0.0)

# 追跡者のリング表示（2026-09-24追加）。エリート・天敵ウォードと見分けがつくよう紫・逆回転にした
func attach_hunter_ring(parent: Node2D, r: float) -> void:
	var ring := Line2D.new()
	ring.width = 2.2
	ring.default_color = _Data.HUNTER_RING_COLOR
	for p in battle._make_ring_points(r * 1.65, 1.0):
		ring.add_point(p)
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", -TAU, 2.6).from(0.0)

# 詠唱者のリング表示（2026-09-24追加）。他のリングは回転するが、こちらは「様子を見ている」
# 感触を出すため脈動（拡大縮小）にして視覚言語を分けた
func attach_caster_ring(parent: Node2D, r: float) -> void:
	var ring := Line2D.new()
	ring.width = 2.4
	ring.default_color = _Data.CASTER_RING_COLOR
	for p in battle._make_ring_points(r * 1.5, 1.0):
		ring.add_point(p)
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "scale", Vector2.ONE * 1.15, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ring, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)

# 天敵ウォードのリング表示（味方の_attach_sigil_ringと同じ発想。本体色は変えない）
func attach_predator_ring(parent: Node2D, r: float, ward: String) -> void:
	var col: Color = _Data.PREDATOR_WARD_COLOR.get(ward, Color.WHITE)
	var ring := Line2D.new()
	ring.width = 2.2
	ring.default_color = col
	for p in battle._make_ring_points(r * 1.5, 1.0):
		ring.add_point(p)
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", TAU, 4.0).from(0.0)

# 敵への全ダメージ経路が通る共通関数（2026-08-04追加）。attrを渡すと天敵ウォード判定を行う。
# attrが空文字（プレイヤー自身の弾など属性を持たない攻撃）の場合はウォードを無視する。
func damage_enemy(e: Dictionary, dmg: int, attr: String = "") -> void:
	var final_dmg := dmg
	if attr != "" and (e.get("ward", "") as String) == attr:
		final_dmg = maxi(1, int(ceil(float(dmg) * (1.0 - _Data.PREDATOR_DMG_CUT))))
	e["hp"] = (e["hp"] as int) - final_dmg

func update_enemies(delta: float) -> void:
	var to_remove : Array[int] = []
	# 2026-08-31：「280秒あたり、大きなウェーブの直前で重くなる」との指摘。敵同士のセパレーションが
	# 全敵×全敵のO(n²)（MAX_ENEMIES=90なら最大8100回/フレーム）だったため、敵数が多い場面で顕著に
	# 重くなっていたと判断。近傍セルだけを調べる簡易グリッド分割に変更して実質的な計算量を減らす
	var sep_grid: Dictionary = {}
	var sep_cell := 100.0
	for e in battle.enemies:
		var cell := Vector2i(int(floor((e["pos"] as Vector2).x / sep_cell)), int(floor((e["pos"] as Vector2).y / sep_cell)))
		if not sep_grid.has(cell):
			sep_grid[cell] = []
		(sep_grid[cell] as Array).append(e)

	for i in range(battle.enemies.size()):
		var e: Dictionary = battle.enemies[i]
		e["kb"] = (e["kb"] as Vector2).lerp(Vector2.ZERO, delta * 5.0)
		# ヒットフラッシュ
		var flash_t: float = e["flash"] as float
		if flash_t > 0.0:
			e["flash"] = maxf(0.0, flash_t - delta)
			(e["node"] as Node2D).modulate = Color(2.2, 2.2, 2.2) if flash_t > 0.06 else Color.WHITE
		# 敵同士のセパレーション（群れが重ならないように押し離す）
		# 2026-08-04：分離が強すぎて敵がプレイヤー周りに均等に薄く広がり、密集が起きない問題を受けて弱めていたが、
		# 2026-08-10：移動速度を減速したことで密集自体はそのまま起きる見込みのため、重なり対策を元の強さに戻した
		var sep := Vector2.ZERO
		var e_pos: Vector2 = e["pos"] as Vector2
		var e_cell := Vector2i(int(floor(e_pos.x / sep_cell)), int(floor(e_pos.y / sep_cell)))
		for nx in range(-1, 2):
			for ny in range(-1, 2):
				var ncell := Vector2i(e_cell.x + nx, e_cell.y + ny)
				if not sep_grid.has(ncell): continue
				for other in (sep_grid[ncell] as Array):
					if other == e: continue
					var diff: Vector2 = e_pos - (other["pos"] as Vector2)
					var min_d: float  = (e["radius"] as float) + (other["radius"] as float) + 4.0
					var d: float      = diff.length()
					if d < min_d and d > 0.5:
						sep += diff.normalized() * (min_d - d)
		var etype: String = e.get("etype", "shard") as String
		if etype == "caster":
			# 2026-09-24追加：「詠唱者」は間合いを取る。近すぎれば離れ、遠すぎれば詰めるだけで、
			# 直線追尾の他の敵と違って周回しているだけでは安全になれない（距離を保って撃ってくる）
			var to_player: Vector2 = battle.player_pos - e_pos
			var dist_to_player := to_player.length()
			var move_dir := Vector2.ZERO
			if dist_to_player > _Data.CASTER_PREFERRED_RANGE + _Data.CASTER_RANGE_SLACK:
				move_dir = to_player.normalized()
			elif dist_to_player < _Data.CASTER_PREFERRED_RANGE - _Data.CASTER_RANGE_SLACK:
				move_dir = -to_player.normalized()
			e["pos"] = e_pos + (move_dir * (e["speed"] as float) + sep * 3.0) * delta + (e["kb"] as Vector2) * delta

			# 詠唱タイマー：発射直前だけ光らせて（テレグラフ）から遠距離弾を撃つ
			e["cast_cd"] = (e["cast_cd"] as float) - delta
			if not (e.get("casting", false) as bool) and (e["cast_cd"] as float) <= _Data.CASTER_TELEGRAPH:
				e["casting"] = true
				(e["node"] as Node2D).modulate = Color(1.5, 1.5, 2.2)
			if (e["cast_cd"] as float) <= 0.0:
				fire_caster_bolt(e)
				e["casting"] = false
				(e["node"] as Node2D).modulate = Color.WHITE
				e["cast_cd"] = _Data.CASTER_CAST_INTERVAL
		else:
			# 2026-09-24追加：「追跡者」は現在地ではなく、移動方向を先読みした地点を狙う。プレイヤーが
			# 一定方向に走り続ける限り追いつかれる（＝同じ半径をぐるぐる回るだけでは避けられない）ため、
			# 直線追尾しかしない他の敵とは違う「詰めてくる」感触になる
			var target_pos: Vector2 = battle.player_pos
			if e.get("hunter", false):
				var player_speed: float = _Data.PLAYER_SPEED * (battle.weapon_stats["move_speed"] as float)
				target_pos = battle.player_pos + (battle.joy_vec as Vector2) * player_speed * _Data.HUNTER_LEAD_TIME
			var dir: Vector2 = (target_pos - e_pos).normalized()
			e["pos"] = e_pos + (dir * (e["speed"] as float) + sep * 3.0) * delta + (e["kb"] as Vector2) * delta
		e["node"].position = e["pos"] as Vector2

		# プレイヤーとの衝突
		if (e["pos"] as Vector2).distance_to(battle.player_pos) < _Data.PLAYER_R + (e["radius"] as float):
			battle.player_hp -= _Data.ENEMY_DAMAGE
			battle.shake_power = 20.0
			Sfx.play_damage()
			to_remove.append(i)
			e["node"].queue_free()
			if battle.player_hp <= 0:
				Sfx.play_game_over()
				battle._game_over()
				return
			continue

		# 仲間との衝突
		var hit_ally : Dictionary = {}
		for a in battle.allies:
			if (e["pos"] as Vector2).distance_to(a["node"].position) < _Data.ALLY_BASE_SIZE + (e["radius"] as float):
				var kb_dir: Vector2 = ((e["pos"] as Vector2) - a["node"].position).normalized()
				e["kb"] = (e["kb"] as Vector2) + kb_dir * 180.0
				var reduction: float = a["dmg_reduction"] as float
				a["hp"] -= 8 * (1.0 - reduction)
				hit_ally = a
				break
		if not hit_ally.is_empty() and hit_ally["hp"] <= 0:
			battle._remove_ally(hit_ally)

	for i in range(to_remove.size() - 1, -1, -1):
		battle.enemies.remove_at(to_remove[i])

	update_enemy_bolts(delta)

# 詠唱者が放つ遠距離弾を1発生成する（2026-09-24追加）
func fire_caster_bolt(e: Dictionary) -> void:
	var from: Vector2 = e["pos"] as Vector2
	var dir: Vector2 = (battle.player_pos - from).normalized()
	var node := Polygon2D.new()
	node.polygon = battle._make_star_pts(4, _Data.CASTER_BOLT_R, 0.35)
	node.color = _Data.CASTER_RING_COLOR
	node.position = from
	battle.add_child(node)
	enemy_bolts.append({ "pos": from, "dir": dir, "node": node, "life": 3.0 })

# 詠唱者の遠距離弾の移動・プレイヤーへの命中判定（2026-09-24追加）。プレイヤーへダメージを与える
# 弾のため、敵にダメージを与える前提のbattle.bulletsとは別枠でEnemySpawnerが保持・更新する
func update_enemy_bolts(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in range(enemy_bolts.size()):
		var b: Dictionary = enemy_bolts[i]
		b["pos"] = (b["pos"] as Vector2) + (b["dir"] as Vector2) * _Data.CASTER_BOLT_SPEED * delta
		b["life"] = (b["life"] as float) - delta
		(b["node"] as Node2D).position = b["pos"] as Vector2
		if (b["pos"] as Vector2).distance_to(battle.player_pos) < _Data.PLAYER_R + _Data.CASTER_BOLT_R:
			(b["node"] as Node2D).queue_free()
			to_remove.append(i)
			battle.player_hp -= _Data.CASTER_BOLT_DMG
			battle.shake_power = maxf(battle.shake_power, 10.0)
			Sfx.play_damage()
			if battle.player_hp <= 0:
				Sfx.play_game_over()
				battle._game_over()
				return
			continue
		if (b["life"] as float) <= 0.0:
			(b["node"] as Node2D).queue_free()
			to_remove.append(i)
	for i in range(to_remove.size() - 1, -1, -1):
		enemy_bolts.remove_at(to_remove[i])
