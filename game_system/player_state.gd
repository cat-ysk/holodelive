class_name PlayerState
extends RefCounted

## プレイヤーID（0 or 1）
var player_id: int
## 手札（最大3枚）
var hand: Array[CardState]
## ユニット
var unit: UnitState
## 楽屋
var backstage: BackstageState
## 取得したラウンド数
var round_wins: int = 0

const MAX_HAND_SIZE := 3


func _init(p_id: int = 0) -> void:
	player_id = p_id
	hand = []
	unit = UnitState.new()
	backstage = BackstageState.new()


func add_to_hand(card: CardState) -> bool:
	if hand.size() >= MAX_HAND_SIZE:
		return false
	hand.append(card)
	return true


func remove_from_hand(card: CardState) -> bool:
	var index := hand.find(card)
	if index == -1:
		return false
	hand.remove_at(index)
	return true


func get_hand_count() -> int:
	return hand.size()


func is_hand_full() -> bool:
	return hand.size() >= MAX_HAND_SIZE


## 手札上限を超えたカードを取得
func get_excess_hand_cards() -> Array[CardState]:
	var excess: Array[CardState] = []
	while hand.size() > MAX_HAND_SIZE:
		excess.append(hand.pop_back())
	return excess


func duplicate_state() -> PlayerState:
	var copy := PlayerState.new(player_id)
	for card in hand:
		copy.hand.append(card.duplicate_state())
	copy.unit = unit.duplicate_state()
	copy.backstage = backstage.duplicate_state()
	copy.round_wins = round_wins
	return copy
