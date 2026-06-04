extends Node2D

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2)
	bg.size = Vector2(390, 844)
	add_child(bg)

	var lbl = Label.new()
	lbl.text = "Godot Web OK"
	lbl.position = Vector2(100, 400)
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)
