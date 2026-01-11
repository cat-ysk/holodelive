class_name TestCardFactory
extends RefCounted

## テスト用カードを生成するファクトリ

static var _card_counter: int = 0


## カードIDカウンターをリセット
static func reset_counter() -> void:
	_card_counter = 0


## 基本的なテストカードを生成
static func create_card(
	name: String = "",
	suit: CardState.Suit = CardState.Suit.LOVELY,
	icons: Array[CardState.Icon] = [],
	play_skill: String = "",
	action_skills: Array[String] = [],
	auto_skill: String = ""
) -> CardState:
	_card_counter += 1
	var id := "test_card_%03d" % _card_counter

	if name.is_empty():
		name = "テストカード %d" % _card_counter

	if icons.is_empty():
		icons = [CardState.Icon.SEISO]

	var card := CardState.new(id, name, suit, icons, play_skill, action_skills, auto_skill)
	return card


## スキル付きカードを生成
static func create_card_with_skill(
	skill_id: String,
	skill_type: SkillState.Type = SkillState.Type.PLAY
) -> CardState:
	var card := create_card()

	match skill_type:
		SkillState.Type.PLAY:
			card.play_skill_id = skill_id
		SkillState.Type.ACTION:
			card.action_skill_ids = [skill_id]
		SkillState.Type.AUTO:
			card.auto_skill_id = skill_id

	return card


## 複数のダミーカードを生成
static func create_dummy_cards(count: int) -> Array[CardState]:
	var cards: Array[CardState] = []
	var suits := [
		CardState.Suit.LOVELY,
		CardState.Suit.COOL,
		CardState.Suit.HOT,
		CardState.Suit.ENGLISH,
		CardState.Suit.INDONESIA
	]
	var icons := [
		CardState.Icon.SEISO,
		CardState.Icon.CHARISMA,
		CardState.Icon.OTAKU,
		CardState.Icon.VOCAL,
		CardState.Icon.ENJOY
	]

	for i in range(count):
		var suit: CardState.Suit = suits[i % suits.size()]
		var icon_array: Array[CardState.Icon] = [icons[i % icons.size()]]
		var card := create_card("ダミー %d" % (i + 1), suit, icon_array)
		cards.append(card)

	return cards


## プリセット: c1s1テスト用の盤面
static func preset_c1s1_test() -> Dictionary:
	reset_counter()

	var p1_hand: Array[CardState] = []
	var p2_hand: Array[CardState] = []
	var deck: Array[CardState] = []

	# P1の手札（スキル持ちカード1枚）
	var skill_card := create_card_with_skill("c1s1", SkillState.Type.PLAY)
	skill_card.card_name = "ドローブースト持ち"
	p1_hand.append(skill_card)

	# 山札に10枚
	deck = create_dummy_cards(10)

	return {
		"p1_hand": p1_hand,
		"p2_hand": p2_hand,
		"p1_unit": [] as Array[CardState],
		"p2_unit": [] as Array[CardState],
		"p1_backstage": null,
		"p2_backstage": null,
		"deck": deck,
		"home": [] as Array[CardState]
	}


## プリセット: c2s1テスト用の盤面（カード交換）
static func preset_c2s1_test() -> Dictionary:
	reset_counter()

	var p1_hand: Array[CardState] = []
	var p2_hand: Array[CardState] = []

	# P1の手札（スキル持ち + ダミー1枚）
	var skill_card := create_card_with_skill("c2s1", SkillState.Type.PLAY)
	skill_card.card_name = "カード交換持ち"
	p1_hand.append(skill_card)
	p1_hand.append(create_card("P1のカードA"))

	# P2の手札（2枚）
	p2_hand.append(create_card("P2のカードA"))
	p2_hand.append(create_card("P2のカードB"))

	return {
		"p1_hand": p1_hand,
		"p2_hand": p2_hand,
		"p1_unit": [] as Array[CardState],
		"p2_unit": [] as Array[CardState],
		"p1_backstage": null,
		"p2_backstage": null,
		"deck": create_dummy_cards(5),
		"home": [] as Array[CardState]
	}


## プリセット: c3s1テスト用の盤面（カウンター）
static func preset_c3s1_test() -> Dictionary:
	reset_counter()

	var p1_hand: Array[CardState] = []
	var p2_unit: Array[CardState] = []

	# P1の手札（c1s1スキル持ち）
	var skill_card := create_card_with_skill("c1s1", SkillState.Type.PLAY)
	skill_card.card_name = "ドローブースト持ち"
	p1_hand.append(skill_card)

	# P2のユニット（c3s1カウンタースキル持ち）
	var counter_card := create_card_with_skill("c3s1", SkillState.Type.AUTO)
	counter_card.card_name = "カウンター持ち"
	p2_unit.append(counter_card)

	return {
		"p1_hand": p1_hand,
		"p2_hand": [] as Array[CardState],
		"p1_unit": [] as Array[CardState],
		"p2_unit": p2_unit,
		"p1_backstage": null,
		"p2_backstage": null,
		"deck": create_dummy_cards(10),
		"home": [] as Array[CardState]
	}
