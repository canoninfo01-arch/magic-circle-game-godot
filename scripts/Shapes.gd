class_name Shapes

# ガイド用の連続した輪郭点（Line2D に渡す）
static func make_guide_pts(shape: String, cx: float, cy: float, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"circle":
			for i in range(301):
				var a := float(i) / 300.0 * TAU
				pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
		"triangle":
			var v: Array[Vector2] = []
			for i in range(3):
				var a := float(i) / 3.0 * TAU - PI / 2.0
				v.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
			v.append(v[0])
			for e in range(3):
				for i in range(101):
					pts.append(v[e].lerp(v[e + 1], float(i) / 100.0))
		"square":
			var v: Array[Vector2] = []
			for i in range(4):
				var a := float(i) / 4.0 * TAU - PI / 4.0
				v.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
			v.append(v[0])
			for e in range(4):
				for i in range(101):
					pts.append(v[e].lerp(v[e + 1], float(i) / 100.0))
		"star5", "star6", "star8":
			var n := 5
			if shape == "star6": n = 6
			elif shape == "star8": n = 8
			pts = _star_guide_pts(n, cx, cy, r)
		"dot":
			for i in range(61):
				var a := float(i) / 60.0 * TAU
				pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
		"eye":
			# 紡錘形（目玉状）。上下に尖った先端、左右に膨らむ一筆書きの輪郭
			for i in range(121):
				var t := float(i) / 120.0 * TAU
				var s := sin(t)
				var x := r * 0.35 * s * s * s
				var y := r * cos(t)
				pts.append(Vector2(cx + x, cy + y))
	return pts

# n個の頂点を持つ星形のガイド輪郭（内径はr*0.4固定）
static func _star_guide_pts(n: int, cx: float, cy: float, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var inner := r * 0.4
	var v: Array[Vector2] = []
	for i in range(n * 2):
		var a := float(i) / float(n * 2) * TAU - PI / 2.0
		var d := r if i % 2 == 0 else inner
		v.append(Vector2(cx + cos(a) * d, cy + sin(a) * d))
	v.append(v[0])
	for i in range(n * 2):
		var seg := int(v[i].distance_to(v[i + 1]) / (r * TAU / 300.0)) + 1
		for j in range(seg):
			pts.append(v[i].lerp(v[i + 1], float(j) / seg))
	pts.append(v[0])
	return pts

# カバー率計算用のサンプル点（Array[Vector2]）
static func make_sample_pts(shape: String, cx: float, cy: float, r: float) -> Array[Vector2]:
	var raw := make_guide_pts(shape, cx, cy, r)
	var out: Array[Vector2] = []
	for p in raw:
		out.append(p)
	return out

# 紋章＝輪郭のリスト。各輪郭は {"shape": String, "radius_ratio": float, "weight": float} を持つ。
# radius_ratioはこの紋章の基準半径rに対する比率、weightは採点時の重み（合計1.0を想定）。
# 中心はすべて共有（オフセットは現状使わない）。
static func make_guide_contours(contours: Array, cx: float, cy: float, r: float) -> Array:
	var out: Array = []
	for c in contours:
		var cd: Dictionary = c as Dictionary
		var ratio: float = cd.get("radius_ratio", 1.0) as float
		out.append(make_guide_pts(cd.get("shape", "circle") as String, cx, cy, r * ratio))
	return out

static func make_sample_contours(contours: Array, cx: float, cy: float, r: float) -> Array:
	var out: Array = []
	for raw in make_guide_contours(contours, cx, cy, r):
		var pts: Array[Vector2] = []
		for p in raw:
			pts.append(p)
		out.append(pts)
	return out
