class_name BackstageState
extends RefCounted

## 楽屋のカード（最大1枚）
var card: CardState = null


func _init() -> void:
	pass


func set_card(new_card: CardState) -> bool:
	if card != null:
		return false
	new_card.is_guest = true
	card = new_card
	return true


func remove_card() -> CardState:
	var removed := card
	card = null
	return removed


func has_card() -> bool:
	return card != null


func is_guest() -> bool:
	return card != null and card.is_guest


func reveal_guest() -> void:
	if card != null:
		card.is_guest = false


func clear() -> void:
	card = null


func duplicate_state() -> BackstageState:
	var copy := BackstageState.new()
	if card != null:
		copy.card = card.duplicate_state()
	return copy
