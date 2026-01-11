extends SkillBase
## カード3の常時スキル: スキルキャンセラー
## 相手のスキルが発動した時、それを無効化できる


func get_id() -> String:
	return "c3s1"


func get_type() -> SkillState.Type:
	return SkillState.Type.AUTO


func get_trigger() -> SkillState.TriggerCondition:
	return SkillState.TriggerCondition.ON_SKILL_ACTIVATED


func get_name() -> String:
	return "スキルキャンセラー"


func get_description() -> String:
	return "相手のスキルが発動した時、それを無効化できる"


func can_activate(state: GameState, context: SkillContext) -> bool:
	# トリガーしたスキルが相手のものか確認
	var triggering_skill_owner: int = context.get_data("triggering_skill_owner", -1)
	if triggering_skill_owner == context.owner_player_id:
		# 自分のスキルにはカウンターしない
		return false
	return true


func execute(state: GameState, context: SkillContext) -> void:
	# トリガーしたスキルのインスタンスIDを取得
	var triggering_instance_id: int = context.get_data("triggering_skill_instance_id", -1)

	if triggering_instance_id < 0:
		return

	# スキルをキャンセル
	var cancelled := state.skill_stack.cancel_instance(triggering_instance_id)

	if cancelled:
		# キャンセル成功を記録
		context.record_action(GameAction.skill_cancel(
			triggering_instance_id,
			context.instance.instance_id if context.instance else -1
		))

		context.record_action(GameAction.skill_effect(
			context.instance.instance_id if context.instance else -1,
			0,
			SkillEffect.Type.CANCEL_SKILL,
			{"cancelled_instance_id": triggering_instance_id}
		))
