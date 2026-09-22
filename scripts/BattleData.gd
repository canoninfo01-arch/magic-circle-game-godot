class_name BattleData

# BattleScene.gd から分離した純粋データ定義（挙動は一切変更していない）。
# ロジック（_ready 以降の func 群）は引き続き BattleScene.gd にある。
# BattleScene.gd 側では `const _Data = preload("res://scripts/BattleData.gd")` で読み込み、
# 各定数を `const X := _Data.X` の形で再エクスポートして参照している。

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
	# 2026-08-31：「強くなればなるほど遅くなるのはありだけど、さすがに遅すぎて余裕で逃げ切れる」との指摘。
	# ENEMY_SPEED_BASE=45換算でspd_m0.4だと実速度18（プレイヤー130の14%）しかなく、本来「本当の強敵」の
	# はずが常時ほぼ静止していた。0.6（実速度27、21%）まで引き上げ、それでも群れの中では圧倒的に遅い
	# 「重戦車」の立ち位置は保ったまま、少しは追い詰められる速度にした
	"void_mark":  { "sides": 6, "radius": 26.0, "color": Color(0.95, 0.95, 1.0),  "hp_m": 8.0,  "spd_m": 0.6  },
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
const ELITE_CHANCE      := 0.11  # ステージ1・2（2026-08-25：120秒プレイして変種が少なすぎるとの指摘で0.05→0.08 / 2026-08-31：「もう少し強くして」との指摘で0.08→0.11）
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
	# 2026-08-31：「ステージ1・2ともにもう少し強くして」との指摘。ウェーブ1（t=55）は「ちょうど良い」と
	# 確認済みのためそのタイミング・規模は据え置き、t=120以降の中盤〜終盤だけ間隔を詰めて敵構成も
	# 前倒しでタフにした。終盤のヴォイドマーク包囲（t=235）は8体と手薄で「簡単に抜け出せる」原因の
	# 一つだったため14体に増量（`_spawn_ring_enemies`の半径縮小と合わせて隙間を埋める）
	# 2026-08-31続き：それでも「120秒あたりから殲滅されてる、弱いかも」との指摘。t=210まで
	# ヴォイドマークが一切混ざらず雑魚（シャード/フラクチャー）だけだったため、プレイヤー側の
	# 火力成長に追いつけていなかったと判断。t=120からヴォイドマークを少量ずつ混ぜ始め、
	# 谷を挟まず段階的に本当の強敵の比率を上げていく形に変更
	# 2026-08-31さらに続き：「終盤は重い敵が多いけど遅い敵とも言える、まだ簡単に逃げられる」との指摘。
	# ヴォイドマーク比率を上げるほど群れ全体の平均速度が落ち、終盤ほど追いつかれにくくなる矛盾に
	# 気づいた。対策は2つ：①segmentsの終盤でシャード比率が0.1〜0.2まで潰れていたのを常に0.25〜0.3の
	# 床を残すよう調整（fracture/void_markで積んでいたタフさは維持）②包囲ウェーブ（events）を単一
	# type固定からmix対応に変更し、ヴォイドマーク主体の包囲にもシャード/フラクチャーの護衛を混ぜて、
	# 「山場なのに全員遅い」状態を解消（`_spawn_ring_enemies`のシグネチャもmix対応に変更）
	1: {
		"segments": [
			{ "t": 0.0,   "interval": 1.4, "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 40.0,  "interval": 2.0, "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 55.0,  "interval": 0.9, "count": 1, "mix": { "shard": 0.7,  "fracture": 0.3 } },
			{ "t": 120.0, "interval": 1.3, "count": 1, "mix": { "shard": 0.5,  "fracture": 0.45, "void_mark": 0.05 } },
			{ "t": 140.0, "interval": 0.55,"count": 2, "mix": { "shard": 0.35, "fracture": 0.55, "void_mark": 0.1 } },
			{ "t": 210.0, "interval": 1.4, "count": 1, "mix": { "shard": 0.35, "fracture": 0.3,  "void_mark": 0.35 } },
			{ "t": 235.0, "interval": 0.4, "count": 2, "mix": { "shard": 0.3,  "fracture": 0.35, "void_mark": 0.35 } },
		],
		"events": [
			{ "t": 55.0,  "count": 16, "mix": { "shard": 1.0 } },
			{ "t": 140.0, "count": 18, "mix": { "fracture": 1.0 } },
			{ "t": 235.0, "count": 14, "mix": { "shard": 0.25, "fracture": 0.25, "void_mark": 0.5 } },
		],
	},
	2: {
		"segments": [
			{ "t": 0.0,   "interval": 1.4,  "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 45.0,  "interval": 1.9,  "count": 1, "mix": { "shard": 1.0 } },
			{ "t": 60.0,  "interval": 0.9,  "count": 1, "mix": { "shard": 0.7,  "fracture": 0.3 } },
			{ "t": 130.0, "interval": 1.3,  "count": 1, "mix": { "shard": 0.5,  "fracture": 0.45, "void_mark": 0.05 } },
			{ "t": 150.0, "interval": 0.6,  "count": 2, "mix": { "shard": 0.35, "fracture": 0.55, "void_mark": 0.1 } },
			{ "t": 230.0, "interval": 1.5,  "count": 1, "mix": { "shard": 0.35, "fracture": 0.35, "void_mark": 0.3 } },
			{ "t": 250.0, "interval": 0.55, "count": 2, "mix": { "shard": 0.3,  "fracture": 0.35, "void_mark": 0.35 } },
			{ "t": 350.0, "interval": 1.6,  "count": 1, "mix": { "shard": 0.3,  "fracture": 0.3,  "void_mark": 0.4 } },
			{ "t": 380.0, "interval": 0.5,  "count": 2, "mix": { "shard": 0.28, "fracture": 0.32, "void_mark": 0.4 } },
			{ "t": 480.0, "interval": 1.4,  "count": 1, "mix": { "shard": 0.28, "fracture": 0.3,  "void_mark": 0.42 } },
			{ "t": 520.0, "interval": 0.4,  "count": 3, "mix": { "shard": 0.28, "fracture": 0.3,  "void_mark": 0.42 } },
		],
		"events": [
			{ "t": 60.0,  "count": 14, "mix": { "shard": 1.0 } },
			{ "t": 150.0, "count": 16, "mix": { "fracture": 1.0 } },
			{ "t": 250.0, "count": 12, "mix": { "shard": 0.25, "fracture": 0.25, "void_mark": 0.5 } },
			{ "t": 380.0, "count": 18, "mix": { "fracture": 1.0 } },
			{ "t": 520.0, "count": 14, "mix": { "shard": 0.25, "fracture": 0.25, "void_mark": 0.5 } },
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
			{ "t": 380.0, "interval": 0.5,  "count": 3, "mix": { "shard": 0.3,  "fracture": 0.3,  "void_mark": 0.4 } },
			{ "t": 500.0, "interval": 1.8,  "count": 1, "mix": { "shard": 0.28, "fracture": 0.3,  "void_mark": 0.42 } },
			{ "t": 530.0, "interval": 0.45, "count": 3, "mix": { "shard": 0.28, "fracture": 0.3,  "void_mark": 0.42 } },
			{ "t": 650.0, "interval": 1.7,  "count": 1, "mix": { "shard": 0.26, "fracture": 0.3,  "void_mark": 0.44 } },
			{ "t": 680.0, "interval": 0.4,  "count": 3, "mix": { "shard": 0.26, "fracture": 0.3,  "void_mark": 0.44 } },
			{ "t": 800.0, "interval": 0.4,  "count": 3, "mix": { "shard": 0.25, "fracture": 0.3,  "void_mark": 0.45 } },
		],
		"events": [
			{ "t": 55.0,  "count": 12, "mix": { "shard": 1.0 } },
			{ "t": 140.0, "count": 16, "mix": { "fracture": 1.0 } },
			{ "t": 250.0, "count": 8,  "mix": { "shard": 0.25, "fracture": 0.25, "void_mark": 0.5 } },
			{ "t": 380.0, "count": 18, "mix": { "fracture": 1.0 } },
			{ "t": 530.0, "count": 10, "mix": { "shard": 0.25, "fracture": 0.25, "void_mark": 0.5 } },
			{ "t": 680.0, "count": 20, "mix": { "fracture": 1.0 } },
		],
		# エンドレス（ステージ4）は900秒（このテーブル終端）を過ぎたら以降ここに切り替わる
		"loop_event": { "period": 100.0, "count": 10, "mix": { "shard": 0.2, "fracture": 0.4, "void_mark": 0.4 } },
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

const STAGE_TIME_LIMIT := { 1: 300.0, 2: 600.0, 3: 900.0, 4: -1.0 }  # 4=エンドレス（上限なし）

# 2026-08-04：⑧ステージ制。制限時間に到達したら死亡扱いにせずステージクリアとして終える。
const STAGE_CLEAR_REWARD_TEXT := {
	1: "紋章tier2が解放された！",
	2: "紋章tier3が解放された！",
	3: "エンドレスモードが解放された！",
}
