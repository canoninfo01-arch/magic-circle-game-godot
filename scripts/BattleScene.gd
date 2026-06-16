extends Node2D

# Hello World 確認用ミニマルスクリプト
# 灰色画面の原因切り分け用。awaitなし・W/H非依存。
# テスト手順:
#   1. このファイルの中身を BattleScene.gd にコピーペースト（上書き）
#   2. Godot を再起動（Project → Reload か エディタ閉じて再起動）
#   3. F5 → 青い画面 + "Hello World" が出れば Godot は正常

var status_lbl : Label

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.2)
	bg.size  = Vector2(1000, 2000)
	add_child(bg)

	status_lbl = Label.new()
	status_lbl.text = "Hello World ✓\nタップしてみて"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	status_lbl.size     = Vector2(390, 300)
	status_lbl.position = Vector2(0, 270)
	status_lbl.add_theme_font_size_override("font_size", 28)
	status_lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(status_lbl)

func _input(event: InputEvent) -> void:
	var tapped := (event is InputEventScreenTouch and event.pressed) or \
	              (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	if not tapped: return
	status_lbl.text = "タップ受付 OK !!\n描画・入力とも正常"
	status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
