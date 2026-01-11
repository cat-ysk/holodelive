extends SkillBase
## カード2のプレイスキル: カード交換
## 自分が相手の手札を1枚指定し、相手が自分の手札を1枚指定して交換する


func get_id() -> String:
	return "c2s1"


func get_type() -> SkillState.Type:
	return SkillState.Type.PLAY


func get_name() -> String:
	return "カード交換"


func get_description() -> String:
	return "自分が相手の手札を1枚指定し、相手が自分の手札を1枚指定して交換する"


func can_activate(state: GameState, context: SkillContext) -> bool:
	# 相手に手札があるか
	var opponent := state.players[context.get_opponent_id()]
	if opponent.hand.is_empty():
		return false
	# 自分に手札があるか
	var player := state.players[context.owner_player_id]
	if player.hand.is_empty():
		return false
	return true


func create_choice_request(state: GameState, context: SkillContext) -> ChoiceRequestState:
	var phase := context.phase

	if phase == 0:
		# フェーズ0: 自分が相手の手札を選択
		return ChoiceRequestState.select_cards(
			context.owner_player_id,
			context.instance.instance_id if context.instance else -1,
			SkillEffect.CardLocation.HAND,
			context.get_opponent_id(),
			1
		)
	elif phase == 1:
		# フェーズ1: 相手が自分の手札を選択
		return ChoiceRequestState.select_cards(
			context.get_opponent_id(),
			context.instance.instance_id if context.instance else -1,
			SkillEffect.CardLocation.HAND,
			context.owner_player_id,
			1
		)

	# フェーズ2以降は選択不要
	return null


func on_choice_made(state: GameState, context: SkillContext, answer: Variant) -> void:
	var phase := context.phase

	if phase == 0:
		# 自分が選んだ相手のカードを保存
		context.store("opponent_card_id", answer)
		context.advance_phase()
	elif phase == 1:
		# 相手が選んだ自分のカードを保存
		context.store("my_card_id", answer)
		context.advance_phase()


func execute(state: GameState, context: SkillContext) -> void:
	# フェーズ2: 実際の交換処理
	var opponent_card_id: String = context.get_data("opponent_card_id", "")
	var my_card_id: String = context.get_data("my_card_id", "")

	if opponent_card_id.is_empty() or my_card_id.is_empty():
		return

	var player := state.players[context.owner_player_id]
	var opponent := state.players[context.get_opponent_id()]

	# カードを探す
	var my_card: CardState = null
	var opponent_card: CardState = null

	for card in player.hand:
		if card.id == my_card_id:
			my_card = card
			break

	for card in opponent.hand:
		if card.id == opponent_card_id:
			opponent_card = card
			break

	if my_card == null or opponent_card == null:
		return

	# 交換実行
	player.remove_from_hand(my_card)
	opponent.remove_from_hand(opponent_card)
	player.add_to_hand(opponent_card)
	opponent.add_to_hand(my_card)

	# アクション記録
	context.record_action(GameAction.skill_effect(
		context.instance.instance_id if context.instance else -1,
		0,
		SkillEffect.Type.SWAP_CARDS,
		{
			"player_card": my_card_id,
			"opponent_card": opponent_card_id
		}
	))
