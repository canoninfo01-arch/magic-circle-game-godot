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
		"star":
			var inner := r * 0.4
			var v: Array[Vector2] = []
			for i in range(10):
				var a := float(i) / 10.0 * TAU - PI / 2.0
				var d := r if i % 2 == 0 else inner
				v.append(Vector2(cx + cos(a) * d, cy + sin(a) * d))
			v.append(v[0])
			for i in range(10):
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
