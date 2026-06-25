class_name Characters

static func get_all() -> Array:
	return [
		{
			"id": "agi", "name": "アギ", "attr": "炎", "element": "fire",
			"color": Color(0.914, 0.271, 0.376), "emoji": "🔥",
			"brush_radius": 8.0,
			"desc": "速く描くほど強い。ガイドは遅れて出る。上級者向け。",
			"techniques": [
				{"id": "fire_circle", "name": "炎円陣", "shape": "circle", "effect": "damage"},
				{"id": "fire_rush",   "name": "速炎陣", "shape": "circle", "effect": "damage", "speed_bonus": true},
			]
		},
		{
			"id": "rai", "name": "ライ", "attr": "雷", "element": "thunder",
			"color": Color(1.0, 0.867, 0.0), "emoji": "⚡",
			"brush_radius": 20.0,
			"desc": "判定が広い。PERFECTを取りやすい。初心者向け。",
			"techniques": [
				{"id": "thunder_circle", "name": "雷円陣", "shape": "circle",   "effect": "damage"},
				{"id": "thunder_time",   "name": "時雷陣", "shape": "triangle", "effect": "pushback", "value": 4.0},
			]
		},
		{
			"id": "fio", "name": "フィオ", "attr": "氷", "element": "ice",
			"color": Color(0.267, 0.667, 1.0), "emoji": "❄️",
			"brush_radius": 12.0,
			"desc": "描いてる間、時間が止まる。FORBIDDEN確率高め。",
			"techniques": [
				{"id": "ice_circle", "name": "氷円陣", "shape": "circle", "effect": "damage"},
				{"id": "ice_star",   "name": "癒星陣", "shape": "star",   "effect": "heal", "value": 30},
			]
		},
	]
