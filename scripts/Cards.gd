class_name Cards

static func get_all() -> Array:
	return [
		# ── アギ ──────────────────────────────────────────
		{"id": "fire_circle_1",  "name": "炎円陣",  "char_id": "agi", "shape": "circle",   "rarity": 1, "color": Color(0.914, 0.271, 0.376), "weight": 10},
		{"id": "fire_circle_2",  "name": "炎円陣",  "char_id": "agi", "shape": "circle",   "rarity": 2, "color": Color(0.914, 0.271, 0.376), "weight": 5},
		{"id": "fire_circle_3",  "name": "炎円陣",  "char_id": "agi", "shape": "circle",   "rarity": 3, "color": Color(0.914, 0.271, 0.376), "weight": 2},
		{"id": "fire_rush_1",    "name": "速炎陣",  "char_id": "agi", "shape": "circle",   "rarity": 1, "color": Color(1.0,   0.5,  0.1),   "weight": 10},
		{"id": "fire_rush_2",    "name": "速炎陣",  "char_id": "agi", "shape": "circle",   "rarity": 2, "color": Color(1.0,   0.5,  0.1),   "weight": 5},
		{"id": "fire_rush_3",    "name": "速炎陣",  "char_id": "agi", "shape": "circle",   "rarity": 3, "color": Color(1.0,   0.5,  0.1),   "weight": 2},
		# ── ライ ─────────────────────────────────────────
		{"id": "thunder_circle_1", "name": "雷円陣", "char_id": "rai", "shape": "circle",   "rarity": 1, "color": Color(1.0,   0.867, 0.0),  "weight": 10},
		{"id": "thunder_circle_2", "name": "雷円陣", "char_id": "rai", "shape": "circle",   "rarity": 2, "color": Color(1.0,   0.867, 0.0),  "weight": 5},
		{"id": "thunder_circle_3", "name": "雷円陣", "char_id": "rai", "shape": "circle",   "rarity": 3, "color": Color(1.0,   0.867, 0.0),  "weight": 2},
		{"id": "thunder_time_1",   "name": "時雷陣", "char_id": "rai", "shape": "triangle", "rarity": 1, "color": Color(0.6,   0.9,  1.0),   "weight": 10},
		{"id": "thunder_time_2",   "name": "時雷陣", "char_id": "rai", "shape": "triangle", "rarity": 2, "color": Color(0.6,   0.9,  1.0),   "weight": 5},
		{"id": "thunder_time_3",   "name": "時雷陣", "char_id": "rai", "shape": "triangle", "rarity": 3, "color": Color(0.6,   0.9,  1.0),   "weight": 2},
		# ── フィオ ────────────────────────────────────────
		{"id": "ice_circle_1",  "name": "氷円陣",  "char_id": "fio", "shape": "circle",   "rarity": 1, "color": Color(0.267, 0.667, 1.0),   "weight": 10},
		{"id": "ice_circle_2",  "name": "氷円陣",  "char_id": "fio", "shape": "circle",   "rarity": 2, "color": Color(0.267, 0.667, 1.0),   "weight": 5},
		{"id": "ice_circle_3",  "name": "氷円陣",  "char_id": "fio", "shape": "circle",   "rarity": 3, "color": Color(0.267, 0.667, 1.0),   "weight": 2},
		{"id": "ice_star_1",    "name": "癒星陣",  "char_id": "fio", "shape": "star",     "rarity": 1, "color": Color(0.4,   0.9,  0.8),    "weight": 10},
		{"id": "ice_star_2",    "name": "癒星陣",  "char_id": "fio", "shape": "star",     "rarity": 2, "color": Color(0.4,   0.9,  0.8),    "weight": 5},
		{"id": "ice_star_3",    "name": "癒星陣",  "char_id": "fio", "shape": "star",     "rarity": 3, "color": Color(0.4,   0.9,  0.8),    "weight": 2},
	]

static func roll_drop() -> Dictionary:
	var pool = get_all()
	var total = 0
	for c in pool: total += c["weight"]
	var roll = randi() % total
	var acc = 0
	for c in pool:
		acc += c["weight"]
		if roll < acc:
			return c
	return pool[0]

static func rarity_label(rarity: int) -> String:
	match rarity:
		1: return "★☆☆"
		2: return "★★☆"
		3: return "★★★"
	return "★☆☆"
