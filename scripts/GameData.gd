extends Node

var collected_ids : Array[String] = []
var equipped      : Dictionary    = {}  # char_id -> card_id

func add_card(card_id: String) -> void:
	if card_id not in collected_ids:
		collected_ids.append(card_id)

func has_card(card_id: String) -> bool:
	return card_id in collected_ids

func equip_card(char_id: String, card_id: String) -> void:
	if card_id == "":
		equipped.erase(char_id)
	else:
		equipped[char_id] = card_id

func get_equipped(char_id: String) -> String:
	return equipped.get(char_id, "")
