extends Node

const _Sigils = preload("res://scripts/Sigils.gd")

# 解放済み紋章id（tier2/3のみ格納。tier1は常時解放扱いなので格納不要）
var collected_ids : Array[String] = []
# 属性名 -> 装備中のsigil_id（例: {"circle": "circle_2", "triangle": "triangle_1", "square": "square_1"}）
var equipped      : Dictionary    = {}

# 2026-08-04：⑧ステージ制。unlocked_stageは到達済みの最高ステージ（1〜3）。
# 4は「エンドレス解禁」を意味する（ステージ3クリアで4になる）。selected_stageはLoadoutSceneで選んだ、次に遊ぶステージ。
var unlocked_stage : int = 1
var selected_stage  : int = 1

# 2026-08-07：メタ進行「残光」。ラン終了時に生存時間に応じて貯まり、出撃前の恒久強化に使う。
# エンドレス（stage>=META_LOCKED_STAGE）は稼ぎも適用も対象外にして、腕試しの場として純度を保つ
const META_LOCKED_STAGE := 4
const UPGRADE_MAX_LV := 5
const UPGRADE_COSTS  := [15, 25, 40, 60, 90]  # Lv0→1, 1→2, ... 4→5 の必要残光
var zankou   : int = 0
var upgrades : Dictionary = { "hp": 0, "atk": 0, "spd": 0 }

func _ready() -> void:
	_load()

func award_zankou(amount: int) -> void:
	if amount <= 0: return
	zankou += amount
	_save()

func upgrade_level(key: String) -> int:
	return upgrades.get(key, 0) as int

func upgrade_cost(key: String) -> int:
	var lv: int = upgrade_level(key)
	if lv >= UPGRADE_MAX_LV: return -1
	return UPGRADE_COSTS[lv]

func can_afford_upgrade(key: String) -> bool:
	var cost := upgrade_cost(key)
	return cost > 0 and zankou >= cost

func buy_upgrade(key: String) -> bool:
	if not can_afford_upgrade(key): return false
	var cost := upgrade_cost(key)
	zankou -= cost
	upgrades[key] = upgrade_level(key) + 1
	_save()
	return true

func unlock_sigil(sigil_id: String) -> void:
	if sigil_id not in collected_ids:
		collected_ids.append(sigil_id)
		_save()

func is_unlocked(sigil_id: String) -> bool:
	var d := _Sigils.get_data(sigil_id)
	if d.get("tier", 1) == 1:
		return true
	return sigil_id in collected_ids

func equip_sigil(attribute: String, sigil_id: String) -> void:
	if is_unlocked(sigil_id):
		equipped[attribute] = sigil_id
		_save()

func get_equipped_sigil(attribute: String) -> String:
	return equipped.get(attribute, _Sigils.default_sigil_id(attribute))

# ステージクリア時の解放処理（2026-08-04：check_placeholder_unlocksを実条件に差し替え）。
# ステージ1クリア→3属性のtier2を一括解放／ステージ2クリア→tier3を一括解放／ステージ3クリア→エンドレス解禁。
# 3属性まとめて解放する方式（守さん確定：属性ごとの個別解放は複雑なだけで不採用）。
func clear_stage(stage: int) -> void:
	if stage == 1:
		for attr in _Sigils.ATTR_TIERS:
			unlock_sigil((_Sigils.ATTR_TIERS[attr] as Array)[1] as String)  # tier2
	elif stage == 2:
		for attr in _Sigils.ATTR_TIERS:
			unlock_sigil((_Sigils.ATTR_TIERS[attr] as Array)[2] as String)  # tier3
	unlocked_stage = maxi(unlocked_stage, stage + 1)
	_save()

func is_stage_unlocked(stage: int) -> bool:
	return stage <= unlocked_stage

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		var loaded_ids: Array = cfg.get_value("sigils", "unlocked", [])
		collected_ids.assign(loaded_ids)
		equipped = cfg.get_value("sigils", "equipped", {})
		unlocked_stage = cfg.get_value("progress", "unlocked_stage", 1) as int
		zankou = cfg.get_value("meta", "zankou", 0) as int
		upgrades = cfg.get_value("meta", "upgrades", { "hp": 0, "atk": 0, "spd": 0 })

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg")  # 既存の[score]セクションなどを保持したまま追記する
	cfg.set_value("sigils", "unlocked", collected_ids)
	cfg.set_value("sigils", "equipped", equipped)
	cfg.set_value("progress", "unlocked_stage", unlocked_stage)
	cfg.set_value("meta", "zankou", zankou)
	cfg.set_value("meta", "upgrades", upgrades)
	cfg.save("user://save.cfg")
