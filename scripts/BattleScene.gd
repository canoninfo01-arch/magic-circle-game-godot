extends Node2D

const _Shapes = preload("res://scripts/Shapes.gd")
const _Sigils = preload("res://scripts/Sigils.gd")

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
const ENEMY_SPEED_BASE: float = 38.0  # 2026-07-16：初期の速すぎる「追いかけっこ」感を抑えるため75→55→46→38にさらに減速
const ENEMY_HP_BASE:    int   = 30
const ENEMY_R:          float = 14.0  # デフォルト（後方互換）
const ENEMY_DAMAGE:     int   = 1

const ENEMY_TYPES := {
	# 2026-07-27：属性相性をはっきりさせるため、シャード（速い・脆い）とヴォイドマーク（遅い・硬い）を尖らせた
	"shard":      { "sides": 3, "radius": 12.0, "color": Color(1.0, 0.2,  0.35), "hp_m": 0.5,  "spd_m": 1.6  },
	"fracture":   { "sides": 5, "radius": 18.0, "color": Color(1.0, 0.5,  0.1),  "hp_m": 2.0,  "spd_m": 0.85 },
	"void_mark":  { "sides": 6, "radius": 26.0, "color": Color(0.75, 0.2, 1.0),  "hp_m": 5.5,  "spd_m": 0.4  },
}

# 特定ウェーブ番号は単一タイプ強制（2026-07-27追加）。「このウェーブは火が輝く」等の山場を作る狙い。
# countは通常式（6+wave_count*2）を使わず個別指定（void_markは1体が重いので少数精鋭にする）
const WAVE_FORCED_TYPE := {
	3: { "type": "shard",     "count": 12 },
	5: { "type": "void_mark", "count": 4  },
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

const FRAGMENT_THRESHOLD_BASE := 5
const CHAR_ITEM_CHANCE  := 0.05  # 2026-07-27：0.08→0.05にさらに減速（10体到達を遅くする狙い）
const FIRST_CHAR_ITEM_GUARANTEE_KILLS := 3  # 2026-07-27：最初の1体は運任せにしない保証
const HEAL_ITEM_CHANCE  := 0.05
const HEAL_AMOUNT       := 2
const ALLY_HEAL_FRACTION := 0.15  # 2026-07-27：仲間にも回復効果を追加（最大HPの割合回復、仮）
const WEAPON_ITEM_CHANCE := 0.12  # 2026-07-18：出現率が低すぎるとの指摘で0.06→0.12に増加
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

const DRAW_DURATION    := 6.5  # 2026-07-27：8.0から短縮（延長は欠片カードの新選択肢で対応）
const DRAW_GUIDE_R     := 120.0
const DRAW_COVER_THR   := 0.70
const DRAW_BRUSH_R     := 18.0  # 2026-07-27：ブラシ半径は紋章サイズに関わらず絶対px固定（tierが上がっても許容範囲を広げない）
const MISS_GAIN        := 3  # 2026-07-27：MISSでも召喚不能にならないよう最低限の加点を入れる
const COATING_DMG_K    := 0.005  # 属性武器ダメージの厚塗り係数（1.0 + coating_power×K、要調整）

const WEAPON_SUBTYPES  := ["atk_speed", "damage", "move_speed", "draw_time"]  # 2026-07-27：描画時間アップを追加、4種から3択

const SHAPE_DATA := {
	# 役割：水=速攻・機動／火=重火力・鈍足／土=盾・耐久（2026-07-12 属性名と役割の対応を再整理。「角の数=弾の数」ルールは廃止）
	# dmg_reduction：被ダメージ軽減率（2026-07-23追加、仮数値）。属性のみで決まり、tierでは変化しない
	# bullets：2026-07-27確定、属性のみで決まりtierでは変化しない（基礎攻撃を地味にして属性武器を目立たせる狙い）
	# tierの伸びはhp_baseの底上げと、厚塗り獲得ポイント・属性武器のtier保証倍率（Sigils.gd）が担う
	"circle":        { "color": Color(0.3,  0.7,  1.0),  "bullets": 1,  "speed_m": 1.6, "dmg_reduction": 0.0,  "hp_base": 35  },
	"triangle":      { "color": Color(1.0,  0.35, 0.35), "bullets": 2,  "speed_m": 0.7, "dmg_reduction": 0.15, "hp_base": 55  },
	"square":        { "color": Color(0.85, 0.6,  0.2),  "bullets": 0,  "speed_m": 1.0, "dmg_reduction": 0.3,  "hp_base": 80  },
	# tier2紋章（中間形態）。HP数値は仮置き——基本形と上位形の中間。バランス調整は別パスで行う（プラン§6）
	"circle_mid":    { "color": Color(0.25, 0.65, 1.0),  "bullets": 1,  "speed_m": 1.6, "dmg_reduction": 0.0,  "hp_base": 55  },
	"triangle_mid":  { "color": Color(1.0,  0.28, 0.28), "bullets": 2,  "speed_m": 0.7, "dmg_reduction": 0.15, "hp_base": 85  },
	"square_mid":    { "color": Color(0.8,  0.52, 0.15), "bullets": 0,  "speed_m": 1.0, "dmg_reduction": 0.3,  "hp_base": 135 },
	# tier3紋章（上位形態。旧・合体進化形の見た目/ステータスをそのまま流用）
	"double_circle": { "color": Color(0.2,  0.6,  1.0),  "bullets": 1,  "speed_m": 1.6, "dmg_reduction": 0.0,  "hp_base": 80  },
	"hexagram":      { "color": Color(1.0,  0.2,  0.2),  "bullets": 2,  "speed_m": 0.7, "dmg_reduction": 0.15, "hp_base": 120 },
	"octagram":      { "color": Color(0.75, 0.45, 0.1),  "bullets": 0,  "speed_m": 0.7, "dmg_reduction": 0.3,  "hp_base": 200 },
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 属性武器（2026-07-18：召喚獣ごとの武器バリエーション。属性単位で共有・武器アイテムで取得/強化）
# 既存の基本攻撃（SHAPE_DATAのbullets）はそのまま残り、属性武器は上乗せで発動する
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const ATTR_WEAPON_MAX_LEVEL := 3

# pattern: "projectile"（弾。pierce/homing/explode_rはオプション）"chain"（連鎖電撃）
#          "orbit"（常時回転する近接武器）"pulse"（自分中心の定期衝撃波）
const ATTR_WEAPON_DATA := {
	"water_homing": { "attr": "circle",   "name": "追尾の光弾",     "pattern": "projectile", "cooldown": 1.4, "dmg": 6,  "col": Color(0.55, 0.85, 1.0), "homing": true },
	"water_pierce": { "attr": "circle",   "name": "貫通の矢",       "pattern": "projectile", "cooldown": 1.0, "dmg": 5,  "col": Color(0.7,  0.95, 1.0), "pierce": true },
	"fire_explode": { "attr": "triangle", "name": "爆裂の紋章弾",   "pattern": "projectile", "cooldown": 1.6, "dmg": 8,  "col": Color(1.0,  0.5,  0.2),  "explode_r": 55.0 },
	"fire_chain":   { "attr": "triangle", "name": "稲妻の鎖",       "pattern": "chain",      "cooldown": 1.8, "dmg": 6,  "col": Color(1.0,  0.9,  0.3),  "jumps": 3, "range": 160.0 },
	"earth_orbit":  { "attr": "square",   "name": "回転する紋章の盾", "pattern": "orbit",    "cooldown": 0.0, "dmg": 4,  "col": Color(0.95, 0.75, 0.3),  "radius": 34.0, "rotate_speed": 2.6 },
	"earth_wave":   { "attr": "square",   "name": "衝撃の紋章波",   "pattern": "pulse",      "cooldown": 2.4, "dmg": 9,  "col": Color(0.85, 0.65, 0.25), "radius": 75.0 },
}

# tier2/3の紋章形態も基礎属性として扱う（どの形態でも同じ属性武器を使える）
const SHAPE_TO_ATTR := {
	"circle": "circle", "circle_mid": "circle", "double_circle": "circle",
	"triangle": "triangle", "triangle_mid": "triangle", "hexagram": "triangle",
	"square": "square", "square_mid": "square", "octagram": "square",
}

# 属性武器ダメージのtier保証倍率を引くための逆引き（2026-07-27追加）
const SHAPE_TO_TIER := {
	"circle": 1, "triangle": 1, "square": 1,
	"circle_mid": 2, "triangle_mid": 2, "square_mid": 2,
	"double_circle": 3, "hexagram": 3, "octagram": 3,
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
# ally: { shape, hp, max_hp, coating, node:Polygon2D, attack_timer, weapon_timers, orbiters }
var allies : Array[Dictionary] = []
var weapon_stats := { "atk_speed": 1.0, "damage": 1.0, "move_speed": 1.0 }
var weapon_levels := {
	"water_homing": 0, "water_pierce": 0,
	"fire_explode": 0, "fire_chain": 0,
	"earth_orbit": 0, "earth_wave": 0,
}

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
var draw_shape       := "circle"          # 属性名（circle/triangle/square）。武器等の参照キーとして維持
var draw_sigil_id    := "circle_1"        # 装備中の紋章id（Sigils.SIGIL_DATA参照）。描画ガイド・召喚結果を決める
var current_guide_r  := DRAW_GUIDE_R      # 装備tierのguide_scaleを反映した、今セッションの紋章半径
var brush_ratio_mult := 1.0               # ペン太さの倍率。将来アイテムで調整する余地として用意（現状は常に1.0）
var draw_time_bonus  := 0.0               # 欠片カード「描画時間アップ」で加算される秒数（2026-07-27）
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
var frag_bar_fill : ColorRect   = null
var hp_bar_w      := 130.0
var fragment_count := 0
var fragment_threshold := FRAGMENT_THRESHOLD_BASE  # 2026-07-27：発動のたびに引き上げる（後半のカード頻発を抑制）
var kills_without_char_item := 0
var got_first_char_item := false

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

	frag_lbl = _make_label("欠片: 0/%d" % fragment_threshold, 14, Vector2(14, 72))
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
	var forced_data: Dictionary = WAVE_FORCED_TYPE.get(wave_count, {}) as Dictionary
	var forced: String = forced_data.get("type", "") as String
	var count: int = forced_data.get("count", 6 + wave_count * 2) as int
	for _i in range(count):
		_spawn_one_enemy(forced)
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

func _spawn_one_enemy(forced_type: String = "") -> void:
	var pos: Vector2  = _random_edge_pos()
	var etype: String = forced_type if forced_type != "" else _pick_enemy_type()
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
				var reduction: float = a["dmg_reduction"] as float
				a["hp"] -= 8 * (1.0 - reduction)
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
	var attr: String = SHAPE_TO_ATTR.get(a["shape"] as String, "") as String
	if attr.is_empty(): return
	if not a.has("weapon_timers"):
		a["weapon_timers"] = {}
	var timers: Dictionary = a["weapon_timers"]

	for id in ATTR_WEAPON_DATA:
		var wdata: Dictionary = ATTR_WEAPON_DATA[id]
		if (wdata["attr"] as String) != attr: continue
		var level: int = weapon_levels[id] as int
		if level <= 0: continue

		if (wdata["pattern"] as String) == "orbit":
			_update_ally_orbiter(a, id, wdata, level, delta)
			continue

		if not timers.has(id):
			timers[id] = randf_range(0.0, wdata["cooldown"] as float)
		timers[id] = (timers[id] as float) - delta
		if (timers[id] as float) <= 0.0:
			_fire_attr_weapon(a, id, wdata, level)
			timers[id] = (wdata["cooldown"] as float) / (1.0 + float(level - 1) * 0.15)

# 属性武器ダメージのtier保証倍率×厚塗り係数（2026-07-27）。基礎弾攻撃には適用しない
func _ally_weapon_tier_mult(a: Dictionary) -> float:
	var tier: int = a.get("tier", 1) as int
	var tier_mult: float = _Sigils.TIER_DMG_MULT.get(tier, 1.0) as float
	var coating: int = a.get("coating", 0) as int
	var coating_mult := 1.0 + float(coating) * COATING_DMG_K
	return tier_mult * coating_mult

func _fire_attr_weapon(a: Dictionary, _id: String, wdata: Dictionary, level: int) -> void:
	var ally_pos: Vector2 = a["node"].position
	var nearest := _nearest_enemy(ally_pos)
	if nearest.is_empty(): return
	var dmg := int(float(wdata["dmg"] as int) * (1.0 + float(level - 1) * 0.25) * (weapon_stats["damage"] as float) * _ally_weapon_tier_mult(a))
	var col: Color = wdata["col"]
	match wdata["pattern"] as String:
		"projectile":
			var dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()
			_fire_bullet(ally_pos, dir, dmg, col, wdata.get("pierce", false), wdata.get("homing", false), wdata.get("explode_r", 0.0) as float)
			Sfx.play_shoot()
		"chain":
			_fire_chain_lightning(ally_pos, dmg, wdata["jumps"] as int, wdata["range"] as float, col)
		"pulse":
			_fire_pulse(ally_pos, dmg, wdata["radius"] as float, col)

func _update_ally_orbiter(a: Dictionary, id: String, wdata: Dictionary, level: int, delta: float) -> void:
	if not a.has("orbiters"):
		a["orbiters"] = {}
	var orbiters: Dictionary = a["orbiters"]
	if not orbiters.has(id):
		var node := Polygon2D.new()
		node.polygon = _make_star_pts(4, 8.0, 0.4)
		node.color = wdata["col"]
		add_child(node)
		orbiters[id] = { "node": node, "angle": randf() * TAU, "hit_cd": 0.0 }

	var orb: Dictionary = orbiters[id]
	orb["angle"] = (orb["angle"] as float) + delta * (wdata["rotate_speed"] as float)
	var ally_pos: Vector2 = a["node"].position
	var offset := Vector2(cos(orb["angle"] as float), sin(orb["angle"] as float)) * (wdata["radius"] as float)
	var world_pos := ally_pos + offset
	(orb["node"] as Polygon2D).position = world_pos

	orb["hit_cd"] = maxf(0.0, (orb["hit_cd"] as float) - delta)
	if (orb["hit_cd"] as float) <= 0.0:
		var dmg := int(float(wdata["dmg"] as int) * (1.0 + float(level - 1) * 0.25) * (weapon_stats["damage"] as float) * _ally_weapon_tier_mult(a))
		for e in enemies:
			if world_pos.distance_to(e["pos"] as Vector2) < (e["radius"] as float) + 10.0:
				e["hp"] = (e["hp"] as int) - dmg
				e["flash"] = 0.12
				# 2026-07-28：土は遠距離弾を持たないため、盾が弾かないと密着ダメージを避けられない指摘を受けて追加
				# 2026-07-29：さらに強めてほしいとの要望で180→300に増加
				var kb_dir: Vector2 = ((e["pos"] as Vector2) - world_pos).normalized()
				e["kb"] = (e["kb"] as Vector2) + kb_dir * 300.0
				orb["hit_cd"] = 0.35
				break

func _fire_chain_lightning(from: Vector2, dmg: int, jumps: int, chain_range: float, col: Color) -> void:
	var hit_enemies: Array = []
	var cur_pos := from
	var any_hit := false
	for _j in range(jumps):
		var target := {}
		var best_d := chain_range
		for e in enemies:
			if hit_enemies.has(e): continue
			var d: float = cur_pos.distance_to(e["pos"] as Vector2)
			if d < best_d:
				best_d = d
				target = e
		if target.is_empty(): break
		target["hp"] = (target["hp"] as int) - dmg
		target["flash"] = 0.12
		_draw_lightning_bolt(cur_pos, target["pos"] as Vector2, col)
		hit_enemies.append(target)
		cur_pos = target["pos"] as Vector2
		any_hit = true
	if any_hit:
		Sfx.play_shoot()

func _draw_lightning_bolt(from: Vector2, to: Vector2, col: Color) -> void:
	var bolt := Line2D.new()
	bolt.width = 2.5
	bolt.default_color = col
	var steps := 5
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var base := from.lerp(to, t)
		var jitter := Vector2.ZERO if (s == 0 or s == steps) else Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		bolt.add_point(base + jitter)
	add_child(bolt)
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "modulate:a", 0.0, 0.2)
	tw.tween_callback(bolt.queue_free)

func _fire_pulse(pos: Vector2, dmg: int, radius: float, col: Color) -> void:
	Sfx.play_shoot()
	for e in enemies:
		if pos.distance_to(e["pos"] as Vector2) < radius:
			e["hp"] = (e["hp"] as int) - dmg
			e["flash"] = 0.12
			# 2026-07-28：衝撃波の名前通り、当てた敵を外側へ弾き飛ばす（土の武器は近接のみで弾かないと密着され続けるため）
			# 2026-07-29：さらに強めてほしいとの要望で220→400に増加
			var kb_dir: Vector2 = ((e["pos"] as Vector2) - pos).normalized()
			e["kb"] = (e["kb"] as Vector2) + kb_dir * 400.0
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = col
	for p in _make_ring_points(10.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	add_child(ring)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * (radius / 10.0), 0.3)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.3)
	ring_tw.chain().tween_callback(ring.queue_free)

func _position_ring(ring: Array[Dictionary], radius: float, delta: float, angle_offset: float = 0.0) -> void:
	if ring.is_empty(): return
	for i in range(ring.size()):
		var angle: float = float(i) / float(ring.size()) * TAU + angle_offset
		var target := player_pos + Vector2(cos(angle), sin(angle)) * radius
		var spd: float = (SHAPE_DATA[ring[i]["shape"] as String]["speed_m"] as float) * 165.0  # 2026-07-16：追従速度を300→230→195→165にさらに減速
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

func _fire_bullet(from: Vector2, dir: Vector2, dmg: int, col: Color = Color(1.0, 1.0, 0.75), pierce: bool = false, homing: bool = false, explode_r: float = 0.0) -> void:
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
	bullets.append({
		"pos": from, "dir": dir, "traveled": 0.0, "dmg": dmg, "node": node, "col": col,
		"pierce": pierce, "homing": homing, "explode_r": explode_r, "hit_set": []
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
				e["hp"] -= b["dmg"]
				e["flash"] = 0.12
				hit = true
				if pierce:
					hit_set.append(e)
				var explode_r: float = b.get("explode_r", 0.0)
				if explode_r > 0.0:
					_explode_at(b["pos"] as Vector2, b["dmg"] as int, explode_r, b["col"] as Color, e)
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

func _explode_at(pos: Vector2, dmg: int, radius: float, col: Color, exclude: Dictionary) -> void:
	for e in enemies:
		if e == exclude: continue
		if pos.distance_to(e["pos"] as Vector2) < radius:
			e["hp"] -= dmg
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
	_spawn_fragment(e["pos"] as Vector2)
	var force_char_item := false
	if not got_first_char_item:
		kills_without_char_item += 1
		if kills_without_char_item >= FIRST_CHAR_ITEM_GUARANTEE_KILLS:
			force_char_item = true
	if force_char_item or randf() < CHAR_ITEM_CHANCE:
		got_first_char_item = true
		_spawn_char_item((e["pos"] as Vector2) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
	elif randf() < HEAL_ITEM_CHANCE:
		_spawn_heal_item((e["pos"] as Vector2) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
	elif randf() < WEAPON_ITEM_CHANCE:
		_spawn_weapon_item((e["pos"] as Vector2) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
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
	# 2026-07-27：属性は完全ランダムをやめ、拾った後にプレイヤーが選択する（敵の属性相性ができたため）
	var node := _make_rune_pickup(Color(0.7, 0.4, 1.0), ITEM_R, 6, 0.45, 5.0)
	node.position = pos
	add_child(node)
	items.append({ "type": "char", "subtype": "", "pos": pos, "node": node })
	_show_hint("char_item", "属性を選んで仲間を召喚！", Vector2(W * 0.5 - 100, H * 0.25))

func _spawn_heal_item(pos: Vector2) -> void:
	var node := _make_rune_pickup(Color(0.4, 1.0, 0.55), FRAGMENT_R * 1.2, 4, 0.4, 4.0)
	node.position = pos
	add_child(node)
	items.append({ "type": "heal", "subtype": "", "pos": pos, "node": node })

func _spawn_weapon_item(pos: Vector2) -> void:
	var node := _make_rune_pickup(Color(1.0, 0.85, 0.4), ITEM_R * 1.1, 8, 0.4, 3.5)
	node.position = pos
	add_child(node)
	items.append({ "type": "weapon", "subtype": "", "pos": pos, "node": node })

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
				if fragment_count >= fragment_threshold:
					fragment_count -= fragment_threshold
					fragment_threshold += 1  # 2026-07-27：発動のたびに次の閾値を引き上げる（後半のカード頻発を抑制）
					_start_upgrade_select()
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
				player_hp = mini(PLAYER_HP_MAX, player_hp + HEAL_AMOUNT)
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
		"draw_time":  ["描画時間アップ", "+1.5秒 描画時間"],
	}
	var accent_cols := {
		"atk_speed":  Color(0.4, 1.0, 1.0),
		"damage":     Color(1.0, 0.45, 0.3),
		"move_speed": Color(0.5, 1.0, 0.6),
		"draw_time":  Color(0.85, 0.6, 1.0),
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
		"draw_time":  draw_time_bonus = draw_time_bonus + 1.5

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

	var card_w := 160.0
	var gap    := 16.0
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

		var icon := Polygon2D.new()
		icon.polygon = _make_star_pts(4, 20.0, 0.4)
		icon.color = accent
		icon.position = Vector2(cx + card_w * 0.5, cy + 40)
		layer.add_child(icon)
		var icon_tw := icon.create_tween()
		icon_tw.set_loops()
		icon_tw.tween_property(icon, "rotation", TAU, 4.0).from(0.0)

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
	var card_w := 160.0
	var gap    := 16.0
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

# 選択→カウントダウン→描画、の間に挟む「3・2・1」（2秒）
func _start_countdown(attr: String) -> void:
	game_state = "countdown"
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var lbl := _make_label("3", 80, Vector2(W * 0.5 - 30, H * 0.4))
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	layer.add_child(lbl)

	var texts := ["3", "2", "1"]
	var tw := lbl.create_tween()
	for t in texts:
		tw.tween_callback(func(): lbl.text = t)
		tw.tween_interval(2.0 / 3.0)
	tw.tween_callback(func():
		layer.queue_free()
		_start_drawing(attr)
	)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 描画フェーズ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func _start_drawing(suggested_shape: String) -> void:
	game_state = "drawing"
	draw_shape = suggested_shape
	draw_sigil_id = GameData.get_equipped_sigil(suggested_shape)
	draw_timer = DRAW_DURATION + draw_time_bonus
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
	var sigil_data := _Sigils.get_data(draw_sigil_id)
	var contour_defs: Array = sigil_data.get("contours", [{"shape": draw_shape, "radius_ratio": 1.0, "weight": 1.0}])
	var guide_scale: float = sigil_data.get("guide_scale", 1.0)
	current_guide_r = DRAW_GUIDE_R * guide_scale

	contour_weights.clear()
	for c in contour_defs:
		contour_weights.append((c as Dictionary).get("weight", 1.0) as float)

	sample_contours = _Shapes.make_sample_contours(contour_defs, cx, cy, current_guide_r)
	var contours := _Shapes.make_guide_contours(contour_defs, cx, cy, current_guide_r)

	guide_line.clear_points()
	guide_glow.clear_points()
	for p in contours[0]:
		guide_line.add_point(p)
		guide_glow.add_point(p)

	if contours.size() > 1:
		guide_line_inner.clear_points()
		guide_glow_inner.clear_points()
		for p in contours[1]:
			guide_line_inner.add_point(p)
			guide_glow_inner.add_point(p)
		guide_line_inner.visible = true
		guide_glow_inner.visible = true
	else:
		guide_line_inner.visible = false
		guide_glow_inner.visible = false

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
	if guide_line_inner.visible:
		guide_line_inner.default_color = guide_line.default_color
		guide_line_inner.width = guide_line.width
		guide_glow_inner.default_color = guide_glow.default_color
		guide_glow_inner.width = guide_glow.width

# ブラシの判定半径。紋章サイズ（tier・輪郭）に関わらず絶対px固定（2026-07-27）
func _brush_radius() -> float:
	return DRAW_BRUSH_R * brush_ratio_mult

func _update_drawing(delta: float) -> void:
	draw_timer -= delta
	draw_timer_lbl.text = "%.1f" % maxf(0.0, draw_timer)

	if not trace_pts.is_empty() and not sample_contours.is_empty():
		var cov := _calc_coverage_contours(trace_pts, sample_contours)
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
	_attach_sigil_ring(node, sz, power)
	allies.append({
		"shape": shape, "hp": hp, "max_hp": hp, "coating": power,
		"node": node, "attack_timer": randf_range(0.0, ATTACK_INTERVAL),
		"dmg_reduction": dmg_reduction, "tier": SHAPE_TO_TIER.get(shape, 1)
	})
	if allies.size() == 3:
		_show_hint("merge", "出撃前に装備した紋章で強さが決まる！", Vector2(W * 0.5 - 110, H * 0.20))
	if burst:
		_summon_burst(pos, col, power)

func _summon_burst(pos: Vector2, col: Color, power: int) -> void:
	# 召喚の瞬間に周囲の敵へ範囲攻撃＋派手な演出を出し、「召喚した」実感を強める
	# 2026-07-16：ノックバックの強さも召喚パワーに応じて増すよう変更（強い召喚ほど吹き飛ばしも大きく）
	# 2026-07-18：見た目（リングの広がり・パーティクル数・電撃）もパワーに連動させ、強い召喚ほど派手になるように拡張
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

	var visual_r := SUMMON_BURST_R * (1.0 + minf(0.7, float(power) / 150.0))
	var ring := Line2D.new()
	ring.width = 4.0 + minf(6.0, float(power) * 0.05)
	ring.default_color = col
	for p in _make_ring_points(20.0, 1.0):
		ring.add_point(p)
	ring.position = pos
	add_child(ring)
	var ring_tw := ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(ring, "scale", Vector2.ONE * (visual_r / 20.0), 0.35)
	ring_tw.tween_property(ring, "modulate:a", 0.0, 0.35)
	ring_tw.chain().tween_callback(ring.queue_free)

	_spawn_summon_particles(pos, col, power)
	if power >= 70:
		_spawn_lightning_crackle(pos, visual_r)

func _spawn_summon_particles(pos: Vector2, col: Color, power: int) -> void:
	var count: int = mini(20, 6 + power / 8)
	for _i in range(count):
		var angle := randf() * TAU
		var spd   := randf_range(80.0, 220.0)
		var node  := Polygon2D.new()
		node.polygon = _make_ngon(3, randf_range(6.0, 9.0))
		node.color   = col
		node.position = pos
		add_child(node)
		particles.append({ "node": node, "vel": Vector2(cos(angle), sin(angle)) * spd, "life": 1.0 })

func _spawn_lightning_crackle(pos: Vector2, visual_r: float) -> void:
	# パワーが高い召喚だけ、電撃っぽいジグザグ線を放射状に走らせる（「バリバリ」演出）
	var bolt_count := 6
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
	if trace_pts.is_empty() or sample_contours.is_empty(): return
	var cov := _calc_coverage_contours(trace_pts, sample_contours)
	trace_pts.clear()
	trace_line.clear_points()
	trace_line.modulate = Color.WHITE
	cov_lbl.text = "0%"

	var lap_gain: Dictionary = _Sigils.get_data(draw_sigil_id).get("lap_gain", {"perfect": 35, "great": 20, "good": 10})
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
		gain = MISS_GAIN; label = "MISS..."; col = Color(0.8, 0.4, 0.4); grade = "miss"

	var pitch := 1.0 + minf(0.5, float(coating_count) * 0.08)
	Sfx.play_lap(grade, pitch)
	coating_power += gain
	if grade != "miss":
		coating_count += 1
		coating_lbl.text = "×%d" % coating_count
		_apply_guide_intensity()
		_spawn_lap_pulse(col)
		_show_combo_flash(coating_count)
	_show_lap_flash(label, col)

func _show_combo_flash(count: int) -> void:
	# 連続成功回数そのものを大きく見せて「積み上がってる」実感を明示する
	if count < 2: return
	var size := 24 + mini(24, (count - 1) * 4)
	var t := clampf(float(count) / 8.0, 0.0, 1.0)
	var col := Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.85, 0.3), t)
	var lbl := _make_label("%d連続！" % count, size, Vector2(W * 0.5 - 70, H * 0.5 + 22))
	lbl.custom_minimum_size = Vector2(140, size + 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", col)
	draw_layer.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)
	shake_power = maxf(shake_power, 4.0 + minf(10.0, float(count) * 1.0))

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
	frag_lbl.text = "欠片: %d/%d" % [fragment_count, fragment_threshold]
	hp_bar_fill.size.x = hp_bar_w * clampf(float(player_hp) / float(PLAYER_HP_MAX), 0.0, 1.0)
	frag_bar_fill.size.x = hp_bar_w * clampf(float(fragment_count) / float(fragment_threshold), 0.0, 1.0)

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

func _calc_coverage(t_pts: Array[Vector2], s_pts: Array[Vector2], brush_r: float) -> float:
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
func _calc_coverage_contours(t_pts: Array[Vector2], contours: Array) -> float:
	if contours.is_empty(): return 0.0
	var brush_r := _brush_radius()
	var total := 0.0
	for i in contours.size():
		var w: float = contour_weights[i] if i < contour_weights.size() else 1.0
		total += _calc_coverage(t_pts, contours[i], brush_r) * w
	return total

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

	# 足元の「世界最後の陣」（2026-07-17再改訂：色を主張しない中立トーンに落とし、
	# HPに連動して欠けていく仕様に変更。「なぜここに陣があるのか」に意味を持たせた）
	var pulse := 0.85 + 0.15 * sin(elapsed_time * 1.2)
	var sigil_r := 140.0
	var sigil_col := Color(0.55, 0.55, 0.62)
	var hp_frac := clampf(float(player_hp) / float(PLAYER_HP_MAX), 0.0, 1.0)
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
