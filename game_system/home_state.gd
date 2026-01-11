class_name HomeState
extends RefCounted

## 自宅のカード
var cards: Array[CardState]
## ターン終了時に山札に戻す閾値
const MAX_CARDS_BEFORE_RETURN := 5


func _init() -> void:
	cards = []


func add_card(card: CardState) -> void:
	cards.append(card)


func remove_card(card: CardState) -> bool:
	var index := cards.find(card)
	if index == -1:
		return false
	cards.remove_at(index)
	return true


func get_card_count() -> int:
	return cards.size()


## ターン終了時に5枚以上なら古いカードを返す
func get_cards_to_return() -> Array[CardState]:
	var to_return: Array[CardState] = []
	while cards.size() >= MAX_CARDS_BEFORE_RETURN:
		to_return.append(cards.pop_front())
	return to_return


func clear() -> void:
	cards.clear()


func get_all_cards() -> Array[CardState]:
	return cards.duplicate()


func duplicate_state() -> HomeState:
	var copy := HomeState.new()
	for card in cards:
		copy.cards.append(card.duplicate_state())
	return copy
