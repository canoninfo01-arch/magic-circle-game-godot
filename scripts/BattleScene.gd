extends Node2D

const _Shapes = preload("res://scripts/Shapes.gd")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 画面サイズ（project.godot 固定値を直接参照）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const W := 390.0
const H := 844.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 定数
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const PLAYER_SPEED     := 220.0
const PLAYER_HP_MAX    := 10
const PLAYER_R         := 11.0
const MAX_ALLIES       := 10
const ALLY_OUTER_R     := 68.0
const ALLY_MID_R       := 46.0
const ALLY_INNER_R     := 26.0
const ALLY_BASE_SIZE   := 14.0

const ENEMY_SPAWN_BASE: float = 2.5
const ENEMY_SPEED_BASE: float = 75.0
const ENEMY_HP_BASE:    int   = 30
const ENEMY_R:          float = 14.0
const ENEMY_DAMAGE:     int   = 1

const ITEM_DROP_CHANCE := 0.35
const CHAR_ITEM_RATIO  := 0.4
const ITEM_PICKUP_R    := 38.0
const ITEM_R           := 14.0

const BULLET_SPEED     := 370.0
const BULLET_RANGE     := 280.0
const BULLET_R         := 4.0
const BULLET_DMG_BASE  := 5
const ATTACK_RANGE          := 240.0
const ATTACK_INTERVAL       := 0.7
const PLAYER_ATTACK_INTERVAL := 1.2
const PLAYER_BULLET_DMG      := 4

const DRAW_DURATION    := 8.0
const DRAW_GUIDE_R     := 120.0
const DRAW_COVER_THR   := 0.70
const DRAW_BRUSH_R     := 18.0

const WEAPON_SUBTYPES  := ["atk_speed", "damage", "move_speed", "bullet_bonus"]

const SHAPE_DATA := {
	"circle":   { "color": Color(0.25, 0.55, 1.0),  "bullets": 0, "speed_m": 1.0, "kb_r": 0.9, "hp_base": 80 },
	"triangle": { "color": Color(1.0,  0.3,  0.3),  "bullets": 3, "speed_m": 1.6, "kb_r": 0.3, "hp_base": 35 },
	"square":   { "color": Color(0.3,  1.0,  0.45), "bullets": 4, "speed_m": 0.7, "kb_r": 0.6, "hp_base": 55 },
	"star":     { "color": Color(1.0,  0.85, 0.1),  "bullets": 5, "speed_m": 1.0, "kb_r": 0.1, "hp_base": 25 },
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# フォント
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var jp_font: Font = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ゲーム状態
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var game_state    := "battle"   # "battle" | "drawing" | "game_over"
var elapsed_time  := 0.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# プレイヤー
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var player_hp    := PLAYER_HP_MAX
var player_pos   := Vector2.ZERO
var player_node  : Polygon2D = null
var joy_id              : int   = -1
var joy_origin          := Vector2.ZERO
var joy_vec             := Vector2.ZERO
var player_attack_timer : float = 0.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 仲間
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ally: { shape, hp, max_hp, coating, node:Polygon2D, attack_timer }
var allies : Array[Dictionary] = []
var weapon_stats := { "atk_speed": 1.0, "damage": 1.0, "move_speed": 1.0, "bullet_bonus": 0 }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 敵
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# enemy: { hp, max_hp, pos, node:Polygon2D, kb:Vector2 }
var enemies          : Array[Dictionary] = []
var enemy_spawn_timer := 0.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 弾
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# bullet: { pos, dir:Vector2, traveled, dmg, node:Polygon2D }
var bullets : Array[Dictionary] = []

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# アイテム
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# item: { type:"weapon"|"char", subtype:String, pos, node:Polygon2D }
var items : Array[Dictionary] = []

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画フェーズ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var draw_shape       := "circle"
var draw_timer       := 0.0
var coating_count    := 0
var coating_power    := 0
var trace_pts        : Array[Vector2] = []
var sample_pts       : Array[Vector2] = []
var draw_touch_id    : int = -1

var draw_layer    : CanvasLayer = null
var trace_line    : Line2D      = null
var guide_line    : Line2D      = null
var guide_glow    : Line2D      = null
var coating_lbl   : Label       = null
var draw_timer_lbl: Label       = null
var cov_lbl       : Label       = null
var shape_btn_row : Array[Button] = []
var confirm_btn   : Button         = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var ui_layer      : CanvasLayer = null
var hp_lbl        : Label       = null
var time_lbl      : Label       = null
var ally_lbl      : Label       = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 初期化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _ready() -> void:
	player_pos = Vector2(W * 0.5, H * 0.6)
	jp_font = load("res://fonts/jp_font.ttf")

	# 背景は Node2D に直接・最初に追加（最背面に描画される）
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.14)
	bg.size = Vector2(W, H)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_ui()
	_build_draw_layer()
	_build_player()
	_add_ally("triangle", 1)

func _build_player() -> void:
	player_node = Polygon2D.new()
	player_node.polygon = _make_ngon(5, PLAYER_R)
	player_node.color = Color(1.0, 1.0, 1.0)
	player_node.position = player_pos
	add_child(player_node)

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	hp_lbl = _make_label("HP: 10", 16, Vector2(12, 12))
	ui_layer.add_child(hp_lbl)

	time_lbl = _make_label("0s", 16, Vector2(W - 70, 12))
	ui_layer.add_child(time_lbl)

	ally_lbl = _make_label("仲間: 0", 14, Vector2(12, 42))
	ui_layer.add_child(ally_lbl)

func _build_draw_layer() -> void:
	draw_layer = CanvasLayer.new()
	draw_layer.layer = 20
	add_child(draw_layer)
	draw_layer.visible = false

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.size = Vector2(W, H)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw_layer.add_child(dim)

	guide_glow = Line2D.new()
	guide_glow.width = 22.0
	guide_glow.default_color = Color(1.0, 1.0, 1.0, 0.15)
	draw_layer.add_child(guide_glow)

	guide_line = Line2D.new()
	guide_line.width = 6.0
	guide_line.default_color = Color(1.0, 1.0, 1.0, 0.65)
	draw_layer.add_child(guide_line)

	trace_line = Line2D.new()
	trace_line.width = 5.0
	trace_line.default_color = Color(0.4, 0.9, 1.0)
	draw_layer.add_child(trace_line)

	draw_timer_lbl = _make_label("8.0", 36, Vector2(W * 0.5 - 28, H * 0.08))
	draw_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	draw_layer.add_child(draw_timer_lbl)

	cov_lbl = _make_label("0%", 22, Vector2(W * 0.5 - 20, H * 0.76))
	cov_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	draw_layer.add_child(cov_lbl)

	coating_lbl = _make_label("×0", 44, Vector2(W * 0.5 - 28, H * 0.81))
	coating_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	draw_layer.add_child(coating_lbl)

	var btn_y := H * 0.05
	var shapes_list := ["circle", "triangle", "square", "star"]
	var labels_list := ["○", "△", "□", "★"]
	for i in range(4):
		var btn := Button.new()
		btn.text = labels_list[i]
		btn.size = Vector2(70, 50)
		btn.position = Vector2(W * 0.5 - 150 + i * 78, btn_y)
		btn.pressed.connect(_on_shape_btn.bind(shapes_list[i]))
		draw_layer.add_child(btn)
		shape_btn_row.append(btn)

	confirm_btn = Button.new()
	confirm_btn.text = "✓"
	confirm_btn.size = Vector2(64, 52)
	confirm_btn.position = Vector2(W - 74, H * 0.05)
	confirm_btn.pressed.connect(_evaluate_lap)
	draw_layer.add_child(confirm_btn)

	if jp_font:
		_apply_font(draw_layer, jp_font)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# メインループ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _process(delta: float) -> void:
	match game_state:
		"battle":
			elapsed_time += delta
			_update_player(delta)
			_update_enemies(delta)
			_update_allies(delta)
			_update_bullets(delta)
			_update_items()
			_spawn_enemies(delta)
			_update_ui()
		"drawing":
			_update_drawing(delta)
		"game_over":
			pass

func _update_player(delta: float) -> void:
	if joy_vec.length_squared() > 0.01:
		var spd: float = PLAYER_SPEED * (weapon_stats["move_speed"] as float)
		player_pos += joy_vec * spd * delta
		player_pos.x = clampf(player_pos.x, PLAYER_R, W - PLAYER_R)
		player_pos.y = clampf(player_pos.y, PLAYER_R, H - PLAYER_R)
	if player_node:
		player_node.position = player_pos

	player_attack_timer -= delta
	if player_attack_timer <= 0.0:
		player_attack_timer = PLAYER_ATTACK_INTERVAL
		_player_shoot()

func _player_shoot() -> void:
	var nearest := _nearest_enemy(player_pos)
	if not nearest.is_empty():
		var dir: Vector2 = ((nearest["pos"] as Vector2) - player_pos).normalized()
		_fire_bullet(player_pos, dir, PLAYER_BULLET_DMG)
		_fire_bullet(player_pos, dir.rotated(PI * 0.5), PLAYER_BULLET_DMG)
		_fire_bullet(player_pos, dir.rotated(-PI * 0.5), PLAYER_BULLET_DMG)
	else:
		for i in range(4):
			var a: float = float(i) / 4.0 * TAU
			_fire_bullet(player_pos, Vector2(cos(a), sin(a)), PLAYER_BULLET_DMG)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 敵
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _spawn_enemies(delta: float) -> void:
	enemy_spawn_timer -= delta
	if enemy_spawn_timer > 0.0: return
	var interval := maxf(0.8, ENEMY_SPAWN_BASE - elapsed_time * 0.03)
	enemy_spawn_timer = interval
	_spawn_one_enemy()

func _spawn_one_enemy() -> void:
	var pos: Vector2 = _random_edge_pos()
	var hp: int      = int(ENEMY_HP_BASE + elapsed_time * 0.8)
	var spd: float   = ENEMY_SPEED_BASE + elapsed_time * 0.5

	var node := Polygon2D.new()
	node.polygon = _make_ngon(3, ENEMY_R)
	node.color = Color(0.9, 0.25, 0.35)
	node.position = pos
	add_child(node)

	enemies.append({ "hp": hp, "max_hp": hp, "pos": pos, "speed": spd, "node": node, "kb": Vector2.ZERO })

func _update_enemies(delta: float) -> void:
	var to_remove : Array[int] = []
	for i in range(enemies.size()):
		var e := enemies[i]
		e["kb"] = (e["kb"] as Vector2).lerp(Vector2.ZERO, delta * 5.0)
		var dir: Vector2 = (player_pos - (e["pos"] as Vector2)).normalized()
		e["pos"] = (e["pos"] as Vector2) + dir * (e["speed"] as float) * delta + (e["kb"] as Vector2) * delta
		e["node"].position = e["pos"] as Vector2

		# プレイヤーとの衝突
		if (e["pos"] as Vector2).distance_to(player_pos) < PLAYER_R + ENEMY_R:
			player_hp -= ENEMY_DAMAGE
			to_remove.append(i)
			e["node"].queue_free()
			if player_hp <= 0:
				_game_over()
				return
			continue

		# 仲間との衝突
		var hit_ally : Dictionary = {}
		for a in allies:
			if (e["pos"] as Vector2).distance_to(a["node"].position) < ALLY_BASE_SIZE + ENEMY_R:
				var kb_dir: Vector2 = ((e["pos"] as Vector2) - a["node"].position).normalized()
				e["kb"] = (e["kb"] as Vector2) + kb_dir * 180.0
				a["hp"] -= 8
				hit_ally = a
				break
		if not hit_ally.is_empty() and hit_ally["hp"] <= 0:
			_remove_ally(hit_ally)

	for i in range(to_remove.size() - 1, -1, -1):
		enemies.remove_at(to_remove[i])

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 仲間
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _update_allies(delta: float) -> void:
	var circles : Array[Dictionary] = []
	var mids    : Array[Dictionary] = []
	var stars_a : Array[Dictionary] = []

	for a in allies:
		match a["shape"]:
			"circle":   circles.append(a)
			"triangle", "square": mids.append(a)
			"star":     stars_a.append(a)

	_position_ring(circles, ALLY_OUTER_R, delta, 0.0)
	_position_ring(mids,    ALLY_MID_R,   delta, PI / 3.0)
	_position_ring(stars_a, ALLY_INNER_R, delta, PI * 2.0 / 3.0)

	for a in allies:
		a["attack_timer"] = (a["attack_timer"] as float) - delta
		if (a["attack_timer"] as float) <= 0.0:
			_ally_attack(a)
			a["attack_timer"] = ATTACK_INTERVAL / (weapon_stats["atk_speed"] as float)

func _position_ring(ring: Array[Dictionary], radius: float, delta: float, angle_offset: float = 0.0) -> void:
	if ring.is_empty(): return
	for i in range(ring.size()):
		var angle: float = float(i) / float(ring.size()) * TAU + angle_offset
		var target := player_pos + Vector2(cos(angle), sin(angle)) * radius
		var spd: float = (SHAPE_DATA[ring[i]["shape"] as String]["speed_m"] as float) * 300.0
		var cur_pos: Vector2 = ring[i]["node"].position
		var dist: float      = cur_pos.distance_to(target)
		var t: float         = minf(1.0, delta * spd / dist) if dist > 1.0 else 1.0
		ring[i]["node"].position = cur_pos.lerp(target, t)

func _ally_attack(a: Dictionary) -> void:
	var shape: String    = a["shape"]
	var bullet_count: int = (SHAPE_DATA[shape]["bullets"] as int) + (weapon_stats["bullet_bonus"] as int)
	if bullet_count <= 0: return

	var ally_pos: Vector2 = a["node"].position
	var nearest := _nearest_enemy(ally_pos)
	if nearest.is_empty(): return

	var dmg: int          = int(BULLET_DMG_BASE * (weapon_stats["damage"] as float))
	var base_dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()

	if shape == "star":
		for i in range(bullet_count):
			var angle: float = float(i) / float(bullet_count) * TAU
			_fire_bullet(ally_pos, Vector2(cos(angle), sin(angle)), dmg)
	else:
		var spread: float = 0.15 * (bullet_count - 1)
		for i in range(bullet_count):
			var offset: float = -spread + spread * 2.0 * float(i) / maxf(1.0, float(bullet_count - 1))
			var dir: Vector2  = base_dir.rotated(offset)
			_fire_bullet(ally_pos, dir, dmg)

func _fire_bullet(from: Vector2, dir: Vector2, dmg: int) -> void:
	var node := Polygon2D.new()
	node.polygon = _make_ngon(6, BULLET_R)
	node.color = Color(1.0, 0.95, 0.4)
	node.position = from
	add_child(node)
	bullets.append({ "pos": from, "dir": dir, "traveled": 0.0, "dmg": dmg, "node": node })

func _remove_ally(a: Dictionary) -> void:
	a["node"].queue_free()
	allies.erase(a)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 弾
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _update_bullets(delta: float) -> void:
	var to_remove : Array[int] = []
	for i in range(bullets.size()):
		var b := bullets[i]
		b["pos"] = (b["pos"] as Vector2) + (b["dir"] as Vector2) * BULLET_SPEED * delta
		b["traveled"] = (b["traveled"] as float) + BULLET_SPEED * delta
		b["node"].position = b["pos"] as Vector2

		var hit := false
		for e in enemies:
			if (b["pos"] as Vector2).distance_to(e["pos"] as Vector2) < ENEMY_R + BULLET_R:
				e["hp"] -= b["dmg"]
				hit = true
				break

		if hit or (b["traveled"] as float) >= BULLET_RANGE:
			b["node"].queue_free()
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		bullets.remove_at(to_remove[i])

	# 死亡した敵をまとめて処理（ループ外でerase）
	var dead : Array[Dictionary] = []
	for e in enemies:
		if e["hp"] <= 0:
			dead.append(e)
	for e in dead:
		_on_enemy_death(e)

func _on_enemy_death(e: Dictionary) -> void:
	if randf() < ITEM_DROP_CHANCE:
		_spawn_item(e["pos"] as Vector2)
	e["node"].queue_free()
	enemies.erase(e)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# アイテム
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _spawn_item(pos: Vector2) -> void:
	var is_char := randf() < CHAR_ITEM_RATIO
	var item_type := "char" if is_char else "weapon"
	var subtype := ""
	if is_char:
		subtype = ["circle", "triangle", "square", "star"][randi() % 4]
	else:
		subtype = WEAPON_SUBTYPES[randi() % 4]

	var col := Color(0.7, 0.4, 1.0) if is_char else Color(1.0, 0.55, 0.1)
	var node := Polygon2D.new()
	node.polygon = _make_ngon(4, ITEM_R)
	node.color = col
	node.position = pos
	add_child(node)

	items.append({ "type": item_type, "subtype": subtype, "pos": pos, "node": node })

func _update_items() -> void:
	var to_remove : Array[int] = []
	for i in range(items.size()):
		var it := items[i]
		if player_pos.distance_to(it["pos"] as Vector2) < ITEM_PICKUP_R + PLAYER_R:
			if it["type"] == "weapon":
				_apply_weapon(it["subtype"])
				it["node"].queue_free()
				to_remove.append(i)
			elif it["type"] == "char":
				it["node"].queue_free()
				to_remove.append(i)
				_start_drawing(it["subtype"])
				break
	for i in range(to_remove.size() - 1, -1, -1):
		items.remove_at(to_remove[i])

func _apply_weapon(subtype: String) -> void:
	match subtype:
		"atk_speed":    weapon_stats["atk_speed"]   = (weapon_stats["atk_speed"]   as float) + 0.2
		"damage":       weapon_stats["damage"]       = (weapon_stats["damage"]       as float) + 0.3
		"move_speed":   weapon_stats["move_speed"]   = (weapon_stats["move_speed"]   as float) + 0.15
		"bullet_bonus": weapon_stats["bullet_bonus"] = (weapon_stats["bullet_bonus"] as int)   + 1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画フェーズ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _start_drawing(suggested_shape: String) -> void:
	game_state = "drawing"
	draw_shape = suggested_shape
	draw_timer = DRAW_DURATION
	coating_count = 0
	coating_power = 0
	trace_pts.clear()
	trace_line.clear_points()
	trace_line.modulate = Color.WHITE
	draw_touch_id = -1
	_refresh_draw_guide()
	draw_layer.visible = true

func _on_shape_btn(shape: String) -> void:
	if game_state != "drawing": return
	draw_shape = shape
	trace_pts.clear()
	trace_line.clear_points()
	trace_line.modulate = Color.WHITE
	coating_count = 0
	coating_power = 0
	coating_lbl.text = "×0"
	_refresh_draw_guide()

func _refresh_draw_guide() -> void:
	var cx := W * 0.5
	var cy := H * 0.5
	sample_pts = _Shapes.make_sample_pts(draw_shape, cx, cy, DRAW_GUIDE_R)
	var guide_pts := _Shapes.make_guide_pts(draw_shape, cx, cy, DRAW_GUIDE_R)
	guide_line.clear_points()
	guide_glow.clear_points()
	for p in guide_pts:
		guide_line.add_point(p)
		guide_glow.add_point(p)
	var shape_colors := {
		"circle":   Color(0.5, 0.7, 1.0, 0.8),
		"triangle": Color(1.0, 0.5, 0.5, 0.8),
		"square":   Color(0.4, 1.0, 0.6, 0.8),
		"star":     Color(1.0, 0.9, 0.3, 0.8),
	}
	var sc: Color = shape_colors.get(draw_shape, Color(1, 1, 1, 0.65))
	guide_line.default_color = sc
	guide_glow.default_color = Color(sc.r, sc.g, sc.b, 0.18)

func _update_drawing(delta: float) -> void:
	draw_timer -= delta
	draw_timer_lbl.text = "%.1f" % maxf(0.0, draw_timer)

	if not trace_pts.is_empty() and sample_pts.size() > 0:
		var cov := _calc_coverage(trace_pts, sample_pts)
		cov_lbl.text = "%d%%" % int(cov * 100)
		trace_line.modulate = _cov_color(cov)
	else:
		cov_lbl.text = "0%"

	if draw_timer <= 0.0:
		_end_drawing()

func _cov_color(cov: float) -> Color:
	if cov >= 0.90: return Color(1.0, 1.0, 0.3)   # 黄：PERFECT
	if cov >= 0.75: return Color(0.4, 1.0, 0.9)   # シアン：GREAT
	if cov >= 0.55: return Color(0.4, 0.6, 1.0)   # 青：まあまあ
	if cov >= 0.30: return Color(1.0, 0.65, 0.3)  # 橙：微妙
	return Color(1.0, 0.4, 0.4)                   # 赤：ずれてる

func _end_drawing() -> void:
	draw_layer.visible = false
	game_state = "battle"
	_add_ally(draw_shape, coating_power)

func _add_ally(shape: String, power: int) -> void:
	var data: Dictionary = SHAPE_DATA[shape]
	var hp_base: int     = data["hp_base"]
	var hp: int          = hp_base + power
	var kb_r: float      = data["kb_r"]

	if allies.size() >= MAX_ALLIES:
		var worst := _most_damaged_ally()
		if not worst.is_empty():
			_remove_ally(worst)

	var col := _ally_color(shape, power)
	var sz  := _ally_size(power)
	var node := Polygon2D.new()
	node.polygon = _make_shape_polygon(shape, sz)
	node.color = col
	node.position = player_pos
	add_child(node)

	allies.append({
		"shape": shape, "hp": hp, "max_hp": hp, "coating": power,
		"node": node, "attack_timer": randf_range(0.0, ATTACK_INTERVAL),
		"kb_resist": kb_r
	})

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# タッチ入力
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _input(event: InputEvent) -> void:
	if game_state == "battle":
		_handle_joystick(event)
	elif game_state == "drawing":
		_handle_draw_input(event)

func _handle_joystick(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and joy_id == -1:
			joy_id = event.index
			joy_origin = event.position
			joy_vec = Vector2.ZERO
		elif not event.pressed and event.index == joy_id:
			joy_id = -1
			joy_vec = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == joy_id:
			var delta_v: Vector2 = drag.position - joy_origin
			if delta_v.length() > 10.0:
				joy_vec = delta_v.normalized()
			else:
				joy_vec = Vector2.ZERO


func _handle_draw_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and draw_touch_id == -1:
			draw_touch_id = event.index
			trace_pts.append(event.position)
			trace_line.add_point(event.position)
		elif not event.pressed and event.index == draw_touch_id:
			draw_touch_id = -1
	elif event is InputEventScreenDrag and event.index == draw_touch_id:
		trace_pts.append(event.position)
		trace_line.add_point(event.position)

func _evaluate_lap() -> void:
	if trace_pts.is_empty() or sample_pts.is_empty(): return
	var cov := _calc_coverage(trace_pts, sample_pts)
	trace_pts.clear()
	trace_line.clear_points()
	trace_line.modulate = Color.WHITE
	cov_lbl.text = "0%"

	var gain := 0
	var label := ""
	var col := Color.WHITE
	if cov >= 0.90:
		gain = 35; label = "PERFECT!!"; col = Color(1.0, 1.0, 0.3)
	elif cov >= 0.75:
		gain = 20; label = "GREAT!";    col = Color(0.4, 1.0, 0.9)
	elif cov >= 0.70:
		gain = 10; label = "GOOD";      col = Color(0.5, 0.7, 1.0)
	else:
		label = "MISS..."; col = Color(0.8, 0.4, 0.4)

	if gain > 0:
		coating_count += 1
		coating_power += gain
		coating_lbl.text = "×%d" % coating_count
	_show_lap_flash(label, col)

func _show_lap_flash(label: String, col: Color) -> void:
	var lbl := _make_label(label, 40, Vector2(W * 0.5 - 80, H * 0.5 - 30))
	lbl.add_theme_color_override("font_color", col)
	if jp_font:
		lbl.add_theme_font_override("font", jp_font)
	draw_layer.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tween.tween_callback(lbl.queue_free)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ゲームオーバー
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _game_over() -> void:
	game_state = "game_over"

	var over_lbl := _make_label("GAME OVER", 52, Vector2(W * 0.5 - 130, H * 0.35))
	over_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	ui_layer.add_child(over_lbl)

	var score_lbl := _make_label("%.0f 秒生存" % elapsed_time, 28, Vector2(W * 0.5 - 70, H * 0.48))
	score_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	ui_layer.add_child(score_lbl)

	var retry_btn := Button.new()
	retry_btn.text = "RETRY"
	retry_btn.size = Vector2(180, 60)
	retry_btn.position = Vector2(W * 0.5 - 90, H * 0.58)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	if jp_font:
		retry_btn.add_theme_font_override("font", jp_font)
	retry_btn.add_theme_font_size_override("font_size", 26)
	ui_layer.add_child(retry_btn)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UI 更新
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _update_ui() -> void:
	hp_lbl.text   = "HP: %d" % player_hp
	time_lbl.text = "%.0fs" % elapsed_time
	ally_lbl.text = "仲間: %d / %d" % [allies.size(), MAX_ALLIES]

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ユーティリティ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _calc_coverage(t_pts: Array[Vector2], s_pts: Array[Vector2]) -> float:
	if s_pts.is_empty() or t_pts.is_empty(): return 0.0
	var covered := 0
	for sp in s_pts:
		for tp in t_pts:
			if tp.distance_to(sp) < DRAW_BRUSH_R:
				covered += 1
				break
	return float(covered) / float(s_pts.size())

func _nearest_enemy(from: Vector2) -> Dictionary:
	var best : Dictionary = {}
	var best_d := ATTACK_RANGE
	for e in enemies:
		var d: float = from.distance_to(e["pos"] as Vector2)
		if d < best_d:
			best_d = d
			best = e
	return best  # 空dictの場合は呼び出し元で .is_empty() チェック

func _most_damaged_ally() -> Dictionary:
	var worst: Dictionary = {}
	var worst_ratio: float = 2.0
	for a in allies:
		var ratio: float = float(a["hp"] as int) / float(a["max_hp"] as int)
		if ratio < worst_ratio:
			worst_ratio = ratio
			worst = a
	return worst

func _ally_color(shape: String, coating: int) -> Color:
	var base: Color       = SHAPE_DATA[shape]["color"]
	var brightness: float = 0.35 + minf(0.65, float(coating) * 0.18)
	var col := base * brightness
	# 最大近くは白く光る（白成分を混ぜる）
	if coating >= 4:
		col = col.lerp(Color.WHITE, minf(0.4, float(coating - 3) * 0.1))
	return col

func _ally_size(_coating: int) -> float:
	return ALLY_BASE_SIZE

func _random_edge_pos() -> Vector2:
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(0, W), -20)
		1: return Vector2(randf_range(0, W), H + 20)
		2: return Vector2(-20, randf_range(0, H))
		_: return Vector2(W + 20, randf_range(0, H))

func _make_ngon(n: int, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := float(i) / float(n) * TAU - PI / 2.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

func _make_shape_polygon(shape: String, size: float) -> PackedVector2Array:
	match shape:
		"circle":   return _make_ngon(12, size)
		"triangle": return _make_ngon(3, size)
		"square":   return _make_ngon(4, size)
		"star":
			var pts := PackedVector2Array()
			var inner := size * 0.45
			for i in range(10):
				var a := float(i) / 10.0 * TAU - PI / 2.0
				var d := size if i % 2 == 0 else inner
				pts.append(Vector2(cos(a) * d, sin(a) * d))
			return pts
	return _make_ngon(6, size)

func _make_label(txt: String, font_size: int, pos: Vector2) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.position = pos
	if jp_font:
		lbl.add_theme_font_override("font", jp_font)
	return lbl

func _apply_font(node: Node, font: Font) -> void:
	if node is Label or node is Button:
		node.add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_font(child, font)
