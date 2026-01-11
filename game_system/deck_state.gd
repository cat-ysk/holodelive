class_name DeckState
extends RefCounted

## 山札のカード
var cards: Array[CardState]


func _init() -> void:
	cards = []


func add_card(card: CardState) -> void:
	cards.append(card)


func add_cards(new_cards: Array[CardState]) -> void:
	cards.append_array(new_cards)


func draw() -> CardState:
	if cards.is_empty():
		return null
	return cards.pop_back()


func shuffle() -> void:
	cards.shuffle()


func get_remaining_count() -> int:
	return cards.size()


func is_empty() -> bool:
	return cards.is_empty()


func clear() -> void:
	cards.clear()


func duplicate_state() -> DeckState:
	var copy := DeckState.new()
	for card in cards:
		copy.cards.append(card.duplicate_state())
	return copy
