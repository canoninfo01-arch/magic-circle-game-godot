extends Node

var collected_ids : Array[String] = []

func add_card(card_id: String) -> void:
	if card_id not in collected_ids:
		collected_ids.append(card_id)

func has_card(card_id: String) -> bool:
	return card_id in collected_ids
