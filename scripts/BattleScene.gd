extends Node2D

const _Characters = preload("res://scripts/Characters.gd")
const _Shapes     = preload("res://scripts/Shapes.gd")

const TARGET_R   := 140.0
const TURN_TIME  := 10.0

var W: float; var H: float
var tx: float; var ty: float

var party          : Array = []
var selected_techs : Array = []
var party_index    : int   = 0
var next_index     : int   = 0
var character      : Dictionary = {}

var game_state    : String = "pre_select"
var boss_max_hp   : int    = 1000
var boss_hp       : int    = 1000
var player_max_hp : int    = 300
var player_hp     : int    = 300
var round_num     : int    = 1
var max_rounds    : int    = 3

var turn_active      : bool  = false
var turn_time_limit  : float = TURN_TIME
var turn_start_sec   : float = 0.0
var fio_frozen_sec   : float = 0.0
var fio_freeze_start : float = -1.0
var stored_attacks   : Array = []
var current_shape    : String = "circle"
var sample_pts       : Array[Vector2] = []
var fio_guide_r      : float = TARGET_R
var fio_tween        : Tween = null
var guide_tween      : Tween = null

var trace_pts      : Array[Vector2] = []
var draw_start_sec : float  = 0.0
var round_start_sec: float  = 0.0
var active_touches : Dictionary = {}
var pending_timer  : SceneTreeTimer = null

var camera         : Camera2D
var guide_rail     : Line2D
var guide_line     : Line2D
var trace_line     : Line2D
var ui_layer       : CanvasLayer

var boss_hp_fill   : ColorRect; var boss_hp_lbl    : Label
var boss_name_lbl  : Label;     var round_lbl      : Label
var player_hp_fill : ColorRect; var player_hp_lbl  : Label
var timer_lbl      : Label;     var combo_lbl      : Label
var result_lbl     : Label;     var power_lbl      : Label
var hint_lbl       : Label;     var tech_lbl       : Label
var next_lbl       : Label
var party_slots    : Array = []

var pre_sel_root   : Control = null
var tech_btns      : Array   = []

func _ready() -> void:
	var cl = CanvasLayer.new()
	add_child(cl)
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	var lbl = Label.new()
	lbl.text = "vars OK"
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cl.add_child(lbl)
