extends Node2D

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2)
	bg.size = Vector2(390, 844)
	add_child(bg)

	var lbl = Label.new()
	lbl.position = Vector2(50, 380)
	lbl.size = Vector2(300, 100)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)

	var party = Characters.get_all()
	var pts = Shapes.make_sample_pts("circle", 195.0, 422.0, 140.0)
	lbl.text = "Party:%d Pts:%d OK" % [party.size(), pts.size()]
