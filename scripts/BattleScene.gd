extends Node2D

const _Shapes = preload("res://scripts/Shapes.gd")
const _Sigils = preload("res://scripts/Sigils.gd")
const _Data = preload("res://scripts/BattleData.gd")
const _EnemySpawner = preload("res://scripts/EnemySpawner.gd")
const _WeaponSystem = preload("res://scripts/WeaponSystem.gd")
const _DrawSystem = preload("res://scripts/DrawSystem.gd")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 定数（実体は BattleData.gd に分離済み。挙動・数値は変更なし、参照名だけ維持するための再エクスポート）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const W := _Data.W
const H := _Data.H

const PLAYER_SPEED     := _Data.PLAYER_SPEED
const PLAYER_HP_MAX    := _Data.PLAYER_HP_MAX
const PLAYER_R         := _Data.PLAYER_R
const MAX_ALLIES       := _Data.MAX_ALLIES
const ALLY_OUTER_R     := _Data.ALLY_OUTER_R
const ALLY_MID_R       := _Data.ALLY_MID_R
const ALLY_BASE_SIZE   := _Data.ALLY_BASE_SIZE

const ALLY_TEX_WATER   := _Data.ALLY_TEX_WATER
const ALLY_TEX_FIRE    := _Data.ALLY_TEX_FIRE
const ALLY_TEX_EARTH   := _Data.ALLY_TEX_EARTH
const ALLY_TEX_WATER_1 := _Data.ALLY_TEX_WATER_1
const ALLY_TEX_FIRE_1  := _Data.ALLY_TEX_FIRE_1
const ALLY_TEX_EARTH_1 := _Data.ALLY_TEX_EARTH_1
const ALLY_TEX_WATER_3 := _Data.ALLY_TEX_WATER_3
const ALLY_TEX_FIRE_3  := _Data.ALLY_TEX_FIRE_3
const ALLY_TEX_EARTH_3 := _Data.ALLY_TEX_EARTH_3
const ALLY_SPRITE_TEXTURES := _Data.ALLY_SPRITE_TEXTURES
const ALLY_SPRITE_CONTENT_RATIO := _Data.ALLY_SPRITE_CONTENT_RATIO

const ENEMY_SPEED_BASE: float = _Data.ENEMY_SPEED_BASE
const ENEMY_HP_BASE:    int   = _Data.ENEMY_HP_BASE
const ENEMY_R:          float = _Data.ENEMY_R
const ENEMY_DAMAGE:     int   = _Data.ENEMY_DAMAGE
const MAX_ENEMIES: int = _Data.MAX_ENEMIES
const ENEMY_TYPES := _Data.ENEMY_TYPES

const PREDATOR_ATTRS := _Data.PREDATOR_ATTRS
const PREDATOR_WARD_COLOR := _Data.PREDATOR_WARD_COLOR
const PREDATOR_DMG_CUT      := _Data.PREDATOR_DMG_CUT
const PREDATOR_CHANCE       := _Data.PREDATOR_CHANCE
const PREDATOR_CHANCE_STAGE3 := _Data.PREDATOR_CHANCE_STAGE3

const ELITE_VARIANTS := _Data.ELITE_VARIANTS
const ELITE_CHANCE      := _Data.ELITE_CHANCE
const ELITE_CHANCE_STAGE3 := _Data.ELITE_CHANCE_STAGE3
const ELITE_MIN_TIME    := _Data.ELITE_MIN_TIME

const STAGE_TIMELINES := _Data.STAGE_TIMELINES

const ENEMY_TEX_SHARD     := _Data.ENEMY_TEX_SHARD
const ENEMY_TEX_FRACTURE  := _Data.ENEMY_TEX_FRACTURE
const ENEMY_TEX_VOID_MARK := _Data.ENEMY_TEX_VOID_MARK
const ENEMY_SPRITE_TEXTURES := _Data.ENEMY_SPRITE_TEXTURES
const ENEMY_SPRITE_CONTENT_RATIO := _Data.ENEMY_SPRITE_CONTENT_RATIO
const ENEMY_DESATURATE_SHADER := _Data.ENEMY_DESATURATE_SHADER
var _enemy_shader_mat: ShaderMaterial
var _enemy_spawner: EnemySpawner
var _weapon_system: WeaponSystem
var _draw_system: DrawSystem

# デバッグモード用（2026-09-24追加）
const DEBUG_TIME_SCALES := [1.0, 2.0, 4.0]
var _debug_time_scale_idx := 0

const FRAGMENT_THRESHOLD_BASE := _Data.FRAGMENT_THRESHOLD_BASE
const FRAGMENT_THRESHOLD_GROWTH := _Data.FRAGMENT_THRESHOLD_GROWTH
const HEAL_ITEM_BASE_CHANCE := _Data.HEAL_ITEM_BASE_CHANCE
const HEAL_ITEM_HP_SCALE    := _Data.HEAL_ITEM_HP_SCALE
const HEAL_ITEM_COOLDOWN    := _Data.HEAL_ITEM_COOLDOWN
const HEAL_AMOUNT       := _Data.HEAL_AMOUNT
const ALLY_HEAL_FRACTION := _Data.ALLY_HEAL_FRACTION
const WEAPON_ITEM_CHANCE := _Data.WEAPON_ITEM_CHANCE
const WEAPON_ITEM_COOLDOWN := _Data.WEAPON_ITEM_COOLDOWN
const NOTABLE_KILL_WEAPON_CHANCE := _Data.NOTABLE_KILL_WEAPON_CHANCE
const NOTABLE_KILL_FRAGMENT_VALUE := _Data.NOTABLE_KILL_FRAGMENT_VALUE
const ITEM_PICKUP_R    := _Data.ITEM_PICKUP_R
const ITEM_R           := _Data.ITEM_R
const FRAGMENT_R       := _Data.FRAGMENT_R

const BULLET_SPEED     := _Data.BULLET_SPEED
const BULLET_RANGE     := _Data.BULLET_RANGE
const BULLET_R         := _Data.BULLET_R
const BULLET_DMG_BASE  := _Data.BULLET_DMG_BASE
const SUMMON_BURST_R      := _Data.SUMMON_BURST_R
const SUMMON_BURST_DMG_BASE := _Data.SUMMON_BURST_DMG_BASE
const ATTACK_RANGE          := _Data.ATTACK_RANGE
const ATTACK_INTERVAL       := _Data.ATTACK_INTERVAL
const PLAYER_ATTACK_INTERVAL := _Data.PLAYER_ATTACK_INTERVAL
const PLAYER_BULLET_DMG      := _Data.PLAYER_BULLET_DMG

const DRAW_DURATION    := _Data.DRAW_DURATION
const DRAW_GUIDE_R     := _Data.DRAW_GUIDE_R
const DRAW_COVER_THR   := _Data.DRAW_COVER_THR
const DRAW_BRUSH_R     := _Data.DRAW_BRUSH_R
const MISS_GAIN        := _Data.MISS_GAIN
const COATING_DMG_K    := _Data.COATING_DMG_K

const SHAPE_DATA := _Data.SHAPE_DATA

const ATTR_WEAPON_MAX_LEVEL := _Data.ATTR_WEAPON_MAX_LEVEL
const ATTR_WEAPON_DATA := _Data.ATTR_WEAPON_DATA

const SHAPE_TO_ATTR := _Data.SHAPE_TO_ATTR
const SHAPE_TO_TIER := _Data.SHAPE_TO_TIER

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# フォント
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var jp_font: Font = null

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ゲーム状態
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var game_state    := "battle"   # "battle" | "drawing" | "upgrade_select" | "game_over" | "stage_clear"
var elapsed_time  := 0.0
# 2026-08-04：⑧ステージ制。current_stageはLoadoutSceneで選んだステージ（GameData.selected_stageから取得）
var current_stage := 1
const STAGE_TIME_LIMIT := _Data.STAGE_TIME_LIMIT
var best_time     := 0.0
var hints_shown   := {}         # 表示済みヒントのフラグ

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# プレイヤー
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var player_hp    := PLAYER_HP_MAX
var player_hp_max := PLAYER_HP_MAX  # 2026-08-07：メタ進行の体力強化で_ready()時に底上げされる
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
# ally: { shape, hp, max_hp, coating, node:Polygon2D, attack_timer, weapon_timers, orbiters }
var allies : Array[Dictionary] = []
var weapon_stats := { "atk_speed": 1.0, "damage": 1.0, "move_speed": 1.0 }
var weapon_levels := {
	"water_rain": 0, "water_pierce": 0,
	"fire_explode": 0, "fire_chain": 0,
	"earth_orbit": 0, "earth_wave": 0,
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 敵
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# enemy: { hp, max_hp, pos, node:Polygon2D, kb:Vector2 }
var enemies          : Array[Dictionary] = []
var enemy_spawn_timer := 0.0
var wave_count        := 0
# 2026-08-18：タイムライン方式に作り直したことに伴う進行管理。events配列の何番目まで消化したか、
# 消化しきった後（主にエンドレス）はloop_eventを何秒おきに発生させるか
var next_event_idx      := 0
var next_loop_event_time := -1.0

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
var last_heal_drop_time   := -999.0  # 2026-08-08：クールダウン計算用。開始直後から出せるよう大きく負の値で初期化
var last_weapon_drop_time := -999.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画フェーズ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var draw_shape       := "circle"          # 属性名（circle/triangle/square）。武器等の参照キーとして維持
var draw_sigil_id    := "circle_1"        # 装備中の紋章id（Sigils.SIGIL_DATA参照）。描画ガイド・召喚結果を決める
var current_guide_r  := DRAW_GUIDE_R      # 装備tierのguide_scaleを反映した、今セッションの紋章半径
var brush_ratio_mult := 1.0               # ペン太さの倍率。将来アイテムで調整する余地として用意（現状は常に1.0）
var draw_time_bonus  := 0.0               # 残光「描画時間強化」の恒久ボーナス秒数（2026-08-08：_ready()で設定、以後固定）
var draw_timer       := 0.0
var coating_count    := 0
var coating_power    := 0
var trace_pts        : Array[Vector2] = []
var sample_contours  : Array = []         # Array[Array[Vector2]]。輪郭ごとにカバー率を判定する
var contour_weights  : Array[float] = []  # sample_contoursと対応する採点の重み（合計1.0想定）
var draw_touch_id    : int = -1

var draw_layer      : CanvasLayer = null
var trace_line      : Line2D      = null
var guide_line      : Line2D      = null
var guide_glow      : Line2D      = null
var guide_line_inner: Line2D      = null  # tier2/3の内側輪郭（点/星）用。tier1では非表示
var guide_glow_inner: Line2D      = null
var guide_line_2    : Line2D      = null  # 3つ目の輪郭用（2026-08-19：火/土に円を追加した際、tier3が
var guide_glow_2    : Line2D      = null  # 円+2輪郭の計3輪郭になったため新設。3輪郭未満の紋章では非表示
var guide_base_color := Color.WHITE
var guide_rune_root : Node2D = null  # 「これは紋章だ」感を出すための、円周上を回るルーン飾り
var guide_rune_marks: Array[Polygon2D] = []
const GUIDE_RUNE_COUNT := 8
var coating_lbl   : Label       = null
var draw_timer_lbl: Label       = null
var cov_lbl       : Label       = null
var confirm_btn   : Button         = null
var summon_result_nodes : Array[Node] = []

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var ui_layer      : CanvasLayer = null
var pause_btn     : Button      = null
var pause_layer   : CanvasLayer = null
var paused_from_state := "battle"
var hp_lbl        : Label       = null
var time_lbl      : Label       = null
var ally_lbl      : Label       = null
var frag_lbl      : Label       = null
var hp_bar_fill   : ColorRect   = null
var frag_bar_fill : ColorRect   = null
var hp_bar_w      := 130.0
var fragment_count := 0
var fragment_threshold := FRAGMENT_THRESHOLD_BASE  # 2026-08-08：貯まるとキャラアイテム（召喚）がドロップする。発動のたびFRAGMENT_THRESHOLD_GROWTHずつ引き上げ

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 初期化
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _ready() -> void:
	player_pos = Vector2(W * 0.5, H * 0.6)
	jp_font = load("res://fonts/jp_font.ttf")
	_load_save()
	current_stage = GameData.selected_stage

	# 2026-08-07：メタ進行（残光での恒久強化）。エンドレスでは適用せず「腕試し」の純度を保つ
	# 2026-08-08：欠片カード廃止に伴い、旧カードの攻撃速度・描画時間アップ効果もここに統合
	if current_stage < GameData.META_LOCKED_STAGE:
		player_hp_max = PLAYER_HP_MAX + GameData.upgrade_level("hp")
		weapon_stats["damage"] = 1.0 + float(GameData.upgrade_level("atk")) * 0.05
		weapon_stats["move_speed"] = 1.0 + float(GameData.upgrade_level("spd")) * 0.04
		weapon_stats["atk_speed"] = 1.0 + float(GameData.upgrade_level("atk_speed")) * 0.08
		draw_time_bonus = float(GameData.upgrade_level("draw_time")) * 0.6
	player_hp = player_hp_max

	_enemy_shader_mat = ShaderMaterial.new()
	_enemy_shader_mat.shader = ENEMY_DESATURATE_SHADER
	_enemy_spawner = _EnemySpawner.new(self)
	_weapon_system = _WeaponSystem.new(self)
	_draw_system = _DrawSystem.new(self)

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

	var stats_panel := _make_glow_panel(Vector2(6, 6), Vector2(150, 100), Color(0.5, 0.8, 1.0, 0.5))
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

	frag_lbl = _make_label("召喚まで: 0/%d" % fragment_threshold, 14, Vector2(14, 72))
	ui_layer.add_child(frag_lbl)

	var frag_bar_bg := ColorRect.new()
	frag_bar_bg.color = Color(0.08, 0.08, 0.05, 0.8)
	frag_bar_bg.position = Vector2(14, 88)
	frag_bar_bg.size = Vector2(hp_bar_w, 6)
	ui_layer.add_child(frag_bar_bg)

	frag_bar_fill = ColorRect.new()
	frag_bar_fill.color = Color(0.4, 1.0, 0.55, 0.95)
	frag_bar_fill.position = Vector2(14, 88)
	frag_bar_fill.size = Vector2(0.0, 6)
	ui_layer.add_child(frag_bar_fill)

	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.size = Vector2(40, 32)
	pause_btn.position = Vector2(W - 46, 44)
	pause_btn.pressed.connect(_open_pause_menu)
	if jp_font:
		pause_btn.add_theme_font_override("font", jp_font)
	pause_btn.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(pause_btn)

	if DebugMode.enabled:
		_build_debug_panel(ui_layer)

# デバッグモード（?debug=1）専用パネル（2026-09-24追加）。時間倍速と、追跡者・詠唱者の
# 強制湧きで、確率任せにせずリング・弾の見た目や挙動をその場で確認できるようにする
func _build_debug_panel(layer: CanvasLayer) -> void:
	var btn_w := 150.0
	var btn_h := 30.0
	var y := 84.0

	var speed_btn := Button.new()
	speed_btn.text = "[DEBUG] 速度 x1"
	speed_btn.size = Vector2(btn_w, btn_h)
	speed_btn.position = Vector2(W - btn_w - 6, y)
	speed_btn.add_theme_font_size_override("font_size", 12)
	speed_btn.modulate = Color(1.0, 0.75, 0.75)
	if jp_font:
		speed_btn.add_theme_font_override("font", jp_font)
	speed_btn.pressed.connect(func():
		_debug_time_scale_idx = (_debug_time_scale_idx + 1) % DEBUG_TIME_SCALES.size()
		var ts: float = DEBUG_TIME_SCALES[_debug_time_scale_idx]
		Engine.time_scale = ts
		speed_btn.text = "[DEBUG] 速度 x%d" % int(ts)
	)
	layer.add_child(speed_btn)
	y += btn_h + 4

	var hunter_btn := Button.new()
	hunter_btn.text = "[DEBUG] 追跡者を湧かせる"
	hunter_btn.size = Vector2(btn_w, btn_h)
	hunter_btn.position = Vector2(W - btn_w - 6, y)
	hunter_btn.add_theme_font_size_override("font_size", 11)
	hunter_btn.modulate = Color(1.0, 0.75, 0.75)
	if jp_font:
		hunter_btn.add_theme_font_override("font", jp_font)
	hunter_btn.pressed.connect(func(): _enemy_spawner.debug_force_spawn("hunter"))
	layer.add_child(hunter_btn)
	y += btn_h + 4

	var caster_btn := Button.new()
	caster_btn.text = "[DEBUG] 詠唱者を湧かせる"
	caster_btn.size = Vector2(btn_w, btn_h)
	caster_btn.position = Vector2(W - btn_w - 6, y)
	caster_btn.add_theme_font_size_override("font_size", 11)
	caster_btn.modulate = Color(1.0, 0.75, 0.75)
	if jp_font:
		caster_btn.add_theme_font_override("font", jp_font)
	caster_btn.pressed.connect(func(): _enemy_spawner.debug_force_spawn("caster"))
	layer.add_child(caster_btn)

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
	# 2026-07-20：紋章はtierごとにサイズが変わる（Sigils.MAX_GUIDE_SCALEまで）が、この装飾は
	# 初期化時の1回しか作らないため、最大tierを見込んだサイズで固定しておく（毎回作り直さない）
	var deco_outer := Line2D.new()
	deco_outer.width = 2.0
	deco_outer.default_color = Color(0.6, 0.8, 1.0, 0.25)
	for p in _make_ring_points(DRAW_GUIDE_R * _Sigils.MAX_GUIDE_SCALE * 1.55, 1.0):
		deco_outer.add_point(p)
	deco_outer.position = Vector2(W * 0.5, H * 0.5)
	draw_layer.add_child(deco_outer)
	var deco_outer_tw := deco_outer.create_tween()
	deco_outer_tw.set_loops()
	deco_outer_tw.tween_property(deco_outer, "rotation", TAU, 22.0).from(0.0)

	var deco_inner := Line2D.new()
	deco_inner.width = 2.0
	deco_inner.default_color = Color(0.6, 0.8, 1.0, 0.18)
	for p in _make_ring_points(DRAW_GUIDE_R * _Sigils.MAX_GUIDE_SCALE * 1.3, 1.0):
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

	# tier2/3の内側輪郭（点/星）用。tier1装備時はvisible=falseのまま使われない
	guide_glow_inner = Line2D.new()
	guide_glow_inner.width = 22.0
	guide_glow_inner.default_color = Color(1.0, 1.0, 1.0, 0.15)
	guide_glow_inner.visible = false
	draw_layer.add_child(guide_glow_inner)

	guide_line_inner = Line2D.new()
	guide_line_inner.width = 6.0
	guide_line_inner.default_color = Color(1.0, 1.0, 1.0, 0.65)
	guide_line_inner.visible = false
	draw_layer.add_child(guide_line_inner)

	# 3つ目の輪郭用（2026-08-19：火/土のtier3に円を追加したことで3輪郭になったため新設）
	guide_glow_2 = Line2D.new()
	guide_glow_2.width = 22.0
	guide_glow_2.default_color = Color(1.0, 1.0, 1.0, 0.15)
	guide_glow_2.visible = false
	draw_layer.add_child(guide_glow_2)

	guide_line_2 = Line2D.new()
	guide_line_2.width = 6.0
	guide_line_2.default_color = Color(1.0, 1.0, 1.0, 0.65)
	guide_line_2.visible = false
	draw_layer.add_child(guide_line_2)

	trace_line = Line2D.new()
	trace_line.width = 5.0
	trace_line.default_color = Color.WHITE  # modulate で色を制御するので白ベース
	draw_layer.add_child(trace_line)

	# 円周上に並ぶ小さなルーン飾り（2026-08-04追加）：なぞる図形が「召喚の紋章」であることを
	# 単純な輪郭線だけより伝えるため、時計の目盛りのようにマークを配置しゆっくり回転させる
	guide_rune_root = Node2D.new()
	guide_rune_root.position = Vector2(W * 0.5, H * 0.5)
	draw_layer.add_child(guide_rune_root)
	var rune_tw := guide_rune_root.create_tween()
	rune_tw.set_loops()
	rune_tw.tween_property(guide_rune_root, "rotation", TAU, 30.0).from(0.0)
	for i in range(GUIDE_RUNE_COUNT):
		var mark := Polygon2D.new()
		mark.polygon = _make_star_pts(4, 7.0, 0.4)
		var ang := float(i) / float(GUIDE_RUNE_COUNT) * TAU
		mark.position = Vector2(cos(ang), sin(ang)) * current_guide_r
		guide_rune_root.add_child(mark)
		guide_rune_marks.append(mark)

	# 2026-08-07：タイマー表示は元々✓ボタンと同じ上部にあったが、ボタンを大きく・中央に据えるため
	# 下部（カバー率・厚塗り数と同じクラスタ）に移動した
	draw_timer_lbl = _make_label("8.0", 32, Vector2(W * 0.5 - 26, H * 0.68))
	draw_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	draw_layer.add_child(draw_timer_lbl)

	cov_lbl = _make_label("0%", 22, Vector2(W * 0.5 - 20, H * 0.76))
	cov_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	draw_layer.add_child(cov_lbl)

	coating_lbl = _make_label("×0", 44, Vector2(W * 0.5 - 28, H * 0.81))
	coating_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	draw_layer.add_child(coating_lbl)

	# 2026-08-07：小さくて押しにくいとの指摘で、上部中央いっぱいに大型化（64x52→220x84）
	confirm_btn = Button.new()
	confirm_btn.text = "✓ ラップ確定"
	confirm_btn.size = Vector2(220, 84)
	confirm_btn.position = Vector2(W * 0.5 - 110, 8)
	confirm_btn.add_theme_font_size_override("font_size", 24)
	var confirm_sb := StyleBoxFlat.new()
	confirm_sb.bg_color = Color(0.1, 0.14, 0.2, 0.88)
	confirm_sb.set_corner_radius_all(16)
	confirm_sb.set_border_width_all(3)
	confirm_sb.border_color = Color(0.6, 0.85, 1.0, 0.9)
	confirm_sb.shadow_color = Color(0.5, 0.75, 1.0, 0.4)
	confirm_sb.shadow_size = 10
	confirm_btn.add_theme_stylebox_override("normal", confirm_sb)
	confirm_btn.add_theme_stylebox_override("hover", confirm_sb)
	confirm_btn.add_theme_stylebox_override("pressed", confirm_sb)
	confirm_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	confirm_btn.pressed.connect(_evaluate_lap)
	draw_layer.add_child(confirm_btn)

	# 2026-09-24追加：デバッグモード（?debug=1）専用。図形を描くジェスチャーは自動テストで
	# 再現できないため、押すとPERFECT相当の結果で即座に召喚フェーズへ進めるショートカット
	if DebugMode.enabled:
		var debug_skip_btn := Button.new()
		debug_skip_btn.text = "[DEBUG] 即召喚(PERFECT)"
		debug_skip_btn.size = Vector2(200, 40)
		debug_skip_btn.position = Vector2(W * 0.5 - 100, H - 60)
		debug_skip_btn.add_theme_font_size_override("font_size", 13)
		debug_skip_btn.modulate = Color(1.0, 0.7, 0.7)
		debug_skip_btn.pressed.connect(func():
			coating_power = 100
			coating_count = 5
			draw_timer = 0.0
		)
		draw_layer.add_child(debug_skip_btn)

	if jp_font:
		_apply_font(draw_layer, jp_font)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# メインループ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _process(delta: float) -> void:
	match game_state:
		"battle":
			elapsed_time += delta
			var limit: float = STAGE_TIME_LIMIT.get(current_stage, -1.0) as float
			if limit > 0.0 and elapsed_time >= limit:
				_stage_clear()
				return
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
		"game_over", "stage_clear", "paused":
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
	# 2026-08-25：3方向ばら撒き（正面+左右90度）は「囲まれる場面がほぼない」との指摘で
	# 正面1発に簡略化。囲まれた時の保険として敵不在時に4方向を撃つ分岐も同じ理由で削除
	var nearest := _nearest_enemy(player_pos)
	if not nearest.is_empty():
		var dir: Vector2 = ((nearest["pos"] as Vector2) - player_pos).normalized()
		_fire_bullet(player_pos, dir, PLAYER_BULLET_DMG)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 敵
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _spawn_enemies(delta: float) -> void:
	_enemy_spawner.spawn_tick(delta)

# ステージ4（エンドレス）はステージ3のタイムラインをそのまま流用する（900秒経過後はloop_eventに切り替わる）
func _current_timeline() -> Dictionary:
	return _enemy_spawner.current_timeline()

# 時刻tが経過時間以下の区間のうち、一番手前（最新）のものを採用する。segmentsは時刻昇順の前提
func _current_segment(segments: Array) -> Dictionary:
	return _enemy_spawner.current_segment(segments)

func _pick_type_from_mix(mix: Dictionary) -> String:
	return _enemy_spawner.pick_type_from_mix(mix)

# ウェーブ専用：プレイヤーを中心に画面外径で均等配置し、四方から一斉に迫る「包囲」を作る
func _spawn_ring_enemies(count: int, mix: Dictionary) -> void:
	_enemy_spawner.spawn_ring_enemies(count, mix)

func _spawn_one_enemy(forced_type: String = "", forced_pos = null) -> void:
	_enemy_spawner.spawn_one_enemy(forced_type, forced_pos)

# エリート個体のリング表示（天敵ウォードと同じ発想。色でtough/swiftの系統が直感的にわかるようにする）
func _attach_elite_ring(parent: Node2D, r: float, ring_color: Color) -> void:
	_enemy_spawner.attach_elite_ring(parent, r, ring_color)

# 天敵ウォードのリング表示（味方の_attach_sigil_ringと同じ発想。本体色は変えない）
func _attach_predator_ring(parent: Node2D, r: float, ward: String) -> void:
	_enemy_spawner.attach_predator_ring(parent, r, ward)

# 敵への全ダメージ経路が通る共通関数（2026-08-04追加）。attrを渡すと天敵ウォード判定を行う。
# attrが空文字（プレイヤー自身の弾など属性を持たない攻撃）の場合はウォードを無視する。
func _damage_enemy(e: Dictionary, dmg: int, attr: String = "") -> void:
	_enemy_spawner.damage_enemy(e, dmg, attr)

func _update_enemies(delta: float) -> void:
	_enemy_spawner.update_enemies(delta)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 仲間
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _update_allies(delta: float) -> void:
	# 2026-07-29：外周/中間の担当を属性の役割（土=盾）に合わせて入れ替え。
	# 旧仕様（丸=盾だった頃）の名残で丸が外周のままになっていたのを修正
	var outer : Array[Dictionary] = []
	var mid   : Array[Dictionary] = []

	for a in allies:
		match a["shape"]:
			"square", "square_mid", "octagram":                            outer.append(a)
			"circle", "circle_mid", "double_circle", "triangle", "triangle_mid", "hexagram": mid.append(a)

	_position_ring(outer, ALLY_OUTER_R, delta, 0.0)
	_position_ring(mid,   ALLY_MID_R,   delta, PI / 3.0)

	for a in allies:
		a["attack_timer"] = (a["attack_timer"] as float) - delta
		if (a["attack_timer"] as float) <= 0.0:
			_ally_attack(a)
			a["attack_timer"] = ATTACK_INTERVAL / (weapon_stats["atk_speed"] as float)
		_update_ally_weapons(a, delta)

# 属性武器（取得済みのものだけ、基本攻撃に上乗せで発動する）
func _update_ally_weapons(a: Dictionary, delta: float) -> void:
	_weapon_system.update_ally_weapons(a, delta)

# 属性武器ダメージのtier保証倍率×厚塗り係数（2026-07-27）。基礎弾攻撃には適用しない
func _ally_weapon_tier_mult(a: Dictionary) -> float:
	return _weapon_system.ally_weapon_tier_mult(a)

func _fire_attr_weapon(a: Dictionary, id: String, wdata: Dictionary, level: int) -> void:
	_weapon_system.fire_attr_weapon(a, id, wdata, level)

func _fire_beam(from: Vector2, dir: Vector2, dmg: int, length: float, width: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	_weapon_system.fire_beam(from, dir, dmg, length, width, col, attr, weapon_id)

func _update_ally_orbiter(a: Dictionary, id: String, wdata: Dictionary, level: int, delta: float) -> void:
	_weapon_system.update_ally_orbiter(a, id, wdata, level, delta)

func _fire_chain_lightning(from: Vector2, dmg: int, jumps: int, chain_range: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	_weapon_system.fire_chain_lightning(from, dmg, jumps, chain_range, col, attr, weapon_id)

func _draw_lightning_bolt(from: Vector2, to: Vector2, col: Color) -> void:
	_weapon_system.draw_lightning_bolt(from, to, col)

func _fire_pulse(pos: Vector2, dmg: int, radius: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	_weapon_system.fire_pulse(pos, dmg, radius, col, attr, weapon_id)

# 2026-08-05：水の「紋章の雨」用。密集地点ほど狙われやすくする（数体をサンプリングし、
# 周囲に一番仲間内...ではなく敵が多い地点を選ぶ）。密集対策（セパレーション緩和）と噛み合わせる狙い
func _pick_rain_target(radius: float) -> Dictionary:
	return _weapon_system.pick_rain_target(radius)

# 天から降り注ぐ範囲攻撃。着弾地点に予告リング＋落下する雨粒を表示してから、少し遅れてダメージを与える
func _start_rain_strike(pos: Vector2, dmg: int, radius: float, col: Color, attr: String, telegraph: float) -> void:
	_weapon_system.start_rain_strike(pos, dmg, radius, col, attr, telegraph)

func _rain_impact(pos: Vector2, dmg: int, radius: float, col: Color, attr: String) -> void:
	_weapon_system.rain_impact(pos, dmg, radius, col, attr)

func _position_ring(ring: Array[Dictionary], radius: float, delta: float, angle_offset: float = 0.0) -> void:
	if ring.is_empty(): return
	for i in range(ring.size()):
		var angle: float = float(i) / float(ring.size()) * TAU + angle_offset
		var target := player_pos + Vector2(cos(angle), sin(angle)) * radius
		# 2026-07-16：追従速度を300→230→195→165にさらに減速（当時はPLAYER_SPEEDと同じ165だったため固定値のままにしていた）
		# 2026-08-18：PLAYER_SPEEDを130まで下げた際にこの165.0だけ取り残され、仲間ごとの速度差が
		# 主人公に対して相対的に薄れてしまっていた。PLAYER_SPEED基準（speed_m＝主人公比の倍率）に変更
		var spd: float = (SHAPE_DATA[ring[i]["shape"] as String]["speed_m"] as float) * PLAYER_SPEED
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

	# 2026-08-07：基本攻撃はtier・厚塗り(coating)を一切反映しておらず、どの仲間も同じ強さに見える
	# 原因になっていたため、属性武器と同じtier・厚塗り倍率(_ally_weapon_tier_mult)を乗せるように変更
	var dmg: int          = int(float(BULLET_DMG_BASE) * (weapon_stats["damage"] as float) * _ally_weapon_tier_mult(a))
	var base_dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()
	var bullet_col: Color = SHAPE_DATA[shape]["color"]

	var attr: String = SHAPE_TO_ATTR.get(shape, "") as String
	var spread: float = 0.15 * (bullet_count - 1)
	for i in range(bullet_count):
		var offset: float = -spread + spread * 2.0 * float(i) / maxf(1.0, float(bullet_count - 1))
		var dir: Vector2  = base_dir.rotated(offset)
		_fire_bullet(ally_pos, dir, dmg, bullet_col, false, false, 0.0, attr)

func _fire_bullet(from: Vector2, dir: Vector2, dmg: int, col: Color = Color(1.0, 1.0, 0.75), pierce: bool = false, homing: bool = false, explode_r: float = 0.0, attr: String = "", special: bool = false) -> void:
	var node := Node2D.new()
	node.position = from

	# 属性武器の弾（special）は基本弾より一回り大きく・明るく・芒星の角も多くして見分けをつける
	var glow_r    := BULLET_R * (3.4 if special else 2.6)
	var glow_a    := 0.5 if special else 0.3
	var rune_pts  := 6 if special else 4
	var rune_r    := BULLET_R * (2.3 if special else 1.9)
	var core_boost := 1.4 if special else 1.0

	var glow := Polygon2D.new()
	glow.polygon = _make_ngon(10, glow_r)
	glow.color = Color(col.r, col.g, col.b, glow_a)
	node.add_child(glow)

	var rune := Polygon2D.new()
	rune.polygon = _make_star_pts(rune_pts, rune_r, 0.35)
	rune.color = Color(col.r * core_boost, col.g * core_boost, col.b * core_boost, 1.0)
	node.add_child(rune)

	if special:
		var outline := Polygon2D.new()
		outline.polygon = _make_star_pts(rune_pts, rune_r * 1.35, 0.6)
		outline.color = Color(col.r, col.g, col.b, 0.4)
		node.add_child(outline)
		node.move_child(outline, 1)

	add_child(node)
	bullets.append({
		"pos": from, "dir": dir, "traveled": 0.0, "dmg": dmg, "node": node, "col": col,
		"pierce": pierce, "homing": homing, "explode_r": explode_r, "hit_set": [], "attr": attr
	})

func _remove_ally(a: Dictionary) -> void:
	a["node"].queue_free()
	if a.has("orbiters"):
		for id in (a["orbiters"] as Dictionary):
			((a["orbiters"] as Dictionary)[id] as Dictionary)["node"].queue_free()
	allies.erase(a)

# 回復アイテムで生きてる仲間全員を最大HPの割合分だけ回復（2026-07-27追加）
func _heal_allies(fraction: float) -> void:
	for a in allies:
		var max_hp: float = a["max_hp"] as float
		var heal: float = ceil(max_hp * fraction)
		var cur: float = a["hp"] as float
		a["hp"] = minf(max_hp, cur + heal)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 弾
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _update_bullets(delta: float) -> void:
	var to_remove : Array[int] = []
	for i in range(bullets.size()):
		var b := bullets[i]
		if b.get("homing", false):
			var target := _nearest_enemy(b["pos"] as Vector2)
			if not target.is_empty():
				var desired: Vector2 = ((target["pos"] as Vector2) - (b["pos"] as Vector2)).normalized()
				b["dir"] = (b["dir"] as Vector2).slerp(desired, minf(1.0, delta * 4.0)).normalized()
		b["pos"] = (b["pos"] as Vector2) + (b["dir"] as Vector2) * BULLET_SPEED * delta
		b["traveled"] = (b["traveled"] as float) + BULLET_SPEED * delta
		b["node"].position = b["pos"] as Vector2
		b["node"].rotation += delta * 16.0

		var hit := false
		var hit_set: Array = b["hit_set"]
		var pierce: bool = b.get("pierce", false)
		for e in enemies:
			if hit_set.has(e): continue
			if (b["pos"] as Vector2).distance_to(e["pos"] as Vector2) < (e["radius"] as float) + BULLET_R:
				_damage_enemy(e, b["dmg"] as int, b.get("attr", "") as String)
				e["flash"] = 0.12
				hit = true
				if pierce:
					hit_set.append(e)
					# 2026-08-06：貫通弾は弾が消えないぶん「当たった感」が薄いとの指摘で、着弾点に小さな火花を追加
					_spawn_hit_spark(b["pos"] as Vector2, b["col"] as Color)
				var explode_r: float = b.get("explode_r", 0.0)
				if explode_r > 0.0:
					_explode_at(b["pos"] as Vector2, b["dmg"] as int, explode_r, b["col"] as Color, e, b.get("attr", "") as String)
				break

		if (hit and not pierce) or (b["traveled"] as float) >= BULLET_RANGE:
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

func _explode_at(pos: Vector2, dmg: int, radius: float, col: Color, exclude: Dictionary, attr: String = "") -> void:
	for e in enemies:
		if e == exclude: continue
		if pos.distance_to(e["pos"] as Vector2) < radius:
			_damage_enemy(e, dmg, attr)
			e["flash"] = 0.12
	_spawn_death_particles(pos, col, radius * 0.35)
	var ring := Line2D.new()
	ring.width = 2.0
	ring.default_color = col
	for p in _make_ring_points(8.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	add_child(ring)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2.ONE * (radius / 8.0), 0.25)
	tw.tween_property(ring, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(ring.queue_free)

func _on_enemy_death(e: Dictionary) -> void:
	Sfx.play_enemy_die()
	_spawn_death_particles(e["pos"] as Vector2, e["color"] as Color, e["radius"] as float)
	# 2026-08-26：ヴォイドマーク・エリートは倒すのに手間がかかる分、見返りも大きくする
	var is_notable: bool = (e.get("etype", "") as String) == "void_mark" or (e.get("elite", false) as bool)
	# 2026-08-14：毎キル確定ドロップだと画面にアイテムが積み上がりごちゃつくとの指摘。
	# VSも毎回ではなく敵の半分程度しか落とさないとの指摘を受け、50%抽選に変更
	# 2026-08-18：ただし最初の仲間が出る前に運悪く欠片が出ないと、1人きりのまま「事故る」との指摘。
	# 最初の仲間が出るまでは確定ドロップにして、事故らないよう保証する
	if is_notable:
		_spawn_fragment(e["pos"] as Vector2, NOTABLE_KILL_FRAGMENT_VALUE)
	elif allies.size() == 0 or randf() < 0.5:
		_spawn_fragment(e["pos"] as Vector2)
	# 2026-08-08：キャラアイテム（召喚）はランダム抽選をやめ、欠片を集めて閾値に達したときだけドロップする
	# 確実なトリガーに変更（_update_itemsの欠片ピックアップ処理を参照）
	# 2026-08-08：回復はHPが減るほど出やすい需要ベースの確率＋クールダウン。武器は既存%にクールダウンのみ追加。
	# どちらも「一番忙しい瞬間（=物量に押されてる時）にドロップが殺到する」のを防ぐのが狙い
	var hp_frac := float(player_hp) / float(player_hp_max)
	var heal_chance := HEAL_ITEM_BASE_CHANCE + (1.0 - hp_frac) * HEAL_ITEM_HP_SCALE
	var weapon_chance := NOTABLE_KILL_WEAPON_CHANCE if is_notable else WEAPON_ITEM_CHANCE
	if elapsed_time - last_heal_drop_time >= HEAL_ITEM_COOLDOWN and randf() < heal_chance:
		last_heal_drop_time = elapsed_time
		_spawn_heal_item((e["pos"] as Vector2) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
	elif elapsed_time - last_weapon_drop_time >= WEAPON_ITEM_COOLDOWN and randf() < weapon_chance:
		last_weapon_drop_time = elapsed_time
		_spawn_weapon_item((e["pos"] as Vector2) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
	e["node"].queue_free()
	enemies.erase(e)

func _spawn_hit_spark(pos: Vector2, col: Color) -> void:
	for _i in range(3):
		var angle := randf() * TAU
		var spd   := randf_range(50.0, 110.0)
		var node  := Polygon2D.new()
		node.polygon = _make_ngon(3, 4.0)
		node.color   = Color(col.r * 1.5, col.g * 1.5, col.b * 1.5, 1.0)
		node.position = pos
		add_child(node)
		particles.append({ "node": node, "vel": Vector2(cos(angle), sin(angle)) * spd, "life": 1.0 })

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
func _spawn_fragment(pos: Vector2, value: int = 1) -> void:
	# 2026-08-04：水色だと水属性の仲間/弾と紛らわしく視認性が悪いとの指摘で、属性を持たない中立な銀白に変更
	# 2026-08-14：最頻出アイテムが白すぎて目立ちすぎるとの指摘で、控えめなグレーに落とした（識別性は形状で担保）
	# 2026-08-26：強敵撃破時（value>1）は豪華な6方向星の「上質な欠片」にする。当初は金色にしていたが
	# 武器アイテムの色(1.0,0.85,0.4)とほぼ同じで紛らわしいとの指摘を受け、明るい銀白（他のどのアイテム
	# 色とも被らない）に変更。形状（6方向星）だけで「特別」を伝える
	var premium := value > 1
	var col := Color(0.85, 0.92, 1.0) if premium else Color(0.55, 0.53, 0.6)
	var r   := FRAGMENT_R * (1.7 if premium else 1.0)
	var pts := 6 if premium else 4
	var node := _make_rune_pickup(col, r, pts, 0.4, 3.0)
	node.position = pos
	add_child(node)
	items.append({ "type": "fragment", "subtype": "", "pos": pos, "node": node, "value": value })

func _spawn_char_item(pos: Vector2) -> void:
	# 2026-07-27：属性は完全ランダムをやめ、拾った後にプレイヤーが選択する（敵の属性相性ができたため）
	var node := _make_rune_pickup(Color(0.7, 0.4, 1.0), ITEM_R, 6, 0.45, 5.0)
	node.position = pos
	add_child(node)
	items.append({ "type": "char", "subtype": "", "pos": pos, "node": node })
	_show_hint("char_item", "属性を選んで仲間を召喚！", Vector2(W * 0.5 - 100, H * 0.25))

func _spawn_heal_item(pos: Vector2) -> void:
	# 2026-08-04：欠片と同じ「星ルーン」だと見分けづらいとの指摘を受け、回復だけ十字（プラス）シルエットに変更
	var node := _make_rune_pickup(Color(0.4, 1.0, 0.55), FRAGMENT_R * 1.2, 4, 0.4, 4.0, "cross")
	node.position = pos
	add_child(node)
	items.append({ "type": "heal", "subtype": "", "pos": pos, "node": node })

func _spawn_weapon_item(pos: Vector2) -> void:
	# 2026-08-04：欠片と同じ「星ルーン」だと見分けづらいとの指摘を受け、武器だけ鋭い4方向の刃型シルエットに変更
	var node := _make_rune_pickup(Color(1.0, 0.85, 0.4), ITEM_R * 1.15, 4, 0.12, 3.5, "blade")
	node.position = pos
	add_child(node)
	items.append({ "type": "weapon", "subtype": "", "pos": pos, "node": node })

# 弾と共通の「ルーン＋グロー」言語でアイテムを表現（欠片=控えめ・キャラアイテム=豪華に）
# shape_kind："star"（既定）/"cross"（回復）/"blade"（武器、鋭い刃型の輪郭を追加）
func _make_rune_pickup(col: Color, r: float, star_points: int, inner_ratio: float, spin_speed: float, shape_kind: String = "star") -> Node2D:
	var node := Node2D.new()

	var glow := Polygon2D.new()
	glow.polygon = _make_ngon(10, r * 2.0)
	glow.color = Color(col.r, col.g, col.b, 0.3)
	node.add_child(glow)

	var rune := Polygon2D.new()
	if shape_kind == "cross":
		rune.polygon = _make_cross_pts(r, 0.38)
	else:
		rune.polygon = _make_star_pts(star_points, r, inner_ratio)
	rune.color = col
	node.add_child(rune)

	if shape_kind == "blade":
		# 刃の輪郭を強調する菱形の縁取り（星ルーンだけの他アイテムと明確に見分けがつくように）
		var frame := Polygon2D.new()
		frame.polygon = _make_ngon(4, r * 0.75)
		frame.color = Color(col.r, col.g, col.b, 0.5)
		node.add_child(frame)
		node.move_child(frame, 1)

	var tw := node.create_tween()
	tw.set_loops()
	tw.tween_property(node, "rotation", TAU, spin_speed).from(0.0)

	return node

# 十字（プラス）型ポリゴン。回復アイテムを他のアイテムと明確に見分けるためのシルエット
func _make_cross_pts(size: float, arm_ratio: float) -> PackedVector2Array:
	var a := size
	var b := size * arm_ratio
	return PackedVector2Array([
		Vector2(-b, -a), Vector2(b, -a), Vector2(b, -b),
		Vector2(a, -b), Vector2(a, b), Vector2(b, b),
		Vector2(b, a), Vector2(-b, a), Vector2(-b, b),
		Vector2(-a, b), Vector2(-a, -b), Vector2(-b, -b),
	])

func _update_items() -> void:
	var to_remove : Array[int] = []
	for i in range(items.size()):
		var it := items[i]
		if player_pos.distance_to(it["pos"] as Vector2) < ITEM_PICKUP_R + PLAYER_R:
			if it["type"] == "fragment":
				Sfx.play_item()
				it["node"].queue_free()
				to_remove.append(i)
				fragment_count += it.get("value", 1) as int
				if fragment_count >= fragment_threshold:
					fragment_count -= fragment_threshold
					fragment_threshold += FRAGMENT_THRESHOLD_GROWTH
					_spawn_char_item(player_pos + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0)))
				break
			elif it["type"] == "char":
				Sfx.play_item()
				it["node"].queue_free()
				to_remove.append(i)
				_start_attr_select()
				break
			elif it["type"] == "heal":
				Sfx.play_item()
				it["node"].queue_free()
				to_remove.append(i)
				player_hp = mini(player_hp_max, player_hp + HEAL_AMOUNT)
				_heal_allies(ALLY_HEAL_FRACTION)
				break
			elif it["type"] == "weapon":
				Sfx.play_item()
				it["node"].queue_free()
				to_remove.append(i)
				_start_weapon_select()
				break
	for i in range(to_remove.size() - 1, -1, -1):
		items.remove_at(to_remove[i])

func _start_weapon_select() -> void:
	# 属性武器の取得/強化選択（6種類中、上限未満のものから最大3択）
	var pool: Array[String] = []
	for id in ATTR_WEAPON_DATA:
		if (weapon_levels[id] as int) < ATTR_WEAPON_MAX_LEVEL:
			pool.append(id)
	if pool.is_empty(): return
	pool.shuffle()
	var choices: Array[String] = []
	for c in pool.slice(0, mini(3, pool.size())): choices.append(c)

	game_state = "upgrade_select"
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size  = Vector2(W, H)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)

	var title := _make_label("紋章の武器を選択", 22, Vector2(W * 0.5 - 100, H * 0.18))
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	layer.add_child(title)

	var card_w := 108.0
	var gap    := 12.0
	var total  := card_w * float(choices.size()) + gap * float(choices.size() - 1)
	var start_x := (W - total) * 0.5

	for ci in range(choices.size()):
		var id       := choices[ci]
		var wdata: Dictionary = ATTR_WEAPON_DATA[id]
		var accent: Color = wdata["col"]
		var level: int = weapon_levels[id] as int
		var cx := start_x + ci * (card_w + gap)
		var cy := H * 0.30

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

		var icon := _make_weapon_icon(wdata, accent)
		icon.position = Vector2(cx + card_w * 0.5, cy + 40)
		layer.add_child(icon)

		var head := _make_label(wdata["name"] as String, 15, Vector2(cx + 10, cy + 78))
		head.custom_minimum_size = Vector2(card_w - 20, 40)
		head.autowrap_mode = TextServer.AUTOWRAP_WORD
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_theme_color_override("font_color", accent)
		layer.add_child(head)

		var desc_text := "NEW！取得" if level == 0 else ("Lv.%d → %d" % [level, level + 1])
		var desc := _make_label(desc_text, 13, Vector2(cx + 10, cy + 130))
		desc.custom_minimum_size = Vector2(card_w - 20, 30)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		layer.add_child(desc)

		card.pressed.connect(func():
			weapon_levels[id] = mini(ATTR_WEAPON_MAX_LEVEL, (weapon_levels[id] as int) + 1)
			layer.queue_free()
			game_state = "battle"
		)

# キャラアイテム取得時の属性選択（2026-07-27：完全ランダムから選択制に戻した）
func _start_attr_select() -> void:
	game_state = "attr_select"
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size  = Vector2(W, H)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)

	var title := _make_label("属性を選ぶ", 22, Vector2(W * 0.5 - 70, H * 0.18))
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 1.0))
	layer.add_child(title)

	var attrs: Array[String] = ["circle", "triangle", "square"]
	var labels := { "circle": "水", "triangle": "火", "square": "土" }
	var accent_cols := {
		"circle":   Color(0.3, 0.7, 1.0),
		"triangle": Color(1.0, 0.35, 0.35),
		"square":   Color(0.85, 0.6, 0.2),
	}
	var card_w := 108.0
	var gap    := 12.0
	var total  := card_w * 3.0 + gap * 2.0
	var start_x := (W - total) * 0.5

	for ci in range(attrs.size()):
		var attr := attrs[ci]
		var accent: Color = accent_cols[attr]
		var cx := start_x + ci * (card_w + gap)
		var cy := H * 0.30

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
		icon.polygon = _make_shape_polygon(attr, 22.0)
		icon.color = accent
		icon.position = Vector2(cx + card_w * 0.5, cy + 50)
		layer.add_child(icon)

		var head := _make_label(labels[attr] as String, 20, Vector2(cx + 10, cy + 100))
		head.custom_minimum_size = Vector2(card_w - 20, 30)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_theme_color_override("font_color", accent)
		layer.add_child(head)

		card.pressed.connect(func():
			layer.queue_free()
			_start_countdown(attr)
		)

	# 2026-08-07：仲間が満タンの時は「描いても最弱と入れ替わるだけ」なので、描画の手間を省けるスキップを追加
	if allies.size() >= MAX_ALLIES:
		var skip_btn := Button.new()
		skip_btn.text = "スキップ（戦闘に戻る）"
		skip_btn.size = Vector2(total, 44)
		skip_btn.position = Vector2(start_x, H * 0.52)
		skip_btn.pressed.connect(func():
			layer.queue_free()
			game_state = "battle"
		)
		if jp_font:
			skip_btn.add_theme_font_override("font", jp_font)
		skip_btn.add_theme_font_size_override("font_size", 16)
		layer.add_child(skip_btn)

# 選択→カウントダウン→描画、の間に挟む「3・2・1」（2秒）
func _start_countdown(attr: String) -> void:
	_draw_system.start_countdown(attr)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画フェーズ（実体は DrawSystem.gd に分離済み）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _start_drawing(suggested_shape: String) -> void:
	_draw_system.start_drawing(suggested_shape)

func _refresh_draw_guide() -> void:
	_draw_system.refresh_draw_guide()

func _apply_guide_intensity() -> void:
	_draw_system.apply_guide_intensity()

func _brush_radius() -> float:
	return _draw_system.brush_radius()

func _update_drawing(delta: float) -> void:
	_draw_system.update_drawing(delta)

func _cov_color(cov: float) -> Color:
	return _draw_system.cov_color(cov)

func _show_summon_result() -> void:
	game_state = "summon_result"
	guide_line.visible = false
	guide_glow.visible = false
	guide_rune_root.visible = false
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
	var sigil_data := _Sigils.get_data(draw_sigil_id)
	var spawn_shape: String = sigil_data.get("spawn_shape", draw_shape)
	_add_ally(spawn_shape, coating_power)
	if (sigil_data.get("tier", 1) as int) >= 2:
		_show_evolve_flash(spawn_shape, player_pos)

func _add_ally(shape: String, power: int, burst: bool = true) -> void:
	if allies.size() >= MAX_ALLIES:
		var worst := _most_damaged_ally()
		if not worst.is_empty():
			_remove_ally(worst)
	_spawn_ally_at(shape, power, player_pos, burst)

func _spawn_ally_at(shape: String, power: int, pos: Vector2, burst: bool = true) -> void:
	var data: Dictionary = SHAPE_DATA[shape]
	var hp_base: int = data["hp_base"] as int
	var hp: int      = hp_base + power
	var dmg_reduction: float = data["dmg_reduction"] as float
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
	_attach_ally_idle_motion(node)
	_attach_sigil_ring(node, sz, power)
	_attach_power_aura(node, sz, power)
	allies.append({
		"shape": shape, "hp": hp, "max_hp": hp, "coating": power,
		"node": node, "attack_timer": randf_range(0.0, ATTACK_INTERVAL),
		"dmg_reduction": dmg_reduction, "tier": SHAPE_TO_TIER.get(shape, 1)
	})
	if allies.size() == 3:
		_show_hint("merge", "出撃前に装備した紋章で強さが決まる！", Vector2(W * 0.5 - 110, H * 0.20))
	if burst:
		_summon_burst(pos, col, power, SHAPE_TO_ATTR.get(shape, "") as String)

# 2026-08-04追加：ドット絵の召喚獣が正面向き固定で静止して見える問題への対処。
# 絵そのものは変えず、わずかな左右の揺れ＋呼吸のような拡縮ループだけを足して「生きてる」感を出す
func _attach_ally_idle_motion(node: Node2D) -> void:
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

func _summon_burst(pos: Vector2, col: Color, power: int, attr: String = "") -> void:
	# 召喚の瞬間に周囲の敵へ範囲攻撃＋派手な演出を出し、「召喚した」実感を強める
	# 2026-08-26：GOOD/GREAT/PERFECTの4段階に離散化する案を一度試したが、「あくまで精度と周回に
	# 基づいた値で強さを判断してほしい、召喚獣本体と同じ基準じゃないとギャップが出る」との指摘で撤回。
	# 中心の数値（半径・太さ・パーティクル数・シェイク・ノックバック）は_ally_size()と同じ
	# 「minfで頭打ちする連続スケーリング」に戻し、可変幅そのものを大きく広げることで
	# 「完全にわかる」との両立を図った。2本目のリング・フラッシュ・電撃といった追加演出だけは
	# 既存のオーラ/紋章リングと同じ閾値（30/70）でオン/オフする
	Sfx.play_evolve()
	var t := clampf(float(power) / 120.0, 0.0, 1.0)  # power=120で頭打ち（PERFECT=70はt≈0.58）

	var burst_r    := SUMMON_BURST_R * (0.7 + 1.3 * t)
	var ring_width := 3.0 + 9.0 * t
	var particle_n := 5 + int(22.0 * t)
	var shake_amt  := 6.0 + 22.0 * t
	var kb_force   := 180.0 + 320.0 * t
	var burst_col : Color = col.lerp(Color(1.0, 0.95, 0.75), 0.5 * t)

	shake_power = maxf(shake_power, shake_amt)

	var dmg := SUMMON_BURST_DMG_BASE + int(float(power) * 0.15)
	for e in enemies:
		var diff: Vector2 = (e["pos"] as Vector2) - pos
		var dist := diff.length()
		if dist < burst_r:
			_damage_enemy(e, dmg, attr)
			e["flash"] = 0.12
			var kb_dir := diff.normalized() if dist > 1.0 else Vector2(1.0, 0.0)
			e["kb"] = (e["kb"] as Vector2) + kb_dir * kb_force

	var ring := Line2D.new()
	ring.width = ring_width
	ring.default_color = burst_col
	for p in _make_ring_points(20.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	add_child(ring)
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
		for p in _make_ring_points(20.0, 1.0):
			ring2.add_point(p)
		ring2.position = pos
		add_child(ring2)
		var ring2_tw := ring2.create_tween()
		ring2_tw.tween_interval(0.08)
		ring2_tw.set_parallel(true)
		ring2_tw.tween_property(ring2, "scale", Vector2.ONE * (burst_r * 1.3 / 20.0), 0.4)
		ring2_tw.tween_property(ring2, "modulate:a", 0.0, 0.4)
		ring2_tw.chain().tween_callback(ring2.queue_free)

	if power >= 70:
		# PERFECT相当だけ、中心が一瞬白く弾けるフラッシュを追加して他ランクと混同しないようにする
		var flash := Polygon2D.new()
		flash.polygon = _make_ngon(16, 34.0)
		flash.color = Color(1.0, 1.0, 0.95, 0.9)
		flash.position = pos
		add_child(flash)
		var flash_tw := flash.create_tween()
		flash_tw.set_parallel(true)
		flash_tw.tween_property(flash, "scale", Vector2.ONE * 2.4, 0.22)
		flash_tw.tween_property(flash, "modulate:a", 0.0, 0.22)
		flash_tw.chain().tween_callback(flash.queue_free)

	_spawn_summon_particles(pos, burst_col, particle_n)
	if power >= 30:
		_spawn_lightning_crackle(pos, burst_r, 3 if power < 70 else 7)

func _spawn_summon_particles(pos: Vector2, col: Color, count: int) -> void:
	for _i in range(count):
		var angle := randf() * TAU
		var spd   := randf_range(80.0, 220.0)
		var node  := Polygon2D.new()
		node.polygon = _make_ngon(3, randf_range(6.0, 9.0))
		node.color   = col
		node.position = pos
		add_child(node)
		particles.append({ "node": node, "vel": Vector2(cos(angle), sin(angle)) * spd, "life": 1.0 })

func _spawn_lightning_crackle(pos: Vector2, visual_r: float, bolt_count: int = 6) -> void:
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
		add_child(bolt)
		var tw := bolt.create_tween()
		tw.tween_property(bolt, "modulate:a", 0.0, 0.18)
		tw.tween_callback(bolt.queue_free)

func _attach_sigil_ring(parent: Node2D, sz: float, power: int) -> void:
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

	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = ring_col
	for p in _make_ring_points(sz * 1.7, arc_frac):
		ring.add_point(p)
	parent.add_child(ring)

	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", TAU, 6.0).from(0.0)

# 2026-08-07：厚塗りの強さがリング以外で伝わらないとの指摘を受け、強い仲間だけに柔らかいオーラを追加
# 2026-08-26：「見た目が変わらない」との指摘でサイズ・アルファを拡大、視認性の要になる輪郭線（Line2D）を
# 追加。色は独自の金/水色だと属性色（土＝茶黄など）と混同しかねないため`_attach_sigil_ring`と統一。
# （この改修一式でバトル開始直後にグレー画面になる不具合が発生し、原因切り分けのためrevert→再適用を
# 繰り返した末、この関数だけが唯一「異なる型のノードを1つの配列にまとめてループで処理する」という
# コードベースに前例のない書き方をしていたため疑い、aura用・ring用でtween設定を別々に書く
# 従来通りのスタイルに書き直した）
func _attach_power_aura(parent: Node2D, sz: float, power: int) -> void:
	if power < 30: return
	var strong := power >= 70
	var aura_r := sz * (3.2 if strong else 2.4)
	var col := Color(1.0, 0.85, 0.3) if strong else Color(0.75, 0.9, 1.0)

	var aura := Polygon2D.new()
	aura.polygon = _make_ngon(24, aura_r)
	aura.color = Color(col.r, col.g, col.b, 0.5 if strong else 0.32)
	aura.z_index = -1
	parent.add_child(aura)

	var ring := Line2D.new()
	ring.width = 2.6 if strong else 1.8
	ring.default_color = col
	for p in _make_ring_points(aura_r, 1.0):
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

func _make_ring_points(radius: float, arc_frac: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 28
	var count := maxi(2, int(steps * arc_frac))
	for i in range(count + 1):
		var a: float = float(i) / float(steps) * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts

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
	_draw_system.handle_draw_input(event)

func _evaluate_lap() -> void:
	_draw_system.evaluate_lap()

func _flash_confirm_btn(col: Color) -> void:
	_draw_system.flash_confirm_btn(col)

func _show_combo_flash(count: int) -> void:
	_draw_system.show_combo_flash(count)

func _spawn_lap_pulse(col: Color) -> void:
	_draw_system.spawn_lap_pulse(col)

func _show_wave_flash(wave: int) -> void:
	var lbl := _make_label("WAVE  %d" % wave, 48, Vector2(W * 0.5 - 80, H * 0.38))
	lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	if jp_font: lbl.add_theme_font_override("font", jp_font)
	# 2026-08-18：ワールド座標のself直下に追加していたため、カメラが原点から離れるほど画面からズレて
	# 見えなくなるバグだった。他のHUDテキストと同じくCanvasLayer（ui_layer）に付けて画面固定にする
	ui_layer.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tween.tween_callback(lbl.queue_free)

func _show_evolve_flash(evolved: String, pos: Vector2) -> void:
	var names := {
		"circle_mid": "紋章・中位！", "triangle_mid": "紋章・中位！", "square_mid": "紋章・中位！",
		"double_circle": "二重丸！", "hexagram": "六芒星！", "octagram": "八芒星！",
	}
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
	_draw_system.show_lap_flash(label, col)

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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 一時停止（2026-08-06追加）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _open_pause_menu() -> void:
	if game_state != "battle": return
	paused_from_state = game_state
	game_state = "paused"
	joy_vec = Vector2.ZERO
	joy_id = -1

	pause_layer = CanvasLayer.new()
	pause_layer.layer = 30
	add_child(pause_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.size = Vector2(W, H)
	pause_layer.add_child(dim)

	var title := _make_label("一時停止中", 30, Vector2(W * 0.5 - 90, H * 0.30))
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	pause_layer.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "再開"
	resume_btn.size = Vector2(180, 56)
	resume_btn.position = Vector2(W * 0.5 - 90, H * 0.42)
	resume_btn.pressed.connect(_resume_from_pause)
	pause_layer.add_child(resume_btn)

	var restart_btn := Button.new()
	restart_btn.text = "リスタート"
	restart_btn.size = Vector2(180, 56)
	restart_btn.position = Vector2(W * 0.5 - 90, H * 0.51)
	restart_btn.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	)
	pause_layer.add_child(restart_btn)

	var stage_select_btn := Button.new()
	stage_select_btn.text = "ステージ選択へ"
	stage_select_btn.size = Vector2(180, 56)
	stage_select_btn.position = Vector2(W * 0.5 - 90, H * 0.60)
	stage_select_btn.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/LoadoutScene.tscn")
	)
	pause_layer.add_child(stage_select_btn)

	for btn in [resume_btn, restart_btn, stage_select_btn]:
		btn.add_theme_font_size_override("font_size", 22)
	if jp_font:
		_apply_font(pause_layer, jp_font)

func _resume_from_pause() -> void:
	if pause_layer:
		pause_layer.queue_free()
		pause_layer = null
	game_state = paused_from_state

# 2026-08-07：ラン終了時に生存時間ベースで「残光」を付与。エンドレスは対象外（腕試しの純度を保つ）
func _award_zankou(stage_cleared: bool) -> int:
	if current_stage >= GameData.META_LOCKED_STAGE: return 0
	var amount := int(elapsed_time / 8.0)
	if stage_cleared:
		amount += 20
	GameData.award_zankou(amount)
	return amount

func _game_over() -> void:
	game_state = "game_over"
	Engine.time_scale = 1.0  # 2026-09-24：デバッグの倍速指定が他画面まで残らないようにする
	Sfx.stop_bgm()
	var is_new := elapsed_time > best_time
	_save_best(elapsed_time)
	var zankou_gain := _award_zankou(false)

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

	if zankou_gain > 0:
		var zankou_lbl := _make_label("残光 +%d" % zankou_gain, 18, Vector2(W * 0.5 - 60, H * 0.56))
		zankou_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		ui_layer.add_child(zankou_lbl)

	var retry_btn := Button.new()
	retry_btn.text = "RETRY"
	retry_btn.size = Vector2(180, 60)
	retry_btn.position = Vector2(W * 0.5 - 90, H * 0.60)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	if jp_font:
		retry_btn.add_theme_font_override("font", jp_font)
	retry_btn.add_theme_font_size_override("font_size", 26)
	ui_layer.add_child(retry_btn)

# 2026-08-04：⑧ステージ制。制限時間に到達したら死亡扱いにせずステージクリアとして終える。
const STAGE_CLEAR_REWARD_TEXT := _Data.STAGE_CLEAR_REWARD_TEXT
func _stage_clear() -> void:
	game_state = "stage_clear"
	Engine.time_scale = 1.0  # 2026-09-24：デバッグの倍速指定が他画面まで残らないようにする
	Sfx.stop_bgm()
	GameData.clear_stage(current_stage)
	_save_best(elapsed_time)
	var zankou_gain := _award_zankou(true)

	var clear_lbl := _make_label("STAGE CLEAR!", 46, Vector2(W * 0.5 - 148, H * 0.26))
	clear_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	ui_layer.add_child(clear_lbl)

	var score_lbl := _make_label(_fmt_time(elapsed_time) + " 生存", 26, Vector2(W * 0.5 - 70, H * 0.38))
	score_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	ui_layer.add_child(score_lbl)

	if zankou_gain > 0:
		var zankou_lbl := _make_label("残光 +%d" % zankou_gain, 18, Vector2(W * 0.5 - 60, H * 0.42))
		zankou_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		ui_layer.add_child(zankou_lbl)

	var reward_txt: String = STAGE_CLEAR_REWARD_TEXT.get(current_stage, "") as String
	if reward_txt != "":
		var reward_lbl := _make_label(reward_txt, 20, Vector2(W * 0.5 - 130, H * 0.46))
		reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		ui_layer.add_child(reward_lbl)

	var next_btn := Button.new()
	next_btn.text = "次へ"
	next_btn.size = Vector2(180, 60)
	next_btn.position = Vector2(W * 0.5 - 90, H * 0.58)
	next_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LoadoutScene.tscn"))
	if jp_font:
		next_btn.add_theme_font_override("font", jp_font)
	next_btn.add_theme_font_size_override("font_size", 24)
	ui_layer.add_child(next_btn)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UI 更新
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _update_ui() -> void:
	hp_lbl.text   = "HP: %d/%d" % [player_hp, player_hp_max]
	time_lbl.text = "%.0fs" % elapsed_time
	ally_lbl.text = "仲間: %d / %d" % [allies.size(), MAX_ALLIES]
	frag_lbl.text = "召喚まで: %d/%d" % [fragment_count, fragment_threshold]
	hp_bar_fill.size.x = hp_bar_w * clampf(float(player_hp) / float(player_hp_max), 0.0, 1.0)
	frag_bar_fill.size.x = hp_bar_w * clampf(float(fragment_count) / float(fragment_threshold), 0.0, 1.0)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ユーティリティ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 新しい点を追加するとき、前の点との線分上に補間点も trace_pts に追加する
# → 「見えてる線 = 評価される線」になる
func _add_to_trace(pos: Vector2) -> void:
	_draw_system.add_to_trace(pos)

func _calc_coverage(t_pts: Array[Vector2], s_pts: Array[Vector2], brush_r: float) -> float:
	return _draw_system.calc_coverage(t_pts, s_pts, brush_r)

func _calc_coverage_contours(t_pts: Array[Vector2], contours: Array) -> float:
	return _draw_system.calc_coverage_contours(t_pts, contours)

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
	# 2026-08-04：初期仲間（coating=1で生成）が暗すぎて視認できない問題を受け、最低輝度の底上げ
	var brightness: float = 0.55 + minf(0.45, float(coating) * 0.11)
	var col := base * brightness
	# 最大近くは白く光る（白成分を混ぜる）
	if coating >= 4:
		col = col.lerp(Color.WHITE, minf(0.4, float(coating - 3) * 0.1))
	return col

func _ally_size(coating: int) -> float:
	# 2026-08-07：サイズ変化なし方針だったが、厚塗りの強さが見た目で全く伝わらないとの指摘で
	# ごくわずかに（最大+22%）だけ連動させる。衝突判定（ALLY_BASE_SIZE固定）はあえて変えない
	return ALLY_BASE_SIZE * (1.0 + minf(0.22, float(coating) / 320.0))

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

	# 瓦礫（2026-08-18追加）：「景色がなく移動の基準がわからない」との指摘で追加。壊れた紋章の世界という
	# 世界観に沿って、割れた石版の破片をワールド座標に固定して地面に散らす。星と同じハッシュ方式でコードのみ
	# 完結させ新規絵の発注はしない。前景（弾・アイテム・敵）を邪魔しないよう低彩度・低コントラストに抑える
	var debris_cell := 170.0
	var d_ox := fmod(tl.x - pad, debris_cell)
	var d_oy := fmod(tl.y - pad, debris_cell)
	for i in range(-1, int((W + pad * 2) / debris_cell) + 2):
		for j in range(-1, int((H + pad * 2) / debris_cell) + 2):
			var wx := tl.x - pad - d_ox + i * debris_cell
			var wy := tl.y - pad - d_oy + j * debris_cell
			var cx := int(round(wx / debris_cell))
			var cy := int(round(wy / debris_cell))
			var h := _hash01(cx * 7 + 3, cy * 13 + 5)
			if h >= 0.3: continue
			var h2 := _hash01(cx + 101, cy + 202)
			var center := Vector2(wx, wy) + Vector2((h - 0.15) * debris_cell * 0.6, (h2 - 0.15) * debris_cell * 0.6)
			var size := 12.0 + h2 * 16.0
			var rot := h * TAU
			var pts := PackedVector2Array()
			var vcount := 4 + int(h2 * 3.0)
			for k in range(vcount):
				var a := rot + (float(k) / float(vcount)) * TAU
				var jitter := 0.55 + _hash01(cx + k * 17, cy + k * 31) * 0.55
				pts.append(center + Vector2(cos(a), sin(a)) * size * jitter)
			draw_colored_polygon(pts, Color(0.16, 0.15, 0.24, 0.4 + h2 * 0.15))

	# 足元の「世界最後の陣」（2026-07-17再改訂：色を主張しない中立トーンに落とし、
	# HPに連動して欠けていく仕様に変更。「なぜここに陣があるのか」に意味を持たせた）
	var pulse := 0.85 + 0.15 * sin(elapsed_time * 1.2)
	var sigil_r := 140.0
	var sigil_col := Color(0.55, 0.55, 0.62)
	var hp_frac := clampf(float(player_hp) / float(player_hp_max), 0.0, 1.0)
	var start_a := -PI * 0.5
	var arc_len := TAU * hp_frac
	if arc_len > 0.01:
		draw_arc(player_pos, sigil_r, start_a, start_a + arc_len, 56, Color(sigil_col.r, sigil_col.g, sigil_col.b, 0.07 * pulse), 8.0)   # 淡いグロー
		draw_arc(player_pos, sigil_r, start_a, start_a + arc_len, 56, Color(sigil_col.r, sigil_col.g, sigil_col.b, 0.22 * pulse), 1.5)   # 輪郭

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

# 2026-08-25：武器選択カードが全種類「回転する★」で見分けがつかず、初見だと効果が想像できない
# との指摘。武器のpattern（6種で全て別々）ごとに効果を示唆する簡易アイコンを生成する
func _make_weapon_icon(wdata: Dictionary, accent: Color) -> Node2D:
	var root := Node2D.new()
	match wdata["pattern"] as String:
		"rain":
			for i in range(3):
				var drop := Polygon2D.new()
				drop.polygon = PackedVector2Array([Vector2(0, -9), Vector2(5, 4), Vector2(0, 9), Vector2(-5, 4)])
				drop.color = accent
				drop.position = Vector2((i - 1) * 12, -14)
				root.add_child(drop)
				var tw := drop.create_tween()
				tw.set_loops()
				tw.tween_interval(i * 0.2)
				tw.tween_property(drop, "position:y", 14.0, 0.8).from(-14.0)
		"projectile":
			var shaft := Line2D.new()
			shaft.width = 3.0
			shaft.default_color = accent
			shaft.add_point(Vector2(-16, 0))
			shaft.add_point(Vector2(10, 0))
			root.add_child(shaft)
			var head := Polygon2D.new()
			head.polygon = PackedVector2Array([Vector2(10, -7), Vector2(20, 0), Vector2(10, 7)])
			head.color = accent
			root.add_child(head)
			if wdata.get("pierce", false):
				for i in range(2):
					var dot := Polygon2D.new()
					dot.polygon = _make_ngon(8, 3.0)
					dot.color = Color(accent.r, accent.g, accent.b, 0.55)
					dot.position = Vector2(16 + i * 9, 0)
					root.add_child(dot)
			elif wdata.has("explode_r"):
				var ring := Line2D.new()
				ring.width = 1.6
				ring.default_color = accent
				for p in _make_ring_points(9.0, 1.0): ring.add_point(p)
				ring.position = Vector2(14, 0)
				root.add_child(ring)
				var rtw := ring.create_tween()
				rtw.set_loops()
				rtw.tween_property(ring, "scale", Vector2(1.8, 1.8), 0.7).from(Vector2(0.6, 0.6))
				rtw.parallel().tween_property(ring, "modulate:a", 0.0, 0.7).from(1.0)
		"chain":
			var pts := [Vector2(-16, -8), Vector2(-4, 6), Vector2(6, -6), Vector2(16, 8)]
			for i in range(pts.size() - 1):
				var seg := Line2D.new()
				seg.width = 2.6
				seg.default_color = accent
				seg.add_point(pts[i])
				seg.add_point(pts[i + 1])
				root.add_child(seg)
			for p in pts:
				var node := Polygon2D.new()
				node.polygon = _make_ngon(8, 3.2)
				node.color = accent
				node.position = p
				root.add_child(node)
		"beam":
			var bar := Polygon2D.new()
			bar.polygon = PackedVector2Array([Vector2(-17, -3), Vector2(17, -3), Vector2(17, 3), Vector2(-17, 3)])
			bar.color = accent
			root.add_child(bar)
			var btw := bar.create_tween()
			btw.set_loops()
			btw.tween_property(bar, "modulate:a", 0.4, 0.5)
			btw.tween_property(bar, "modulate:a", 1.0, 0.5)
		"pulse":
			for i in range(2):
				var ring := Line2D.new()
				ring.width = 2.0
				ring.default_color = accent
				for p in _make_ring_points(6.0, 1.0): ring.add_point(p)
				root.add_child(ring)
				var rtw := ring.create_tween()
				rtw.set_loops()
				rtw.tween_interval(i * 0.55)
				rtw.tween_property(ring, "scale", Vector2(3.2, 3.2), 1.1).from(Vector2(0.4, 0.4))
				rtw.parallel().tween_property(ring, "modulate:a", 0.0, 1.1).from(0.9)
		_:
			var icon := Polygon2D.new()
			icon.polygon = _make_star_pts(4, 20.0, 0.4)
			icon.color = accent
			root.add_child(icon)
	return root

func _make_shape_polygon(shape: String, size: float) -> PackedVector2Array:
	match shape:
		"circle":        return _make_ngon(12, size)
		"triangle":      return _make_ngon(3, size)
		"square":        return _make_ngon(4, size)
		"circle_mid":    return _make_ngon(18, size * 1.2)
		"triangle_mid":  return _make_star_pts(3, size * 1.25, 0.6)
		"square_mid":    return _make_star_pts(4, size * 1.25, 0.6)
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
