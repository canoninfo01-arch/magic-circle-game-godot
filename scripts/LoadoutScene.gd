extends Node2D

const _Sigils = preload("res://scripts/Sigils.gd")

const W := 390.0
const H := 844.0

const ATTR_ORDER  := ["circle", "triangle", "square"]
const ATTR_LABELS := { "circle": "水", "triangle": "火", "square": "土" }
const ATTR_COLORS := {
	"circle":   Color(0.3,  0.7,  1.0),
	"triangle": Color(1.0,  0.35, 0.35),
	"square":   Color(0.85, 0.6,  0.2),
}
const TIER_LABELS := { 1: "基本", 2: "中位", 3: "上位" }

# 2026-08-04：⑧ステージ制。4はエンドレス（ステージ3クリアで解禁）
const STAGE_LABELS   := { 1: "1", 2: "2", 3: "3", 4: "∞" }
const STAGE_SUBLABEL := { 1: "5分", 2: "10分", 3: "15分", 4: "エンドレス" }

var jp_font: Font = null
var chip_buttons: Dictionary = {}  # sigil_id -> Button
var stage_buttons: Dictionary = {}  # stage(int) -> Button

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

	var title := _make_centered_label("紋章を選ぶ", 34, H * 0.08, 50)
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 1.0))
	layer.add_child(title)

	var sub := _make_centered_label("出撃前に、属性ごとの紋章を装備する", 15, H * 0.08 + 46, 26)
	sub.add_theme_color_override("font_color", Color(0.62, 0.6, 0.78))
	layer.add_child(sub)

	_build_stage_row(layer, H * 0.20)

	var row_h := (H * 0.55) / 3.0
	for ai in range(ATTR_ORDER.size()):
		var attr: String = ATTR_ORDER[ai]
		var row_y := H * 0.30 + row_h * ai
		_build_attr_row(layer, attr, row_y, row_h)

	var start_btn := Button.new()
	start_btn.text = "バトル開始"
	start_btn.size = Vector2(220, 56)
	start_btn.position = Vector2(W * 0.5 - 110, H * 0.90)
	if jp_font:
		start_btn.add_theme_font_override("font", jp_font)
	start_btn.add_theme_font_size_override("font_size", 20)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.32, 0.5, 0.9)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.6, 0.85, 1.0)
	sb.shadow_color = Color(0.4, 0.7, 1.0, 0.4)
	sb.shadow_size = 8
	start_btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.16, 0.4, 0.6, 0.95)
	start_btn.add_theme_stylebox_override("hover", sb_hover)
	start_btn.add_theme_stylebox_override("pressed", sb_hover)
	start_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	start_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
	)
	layer.add_child(start_btn)

func _build_stage_row(layer: CanvasLayer, row_y: float) -> void:
	var label := _make_centered_label("ステージ", 15, row_y, 22)
	label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.85))
	layer.add_child(label)

	var stages := [1, 2, 3, 4]
	var chip_w := 80.0
	var gap := 10.0
	var total := chip_w * float(stages.size()) + gap * float(stages.size() - 1)
	var start_x := (W - total) * 0.5
	var chip_y := row_y + 26.0

	for si in range(stages.size()):
		var stage: int = stages[si]
		var cx := start_x + si * (chip_w + gap)

		var chip := Button.new()
		chip.size = Vector2(chip_w, 52)
		chip.position = Vector2(cx, chip_y)
		chip.text = "%s\n%s" % [STAGE_LABELS[stage], STAGE_SUBLABEL[stage]]
		if jp_font:
			chip.add_theme_font_override("font", jp_font)
		chip.add_theme_font_size_override("font_size", 13)
		chip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		chip.pressed.connect(func():
			GameData.selected_stage = stage
			_refresh_stage_buttons()
		)
		layer.add_child(chip)
		stage_buttons[stage] = chip

	_refresh_stage_buttons()

func _refresh_stage_buttons() -> void:
	for stage in stage_buttons:
		var chip: Button = stage_buttons[stage]
		var unlocked: bool = GameData.is_stage_unlocked(stage as int)
		var is_selected: bool = (stage as int) == GameData.selected_stage
		chip.disabled = not unlocked

		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(2)
		if not unlocked:
			sb.bg_color = Color(0.06, 0.06, 0.09, 0.85)
			sb.border_color = Color(0.3, 0.3, 0.34)
			chip.modulate = Color(0.5, 0.5, 0.5)
		elif is_selected:
			sb.bg_color = Color(0.3, 0.22, 0.5, 0.95)
			sb.border_color = Color(0.75, 0.6, 1.0)
			sb.shadow_color = Color(0.6, 0.45, 1.0, 0.5)
			sb.shadow_size = 8
			chip.modulate = Color(1, 1, 1)
		else:
			sb.bg_color = Color(0.08, 0.08, 0.14, 0.9)
			sb.border_color = Color(0.5, 0.45, 0.65, 0.6)
			chip.modulate = Color(1, 1, 1)
		chip.add_theme_stylebox_override("normal", sb)
		chip.add_theme_stylebox_override("hover", sb)
		chip.add_theme_stylebox_override("pressed", sb)
		chip.add_theme_stylebox_override("disabled", sb)

func _build_attr_row(layer: CanvasLayer, attr: String, row_y: float, row_h: float) -> void:
	var accent: Color = ATTR_COLORS[attr]
	var label := _make_label("%s属性" % (ATTR_LABELS[attr] as String), 18, Vector2(30, row_y))
	label.add_theme_color_override("font_color", accent)
	layer.add_child(label)

	var tiers: Array = _Sigils.ATTR_TIERS[attr]
	var chip_w := 100.0
	var gap := 14.0
	var total := chip_w * float(tiers.size()) + gap * float(tiers.size() - 1)
	var start_x := (W - total) * 0.5
	var chip_y := row_y + 34.0

	for ti in range(tiers.size()):
		var sigil_id: String = tiers[ti]
		var sigil_data := _Sigils.get_data(sigil_id)
		var tier: int = sigil_data.get("tier", 1)
		var cx := start_x + ti * (chip_w + gap)

		var chip := Button.new()
		chip.size = Vector2(chip_w, 64)
		chip.position = Vector2(cx, chip_y)
		chip.text = TIER_LABELS.get(tier, "?")
		if jp_font:
			chip.add_theme_font_override("font", jp_font)
		chip.add_theme_font_size_override("font_size", 16)
		chip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		chip.pressed.connect(func():
			GameData.equip_sigil(attr, sigil_id)
			_refresh_attr_chips(attr)
		)
		layer.add_child(chip)
		chip_buttons[sigil_id] = chip

	_refresh_attr_chips(attr)

func _refresh_attr_chips(attr: String) -> void:
	var accent: Color = ATTR_COLORS[attr]
	var equipped_id := GameData.get_equipped_sigil(attr)
	for sigil_id in (_Sigils.ATTR_TIERS[attr] as Array):
		var chip: Button = chip_buttons[sigil_id]
		var unlocked: bool = GameData.is_unlocked(sigil_id)
		var is_equipped: bool = sigil_id == equipped_id
		chip.disabled = not unlocked

		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(2)
		if not unlocked:
			sb.bg_color = Color(0.06, 0.06, 0.09, 0.85)
			sb.border_color = Color(0.3, 0.3, 0.34)
			chip.modulate = Color(0.5, 0.5, 0.5)
		elif is_equipped:
			sb.bg_color = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.95)
			sb.border_color = accent
			sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
			sb.shadow_size = 8
			chip.modulate = Color(1, 1, 1)
		else:
			sb.bg_color = Color(0.08, 0.08, 0.14, 0.9)
			sb.border_color = Color(accent.r, accent.g, accent.b, 0.5)
			chip.modulate = Color(1, 1, 1)
		chip.add_theme_stylebox_override("normal", sb)
		chip.add_theme_stylebox_override("hover", sb)
		chip.add_theme_stylebox_override("pressed", sb)
		chip.add_theme_stylebox_override("disabled", sb)

func _make_label(txt: String, font_size: int, pos: Vector2) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	if jp_font:
		lbl.add_theme_font_override("font", jp_font)
	return lbl

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
