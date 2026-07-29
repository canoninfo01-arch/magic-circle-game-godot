class_name Sigils

# tier: 1=基本（常時解放） 2=中間 3=上位（合体廃止に伴い、これが進化形への到達手段になる）
# guide_scale: DRAW_GUIDE_R に掛ける倍率。tierが上がるほど紋章全体を大きく描かせる
# contours: 紋章を構成する輪郭のリスト。各輪郭は {shape, radius_ratio, weight}。
#   shape: Shapes.make_guide_pts が受け取る形状名
#   radius_ratio: この紋章のguide半径に対する比率（中心は共有、オフセットは現状使わない）
#   weight: 採点時の重み（1紋章内の合計が1.0になるよう設定）
# lap_gain: 1周ごとの獲得ポイント（PERFECT/GREAT/GOOD）。tierが上がるほど、入れ子や単体星形など
#   1周に必要な工程が増える分を素点で補うために引き上げる（2026-07-27確定）
const SIGIL_DATA := {
	"circle_1": {
		"attribute": "circle", "tier": 1, "guide_scale": 1.0,
		"contours": [{"shape": "circle", "radius_ratio": 1.0, "weight": 1.0}],
		"spawn_shape": "circle",
		"lap_gain": {"perfect": 35, "great": 20, "good": 10},
	},
	"circle_2": {
		"attribute": "circle", "tier": 2, "guide_scale": 1.15,
		# 2026-07-29：目玉は小さい内接図形ではなく、外周の丸とほぼ同径（先端が外周に接するくらい大きい）
		"contours": [
			{"shape": "circle", "radius_ratio": 1.0, "weight": 0.5},
			{"shape": "eye", "radius_ratio": 1.0, "weight": 0.5},
		],
		"spawn_shape": "circle_mid",
		"lap_gain": {"perfect": 50, "great": 30, "good": 15},
	},
	"circle_3": {
		"attribute": "circle", "tier": 3, "guide_scale": 1.3,
		"contours": [
			{"shape": "circle", "radius_ratio": 1.0, "weight": 0.6},
			{"shape": "star5", "radius_ratio": 0.42, "weight": 0.4},
		],
		"spawn_shape": "double_circle",
		"lap_gain": {"perfect": 70, "great": 40, "good": 20},
	},
	"triangle_1": {
		"attribute": "triangle", "tier": 1, "guide_scale": 1.0,
		"contours": [{"shape": "triangle", "radius_ratio": 1.0, "weight": 1.0}],
		"spawn_shape": "triangle",
		"lap_gain": {"perfect": 35, "great": 20, "good": 10},
	},
	"triangle_2": {
		"attribute": "triangle", "tier": 2, "guide_scale": 1.15,
		"contours": [
			{"shape": "triangle", "radius_ratio": 1.0, "weight": 0.6},
			{"shape": "dot", "radius_ratio": 0.42, "weight": 0.4},
		],
		"spawn_shape": "triangle_mid",
		"lap_gain": {"perfect": 50, "great": 30, "good": 15},
	},
	"triangle_3": {
		"attribute": "triangle", "tier": 3, "guide_scale": 1.3,
		# 単体・フルサイズの六芒星（三角2つの意味）。外形に包まれた入れ子ではない
		"contours": [{"shape": "star6", "radius_ratio": 1.0, "weight": 1.0}],
		"spawn_shape": "hexagram",
		"lap_gain": {"perfect": 70, "great": 40, "good": 20},
	},
	"square_1": {
		"attribute": "square", "tier": 1, "guide_scale": 1.0,
		"contours": [{"shape": "square", "radius_ratio": 1.0, "weight": 1.0}],
		"spawn_shape": "square",
		"lap_gain": {"perfect": 35, "great": 20, "good": 10},
	},
	"square_2": {
		"attribute": "square", "tier": 2, "guide_scale": 1.15,
		"contours": [
			{"shape": "square", "radius_ratio": 1.0, "weight": 0.6},
			{"shape": "dot", "radius_ratio": 0.42, "weight": 0.4},
		],
		"spawn_shape": "square_mid",
		"lap_gain": {"perfect": 50, "great": 30, "good": 15},
	},
	"square_3": {
		"attribute": "square", "tier": 3, "guide_scale": 1.3,
		# 単体・フルサイズの八芒星（四角2つの意味）。外形に包まれた入れ子ではない
		"contours": [{"shape": "star8", "radius_ratio": 1.0, "weight": 1.0}],
		"spawn_shape": "octagram",
		"lap_gain": {"perfect": 70, "great": 40, "good": 20},
	},
}

const ATTR_TIERS := {
	"circle":   ["circle_1", "circle_2", "circle_3"],
	"triangle": ["triangle_1", "triangle_2", "triangle_3"],
	"square":   ["square_1", "square_2", "square_3"],
}

# 装飾リングなど「常に最大tierを想定してサイズを決めておきたい」箇所が参照する上限値
const MAX_GUIDE_SCALE := 1.3

# tierが保証するダメージ倍率（属性武器のみに適用。基礎弾攻撃には掛からない）
const TIER_DMG_MULT := { 1: 1.0, 2: 1.1, 3: 1.2 }

static func default_sigil_id(attr: String) -> String:
	return (ATTR_TIERS[attr] as Array)[0] as String

static func get_data(sigil_id: String) -> Dictionary:
	return SIGIL_DATA.get(sigil_id, {})
