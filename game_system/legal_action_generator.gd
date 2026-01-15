class_name LegalActionGenerator
extends RefCounted

## AI/Botが現在のゲーム状態から合法なアクションを列挙するためのユーティリティ


## メインエントリーポイント: 現在の状態で取れる全ての合法アクションを取得
static func get_legal_actions(state: GameState, registry: SkillRegistry) -> Array[GameAction]:
	var actions: Array[GameAction] = []

	# ゲーム終了時は何もできない
	if state.is_game_over:
		return actions

	# スキル解決中で選択待ちの場合
	if state.is_waiting_player_choice():
		return _get_choice_actions(state)

	# スキル解決中（選択待ち以外）は待機
	if state.is_resolving_skills():
		return actions

	# 現在のステップに応じたアクションを生成
	match state.current_step:
		GameState.Step.TURN_START:
			# 自動処理のため選択肢なし
			pass
		GameState.Step.ACTION:
			actions = _get_action_step_actions(state, registry)
		GameState.Step.PLAY:
			actions = _get_play_step_actions(state)
		GameState.Step.TURN_END:
			# 自動処理のため選択肢なし
			pass

	return actions


## 選択待ち状態での回答アクションを生成
static func _get_choice_actions(state: GameState) -> Array[GameAction]:
	var actions: Array[GameAction] = []
	var choice := state.skill_stack.pending_choice

	if choice == null or not choice.is_pending():
		return actions

	var player_id := choice.player_id
	var request_id := choice.request_id

	match choice.type:
		ChoiceRequestState.Type.SELECT_YES_NO, ChoiceRequestState.Type.CONFIRM_TRIGGER:
			# はい/いいえの2択
			actions.append(GameAction.choice_answer(player_id, request_id, true))
			actions.append(GameAction.choice_answer(player_id, request_id, false))

		ChoiceRequestState.Type.SELECT_OPTION:
			# オプションから選択
			var options: Array = choice.params.get("options", [])
			for i in range(options.size()):
				actions.append(GameAction.choice_answer(player_id, request_id, i))

		ChoiceRequestState.Type.SELECT_CARDS:
			# カード選択
			var card_actions := _generate_card_selection_actions(state, choice)
			actions.append_array(card_actions)

		ChoiceRequestState.Type.SELECT_PLAYER:
			# プレイヤー選択（0 or 1）
			actions.append(GameAction.choice_answer(player_id, request_id, 0))
			actions.append(GameAction.choice_answer(player_id, request_id, 1))

		ChoiceRequestState.Type.SELECT_SKILL:
			# スキル選択（現状は実装省略）
			pass

	return actions


## カード選択の回答アクションを生成
static func _generate_card_selection_actions(state: GameState, choice: ChoiceRequestState) -> Array[GameAction]:
	var actions: Array[GameAction] = []
	var player_id := choice.player_id
	var request_id := choice.request_id

	var from_location: int = choice.params.get("from_location", 0)
	var from_player_id: int = choice.params.get("from_player_id", player_id)
	var count: int = choice.params.get("count", 1)
	var optional: bool = choice.params.get("optional", false)

	# 対象のカードリストを取得
	var available_cards := _get_cards_at_location(state, from_player_id, from_location)

	# フィルタ適用（存在すれば）
	var filter: Dictionary = choice.params.get("filter", {})
	if not filter.is_empty():
		available_cards = _filter_cards(available_cards, filter)

	# オプショナルなら選択しないことも可能
	if optional:
		actions.append(GameAction.choice_answer(player_id, request_id, []))

	# 必要枚数を選べない場合
	if available_cards.size() < count:
		if optional:
			return actions
		# 選べる限りの枚数を選択
		var card_ids: Array[String] = []
		for card in available_cards:
			card_ids.append(card.id)
		actions.append(GameAction.choice_answer(player_id, request_id, card_ids))
		return actions

	# 組み合わせを生成
	var combinations := _get_combinations(available_cards, count)
	for combo in combinations:
		var card_ids: Array[String] = []
		for card in combo:
			card_ids.append(card.id)
		actions.append(GameAction.choice_answer(player_id, request_id, card_ids))

	return actions


## ACTIONステップで取れるアクションを生成
static func _get_action_step_actions(state: GameState, registry: SkillRegistry) -> Array[GameAction]:
	var actions: Array[GameAction] = []
	var player_id := state.current_player
	var player := state.get_current_player_state()

	# PASS_ACTION は常に選択可能
	actions.append(GameAction.pass_action(player_id))

	# Unit内のカードからアクションスキルを探す
	for card in player.unit.cards:
		_add_action_skill_actions(actions, state, card, player_id, registry)

	# Backstageのカード（公開されている場合）からアクションスキルを探す
	if player.backstage.has_card() and not player.backstage.is_guest():
		_add_action_skill_actions(actions, state, player.backstage.card, player_id, registry)

	return actions


## カードからアクションスキルのアクションを追加
static func _add_action_skill_actions(
	actions: Array[GameAction],
	state: GameState,
	card: CardState,
	player_id: int,
	registry: SkillRegistry
) -> void:
	for skill_id in card.action_skill_ids:
		var skill := registry.get_skill(skill_id)
		if skill == null:
			continue

		# スキル種類チェック
		if skill.get_type() != SkillState.Type.ACTION:
			continue

		# 発動可能かチェック
		var context := SkillContext.new(player_id, card.id)
		if skill.can_activate(state, context):
			actions.append(GameAction.use_action_skill(player_id, card.id, skill_id))


## PLAYステップで取れるアクションを生成
static func _get_play_step_actions(state: GameState) -> Array[GameAction]:
	var actions: Array[GameAction] = []
	var player_id := state.current_player
	var player := state.get_current_player_state()

	# 手札の各カードについて
	for card in player.hand:
		# Unitに出す（Unitが満杯でなければ）
		if not player.unit.is_full():
			actions.append(GameAction.play_to_unit(player_id, card.id))

		# Backstageに出す（Backstageが空なら）
		if not player.backstage.has_card():
			actions.append(GameAction.play_to_backstage(player_id, card.id))

	# ゲストを公開する（Backstageにゲストがいれば）
	if player.backstage.is_guest():
		actions.append(GameAction.reveal_guest(player_id))

	return actions


#region ヘルパーメソッド

## 指定された場所からカードリストを取得
static func _get_cards_at_location(state: GameState, player_id: int, location: int) -> Array[CardState]:
	var cards: Array[CardState] = []
	var player := state.get_player_state(player_id)

	if player == null:
		return cards

	match location:
		SkillEffect.CardLocation.HAND:
			cards.append_array(player.hand)
		SkillEffect.CardLocation.UNIT:
			cards.append_array(player.unit.cards)
		SkillEffect.CardLocation.BACKSTAGE:
			if player.backstage.has_card():
				cards.append(player.backstage.card)
		SkillEffect.CardLocation.DECK:
			cards.append_array(state.deck.cards)
		SkillEffect.CardLocation.HOME:
			cards.append_array(state.home.cards)
		SkillEffect.CardLocation.ANY_FIELD:
			# フィールド上のすべてのカード（手札、ユニット、楽屋）
			cards.append_array(player.hand)
			cards.append_array(player.unit.cards)
			if player.backstage.has_card():
				cards.append(player.backstage.card)

	return cards


## カードをフィルタリング
static func _filter_cards(cards: Array[CardState], filter: Dictionary) -> Array[CardState]:
	var result: Array[CardState] = []

	for card in cards:
		var matches := true

		# スートフィルタ
		if filter.has("suit") and card.suit != filter["suit"]:
			matches = false

		# アイコンフィルタ
		if filter.has("icon"):
			var icon: int = filter["icon"]
			if not card.icons.has(icon):
				matches = false

		# カードIDフィルタ
		if filter.has("card_ids"):
			var card_ids: Array = filter["card_ids"]
			if not card_ids.has(card.id):
				matches = false

		if matches:
			result.append(card)

	return result


## 組み合わせを生成（nCr）
static func _get_combinations(items: Array, count: int) -> Array:
	var result: Array = []
	if count <= 0 or count > items.size():
		return result

	_generate_combinations_recursive(items, count, 0, [], result)
	return result


static func _generate_combinations_recursive(
	items: Array,
	count: int,
	start: int,
	current: Array,
	result: Array
) -> void:
	if current.size() == count:
		result.append(current.duplicate())
		return

	for i in range(start, items.size()):
		current.append(items[i])
		_generate_combinations_recursive(items, count, i + 1, current, result)
		current.pop_back()

#endregion
