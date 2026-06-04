extends Node2D

func _ready() -> void:
	var cl = CanvasLayer.new()
	add_child(cl)
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.5, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	var lbl = Label.new()
	lbl.text = "TEST OK"
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cl.add_child(lbl)
