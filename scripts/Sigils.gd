class_name Sigils

# tier: 1=基本（常時解放） 2=中間 3=上位（合体廃止に伴い、これが進化形への到達手段になる）
# guide_scale: DRAW_GUIDE_R に掛ける倍率。tierが上がるほど紋章全体を大きく描かせ、
#              内側の入れ子図形との視認的な詰まりを避ける
const SIGIL_DATA := {
	"circle_1":   { "attribute": "circle",   "tier": 1, "guide_scale": 1.0, "guide_pattern": {"outer": "circle",   "inner": ""},     "spawn_shape": "circle" },
	"circle_2":   { "attribute": "circle",   "tier": 2, "guide_scale": 1.15, "guide_pattern": {"outer": "circle",   "inner": "dot"},  "spawn_shape": "circle_mid" },
	"circle_3":   { "attribute": "circle",   "tier": 3, "guide_scale": 1.3, "guide_pattern": {"outer": "circle",   "inner": "star"}, "spawn_shape": "double_circle" },
	"triangle_1": { "attribute": "triangle", "tier": 1, "guide_scale": 1.0, "guide_pattern": {"outer": "triangle", "inner": ""},     "spawn_shape": "triangle" },
	"triangle_2": { "attribute": "triangle", "tier": 2, "guide_scale": 1.15, "guide_pattern": {"outer": "triangle", "inner": "dot"},  "spawn_shape": "triangle_mid" },
	"triangle_3": { "attribute": "triangle", "tier": 3, "guide_scale": 1.3, "guide_pattern": {"outer": "triangle", "inner": "star"}, "spawn_shape": "hexagram" },
	"square_1":   { "attribute": "square",   "tier": 1, "guide_scale": 1.0, "guide_pattern": {"outer": "square",   "inner": ""},     "spawn_shape": "square" },
	"square_2":   { "attribute": "square",   "tier": 2, "guide_scale": 1.15, "guide_pattern": {"outer": "square",   "inner": "dot"},  "spawn_shape": "square_mid" },
	"square_3":   { "attribute": "square",   "tier": 3, "guide_scale": 1.3, "guide_pattern": {"outer": "square",   "inner": "star"}, "spawn_shape": "octagram" },
}

const ATTR_TIERS := {
	"circle":   ["circle_1", "circle_2", "circle_3"],
	"triangle": ["triangle_1", "triangle_2", "triangle_3"],
	"square":   ["square_1", "square_2", "square_3"],
}

# 装飾リングなど「常に最大tierを想定してサイズを決めておきたい」箇所が参照する上限値
const MAX_GUIDE_SCALE := 1.3

static func default_sigil_id(attr: String) -> String:
	return (ATTR_TIERS[attr] as Array)[0] as String

static func get_data(sigil_id: String) -> Dictionary:
	return SIGIL_DATA.get(sigil_id, {})
