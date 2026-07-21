extends Node2D

const W := 390.0
const H := 844.0

var jp_font: Font = null

func _ready() -> void:
	jp_font = load("res://fonts/jp_font.ttf")

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.03, 0.03, 0.10)
	env.environment = e
	add_child(env)

	_build_ui()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/player.png")
	var tex_size: Vector2 = sprite.texture.get_size()
	var content_px: float = max(tex_size.x, tex_size.y) * 0.59
	sprite.scale = Vector2.ONE * (150.0 / content_px)
	sprite.position = Vector2(W * 0.5, H * 0.36)
	layer.add_child(sprite)

	var title := _make_centered_label("SIGIL", 60, H * 0.52, 80)
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 1.0))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0.5))
	layer.add_child(title)

	var tagline := _make_centered_label("Draw to survive.", 18, H * 0.52 + 66, 30)
	tagline.add_theme_color_override("font_color", Color(0.62, 0.6, 0.78))
	layer.add_child(tagline)

	var prompt := _make_centered_label("TAP TO START", 16, H * 0.78, 30)
	prompt.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	layer.add_child(prompt)

	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(prompt, "modulate:a", 0.2, 0.7)
	tw.tween_property(prompt, "modulate:a", 1.0, 0.7)

func _make_centered_label(txt: String, font_size: int, y: float, box_h: float) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.position = Vector2(0, y)
	lbl.custom_minimum_size = Vector2(W, box_h)
	lbl.size = Vector2(W, box_h)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if jp_font:
		lbl.add_theme_font_override("font", jp_font)
	return lbl

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_tree().change_scene_to_file("res://scenes/LoadoutScene.tscn")
