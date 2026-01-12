class_name CardState
extends RefCounted

## カードのスート（所属）
enum Suit {
	LOVELY,
	COOL,
	HOT,
	ENGLISH,
	INDONESIA,
	STAFF
}

## カードのアイコン（性格・性質）
enum Icon {
	SEISO,
	CHARISMA,
	OTAKU,
	VOCAL,
	ENJOY,
	REACTION,
	DUELIST,
	KUSOGAKI,
	INTEL,
	SEXY,
	ALCOHOL
}

var id: String
var card_name: String
var suit: Suit
var icons: Array[Icon]
var play_skill_id: String  # 0-1個、空文字列はなし
var action_skill_ids: Array[String]  # 0-2個
var auto_skill_id: String  # 0-1個、空文字列はなし
var is_guest: bool = false  # 伏せ状態（楽屋でのゲスト状態）


func _init(
	p_id: String = "",
	p_name: String = "",
	p_suit: Suit = Suit.LOVELY,
	p_icons: Array[Icon] = [],
	p_play_skill: String = "",
	p_action_skills: Array[String] = [],
	p_auto_skill: String = ""
) -> void:
	id = p_id
	card_name = p_name
	suit = p_suit
	icons = p_icons
	play_skill_id = p_play_skill
	action_skill_ids = p_action_skills
	auto_skill_id = p_auto_skill


func duplicate_state() -> CardState:
	var copy := CardState.new(
		id, card_name, suit, icons.duplicate(),
		play_skill_id, action_skill_ids.duplicate(), auto_skill_id
	)
	copy.is_guest = is_guest
	return copy
