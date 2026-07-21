extends Node

const _Sigils = preload("res://scripts/Sigils.gd")

# 解放済み紋章id（tier2/3のみ格納。tier1は常時解放扱いなので格納不要）
var collected_ids : Array[String] = []
# 属性名 -> 装備中のsigil_id（例: {"circle": "circle_2", "triangle": "triangle_1", "square": "square_1"}）
var equipped      : Dictionary    = {}

func _ready() -> void:
	_load()

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

# TODO(実績本実装): 現在は条件なしで全tierを解放する。
# 目的は「解放→装備→バトル中の描画/召喚に反映」のパイプライン確認であり、
# 実際の実績条件はこの関数の中身だけを差し替えれば済むようにしてある。
func check_placeholder_unlocks() -> void:
	for attr in _Sigils.ATTR_TIERS:
		for sigil_id in (_Sigils.ATTR_TIERS[attr] as Array):
			unlock_sigil(sigil_id as String)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		var loaded_ids: Array = cfg.get_value("sigils", "unlocked", [])
		collected_ids.assign(loaded_ids)
		equipped = cfg.get_value("sigils", "equipped", {})

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg")  # 既存の[score]セクションなどを保持したまま追記する
	cfg.set_value("sigils", "unlocked", collected_ids)
	cfg.set_value("sigils", "equipped", equipped)
	cfg.save("user://save.cfg")
