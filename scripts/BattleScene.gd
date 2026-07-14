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

# 召喚獣ドット絵（基本形のみ。進化形は引き続き幾何学図形）
const ALLY_TEX_WATER := preload("res://assets/sprites/ally_water.png")
const ALLY_TEX_FIRE  := preload("res://assets/sprites/ally_fire.png")
const ALLY_TEX_EARTH := preload("res://assets/sprites/ally_earth.png")
const ALLY_SPRITE_TEXTURES := {
	"circle":   ALLY_TEX_WATER,
	"triangle": ALLY_TEX_FIRE,
	"square":   ALLY_TEX_EARTH,
}
# 各画像の余白を除いた実キャラ部分のキャンバス比率（スケール計算用）
const ALLY_SPRITE_CONTENT_RATIO := {
	"circle":   0.90,
	"triangle": 0.92,
	"square":   0.94,
}

const ENEMY_SPAWN_BASE: float = 2.5
const ENEMY_SPEED_BASE: float = 46.0  # 2026-07-16：初期の速すぎる「追いかけっこ」感を抑えるため75→55→46にさらに減速
const ENEMY_HP_BASE:    int   = 30
const ENEMY_R:          float = 14.0  # デフォルト（後方互換）
const ENEMY_DAMAGE:     int   = 1

const ENEMY_TYPES := {
	"shard":      { "sides": 3, "radius": 12.0, "color": Color(1.0, 0.2,  0.35), "hp_m": 0.7,  "spd_m": 1.35 },
	"fracture":   { "sides": 5, "radius": 18.0, "color": Color(1.0, 0.5,  0.1),  "hp_m": 2.0,  "spd_m": 0.85 },
	"void_mark":  { "sides": 6, "radius": 26.0, "color": Color(0.75, 0.2, 1.0),  "hp_m": 4.0,  "spd_m": 0.5  },
}

# 敵ドット絵（VS基準：小さく・簡素・大量湧きでも視認性重視）
const ENEMY_TEX_SHARD     := preload("res://assets/sprites/enemy_shard.png")
const ENEMY_TEX_FRACTURE  := preload("res://assets/sprites/enemy_fracture.png")
const ENEMY_TEX_VOID_MARK := preload("res://assets/sprites/enemy_void_mark.png")
const ENEMY_SPRITE_TEXTURES := {
	"shard":     ENEMY_TEX_SHARD,
	"fracture":  ENEMY_TEX_FRACTURE,
	"void_mark": ENEMY_TEX_VOID_MARK,
}
const ENEMY_SPRITE_CONTENT_RATIO := {
	"shard":     0.70,
	"fracture":  0.80,
	"void_mark": 0.83,
}

const FRAGMENT_THRESHOLD := 5
const CHAR_ITEM_CHANCE  := 0.15
const ITEM_PICKUP_R    := 38.0
const ITEM_R           := 14.0
const FRAGMENT_R       := 7.0

const BULLET_SPEED     := 370.0
const BULLET_RANGE     := 280.0
const BULLET_R         := 4.0
const BULLET_DMG_BASE  := 5
const SUMMON_BURST_R      := 100.0
const SUMMON_BURST_DMG_BASE := 12
const ATTACK_RANGE          := 240.0
const ATTACK_INTERVAL       := 0.7
const PLAYER_ATTACK_INTERVAL := 1.2
const PLAYER_BULLET_DMG      := 4

const DRAW_DURATION    := 8.0
const DRAW_GUIDE_R     := 120.0
const DRAW_COVER_THR   := 0.70
const DRAW_BRUSH_R     := 18.0

const WEAPON_SUBTYPES  := ["atk_speed", "damage", "move_speed"]

const SHAPE_DATA := {
	# 役割：水=速攻・機動／火=重火力・鈍足／土=盾・耐久（2026-07-12 属性名と役割の対応を再整理。「角の数=弾の数」ルールは廃止）
	"circle":        { "color": Color(0.3,  0.7,  1.0),  "bullets": 3,  "speed_m": 1.6, "kb_r": 0.3, "hp_base": 35  },
	"triangle":      { "color": Color(1.0,  0.35, 0.35), "bullets": 4,  "speed_m": 0.7, "kb_r": 0.6, "hp_base": 55  },
	"square":        { "color": Color(0.85, 0.6,  0.2),  "bullets": 0,  "speed_m": 1.0, "kb_r": 0.9, "hp_base": 80  },
	# 進化形態（2体合体で誕生）
	"double_circle": { "color": Color(0.2,  0.6,  1.0),  "bullets": 6,  "speed_m": 1.6, "kb_r": 0.3, "hp_base": 80  },
	"hexagram":      { "color": Color(1.0,  0.2,  0.2),  "bullets": 8,  "speed_m": 0.7, "kb_r": 0.6, "hp_base": 120 },
	"octagram":      { "color": Color(0.75, 0.45, 0.1),  "bullets": 0,  "speed_m": 0.7, "kb_r": 1.5, "hp_base": 200 },
}

# 合体進化マップ（このキーにある形だけが合体できる）
const EVOLVE_MAP := {
	"circle":   "double_circle",
	"triangle": "hexagram",
	"square":   "octagram",
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# フォント
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var jp_font: Font = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ゲーム状態
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var game_state    := "battle"   # "battle" | "drawing" | "upgrade_select" | "game_over"
var elapsed_time  := 0.0
var best_time     := 0.0
var hints_shown   := {}         # 表示済みヒントのフラグ

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# プレイヤー
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var player_hp    := PLAYER_HP_MAX
var player_pos   := Vector2.ZERO
var player_node  : Sprite2D = null
var camera       : Camera2D  = null
var player_trail : Array[Vector2] = []
var shake_power  := 0.0
var particles    : Array[Dictionary] = []
var joy_id              : int   = -1
var joy_origin          := Vector2.ZERO
var joy_vec             := Vector2.ZERO
var player_attack_timer : float = 0.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 仲間
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ally: { shape, hp, max_hp, coating, node:Polygon2D, attack_timer }
var allies : Array[Dictionary] = []
var weapon_stats := { "atk_speed": 1.0, "damage": 1.0, "move_speed": 1.0 }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 敵
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# enemy: { hp, max_hp, pos, node:Polygon2D, kb:Vector2 }
var enemies          : Array[Dictionary] = []
var enemy_spawn_timer := 0.0
var next_wave_time    := 60.0
var wave_count        := 0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 弾
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# bullet: { pos, dir:Vector2, traveled, dmg, node:Polygon2D }
var bullets : Array[Dictionary] = []

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# アイテム
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# item: { type:"fragment"|"char", subtype:String, pos, node:Polygon2D }
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
var guide_base_color := Color.WHITE
var coating_lbl   : Label       = null
var draw_timer_lbl: Label       = null
var cov_lbl       : Label       = null
var confirm_btn   : Button         = null
var summon_result_nodes : Array[Node] = []

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var ui_layer      : CanvasLayer = null
var hp_lbl        : Label       = null
var time_lbl      : Label       = null
var ally_lbl      : Label       = null
var frag_lbl      : Label       = null
var hp_bar_fill   : ColorRect   = null
var hp_bar_w      := 130.0
var fragment_count := 0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 初期化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _ready() -> void:
	player_pos = Vector2(W * 0.5, H * 0.6)
	jp_font = load("res://fonts/jp_font.ttf")
	_load_save()

	# カメラ（プレイヤー追従・無限フィールド）
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	# グロー環境
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.10)
	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity  = 1.6
	env.glow_strength   = 1.2
	env.glow_bloom      = 0.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(0, 0.5)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.4)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	_build_ui()
	_build_draw_layer()
	_build_player()
	_add_ally("triangle", 1, false)

func _build_player() -> void:
	player_node = Sprite2D.new()
	player_node.texture = preload("res://assets/sprites/player.png")
	var tex_size: Vector2 = player_node.texture.get_size()
	# 画像は1024x1024キャンバス中央に約59%サイズでキャラが描かれている（周囲は透明余白）
	var content_px: float = max(tex_size.x, tex_size.y) * 0.59
	var target_px := PLAYER_R * 2.8
	player_node.scale = Vector2.ONE * (target_px / content_px)
	player_node.position = player_pos
	add_child(player_node)

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	var stats_panel := _make_glow_panel(Vector2(6, 6), Vector2(150, 92), Color(0.5, 0.8, 1.0, 0.5))
	ui_layer.add_child(stats_panel)

	var time_panel := _make_glow_panel(Vector2(W - 84, 6), Vector2(78, 34), Color(1.0, 0.9, 0.5, 0.5))
	ui_layer.add_child(time_panel)

	hp_lbl = _make_label("HP: 10", 16, Vector2(14, 12))
	ui_layer.add_child(hp_lbl)

	var hp_bar_bg := ColorRect.new()
	hp_bar_bg.color = Color(0.15, 0.05, 0.05, 0.8)
	hp_bar_bg.position = Vector2(14, 34)
	hp_bar_bg.size = Vector2(hp_bar_w, 8)
	ui_layer.add_child(hp_bar_bg)

	hp_bar_fill = ColorRect.new()
	hp_bar_fill.color = Color(1.0, 0.35, 0.35, 0.95)
	hp_bar_fill.position = Vector2(14, 34)
	hp_bar_fill.size = Vector2(hp_bar_w, 8)
	ui_layer.add_child(hp_bar_fill)

	time_lbl = _make_label("0s", 16, Vector2(W - 76, 13))
	ui_layer.add_child(time_lbl)

	ally_lbl = _make_label("仲間: 0", 14, Vector2(14, 50))
	ui_layer.add_child(ally_lbl)

	frag_lbl = _make_label("欠片: 0/%d" % FRAGMENT_THRESHOLD, 14, Vector2(14, 72))
	ui_layer.add_child(frag_lbl)

func _make_glow_panel(pos: Vector2, size: Vector2, border_col: Color) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.09, 0.72)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = border_col
	sb.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.35)
	sb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", sb)
	return panel

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

	# 背景の装飾リング（ゆっくり逆回転しあう2本。描画シーンを「魔法陣」らしくリッチにする）
	var deco_outer := Line2D.new()
	deco_outer.width = 2.0
	deco_outer.default_color = Color(0.6, 0.8, 1.0, 0.25)
	for p in _make_ring_points(DRAW_GUIDE_R * 1.55, 1.0):
		deco_outer.add_point(p)
	deco_outer.position = Vector2(W * 0.5, H * 0.5)
	draw_layer.add_child(deco_outer)
	var deco_outer_tw := deco_outer.create_tween()
	deco_outer_tw.set_loops()
	deco_outer_tw.tween_property(deco_outer, "rotation", TAU, 22.0).from(0.0)

	var deco_inner := Line2D.new()
	deco_inner.width = 2.0
	deco_inner.default_color = Color(0.6, 0.8, 1.0, 0.18)
	for p in _make_ring_points(DRAW_GUIDE_R * 1.3, 1.0):
		deco_inner.add_point(p)
	deco_inner.position = Vector2(W * 0.5, H * 0.5)
	draw_layer.add_child(deco_inner)
	var deco_inner_tw := deco_inner.create_tween()
	deco_inner_tw.set_loops()
	deco_inner_tw.tween_property(deco_inner, "rotation", -TAU, 16.0).from(0.0)

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
	trace_line.default_color = Color.WHITE  # modulate で色を制御するので白ベース
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
			_update_particles(delta)
		"drawing":
			_update_drawing(delta)
		"game_over":
			pass

func _update_player(delta: float) -> void:
	if joy_vec.length_squared() > 0.01:
		var spd: float = PLAYER_SPEED * (weapon_stats["move_speed"] as float)
		player_pos += joy_vec * spd * delta
	if player_node:
		player_node.position = player_pos
	if camera:
		var shake_offset := Vector2.ZERO
		if shake_power > 0.0:
			shake_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_power
			shake_power  = maxf(0.0, shake_power - 300.0 * delta)
		camera.position = player_pos + shake_offset
	# 軌跡更新（最大20点）
	if joy_vec.length_squared() > 0.01:
		player_trail.append(player_pos)
		if player_trail.size() > 20:
			player_trail.pop_front()
	elif not player_trail.is_empty():
		player_trail.pop_front()
	queue_redraw()

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
	# ウェーブラッシュ（60秒ごと）
	if elapsed_time >= next_wave_time:
		next_wave_time += 60.0
		wave_count += 1
		_trigger_wave()

	# 通常スポーン
	enemy_spawn_timer -= delta
	if enemy_spawn_timer > 0.0: return
	var interval := maxf(0.8, ENEMY_SPAWN_BASE - elapsed_time * 0.03)
	enemy_spawn_timer = interval
	_spawn_one_enemy()

func _trigger_wave() -> void:
	var count := 6 + wave_count * 2
	for _i in range(count):
		_spawn_one_enemy()
	_show_wave_flash(wave_count)

func _pick_enemy_type() -> String:
	var r := randf()
	if elapsed_time >= 120.0:
		if r < 0.25: return "void_mark"
		if r < 0.60: return "fracture"
		return "shard"
	elif elapsed_time >= 60.0:
		if r < 0.40: return "fracture"
		return "shard"
	return "shard"

func _spawn_one_enemy() -> void:
	var pos: Vector2  = _random_edge_pos()
	var etype: String = _pick_enemy_type()
	var edata: Dictionary = ENEMY_TYPES[etype]
	var hp: int   = int((ENEMY_HP_BASE + elapsed_time * 0.8) * (edata["hp_m"] as float))
	var spd: float = (ENEMY_SPEED_BASE + elapsed_time * 0.5) * (edata["spd_m"] as float)
	var r: float  = edata["radius"] as float

	var node := Sprite2D.new()
	node.texture = ENEMY_SPRITE_TEXTURES[etype]
	var tex_size: Vector2 = node.texture.get_size()
	var content_ratio: float = ENEMY_SPRITE_CONTENT_RATIO[etype] as float
	var content_px: float = max(tex_size.x, tex_size.y) * content_ratio
	node.scale = Vector2.ONE * ((r * 2.2) / content_px)
	node.position = pos
	add_child(node)

	enemies.append({ "hp": hp, "max_hp": hp, "pos": pos, "speed": spd, "radius": r, "node": node, "kb": Vector2.ZERO, "color": edata["color"] as Color, "flash": 0.0 })

func _update_enemies(delta: float) -> void:
	var to_remove : Array[int] = []
	for i in range(enemies.size()):
		var e := enemies[i]
		e["kb"] = (e["kb"] as Vector2).lerp(Vector2.ZERO, delta * 5.0)
		# ヒットフラッシュ
		var flash_t: float = e["flash"] as float
		if flash_t > 0.0:
			e["flash"] = maxf(0.0, flash_t - delta)
			(e["node"] as Node2D).modulate = Color(2.2, 2.2, 2.2) if flash_t > 0.06 else Color.WHITE
		# 敵同士のセパレーション（群れが重ならないように押し離す）
		var sep := Vector2.ZERO
		for other in enemies:
			if other == e: continue
			var diff: Vector2 = (e["pos"] as Vector2) - (other["pos"] as Vector2)
			var min_d: float  = (e["radius"] as float) + (other["radius"] as float) + 4.0
			var d: float      = diff.length()
			if d < min_d and d > 0.5:
				sep += diff.normalized() * (min_d - d)
		var dir: Vector2 = (player_pos - (e["pos"] as Vector2)).normalized()
		e["pos"] = (e["pos"] as Vector2) + (dir * (e["speed"] as float) + sep * 3.0) * delta + (e["kb"] as Vector2) * delta
		e["node"].position = e["pos"] as Vector2

		# プレイヤーとの衝突
		if (e["pos"] as Vector2).distance_to(player_pos) < PLAYER_R + (e["radius"] as float):
			player_hp -= ENEMY_DAMAGE
			shake_power = 20.0
			Sfx.play_damage()
			to_remove.append(i)
			e["node"].queue_free()
			if player_hp <= 0:
				Sfx.play_game_over()
				_game_over()
				return
			continue

		# 仲間との衝突
		var hit_ally : Dictionary = {}
		for a in allies:
			if (e["pos"] as Vector2).distance_to(a["node"].position) < ALLY_BASE_SIZE + (e["radius"] as float):
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
			"circle", "double_circle":                    circles.append(a)
			"triangle", "square", "hexagram", "octagram": mids.append(a)
			"star", "decagram":                           stars_a.append(a)

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
		var spd: float = (SHAPE_DATA[ring[i]["shape"] as String]["speed_m"] as float) * 195.0  # 2026-07-16：追従速度を300→230→195にさらに減速
		var cur_pos: Vector2 = ring[i]["node"].position
		var dist: float      = cur_pos.distance_to(target)
		var t: float         = minf(1.0, delta * spd / dist) if dist > 1.0 else 1.0
		ring[i]["node"].position = cur_pos.lerp(target, t)

func _ally_attack(a: Dictionary) -> void:
	var shape: String    = a["shape"]
	var bullet_count: int = SHAPE_DATA[shape]["bullets"] as int
	if bullet_count <= 0: return

	var ally_pos: Vector2 = a["node"].position
	var nearest := _nearest_enemy(ally_pos)
	if nearest.is_empty(): return
	Sfx.play_shoot()

	var dmg: int          = int(BULLET_DMG_BASE * (weapon_stats["damage"] as float))
	var base_dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()
	var bullet_col: Color = SHAPE_DATA[shape]["color"]

	var spread: float = 0.15 * (bullet_count - 1)
	for i in range(bullet_count):
		var offset: float = -spread + spread * 2.0 * float(i) / maxf(1.0, float(bullet_count - 1))
		var dir: Vector2  = base_dir.rotated(offset)
		_fire_bullet(ally_pos, dir, dmg, bullet_col)

func _fire_bullet(from: Vector2, dir: Vector2, dmg: int, col: Color = Color(1.0, 1.0, 0.75)) -> void:
	var node := Node2D.new()
	node.position = from

	var glow := Polygon2D.new()
	glow.polygon = _make_ngon(10, BULLET_R * 2.6)
	glow.color = Color(col.r, col.g, col.b, 0.3)
	node.add_child(glow)

	var rune := Polygon2D.new()
	rune.polygon = _make_star_pts(4, BULLET_R * 1.9, 0.35)
	rune.color = col
	node.add_child(rune)

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
		b["node"].rotation += delta * 16.0

		var hit := false
		for e in enemies:
			if (b["pos"] as Vector2).distance_to(e["pos"] as Vector2) < (e["radius"] as float) + BULLET_R:
				e["hp"] -= b["dmg"]
				e["flash"] = 0.12
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
	Sfx.play_enemy_die()
	_spawn_death_particles(e["pos"] as Vector2, e["color"] as Color, e["radius"] as float)
	_spawn_fragment(e["pos"] as Vector2)
	if randf() < CHAR_ITEM_CHANCE:
		_spawn_char_item((e["pos"] as Vector2) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
	e["node"].queue_free()
	enemies.erase(e)

func _spawn_death_particles(pos: Vector2, col: Color, r: float) -> void:
	for _i in range(6):
		var angle := randf() * TAU
		var spd   := randf_range(60.0, 160.0)
		var node  := Polygon2D.new()
		node.polygon = _make_ngon(3, r * 0.28)
		node.color   = col
		node.position = pos
		add_child(node)
		particles.append({ "node": node, "vel": Vector2(cos(angle), sin(angle)) * spd, "life": 1.0 })

func _update_particles(delta: float) -> void:
	var dead: Array[int] = []
	for i in range(particles.size()):
		var p := particles[i]
		p["life"] = (p["life"] as float) - delta * 1.8
		if (p["life"] as float) <= 0.0:
			(p["node"] as Polygon2D).queue_free()
			dead.append(i)
		else:
			var n := p["node"] as Polygon2D
			n.position += (p["vel"] as Vector2) * delta
			n.modulate.a = p["life"] as float
	for i in range(dead.size() - 1, -1, -1):
		particles.remove_at(dead[i])

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# アイテム
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _spawn_fragment(pos: Vector2) -> void:
	var node := _make_rune_pickup(Color(0.6, 0.85, 1.0), FRAGMENT_R, 4, 0.4, 3.0)
	node.position = pos
	add_child(node)
	items.append({ "type": "fragment", "subtype": "", "pos": pos, "node": node })

func _spawn_char_item(pos: Vector2) -> void:
	var subtype: String = ["circle", "triangle", "square"][randi() % 3]
	var node := _make_rune_pickup(Color(0.7, 0.4, 1.0), ITEM_R, 6, 0.45, 5.0)
	node.position = pos
	add_child(node)
	items.append({ "type": "char", "subtype": subtype, "pos": pos, "node": node })
	_show_hint("char_item", "図形を描いて仲間を召喚！", Vector2(W * 0.5 - 100, H * 0.25))

# 弾と共通の「ルーン＋グロー」言語でアイテムを表現（欠片=控えめ・キャラアイテム=豪華に）
func _make_rune_pickup(col: Color, r: float, star_points: int, inner_ratio: float, spin_speed: float) -> Node2D:
	var node := Node2D.new()

	var glow := Polygon2D.new()
	glow.polygon = _make_ngon(10, r * 2.0)
	glow.color = Color(col.r, col.g, col.b, 0.3)
	node.add_child(glow)

	var rune := Polygon2D.new()
	rune.polygon = _make_star_pts(star_points, r, inner_ratio)
	rune.color = col
	node.add_child(rune)

	var tw := node.create_tween()
	tw.set_loops()
	tw.tween_property(node, "rotation", TAU, spin_speed).from(0.0)

	return node

func _update_items() -> void:
	var to_remove : Array[int] = []
	for i in range(items.size()):
		var it := items[i]
		if player_pos.distance_to(it["pos"] as Vector2) < ITEM_PICKUP_R + PLAYER_R:
			if it["type"] == "fragment":
				Sfx.play_item()
				it["node"].queue_free()
				to_remove.append(i)
				fragment_count += 1
				if fragment_count >= FRAGMENT_THRESHOLD:
					fragment_count -= FRAGMENT_THRESHOLD
					_start_upgrade_select()
				break
			elif it["type"] == "char":
				Sfx.play_item()
				it["node"].queue_free()
				to_remove.append(i)
				_start_drawing(it["subtype"])
				break
	for i in range(to_remove.size() - 1, -1, -1):
		items.remove_at(to_remove[i])

func _start_upgrade_select() -> void:
	game_state = "upgrade_select"
	# ランダム3択（重複なし）
	var pool := WEAPON_SUBTYPES.duplicate()
	pool.shuffle()
	var choices: Array[String] = []
	for c in pool.slice(0, 3): choices.append(c as String)

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	# 暗幕
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size  = Vector2(W, H)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)

	var title := _make_label("パワーアップ選択", 22, Vector2(W * 0.5 - 90, H * 0.18))
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	layer.add_child(title)

	var labels := {
		"atk_speed":  ["攻撃速度アップ", "+20% 攻撃速度"],
		"damage":     ["ダメージアップ", "+30% 弾ダメージ"],
		"move_speed": ["移動速度アップ", "+15% 移動速度"],
	}
	var accent_cols := {
		"atk_speed":  Color(0.4, 1.0, 1.0),
		"damage":     Color(1.0, 0.45, 0.3),
		"move_speed": Color(0.5, 1.0, 0.6),
	}
	var card_w := 160.0
	var gap    := 16.0
	var total  := card_w * 3.0 + gap * 2.0
	var start_x := (W - total) * 0.5

	for ci in range(choices.size()):
		var ch    := choices[ci] as String
		var info  := labels[ch] as Array
		var accent: Color = accent_cols[ch] as Color
		var cx    := start_x + ci * (card_w + gap)
		var cy    := H * 0.30

		var card := Button.new()
		card.size = Vector2(card_w, 180)
		card.position = Vector2(cx, cy)
		card.text = ""
		if jp_font:
			card.add_theme_font_override("font", jp_font)
		card.add_theme_font_size_override("font_size", 14)

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.05, 0.11, 0.9)
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(2)
		sb.border_color = accent
		sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.45)
		sb.shadow_size = 10
		card.add_theme_stylebox_override("normal", sb)
		var sb_hover := sb.duplicate() as StyleBoxFlat
		sb_hover.bg_color = Color(0.1, 0.1, 0.18, 0.95)
		card.add_theme_stylebox_override("hover", sb_hover)
		card.add_theme_stylebox_override("pressed", sb_hover)
		card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		layer.add_child(card)

		var icon := Polygon2D.new()
		icon.polygon = _make_star_pts(4, 20.0, 0.4)
		icon.color = accent
		icon.position = Vector2(cx + card_w * 0.5, cy + 40)
		layer.add_child(icon)
		var icon_tw := icon.create_tween()
		icon_tw.set_loops()
		icon_tw.tween_property(icon, "rotation", TAU, 4.0).from(0.0)

		var head := _make_label(info[0] as String, 15, Vector2(cx + 10, cy + 78))
		head.custom_minimum_size = Vector2(card_w - 20, 40)
		head.autowrap_mode = TextServer.AUTOWRAP_WORD
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_theme_color_override("font_color", accent)
		layer.add_child(head)

		var desc := _make_label(info[1] as String, 13, Vector2(cx + 10, cy + 130))
		desc.custom_minimum_size = Vector2(card_w - 20, 30)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		layer.add_child(desc)

		card.pressed.connect(func():
			_apply_weapon(ch)
			layer.queue_free()
			game_state = "battle"
		)

func _apply_weapon(subtype: String) -> void:
	match subtype:
		"atk_speed":    weapon_stats["atk_speed"]   = (weapon_stats["atk_speed"]   as float) + 0.2
		"damage":       weapon_stats["damage"]       = (weapon_stats["damage"]       as float) + 0.3
		"move_speed": weapon_stats["move_speed"] = (weapon_stats["move_speed"] as float) + 0.15

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
	guide_line.visible = true
	guide_glow.visible = true
	trace_line.visible = true
	draw_timer_lbl.visible = true
	cov_lbl.visible = true
	coating_lbl.visible = true
	confirm_btn.visible = true
	_refresh_draw_guide()
	draw_layer.visible = true

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
		"square":   Color(0.85, 0.6, 0.2, 0.8),
	}
	var sc: Color = shape_colors.get(draw_shape, Color(1, 1, 1, 0.65))
	guide_base_color = sc
	_apply_guide_intensity()

func _apply_guide_intensity() -> void:
	# 周回を重ねるほどガイド自体が明るく・太くなり、強くなっていく実感を描画中に出す
	var boost := clampf(float(coating_count) * 0.15, 0.0, 1.0)
	guide_line.default_color = guide_base_color.lerp(Color.WHITE, boost)
	guide_line.width = 6.0 + boost * 8.0
	guide_glow.default_color = Color(guide_base_color.r, guide_base_color.g, guide_base_color.b, 0.18 + boost * 0.35)
	guide_glow.width = 22.0 + boost * 24.0

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
		_show_summon_result()

func _cov_color(cov: float) -> Color:
	if cov >= 0.90: return Color(1.0, 1.0, 0.3)   # 黄：PERFECT
	if cov >= 0.75: return Color(0.4, 1.0, 0.9)   # シアン：GREAT
	if cov >= 0.55: return Color(0.4, 0.6, 1.0)   # 青：まあまあ
	if cov >= 0.30: return Color(1.0, 0.65, 0.3)  # 橙：微妙
	return Color(1.0, 0.4, 0.4)                   # 赤：ずれてる

func _show_summon_result() -> void:
	game_state = "summon_result"
	guide_line.visible = false
	guide_glow.visible = false
	trace_line.visible = false
	draw_timer_lbl.visible = false
	cov_lbl.visible = false
	coating_lbl.visible = false
	confirm_btn.visible = false

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

	var panel := _make_glow_panel(Vector2(W * 0.5 - 110, H * 0.28), Vector2(220, 230), tier_col)
	draw_layer.add_child(panel)
	summon_result_nodes.append(panel)

	var title := _make_label(tier_name, 28, Vector2(W * 0.5 - 100, H * 0.28 + 16))
	title.custom_minimum_size = Vector2(200, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", tier_col)
	draw_layer.add_child(title)
	summon_result_nodes.append(title)

	var stat := _make_label("パワー %d（%d周）" % [coating_power, coating_count], 16, Vector2(W * 0.5 - 100, H * 0.28 + 56))
	stat.custom_minimum_size = Vector2(200, 26)
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	draw_layer.add_child(stat)
	summon_result_nodes.append(stat)

	if tier_frac > 0.0:
		var preview := Line2D.new()
		preview.width = 3.0
		preview.default_color = tier_col
		for p in _make_ring_points(36.0, tier_frac):
			preview.add_point(p)
		preview.position = Vector2(W * 0.5, H * 0.28 + 130)
		draw_layer.add_child(preview)
		summon_result_nodes.append(preview)
		var preview_tw := preview.create_tween()
		preview_tw.set_loops()
		preview_tw.tween_property(preview, "rotation", TAU, 5.0).from(0.0)

	var btn := Button.new()
	btn.text = "召喚！"
	btn.size = Vector2(180, 56)
	btn.position = Vector2(W * 0.5 - 90, H * 0.28 + 170)
	if jp_font:
		btn.add_theme_font_override("font", jp_font)
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
	btn.pressed.connect(_confirm_summon)
	draw_layer.add_child(btn)
	summon_result_nodes.append(btn)

func _confirm_summon() -> void:
	for n in summon_result_nodes:
		n.queue_free()
	summon_result_nodes.clear()
	_end_drawing()

func _end_drawing() -> void:
	draw_layer.visible = false
	game_state = "battle"
	_add_ally(draw_shape, coating_power)

func _add_ally(shape: String, power: int, burst: bool = true) -> void:
	if allies.size() >= MAX_ALLIES:
		if not _try_merge():
			var worst := _most_damaged_ally()
			if not worst.is_empty():
				_remove_ally(worst)
	_spawn_ally_at(shape, power, player_pos, burst)

func _spawn_ally_at(shape: String, power: int, pos: Vector2, burst: bool = true) -> void:
	var data: Dictionary = SHAPE_DATA[shape]
	var hp_base: int = data["hp_base"] as int
	var hp: int      = hp_base + power
	var kb_r: float  = data["kb_r"] as float
	var col := _ally_color(shape, power)
	var sz  := _ally_size(power)
	var node: Node2D
	if ALLY_SPRITE_TEXTURES.has(shape):
		var spr := Sprite2D.new()
		spr.texture = ALLY_SPRITE_TEXTURES[shape]
		var tex_size: Vector2 = spr.texture.get_size()
		var content_ratio: float = ALLY_SPRITE_CONTENT_RATIO[shape] as float
		var content_px: float = max(tex_size.x, tex_size.y) * content_ratio
		spr.scale = Vector2.ONE * ((sz * 2.8) / content_px)
		spr.modulate = col
		node = spr
	else:
		var poly := Polygon2D.new()
		poly.polygon = _make_shape_polygon(shape, sz)
		poly.color = col
		node = poly
	node.position = pos
	add_child(node)
	_attach_sigil_ring(node, sz, power)
	allies.append({
		"shape": shape, "hp": hp, "max_hp": hp, "coating": power,
		"node": node, "attack_timer": randf_range(0.0, ATTACK_INTERVAL),
		"kb_resist": kb_r
	})
	if allies.size() == 3:
		_show_hint("merge", "仲間が10体になると合体進化！", Vector2(W * 0.5 - 110, H * 0.20))
	if burst:
		_summon_burst(pos, col, power)

func _summon_burst(pos: Vector2, col: Color, power: int) -> void:
	# 召喚の瞬間に周囲の敵へ範囲攻撃＋派手な演出を出し、「召喚した」実感を強める
	# 2026-07-16：ノックバックの強さも召喚パワーに応じて増すよう変更（強い召喚ほど吹き飛ばしも大きく）
	Sfx.play_evolve()
	shake_power = maxf(shake_power, 10.0 + minf(14.0, float(power) * 0.15))

	var dmg      := SUMMON_BURST_DMG_BASE + int(float(power) * 0.15)
	var kb_force := 220.0 + minf(260.0, float(power) * 3.5)
	for e in enemies:
		var diff: Vector2 = (e["pos"] as Vector2) - pos
		var dist := diff.length()
		if dist < SUMMON_BURST_R:
			e["hp"] = (e["hp"] as int) - dmg
			e["flash"] = 0.12
			var kb_dir := diff.normalized() if dist > 1.0 else Vector2(1.0, 0.0)
			e["kb"] = (e["kb"] as Vector2) + kb_dir * kb_force

	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = col
	for p in _make_ring_points(20.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	add_child(ring)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * (SUMMON_BURST_R / 20.0), 0.35)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.35)
	ring_tw.chain().tween_callback(ring.queue_free)

	_spawn_death_particles(pos, col, 26.0)

func _attach_sigil_ring(parent: Node2D, sz: float, power: int) -> void:
	if power < 10: return
	var arc_frac := 0.0
	var ring_col := Color.WHITE
	if power >= 70:
		arc_frac = 1.0;  ring_col = Color(1.0, 0.95, 0.6, 0.95)
	elif power >= 30:
		arc_frac = 0.85; ring_col = Color(0.85, 0.85, 0.8, 0.7)
	else:
		arc_frac = 0.55; ring_col = Color(0.7, 0.7, 0.68, 0.4)

	var ring := Line2D.new()
	ring.width = 1.6
	ring.default_color = ring_col
	for p in _make_ring_points(sz * 1.7, arc_frac):
		ring.add_point(p)
	parent.add_child(ring)

	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", TAU, 6.0).from(0.0)

func _make_ring_points(radius: float, arc_frac: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 28
	var count := maxi(2, int(steps * arc_frac))
	for i in range(count + 1):
		var a: float = float(i) / float(steps) * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts

func _try_merge() -> bool:
	var groups: Dictionary = {}
	for a in allies:
		var s: String = a["shape"] as String
		if not EVOLVE_MAP.has(s): continue
		if not groups.has(s): groups[s] = []
		(groups[s] as Array).append(a)
	for shape in groups:
		var grp: Array = groups[shape] as Array
		if grp.size() >= 2:
			var a1: Dictionary = grp[0] as Dictionary
			var a2: Dictionary = grp[1] as Dictionary
			var merged_power: int  = (a1["coating"] as int) + (a2["coating"] as int)
			var merge_pos: Vector2 = ((a1["node"] as Node2D).position + (a2["node"] as Node2D).position) / 2.0
			_remove_ally(a1)
			_remove_ally(a2)
			var evolved: String = EVOLVE_MAP[shape] as String
			_spawn_ally_at(evolved, merged_power, merge_pos)
			_show_evolve_flash(evolved, merge_pos)
			Sfx.play_evolve()
			return true
	return false

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
			Sfx.unlock()
			Sfx.play_bgm()
			_show_hint("move", "← スティックで移動・敵を避けよう", Vector2(W * 0.5 - 110, H - 130))
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
		if event.pressed and draw_touch_id == -1:
			draw_touch_id = event.index
			_add_to_trace(event.position)
		elif not event.pressed and event.index == draw_touch_id:
			draw_touch_id = -1
	elif event is InputEventScreenDrag and event.index == draw_touch_id:
		_add_to_trace(event.position)

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
	var grade := ""
	if cov >= 0.90:
		gain = 35; label = "PERFECT!!"; col = Color(1.0, 1.0, 0.3); grade = "perfect"
	elif cov >= 0.75:
		gain = 20; label = "GREAT!";    col = Color(0.4, 1.0, 0.9); grade = "great"
	elif cov >= 0.70:
		gain = 10; label = "GOOD";      col = Color(0.5, 0.7, 1.0); grade = "good"
	else:
		label = "MISS..."; col = Color(0.8, 0.4, 0.4); grade = "miss"

	var pitch := 1.0 + minf(0.5, float(coating_count) * 0.08)
	Sfx.play_lap(grade, pitch)
	if gain > 0:
		coating_count += 1
		coating_power += gain
		coating_lbl.text = "×%d" % coating_count
		_apply_guide_intensity()
		_spawn_lap_pulse(col)
	_show_lap_flash(label, col)

func _spawn_lap_pulse(col: Color) -> void:
	# 成功ラップのたびにガイドの輪から光の輪が広がる。周回を重ねるほど大きく広がる
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = col
	for p in _make_ring_points(DRAW_GUIDE_R, 1.0):
		ring.add_point(p)
	ring.position = Vector2(W * 0.5, H * 0.5)
	draw_layer.add_child(ring)
	var grow := 1.15 + minf(0.6, float(coating_count) * 0.08)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2.ONE * grow, 0.4)
	tw.tween_property(ring, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(ring.queue_free)

func _show_wave_flash(wave: int) -> void:
	var lbl := _make_label("WAVE  %d" % wave, 48, Vector2(W * 0.5 - 80, H * 0.38))
	lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	if jp_font: lbl.add_theme_font_override("font", jp_font)
	add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tween.tween_callback(lbl.queue_free)

func _show_evolve_flash(evolved: String, pos: Vector2) -> void:
	var names := { "double_circle": "二重丸！", "hexagram": "六芒星！", "octagram": "八芒星！" }
	var txt: String = names.get(evolved, "EVOLVE!") as String
	var lbl := _make_label(txt, 32, pos - Vector2(45, 20))
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	if jp_font: lbl.add_theme_font_override("font", jp_font)
	add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 40, 0.8)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tween.tween_callback(lbl.queue_free)

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
func _show_hint(key: String, text: String, pos: Vector2) -> void:
	if hints_shown.has(key): return
	hints_shown[key] = true
	var lbl := _make_label(text, 17, pos)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	lbl.modulate.a = 0.0
	ui_layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.tween_callback(lbl.queue_free)

func _fmt_time(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	return "%d:%02d" % [m, s] if m > 0 else "%d秒" % int(t)

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		best_time = cfg.get_value("score", "best_time", 0.0) as float

func _save_best(t: float) -> void:
	if t <= best_time: return
	best_time = t
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best_time", best_time)
	cfg.save("user://save.cfg")

func _game_over() -> void:
	game_state = "game_over"
	Sfx.stop_bgm()
	var is_new := elapsed_time > best_time
	_save_best(elapsed_time)

	var over_lbl := _make_label("GAME OVER", 52, Vector2(W * 0.5 - 130, H * 0.30))
	over_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	ui_layer.add_child(over_lbl)

	var score_lbl := _make_label(_fmt_time(elapsed_time) + " 生存", 30, Vector2(W * 0.5 - 80, H * 0.43))
	score_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	ui_layer.add_child(score_lbl)

	var best_txt  := "NEW RECORD!!" if is_new else "ベスト: " + _fmt_time(best_time)
	var best_col  := Color(1.0, 0.9, 0.2) if is_new else Color(0.6, 0.6, 0.6)
	var best_lbl  := _make_label(best_txt, 22, Vector2(W * 0.5 - 80, H * 0.51))
	best_lbl.add_theme_color_override("font_color", best_col)
	ui_layer.add_child(best_lbl)

	var retry_btn := Button.new()
	retry_btn.text = "RETRY"
	retry_btn.size = Vector2(180, 60)
	retry_btn.position = Vector2(W * 0.5 - 90, H * 0.60)
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
	frag_lbl.text = "欠片: %d/%d" % [fragment_count, FRAGMENT_THRESHOLD]
	hp_bar_fill.size.x = hp_bar_w * clampf(float(player_hp) / float(PLAYER_HP_MAX), 0.0, 1.0)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ユーティリティ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 新しい点を追加するとき、前の点との線分上に補間点も trace_pts に追加する
# → 「見えてる線 = 評価される線」になる
func _add_to_trace(pos: Vector2) -> void:
	trace_line.add_point(pos)
	if not trace_pts.is_empty():
		var prev: Vector2 = trace_pts.back()
		var dist: float   = prev.distance_to(pos)
		var step: float   = DRAW_BRUSH_R * 0.7
		if dist > step:
			var n: int = int(dist / step)
			for i in range(1, n):
				trace_pts.append(prev.lerp(pos, float(i) / float(n)))
	trace_pts.append(pos)

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
	var hw := W * 0.5 + 60.0
	var hh := H * 0.5 + 60.0
	match randi() % 4:
		0: return player_pos + Vector2(randf_range(-hw, hw), -hh)
		1: return player_pos + Vector2(randf_range(-hw, hw),  hh)
		2: return player_pos + Vector2(-hw, randf_range(-hh, hh))
		_: return player_pos + Vector2( hw, randf_range(-hh, hh))

func _make_ngon(n: int, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := float(i) / float(n) * TAU - PI / 2.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

func _hash01(x: int, y: int) -> float:
	var s := sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
	return s - floor(s)

func _draw() -> void:
	var tl  := player_pos - Vector2(W * 0.5, H * 0.5)
	var pad := 200.0
	draw_rect(Rect2(tl - Vector2(pad, pad), Vector2(W + pad * 2, H + pad * 2)), Color(0.03, 0.03, 0.10))

	# 星空（「暗い宇宙」のイメージ。ランダムな瞬きで単調なグリッドと差別化）
	var star_cell := 60.0
	var s_ox := fmod(tl.x - pad, star_cell)
	var s_oy := fmod(tl.y - pad, star_cell)
	for i in range(-1, int((W + pad * 2) / star_cell) + 2):
		for j in range(-1, int((H + pad * 2) / star_cell) + 2):
			var wx := tl.x - pad - s_ox + i * star_cell
			var wy := tl.y - pad - s_oy + j * star_cell
			var h := _hash01(int(round(wx / star_cell)), int(round(wy / star_cell)))
			if h < 0.1:
				draw_circle(Vector2(wx, wy), 1.0 + h * 2.5, Color(0.8, 0.85, 1.0, 0.25 + h * 0.4))

	# グリッド線（控えめに）
	var grid     := 100.0
	var line_col := Color(1.0, 1.0, 1.0, 0.05)
	var ox := fmod(tl.x, grid)
	var oy := fmod(tl.y, grid)
	for i in range(-1, int(W / grid) + 2):
		var x := tl.x - ox + i * grid
		draw_line(Vector2(x, tl.y - pad), Vector2(x, tl.y + H + pad), line_col, 1.0)
	for j in range(-1, int(H / grid) + 2):
		var y := tl.y - oy + j * grid
		draw_line(Vector2(tl.x - pad, y), Vector2(tl.x + W + pad, y), line_col, 1.0)

	# 足元の「世界最後の陣」（2026-07-16：世界観の中心表現として追加。プレイヤーに常時追従）
	var pulse := 0.75 + 0.25 * sin(elapsed_time * 1.2)
	var sigil_r := 150.0
	draw_arc(player_pos, sigil_r, 0.0, TAU, 56, Color(0.55, 0.35, 0.95, 0.16 * pulse), 16.0)   # 外側の淡いグロー
	draw_arc(player_pos, sigil_r, 0.0, TAU, 56, Color(0.65, 0.5, 1.0, 0.5 * pulse), 2.5)        # くっきりした輪
	draw_arc(player_pos, sigil_r * 0.72, 0.0, TAU, 48, Color(0.65, 0.5, 1.0, 0.3 * pulse), 1.5) # 内側の輪
	var rot := elapsed_time * 0.2
	var star_pts := _make_star_pts(6, sigil_r * 0.85, 0.5)
	var rotated := PackedVector2Array()
	for p in star_pts:
		rotated.append(p.rotated(rot) + player_pos)
	rotated.append(rotated[0])
	draw_polyline(rotated, Color(0.65, 0.5, 1.0, 0.35 * pulse), 1.5)

	# プレイヤー軌跡
	for k in range(player_trail.size()):
		var alpha := float(k) / float(player_trail.size()) * 0.5
		draw_circle(player_trail[k], 3.5, Color(0.5, 0.8, 1.0, alpha))

func _make_star_pts(n: int, size: float, inner_ratio: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n * 2):
		var a := float(i) / float(n * 2) * TAU - PI / 2.0
		var d := size if i % 2 == 0 else size * inner_ratio
		pts.append(Vector2(cos(a) * d, sin(a) * d))
	return pts

func _make_shape_polygon(shape: String, size: float) -> PackedVector2Array:
	match shape:
		"circle":        return _make_ngon(12, size)
		"triangle":      return _make_ngon(3, size)
		"square":        return _make_ngon(4, size)
		"double_circle": return _make_ngon(24, size * 1.5)
		"hexagram":      return _make_star_pts(6, size, 0.5)
		"octagram":      return _make_star_pts(8, size, 0.42)
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
