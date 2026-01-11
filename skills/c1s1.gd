extends SkillBase
## カード1のプレイスキル: ドローブースト
## カードを2枚ドローして、1枚を選び山札の一番上に戻す


func get_id() -> String:
	return "c1s1"


func get_type() -> SkillState.Type:
	return SkillState.Type.PLAY


func get_name() -> String:
	return "ドローブースト"


func get_description() -> String:
	return "カードを2枚ドローして、1枚を選び山札の一番上に戻す"


func create_choice_request(state: GameState, context: SkillContext) -> ChoiceRequestState:
	var phase := context.phase

	if phase == 0:
		# フェーズ0: まず2枚ドロー（選択なし）
		return null

	elif phase == 1:
		# フェーズ1: 手札から1枚選択して山札に戻す
		var player := state.players[context.owner_player_id]
		if player.hand.is_empty():
			return null

		return ChoiceRequestState.select_cards(
			context.owner_player_id,
			context.instance.instance_id if context.instance else -1,
			SkillEffect.CardLocation.HAND,
			context.owner_player_id,
			1
		)

	return null


func on_choice_made(state: GameState, context: SkillContext, answer: Variant) -> void:
	var phase := context.phase

	if phase == 1:
		# 選んだカードIDを保存
		context.store("return_card_id", answer)
		context.advance_phase()


func execute(state: GameState, context: SkillContext) -> void:
	var player := state.players[context.owner_player_id]
	var phase := context.phase

	if phase == 0:
		# フェーズ0: 2枚ドロー
		var drawn_count := 0
		for i in range(2):
			var card := state.deck.draw()
			if card:
				player.add_to_hand(card)
				drawn_count += 1

		context.record_action(GameAction.skill_effect(
			context.instance.instance_id if context.instance else -1,
			0,
			SkillEffect.Type.DRAW_CARDS,
			{"player_id": context.owner_player_id, "count": drawn_count}
		))

		# 次のフェーズへ（カード選択）
		context.advance_phase()
		return

	elif phase == 2:
		# フェーズ2: 選んだカードを山札の一番上に戻す
		var return_card_id: String = context.get_data("return_card_id", "")
		if return_card_id.is_empty():
			return

		# 手札からカードを探す
		var return_card: CardState = null
		for card in player.hand:
			if card.id == return_card_id:
				return_card = card
				break

		if return_card == null:
			return

		# 手札から除去して山札の一番上に戻す
		player.remove_from_hand(return_card)
		state.deck.cards.append(return_card)  # append = 一番上に追加

		context.record_action(GameAction.skill_effect(
			context.instance.instance_id if context.instance else -1,
			1,
			SkillEffect.Type.RETURN_TO_DECK,
			{"player_id": context.owner_player_id, "card_id": return_card_id}
		))
