class_name SkillBase
extends RefCounted

## スキルID（c1s1形式）を返す - 必ずオーバーライド
func get_id() -> String:
	return ""


## カードIDを取得
func get_card_id() -> int:
	var id := get_id()
	var regex := RegEx.new()
	regex.compile("^c(\\d+)s\\d+$")
	var result := regex.search(id)
	if result:
		return int(result.get_string(1))
	return -1


## スキルインデックスを取得
func get_skill_index() -> int:
	var id := get_id()
	var regex := RegEx.new()
	regex.compile("^c\\d+s(\\d+)$")
	var result := regex.search(id)
	if result:
		return int(result.get_string(1))
	return -1


## スキル種類を返す - 必ずオーバーライド
func get_type() -> SkillState.Type:
	return SkillState.Type.PLAY


## トリガー条件を返す（AUTOスキル用）
func get_trigger() -> SkillState.TriggerCondition:
	return SkillState.TriggerCondition.NONE


## トリガーフィルタを返す（AUTOスキル用、追加条件）
func get_trigger_filter() -> Dictionary:
	return {}


## スキル名を返す - 必ずオーバーライド
func get_name() -> String:
	return ""


## 説明文を返す
func get_description() -> String:
	return ""


## 発動可能かチェック（オーバーライド可能）
func can_activate(state: GameState, context: SkillContext) -> bool:
	return true


## 効果実行 - 必ずオーバーライド
func execute(state: GameState, context: SkillContext) -> void:
	pass


## 選択が必要な場合の選択リクエスト生成（オーバーライド可能）
func create_choice_request(state: GameState, context: SkillContext) -> ChoiceRequestState:
	return null


## 選択結果を受け取って処理続行（オーバーライド可能）
func on_choice_made(state: GameState, context: SkillContext, answer: Variant) -> void:
	pass


## 演出を再生（オーバーライド可能）
func play_presentation(view: Node, context: SkillContext) -> void:
	pass


## 演出の完了を待つ必要があるか
func needs_presentation_wait() -> bool:
	return false


## SkillStateに変換（SkillResolverとの互換用）
func to_skill_state() -> SkillState:
	var skill := SkillState.new(
		get_id(),
		get_name(),
		get_type(),
		get_trigger()
	)
	skill.trigger_filter = get_trigger_filter()
	skill.description = get_description()
	return skill
