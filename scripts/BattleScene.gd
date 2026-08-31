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
const PLAYER_SPEED     := 130.0  # 2026-08-10：まだ速いとの指摘で190→165にさらに減速 / 2026-08-18：敵との速度差がありすぎるとの指摘で165→130に
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
# 2026-08-04：tier構成の組み替えに伴い、旧来のally_*.pngはtier2として扱う。
# tier1（弱化版・仮）・tier3（強化版）を新規追加
const ALLY_TEX_WATER_1 := preload("res://assets/sprites/ally_water_1.png")
const ALLY_TEX_FIRE_1  := preload("res://assets/sprites/ally_fire_1.png")
const ALLY_TEX_EARTH_1 := preload("res://assets/sprites/ally_earth_1.png")
const ALLY_TEX_WATER_3 := preload("res://assets/sprites/ally_water_3.png")
const ALLY_TEX_FIRE_3  := preload("res://assets/sprites/ally_fire_3.png")
const ALLY_TEX_EARTH_3 := preload("res://assets/sprites/ally_earth_3.png")
const ALLY_SPRITE_TEXTURES := {
	"circle":        ALLY_TEX_WATER_1,
	"triangle":      ALLY_TEX_FIRE_1,
	"square":        ALLY_TEX_EARTH_1,
	"circle_mid":    ALLY_TEX_WATER,
	"triangle_mid":  ALLY_TEX_FIRE,
	"square_mid":    ALLY_TEX_EARTH,
	"double_circle": ALLY_TEX_WATER_3,
	"hexagram":      ALLY_TEX_FIRE_3,
	"octagram":      ALLY_TEX_EARTH_3,
}
# 各画像の余白を除いた実キャラ部分のキャンバス比率（スケール計算用）
const ALLY_SPRITE_CONTENT_RATIO := {
	"circle":        0.82,
	"triangle":      0.6,
	"square":        0.62,
	"circle_mid":    0.90,
	"triangle_mid":  0.92,
	"square_mid":    0.94,
	"double_circle": 0.88,
	"hexagram":      0.95,
	"octagram":      0.92,
}

# 2026-08-25：「ステージ終盤もかわしきれる」の根本原因を再検証。プレイヤー速度は220→130（0.59倍）
# だった一方、敵基礎速度は75→27（0.36倍）とそれ以上に削られており、これまでの調整を通じて両者の
# 速度比が一貫して開いていたと判明（130 vs 27＝敵はプレイヤーの21%しか出ていない）。包囲ウェーブだけ
# 底上げする対症療法（RING_SPEED_MULT等）は一旦導入したが「根本解決にならない」との指摘を受けて撤回し、
# 基礎速度そのものを07-16の水準（46）に近い45まで戻して比率自体を是正する方針に切り替えた
const ENEMY_SPEED_BASE: float = 45.0
const ENEMY_HP_BASE:    int   = 30
const ENEMY_R:          float = 14.0  # デフォルト（後方互換）
const ENEMY_DAMAGE:     int   = 1
# 2026-08-07：後退するだけで簡単にかわせてしまう問題への対処。プレイヤーが終始敵より速く・湧く数も
# 少なかったため「囲まれる」圧が発生しなかった（VSは逆に遅いが物量で包囲する）。速度はそのままに、
# 物量を大幅に増やす方向で対処する。O(n²)のセパレーション処理があるため上限を設けて実機負荷を抑える
const MAX_ENEMIES: int = 90

const ENEMY_TYPES := {
	# 2026-07-27：属性相性をはっきりさせるため、シャード（速い・脆い）とヴォイドマーク（遅い・硬い）を尖らせた
	# 2026-08-04：colorを白銀ベースに変更（彩度は天敵ウォード専用に空けるため）。本体スプライトはENEMY_DESATURATE_SHADERで
	# 彩度を落としており、この色は死亡パーティクル（_spawn_death_particles）にのみ使われる
	# 2026-08-07：物量戦にする都合、雑魚役のシャード・フラクチャーのHPを下げて「群れは弱いが数で押す」を明確化
	# 2026-08-14：TTK計算で再調整（仲間5体の基礎攻撃だけで50〜70DPS相当と判明、フラクチャー以上が一瞬で溶けていた）。
	# シャードは雑魚のまま、フラクチャー・ヴォイドマークは持久力を底上げして「群れの芯」「本当の強敵」の役割を明確化
	"shard":      { "sides": 3, "radius": 12.0, "color": Color(0.82, 0.84, 0.9),  "hp_m": 0.4,  "spd_m": 1.6  },
	"fracture":   { "sides": 5, "radius": 18.0, "color": Color(0.9,  0.9,  0.86), "hp_m": 2.2,  "spd_m": 0.85 },
	"void_mark":  { "sides": 6, "radius": 26.0, "color": Color(0.95, 0.95, 1.0),  "hp_m": 8.0,  "spd_m": 0.4  },
}

# 天敵（2026-08-04追加）：既存3種のどれにでも乗る属性ウォード。本体色は変えず、周りにウォード色のリングを重ねて
# 「見た目だけで効かなそう」を表現する（味方の_attach_sigil_ringと同じ発想）。弱点属性からのダメージのみ軽減する。
# ⑧のステージ制実装により、出現条件は経過時間ではなくcurrent_stage（ステージ2以降）に差し替え済み
const PREDATOR_ATTRS := ["circle", "triangle", "square"]
const PREDATOR_WARD_COLOR := {
	"circle":   Color(0.3,  0.7,  1.0),
	"triangle": Color(1.0,  0.45, 0.2),
	"square":   Color(0.85, 0.65, 0.25),
}
const PREDATOR_DMG_CUT      := 0.6
const PREDATOR_CHANCE       := 0.18  # ステージ2
const PREDATOR_CHANCE_STAGE3 := 0.3  # ステージ3・エンドレスは種類・頻度を増やす

# エリート個体（2026-08-14追加）：既存3種のどれにでも乗る強化バリエーション。新規ドット絵を発注せず、
# 天敵ウォードと同じ「本体はそのまま・リングで異質さを表現」の手法を流用。HP・速度・サイズを底上げし、
# 見た目も強さも違う個体として「新しい敵タイプが増えた」体験を安く実現する
# 2026-08-18：均一強化だけだと「速い個体がいない」との指摘。tough（硬い）とswift（速い）の2系統に分け、
# リング色も分けて見分けられるようにした（赤=硬い・黄=速い）。今後増やすならこの辞書に追加するだけでいい
const ELITE_VARIANTS := {
	"tough": { "hp_mult": 2.5, "speed_mult": 1.15, "scale_mult": 1.3,  "ring_color": Color(1.0, 0.2, 0.2) },
	"swift": { "hp_mult": 1.3, "speed_mult": 2.0,  "scale_mult": 1.05, "ring_color": Color(1.0, 0.9, 0.2) },
}
const ELITE_CHANCE      := 0.08  # ステージ1・2（2026-08-25：120秒プレイして変種が少なすぎるとの指摘で0.05→0.08）
const ELITE_CHANCE_STAGE3 := 0.1  # ステージ3・エンドレスは頻度を増やす
const ELITE_MIN_TIME    := 45.0  # 開幕直後の無防備な時間帯には出さない

# ステージ毎のスポーンタイムライン（2026-08-18：数式ベースの湧きペース＋ランダム敵種選択を全面的に作り直した）。
# 「敵の湧きをどう制御してるか」という相談から、VSが採用する“ステージごとの譜面”方式に寄せた設計：
#   segments：常時湧きの密度（interval=間隔・count=1回の同時湧き数）と敵構成比（mix）を時刻で切り替える。
#             意図的に間隔を伸ばす「谷」を挟むことで、山場（wave）の前後に緊張と緩和を作る
#   events  ：特定時刻に1回だけ発生する、プレイヤーを囲む包囲ウェーブ（_spawn_ring_enemies）。
#             segmentsの密度が上がるタイミングと合わせて「ここが山場」という体感を強調する
#   loop_event：全eventsを消化した後（主にステージ4＝エンドレス）、指定周期で包囲ウェーブを反復させる
# mixの合計は1.0でなくてよい（ルーレット判定、外れた分はshard扱い）。ステージ4（エンドレス）はステージ3の
# テーブルをそのまま流用し、900秒地点でloop_eventに切り替わる。これは初回の手書き案——実プレイでの
# 体感調整が前提（山場が弱い/強い、谷が長い/短い等はいつでも数値だけで直せる）
const STAGE_TIMELINES := {
	# 2026-08-25：120秒プレイして「まだ恐怖感がない」との指摘。ウェーブ1（旧t=60・10体）が
	# シャード限定・小規模すぎたのが主因と判断し、谷を浅く・山を大きく、全体的に間隔も詰めた
	1: {
		"segments": [
			{ "t": 0.0,   "interval": 1.4, "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 40.0,  "interval": 2.0, "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 55.0,  "interval": 0.9, "count": 1, "mix": { "shard": 0.7,  "fracture": 0.3 } },
			{ "t": 120.0, "interval": 1.8, "count": 1, "mix": { "shard": 0.65, "fracture": 0.35 } },
			{ "t": 140.0, "interval": 0.75,"count": 2, "mix": { "shard": 0.5,  "fracture": 0.5 } },
			{ "t": 210.0, "interval": 1.7, "count": 1, "mix": { "shard": 0.45, "fracture": 0.35, "void_mark": 0.2 } },
			{ "t": 235.0, "interval": 0.5, "count": 2, "mix": { "shard": 0.35, "fracture": 0.4,  "void_mark": 0.25 } },
		],
		"events": [
			{ "t": 55.0,  "count": 16, "type": "shard" },
			{ "t": 140.0, "count": 18, "type": "fracture" },
			{ "t": 235.0, "count": 8,  "type": "void_mark" },
		],
	},
	2: {
		"segments": [
			{ "t": 0.0,   "interval": 1.6,  "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 45.0,  "interval": 2.4,  "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 60.0,  "interval": 1.1,  "count": 1, "mix": { "shard": 0.75, "fracture": 0.25 } },
			{ "t": 130.0, "interval": 2.2,  "count": 1, "mix": { "shard": 0.7,  "fracture": 0.3 } },
			{ "t": 150.0, "interval": 0.9,  "count": 2, "mix": { "shard": 0.55, "fracture": 0.45 } },
			{ "t": 230.0, "interval": 2.0,  "count": 1, "mix": { "shard": 0.5,  "fracture": 0.35, "void_mark": 0.15 } },
			{ "t": 250.0, "interval": 0.7,  "count": 2, "mix": { "shard": 0.4,  "fracture": 0.4,  "void_mark": 0.2 } },
			{ "t": 350.0, "interval": 2.2,  "count": 1, "mix": { "shard": 0.35, "fracture": 0.4,  "void_mark": 0.25 } },
			{ "t": 380.0, "interval": 0.6,  "count": 2, "mix": { "shard": 0.3,  "fracture": 0.4,  "void_mark": 0.3 } },
			{ "t": 480.0, "interval": 1.8,  "count": 1, "mix": { "shard": 0.3,  "fracture": 0.35, "void_mark": 0.35 } },
			{ "t": 520.0, "interval": 0.5,  "count": 3, "mix": { "shard": 0.25, "fracture": 0.35, "void_mark": 0.4 } },
		],
		"events": [
			{ "t": 60.0,  "count": 10, "type": "shard" },
			{ "t": 150.0, "count": 14, "type": "fracture" },
			{ "t": 250.0, "count": 6,  "type": "void_mark" },
			{ "t": 380.0, "count": 16, "type": "fracture" },
			{ "t": 520.0, "count": 8,  "type": "void_mark" },
		],
	},
	3: {
		"segments": [
			{ "t": 0.0,   "interval": 1.5,  "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 40.0,  "interval": 2.2,  "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 55.0,  "interval": 1.0,  "count": 2, "mix": { "shard": 0.7,  "fracture": 0.3 } },
			{ "t": 120.0, "interval": 2.0,  "count": 1, "mix": { "shard": 0.6,  "fracture": 0.4 } },
			{ "t": 140.0, "interval": 0.8,  "count": 2, "mix": { "shard": 0.5,  "fracture": 0.4,  "void_mark": 0.1 } },
			{ "t": 220.0, "interval": 1.9,  "count": 1, "mix": { "shard": 0.45, "fracture": 0.35, "void_mark": 0.2 } },
			{ "t": 250.0, "interval": 0.6,  "count": 2, "mix": { "shard": 0.35, "fracture": 0.4,  "void_mark": 0.25 } },
			{ "t": 350.0, "interval": 2.0,  "count": 1, "mix": { "shard": 0.3,  "fracture": 0.4,  "void_mark": 0.3 } },
			{ "t": 380.0, "interval": 0.5,  "count": 3, "mix": { "shard": 0.25, "fracture": 0.35, "void_mark": 0.4 } },
			{ "t": 500.0, "interval": 1.8,  "count": 1, "mix": { "shard": 0.2,  "fracture": 0.35, "void_mark": 0.45 } },
			{ "t": 530.0, "interval": 0.45, "count": 3, "mix": { "shard": 0.2,  "fracture": 0.3,  "void_mark": 0.5 } },
			{ "t": 650.0, "interval": 1.7,  "count": 1, "mix": { "shard": 0.15, "fracture": 0.3,  "void_mark": 0.55 } },
			{ "t": 680.0, "interval": 0.4,  "count": 3, "mix": { "shard": 0.15, "fracture": 0.3,  "void_mark": 0.55 } },
			{ "t": 800.0, "interval": 0.4,  "count": 3, "mix": { "shard": 0.1,  "fracture": 0.3,  "void_mark": 0.6 } },
		],
		"events": [
			{ "t": 55.0,  "count": 12, "type": "shard" },
			{ "t": 140.0, "count": 16, "type": "fracture" },
			{ "t": 250.0, "count": 8,  "type": "void_mark" },
			{ "t": 380.0, "count": 18, "type": "fracture" },
			{ "t": 530.0, "count": 10, "type": "void_mark" },
			{ "t": 680.0, "count": 20, "type": "fracture" },
		],
		# エンドレス（ステージ4）は900秒（このテーブル終端）を過ぎたら以降ここに切り替わる
		"loop_event": { "period": 100.0, "count": 10, "types": ["fracture", "void_mark"] },
	},
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
# 2026-08-04：敵の彩度を落として白銀寄りにするシェーダー。全敵スプライトで共有する1つのマテリアルを使い回す
const ENEMY_DESATURATE_SHADER := preload("res://shaders/enemy_desaturate.gdshader")
var _enemy_shader_mat: ShaderMaterial

# 2026-08-08：欠片カード（攻撃速度/ダメージ/移動速度/描画時間の3択ポップアップ）は廃止。
# 4効果は全て残光の恒久強化に移行した（GameData.gd参照）。欠片アイテム自体は残すが、役割を
# 「集めるとキャラアイテム（召喚）がドロップする」トリガーに変更。3.5%のランダム抽選も廃止し、
# 確実に貯まる欠片ベースの可視カウンターに統一（あと何個で次の召喚かがHUDでわかる）
const FRAGMENT_THRESHOLD_BASE := 3  # 2026-08-10：初回召喚が遅いと序盤が味気ないとの指摘で15→3に短縮
const FRAGMENT_THRESHOLD_GROWTH := 12  # 2026-08-10：まだ仲間が増えるペースが速いとの指摘で「今の半分」に6→12（初回召喚3個は据え置き）
# 2026-08-08：単純なキル毎%だと、敵の物量戦化でキル数が跳ねた瞬間（＝一番忙しい瞬間）に
# ドロップも比例して殺到してしまう。回復はHPが減るほど出やすくなる需要ベースの確率に変更しつつ、
# クールダウンで絶対量に天井を設けた（需要が煽っても際限なく出ないように）。武器はクールダウンのみ追加
const HEAL_ITEM_BASE_CHANCE := 0.01  # HP満タン時の下限
const HEAL_ITEM_HP_SCALE    := 0.10  # HPが0%に近づくほど、この分だけ確率が上乗せされる
const HEAL_ITEM_COOLDOWN    := 7.0   # 秒。これより短い間隔では絶対に連続ドロップしない
const HEAL_AMOUNT       := 2
const ALLY_HEAL_FRACTION := 0.15  # 2026-07-27：仲間にも回復効果を追加（最大HPの割合回復、仮）
const WEAPON_ITEM_CHANCE := 0.025  # 2026-07-18：0.06→0.12 / 2026-08-07：0.12→0.08 / 2026-08-10：プレイヤーが強くなるペースが速すぎるとの指摘で0.08→0.05→「今の半分」で0.025
const WEAPON_ITEM_COOLDOWN := 5.0  # 秒。回復と同じ理由でクールダウンを追加
# 2026-08-26：「強い敵を倒したら基本アイテムも良いものであるべき」との指摘。ヴォイドマーク・エリートの
# 撃破に限り、武器ドロップ抽選を大幅に引き上げ、通常より価値の高い欠片（value倍）を確定ドロップする
const NOTABLE_KILL_WEAPON_CHANCE := 0.25
const NOTABLE_KILL_FRAGMENT_VALUE := 3
const ITEM_PICKUP_R    := 60.0  # 2026-08-14：38だと拾いきれず画面にアイテムが積み上がって見た目がごちゃつくとの指摘で拡大
const ITEM_R           := 14.0
const FRAGMENT_R       := 7.0  # 2026-08-04：視認しづらいとの指摘で7.0→9.5に拡大 / 2026-08-18：目立ちすぎの原因は明るさでなくサイズだったと判明し7.0に戻す

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

const DRAW_DURATION    := 5.0  # 2026-07-27：8.0から短縮 / 2026-08-18：最初はもっと短くていいとの指摘で6.5→5.0に再短縮（延長は残光の恒久強化「描画時間強化」で対応、2026-08-08）
const DRAW_GUIDE_R     := 120.0
const DRAW_COVER_THR   := 0.70
const DRAW_BRUSH_R     := 18.0  # 2026-07-27：ブラシ半径は紋章サイズに関わらず絶対px固定（tierが上がっても許容範囲を広げない）
const MISS_GAIN        := 3  # 2026-07-27：MISSでも召喚不能にならないよう最低限の加点を入れる
const COATING_DMG_K    := 0.005  # 属性武器ダメージの厚塗り係数（1.0 + coating_power×K、要調整）

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
const ATTR_WEAPON_MAX_LEVEL := 5  # 2026-08-06：3だと6種×3Lv=18回で武器アイテムが2分程度で枯渇するため5に引き上げ

# pattern: "projectile"（弾。pierce/homing/explode_rはオプション）"chain"（連鎖電撃）
#          "orbit"（常時回転する近接武器）"pulse"（自分中心の定期衝撃波）
#          "rain"（敵の密集地点を狙い、予告→着弾までの遅延がある範囲攻撃）
const ATTR_WEAPON_DATA := {
	# 2026-08-05：旧・追尾の光弾は「敵が常にこちらへ直進してくる」設計と役割が被り無意味だったため、
	# 天から降り注ぐ範囲攻撃「紋章の雨」に置き換えた。密集地点を狙って落ちるので、敵の集まり対策とも噛み合う
	"water_rain":   { "attr": "circle",   "name": "紋章の雨",       "pattern": "rain",       "cooldown": 2.2, "dmg": 7,  "col": Color(0.55, 0.85, 1.0), "radius": 46.0, "telegraph": 0.5 },
	"water_pierce": { "attr": "circle",   "name": "貫通の矢",       "pattern": "projectile", "cooldown": 1.0, "dmg": 5,  "col": Color(0.7,  0.95, 1.0), "pierce": true },
	"fire_explode": { "attr": "triangle", "name": "爆裂の紋章弾",   "pattern": "projectile", "cooldown": 1.6, "dmg": 8,  "col": Color(1.0,  0.5,  0.2),  "explode_r": 85.0 },  # 2026-08-18：効果が分かりづらいとの指摘で55→85に拡大
	"fire_chain":   { "attr": "triangle", "name": "稲妻の鎖",       "pattern": "chain",      "cooldown": 1.8, "dmg": 6,  "col": Color(1.0,  0.9,  0.3),  "jumps": 3, "range": 160.0 },
	# 2026-08-07：回転する紋章の盾は判定が軌道上の薄い輪っかだけ＋自身のノックバックで敵を弾き飛ばしてしまい、
	# 同じ土属性の衝撃波（こちらもノックバック持ち）と弾き合って当たりにくいとの指摘で「固めるビーム」に作り替えた。
	# 最も近い敵の方向へ、太さのある一直線のビームを放ち、直線上の敵をまとめて貫通ダメージする
	# 2026-08-26：狙う相手を探す`_nearest_enemy()`はATTACK_RANGE(240)まで拾うのに、ビーム自体の届く
	# 距離は150しかなく、150〜240の間の敵を「狙ってはいるが実際は届いていない」空振りが頻発していた。
	# 射程をATTACK_RANGEより長い260に、幅も敵を巻き込みやすいよう拡大
	"earth_orbit":  { "attr": "square",   "name": "固めるビーム",   "pattern": "beam",       "cooldown": 1.3, "dmg": 9,  "col": Color(0.95, 0.75, 0.3),  "range": 260.0, "width": 40.0 },
	"earth_wave":   { "attr": "square",   "name": "衝撃の紋章波",   "pattern": "pulse",      "cooldown": 2.4, "dmg": 9,  "col": Color(0.85, 0.65, 0.25), "radius": 95.0 },
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
var game_state    := "battle"   # "battle" | "drawing" | "upgrade_select" | "game_over" | "stage_clear"
var elapsed_time  := 0.0
# 2026-08-04：⑧ステージ制。current_stageはLoadoutSceneで選んだステージ（GameData.selected_stageから取得）
var current_stage := 1
const STAGE_TIME_LIMIT := { 1: 300.0, 2: 600.0, 3: 900.0, 4: -1.0 }  # 4=エンドレス（上限なし）
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
	var timeline := _current_timeline()

	# ウェーブ（events）：時刻を迎えたら1回だけ包囲ウェーブを発生させる。全部消化したらloop_eventに切り替える
	var events: Array = timeline.get("events", []) as Array
	if next_event_idx < events.size():
		var ev: Dictionary = events[next_event_idx] as Dictionary
		if elapsed_time >= (ev["t"] as float):
			wave_count += 1
			_spawn_ring_enemies(ev["count"] as int, ev["type"] as String)
			_show_wave_flash(wave_count)
			next_event_idx += 1
	else:
		var loop_event: Dictionary = timeline.get("loop_event", {}) as Dictionary
		if not loop_event.is_empty() and elapsed_time >= next_loop_event_time:
			var types: Array = loop_event.get("types", ["shard"]) as Array
			var etype: String = types[randi() % types.size()] as String
			wave_count += 1
			_spawn_ring_enemies(loop_event.get("count", 8) as int, etype)
			_show_wave_flash(wave_count)
			next_loop_event_time = elapsed_time + (loop_event.get("period", 90.0) as float)

	# 通常スポーン（segments）：区間ごとの密度・敵構成に従う
	enemy_spawn_timer -= delta
	if enemy_spawn_timer > 0.0: return
	var seg := _current_segment(timeline.get("segments", []) as Array)
	enemy_spawn_timer = seg.get("interval", 1.5) as float
	var count: int = seg.get("count", 1) as int
	var mix: Dictionary = seg.get("mix", { "shard": 1.0 }) as Dictionary
	for _i in range(count):
		if enemies.size() >= MAX_ENEMIES: break
		_spawn_one_enemy(_pick_type_from_mix(mix))

# ステージ4（エンドレス）はステージ3のタイムラインをそのまま流用する（900秒経過後はloop_eventに切り替わる）
func _current_timeline() -> Dictionary:
	var key := mini(current_stage, 3)
	return STAGE_TIMELINES.get(key, STAGE_TIMELINES[3]) as Dictionary

# 時刻tが経過時間以下の区間のうち、一番手前（最新）のものを採用する。segmentsは時刻昇順の前提
func _current_segment(segments: Array) -> Dictionary:
	var chosen: Dictionary = segments[0] as Dictionary
	for seg in segments:
		if elapsed_time >= ((seg as Dictionary)["t"] as float):
			chosen = seg as Dictionary
		else:
			break
	return chosen

func _pick_type_from_mix(mix: Dictionary) -> String:
	var r := randf()
	var acc := 0.0
	for k in mix:
		acc += float(mix[k])
		if r < acc: return k as String
	return "shard"

# ウェーブ専用：プレイヤーを中心に画面外径で均等配置し、四方から一斉に迫る「包囲」を作る
func _spawn_ring_enemies(count: int, forced_type: String) -> void:
	if count <= 0: return
	var radius := maxf(W, H) * 0.5 + 80.0
	var start_a := randf() * TAU
	for i in range(count):
		if enemies.size() >= MAX_ENEMIES: break
		var a := start_a + (float(i) / float(count)) * TAU + randf_range(-0.12, 0.12)
		var pos := player_pos + Vector2(cos(a), sin(a)) * radius
		_spawn_one_enemy(forced_type, pos)

func _spawn_one_enemy(forced_type: String = "", forced_pos = null) -> void:
	var pos: Vector2  = forced_pos if forced_pos != null else _random_edge_pos()
	# 2026-08-18：敵種の抽選はSTAGE_TIMELINESの区間ごとのmixに一本化したため、呼び出し元は
	# 常に解決済みの型を渡す想定。空文字が来た場合のみ雑魚のシャードにフォールバックする
	var etype: String = forced_type if forced_type != "" else "shard"
	var edata: Dictionary = ENEMY_TYPES[etype]
	# 2026-08-10：HP・速度の時間経過スケーリングを廃止（見た目が変わらないまま個体が強くなるのは
	# プレイヤーに伝わらないとの指摘）。難易度上昇は「数が増える」「新しい敵タイプが混ざる」に一本化
	# （2026-08-18：どちらもSTAGE_TIMELINESの区間・イベントで制御するタイムライン方式に作り直した）
	var hp: int   = int(ENEMY_HP_BASE * (edata["hp_m"] as float))
	var spd: float = ENEMY_SPEED_BASE * (edata["spd_m"] as float)
	var r: float  = edata["radius"] as float

	var is_elite := false
	var elite_variant := ""
	if elapsed_time >= ELITE_MIN_TIME:
		var elite_chance: float = ELITE_CHANCE_STAGE3 if current_stage >= 3 else ELITE_CHANCE
		is_elite = randf() < elite_chance
	if is_elite:
		var variant_keys := ELITE_VARIANTS.keys()
		elite_variant = variant_keys[randi() % variant_keys.size()] as String
		var v: Dictionary = ELITE_VARIANTS[elite_variant] as Dictionary
		hp = int(float(hp) * (v["hp_mult"] as float))
		spd *= v["speed_mult"] as float
		r *= v["scale_mult"] as float

	var node := Sprite2D.new()
	node.texture = ENEMY_SPRITE_TEXTURES[etype]
	var tex_size: Vector2 = node.texture.get_size()
	var content_ratio: float = ENEMY_SPRITE_CONTENT_RATIO[etype] as float
	var content_px: float = max(tex_size.x, tex_size.y) * content_ratio
	node.scale = Vector2.ONE * ((r * 2.2) / content_px)
	node.position = pos
	node.material = _enemy_shader_mat
	add_child(node)

	if is_elite:
		_attach_elite_ring(node, r, (ELITE_VARIANTS[elite_variant] as Dictionary)["ring_color"] as Color)

	var ward := ""
	if current_stage >= 2:
		var chance: float = PREDATOR_CHANCE_STAGE3 if current_stage >= 3 else PREDATOR_CHANCE
		if randf() < chance:
			ward = PREDATOR_ATTRS[randi() % PREDATOR_ATTRS.size()]
			_attach_predator_ring(node, r, ward)

	enemies.append({ "hp": hp, "max_hp": hp, "pos": pos, "speed": spd, "radius": r, "node": node, "kb": Vector2.ZERO, "color": edata["color"] as Color, "flash": 0.0, "ward": ward, "elite": is_elite, "etype": etype })

# エリート個体のリング表示（天敵ウォードと同じ発想。色でtough/swiftの系統が直感的にわかるようにする）
func _attach_elite_ring(parent: Node2D, r: float, ring_color: Color) -> void:
	var ring := Line2D.new()
	ring.width = 2.6
	ring.default_color = ring_color
	for p in _make_ring_points(r * 1.35, 1.0):
		ring.add_point(p)
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", TAU, 2.2).from(0.0)

# 天敵ウォードのリング表示（味方の_attach_sigil_ringと同じ発想。本体色は変えない）
func _attach_predator_ring(parent: Node2D, r: float, ward: String) -> void:
	var col: Color = PREDATOR_WARD_COLOR.get(ward, Color.WHITE)
	var ring := Line2D.new()
	ring.width = 2.2
	ring.default_color = col
	for p in _make_ring_points(r * 1.5, 1.0):
		ring.add_point(p)
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_loops()
	tw.tween_property(ring, "rotation", TAU, 4.0).from(0.0)

# 敵への全ダメージ経路が通る共通関数（2026-08-04追加）。attrを渡すと天敵ウォード判定を行う。
# attrが空文字（プレイヤー自身の弾など属性を持たない攻撃）の場合はウォードを無視する。
func _damage_enemy(e: Dictionary, dmg: int, attr: String = "") -> void:
	var final_dmg := dmg
	if attr != "" and (e.get("ward", "") as String) == attr:
		final_dmg = maxi(1, int(ceil(float(dmg) * (1.0 - PREDATOR_DMG_CUT))))
	e["hp"] = (e["hp"] as int) - final_dmg

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
		# 2026-08-04：分離が強すぎて敵がプレイヤー周りに均等に薄く広がり、密集が起きない問題を受けて弱めていたが、
		# 2026-08-10：移動速度を減速したことで密集自体はそのまま起きる見込みのため、重なり対策を元の強さに戻した
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

func _fire_attr_weapon(a: Dictionary, id: String, wdata: Dictionary, level: int) -> void:
	var ally_pos: Vector2 = a["node"].position
	var nearest := _nearest_enemy(ally_pos)
	if nearest.is_empty(): return
	var dmg := int(float(wdata["dmg"] as int) * (1.0 + float(level - 1) * 0.25) * (weapon_stats["damage"] as float) * _ally_weapon_tier_mult(a))
	var col: Color = wdata["col"]
	var attr: String = wdata["attr"] as String
	match wdata["pattern"] as String:
		"projectile":
			var dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()
			_fire_bullet(ally_pos, dir, dmg, col, wdata.get("pierce", false), wdata.get("homing", false), wdata.get("explode_r", 0.0) as float, attr, true)
			Sfx.play_weapon(id)
		"chain":
			_fire_chain_lightning(ally_pos, dmg, wdata["jumps"] as int, wdata["range"] as float, col, attr, id)
		"pulse":
			# 2026-08-06：範囲攻撃はダメージだけでなくAoE半径もLvに連動させる（Lv1〜5、+8%/Lv）
			var pulse_r: float = (wdata["radius"] as float) * (1.0 + float(level - 1) * 0.08)
			_fire_pulse(ally_pos, dmg, pulse_r, col, attr, id)
		"rain":
			var target := _pick_rain_target(wdata["radius"] as float)
			if not target.is_empty():
				_start_rain_strike(target["pos"] as Vector2, dmg, wdata["radius"] as float, col, attr, wdata.get("telegraph", 0.5) as float)
		"beam":
			# 2026-08-07：太さのある直線ビーム。Lvが上がるほど太さも伸びる（+10%/Lv）
			var dir: Vector2 = ((nearest["pos"] as Vector2) - ally_pos).normalized()
			var beam_w: float = (wdata["width"] as float) * (1.0 + float(level - 1) * 0.1)
			_fire_beam(ally_pos, dir, dmg, wdata["range"] as float, beam_w, col, attr, id)

func _fire_beam(from: Vector2, dir: Vector2, dmg: int, length: float, width: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	var to := from + dir * length
	for e in enemies:
		var epos: Vector2 = e["pos"] as Vector2
		# 線分(from-to)への垂直距離と、線分の範囲内かどうかを判定
		var seg: Vector2 = to - from
		var t := clampf(seg.dot(epos - from) / seg.length_squared(), 0.0, 1.0)
		var closest: Vector2 = from + seg * t
		if epos.distance_to(closest) < width * 0.5 + (e["radius"] as float):
			_damage_enemy(e, dmg, attr)
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
	add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "modulate:a", 0.0, 0.16)
	tw.tween_callback(beam.queue_free)
	Sfx.play_weapon(weapon_id)

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
				_damage_enemy(e, dmg, wdata["attr"] as String)
				e["flash"] = 0.12
				# 2026-07-28：土は遠距離弾を持たないため、盾が弾かないと密着ダメージを避けられない指摘を受けて追加
				# 2026-07-29：さらに強めてほしいとの要望で180→300に増加
				var kb_dir: Vector2 = ((e["pos"] as Vector2) - world_pos).normalized()
				e["kb"] = (e["kb"] as Vector2) + kb_dir * 300.0
				orb["hit_cd"] = 0.35
				break

func _fire_chain_lightning(from: Vector2, dmg: int, jumps: int, chain_range: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
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
		_damage_enemy(target, dmg, attr)
		target["flash"] = 0.12
		_draw_lightning_bolt(cur_pos, target["pos"] as Vector2, col)
		hit_enemies.append(target)
		cur_pos = target["pos"] as Vector2
		any_hit = true
	if any_hit:
		Sfx.play_weapon(weapon_id)

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

func _fire_pulse(pos: Vector2, dmg: int, radius: float, col: Color, attr: String = "", weapon_id: String = "") -> void:
	Sfx.play_weapon(weapon_id)
	for e in enemies:
		if pos.distance_to(e["pos"] as Vector2) < radius:
			_damage_enemy(e, dmg, attr)
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

# 2026-08-05：水の「紋章の雨」用。密集地点ほど狙われやすくする（数体をサンプリングし、
# 周囲に一番仲間内...ではなく敵が多い地点を選ぶ）。密集対策（セパレーション緩和）と噛み合わせる狙い
func _pick_rain_target(radius: float) -> Dictionary:
	if enemies.is_empty(): return {}
	var best: Dictionary = {}
	var best_count := -1
	var sample_n := mini(6, enemies.size())
	var tried_idx: Array[int] = []
	for _i in range(sample_n * 2):
		if tried_idx.size() >= sample_n: break
		var idx := randi() % enemies.size()
		if tried_idx.has(idx): continue
		tried_idx.append(idx)
		var cand: Dictionary = enemies[idx]
		var cnt := 0
		for other in enemies:
			if (cand["pos"] as Vector2).distance_to(other["pos"] as Vector2) <= radius:
				cnt += 1
		if cnt > best_count:
			best_count = cnt
			best = cand
	return best

# 天から降り注ぐ範囲攻撃。着弾地点に予告リング＋落下する雨粒を表示してから、少し遅れてダメージを与える
func _start_rain_strike(pos: Vector2, dmg: int, radius: float, col: Color, attr: String, telegraph: float) -> void:
	var warn := Line2D.new()
	warn.width = 2.5
	warn.default_color = Color(col.r, col.g, col.b, 0.75)
	for p in _make_ring_points(radius, 1.0):
		warn.add_point(p)
	warn.position = pos
	add_child(warn)
	var warn_tw := warn.create_tween()
	warn_tw.tween_property(warn, "scale", Vector2.ONE * 0.75, telegraph).from(Vector2.ONE * 1.3).set_trans(Tween.TRANS_SINE)
	warn_tw.tween_callback(func():
		warn.queue_free()
		_rain_impact(pos, dmg, radius, col, attr)
	)

	for _i in range(5):
		var drop := Polygon2D.new()
		drop.polygon = _make_star_pts(4, 5.0, 0.25)
		drop.color = Color(col.r, col.g, col.b, 0.85)
		var off := Vector2(randf_range(-radius * 0.6, radius * 0.6), randf_range(-radius * 0.6, radius * 0.6))
		var end_pos := pos + off
		var start_pos := end_pos + Vector2(0, -240.0 - randf() * 80.0)
		drop.position = start_pos
		add_child(drop)
		var dtw := drop.create_tween()
		dtw.tween_interval(randf() * telegraph * 0.3)
		dtw.tween_property(drop, "position", end_pos, telegraph * randf_range(0.7, 1.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		dtw.tween_callback(drop.queue_free)

func _rain_impact(pos: Vector2, dmg: int, radius: float, col: Color, attr: String) -> void:
	# 2026-08-25：旧仕様は進化ファンファーレ（play_evolve）を流用しておりミスマッチだったため専用音に変更
	Sfx.play_rain_impact()
	# 2026-08-14：敵が多いと着弾のたび画面が揺れて邪魔になるとの指摘で、揺れを大幅に弱めた（8.0→2.0）
	shake_power = maxf(shake_power, 2.0)
	for e in enemies:
		var d := pos.distance_to(e["pos"] as Vector2)
		if d < radius:
			_damage_enemy(e, dmg, attr)
			e["flash"] = 0.12
			var kb_dir: Vector2 = ((e["pos"] as Vector2) - pos).normalized() if d > 1.0 else Vector2(0.0, -1.0)
			e["kb"] = (e["kb"] as Vector2) + kb_dir * 160.0
	_spawn_death_particles(pos, col, radius * 0.35)
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
	guide_rune_root.visible = true
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

	if contours.size() > 2:
		guide_line_2.clear_points()
		guide_glow_2.clear_points()
		for p in contours[2]:
			guide_line_2.add_point(p)
			guide_glow_2.add_point(p)
		guide_line_2.visible = true
		guide_glow_2.visible = true
	else:
		guide_line_2.visible = false
		guide_glow_2.visible = false

	var shape_colors := {
		"circle":   Color(0.5, 0.7, 1.0, 0.8),
		"triangle": Color(1.0, 0.5, 0.5, 0.8),
		"square":   Color(0.85, 0.6, 0.2, 0.8),
	}
	var sc: Color = shape_colors.get(draw_shape, Color(1, 1, 1, 0.65))
	guide_base_color = sc

	for i in range(guide_rune_marks.size()):
		var ang := float(i) / float(guide_rune_marks.size()) * TAU
		guide_rune_marks[i].position = Vector2(cos(ang), sin(ang)) * current_guide_r

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
	if guide_line_2.visible:
		guide_line_2.default_color = guide_line.default_color
		guide_line_2.width = guide_line.width
		guide_glow_2.default_color = guide_glow.default_color
		guide_glow_2.width = guide_glow.width

	var rune_col := guide_base_color.lerp(Color.WHITE, boost)
	var rune_scale := 1.0 + boost * 0.6
	for mark in guide_rune_marks:
		mark.color = rune_col
		mark.scale = Vector2.ONE * rune_scale

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
	_flash_confirm_btn(col)

# 2026-08-07：ボタンが小さく押しにくかった件の対処と合わせて、押した直後にボタン自体も
# 判定色でパッと光らせて「押せた・1周終わった」がその場でわかるようにする
func _flash_confirm_btn(col: Color) -> void:
	confirm_btn.modulate = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6)
	var tw := confirm_btn.create_tween()
	tw.tween_property(confirm_btn, "modulate", Color.WHITE, 0.35)

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
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	pause_layer.add_child(restart_btn)

	var stage_select_btn := Button.new()
	stage_select_btn.text = "ステージ選択へ"
	stage_select_btn.size = Vector2(180, 56)
	stage_select_btn.position = Vector2(W * 0.5 - 90, H * 0.60)
	stage_select_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LoadoutScene.tscn"))
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
const STAGE_CLEAR_REWARD_TEXT := {
	1: "紋章tier2が解放された！",
	2: "紋章tier3が解放された！",
	3: "エンドレスモードが解放された！",
}
func _stage_clear() -> void:
	game_state = "stage_clear"
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
