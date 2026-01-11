class_name SkillResolver
extends RefCounted

## スキル解決時にアクションを記録するためのコールバック
var on_action: Callable

## スキルレジストリ
var registry: SkillRegistry


func _init() -> void:
	registry = SkillRegistry.new()
	on_action = func(_action: GameAction): pass


## スキルレジストリを設定
func set_registry(p_registry: SkillRegistry) -> void:
	registry = p_registry


## スキルをIDで取得（SkillBase）
func get_skill(skill_id: String) -> SkillBase:
	return registry.get_skill(skill_id)


#region スキル発動

## スキルを発動する（スタックに積む）
func activate_skill(
	state: GameState,
	skill_id: String,
	owner_player_id: int,
	source_card_id: String
) -> SkillInstanceState:
	var skill := get_skill(skill_id)
	if skill == null:
		push_warning("Skill not found: %s" % skill_id)
		return null

	# SkillStateに変換してインスタンス作成
	var skill_state := skill.to_skill_state()
	var instance := SkillInstanceState.new(skill_state, owner_player_id, source_card_id)
	state.skill_stack.push(instance)

	on_action.call(GameAction.skill_activate(
		owner_player_id,
		skill_id,
		source_card_id,
		instance.instance_id
	))

	return instance


## プレイスキルを発動
func activate_play_skill(
	state: GameState,
	card: CardState,
	owner_player_id: int
) -> SkillInstanceState:
	if card.play_skill_id.is_empty():
		return null

	var skill := get_skill(card.play_skill_id)
	if skill == null:
		return null

	# 発動可能かチェック
	var context := SkillContext.new(owner_player_id, card.id, null)
	context.on_action = on_action
	if not skill.can_activate(state, context):
		return null

	return activate_skill(state, card.play_skill_id, owner_player_id, card.id)


## アクションスキルを発動
func activate_action_skill(
	state: GameState,
	card: CardState,
	skill_index: int,
	owner_player_id: int
) -> SkillInstanceState:
	if skill_index < 0 or skill_index >= card.action_skill_ids.size():
		return null

	var skill_id := card.action_skill_ids[skill_index]
	var skill := get_skill(skill_id)
	if skill == null:
		return null

	# 発動可能かチェック
	var context := SkillContext.new(owner_player_id, card.id, null)
	context.on_action = on_action
	if not skill.can_activate(state, context):
		return null

	return activate_skill(state, skill_id, owner_player_id, card.id)

#endregion


#region 常時スキルトリガー

## 常時スキルのトリガーをチェック（場にあるカードから）
func check_auto_skill_triggers(
	state: GameState,
	trigger_condition: SkillState.TriggerCondition,
	context: Dictionary = {}
) -> Array[SkillBase]:
	on_action.call(GameAction.skill_trigger_check(trigger_condition))

	var triggerable_skills: Array[SkillBase] = []

	# 全プレイヤーのユニットと楽屋のカードをチェック
	for player in state.players:
		# ユニットのカード
		for card in player.unit.cards:
			if not card.auto_skill_id.is_empty():
				var skill := get_skill(card.auto_skill_id)
				if skill and skill.get_type() == SkillState.Type.AUTO:
					if skill.get_trigger() == trigger_condition:
						triggerable_skills.append(skill)

		# 楽屋のカード（ゲストでない場合のみ）
		if player.backstage.has_card() and not player.backstage.is_guest():
			var card := player.backstage.card
			if not card.auto_skill_id.is_empty():
				var skill := get_skill(card.auto_skill_id)
				if skill and skill.get_type() == SkillState.Type.AUTO:
					if skill.get_trigger() == trigger_condition:
						triggerable_skills.append(skill)

	return triggerable_skills


## 常時スキルの発動確認をリクエスト
func request_auto_skill_confirmation(
	state: GameState,
	player_id: int,
	skill: SkillBase,
	triggering_skill_id: String
) -> ChoiceRequestState:
	var skill_state := skill.to_skill_state()
	var instance := SkillInstanceState.new(skill_state, player_id, "")
	instance.status = SkillInstanceState.Status.RESPONDING

	var request := ChoiceRequestState.confirm_trigger(
		player_id,
		triggering_skill_id,
		instance.instance_id
	)

	state.skill_stack.set_waiting_choice(request)

	on_action.call(GameAction.choice_request(
		player_id,
		request.request_id,
		request.type,
		request.params
	))

	return request

#endregion


#region スキル解決

## スタックの解決を1ステップ進める
func resolve_step(state: GameState) -> bool:
	var stack := state.skill_stack

	# 選択待ちの場合は進めない
	if stack.is_waiting_choice():
		return false

	# スタックが空なら完了
	if stack.is_empty():
		stack.reset_to_idle()
		return false

	# スタックの一番上を解決
	var instance := stack.peek()

	if instance.status == SkillInstanceState.Status.PENDING:
		# 解決開始
		instance.status = SkillInstanceState.Status.RESOLVING
		stack.set_resolving()

	if instance.status == SkillInstanceState.Status.RESOLVING:
		# スキルの実行
		var needs_choice := _execute_skill(state, instance)
		if needs_choice:
			instance.status = SkillInstanceState.Status.WAITING_CHOICE
			return true

		# スキル解決完了
		stack.pop()
		stack.mark_resolved(instance)
		on_action.call(GameAction.skill_resolve(instance.instance_id))

		# スタックが空になったらアイドルに
		if stack.is_empty():
			stack.reset_to_idle()

	return true


## スキルを実行（選択が必要な場合はtrueを返す）
func _execute_skill(state: GameState, instance: SkillInstanceState) -> bool:
	var skill_id := instance.get_skill_id()
	var skill := get_skill(skill_id)

	if skill == null:
		push_warning("Skill not found during execution: %s" % skill_id)
		return false

	var context := SkillContext.from_instance(instance, on_action)

	# 選択が必要かチェック
	var choice_request := skill.create_choice_request(state, context)
	if choice_request != null:
		state.skill_stack.set_waiting_choice(choice_request)
		on_action.call(GameAction.choice_request(
			choice_request.player_id,
			choice_request.request_id,
			choice_request.type,
			choice_request.params
		))
		return true

	# スキル効果を実行
	skill.execute(state, context)

	on_action.call(GameAction.skill_effect(
		instance.instance_id,
		0,
		SkillEffect.Type.SEQUENCE,
		{"skill_id": skill_id, "status": "executed"}
	))

	return false

#endregion


#region 選択回答処理

## プレイヤーの選択回答を処理
func handle_choice_answer(state: GameState, player_id: int, answer: Variant) -> void:
	var stack := state.skill_stack
	var request := stack.get_pending_choice()

	if request == null or request.player_id != player_id:
		return

	request.set_answer(answer)

	on_action.call(GameAction.choice_answer(player_id, request.request_id, answer))

	# 選択結果をスキルインスタンスのコンテキストに保存
	var instance := stack.find_instance_by_id(request.skill_instance_id)
	if instance:
		instance.store_context("choice_answer", answer)

		# スキルのon_choice_madeを呼ぶ
		var skill := get_skill(instance.get_skill_id())
		if skill:
			var context := SkillContext.from_instance(instance, on_action)
			skill.on_choice_made(state, context, answer)

		instance.status = SkillInstanceState.Status.RESOLVING

	stack.complete_choice()

#endregion
