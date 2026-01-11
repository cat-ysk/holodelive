class_name UnitState
extends RefCounted

## ユニットのカード（最大3枚）
var cards: Array[CardState]
## ライブ準備状態
var is_live_ready: bool = false


func _init() -> void:
	cards = []


func add_card(card: CardState) -> bool:
	if cards.size() >= 3:
		return false
	cards.append(card)
	return true


func remove_card(card: CardState) -> bool:
	var index := cards.find(card)
	if index == -1:
		return false
	cards.remove_at(index)
	return true


func get_card_count() -> int:
	return cards.size()


func is_full() -> bool:
	return cards.size() >= 3


func clear() -> void:
	cards.clear()
	is_live_ready = false


func duplicate_state() -> UnitState:
	var copy := UnitState.new()
	for card in cards:
		copy.cards.append(card.duplicate_state())
	copy.is_live_ready = is_live_ready
	return copy
