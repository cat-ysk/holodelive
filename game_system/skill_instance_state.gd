class_name SkillInstanceState
extends RefCounted

## スキルインスタンスの状態
enum Status {
	PENDING,        # スタックに積まれて待機中
	RESPONDING,     # 常時スキルの反応待ち
	RESOLVING,      # 解決中
	WAITING_CHOICE, # プレイヤーの選択待ち
	RESOLVED,       # 解決完了
	CANCELLED       # キャンセルされた
}

## インスタンスの一意ID
var instance_id: int
## スキルの定義
var skill: SkillState
## 発動したプレイヤーID
var owner_player_id: int
## 発動元のカードID
var source_card_id: String
## 現在の状態
var status: Status
## 現在実行中の効果インデックス
var current_effect_index: int
## 効果の実行で収集されたデータ（選択されたカード等）
var context_data: Dictionary
## このスキルがキャンセル可能かどうか
var is_cancellable: bool

## インスタンスIDのカウンター（静的）
static var _next_instance_id: int = 0


func _init(
	p_skill: SkillState = null,
	p_owner: int = 0,
	p_source_card: String = ""
) -> void:
	instance_id = _next_instance_id
	_next_instance_id += 1

	skill = p_skill
	owner_player_id = p_owner
	source_card_id = p_source_card
	status = Status.PENDING
	current_effect_index = 0
	context_data = {}
	is_cancellable = true


func duplicate_state() -> SkillInstanceState:
	var copy := SkillInstanceState.new()
	copy.instance_id = instance_id
	copy.skill = skill.duplicate_state() if skill else null
	copy.owner_player_id = owner_player_id
	copy.source_card_id = source_card_id
	copy.status = status
	copy.current_effect_index = current_effect_index
	copy.context_data = context_data.duplicate(true)
	copy.is_cancellable = is_cancellable
	return copy


## 現在の効果を取得
func get_current_effect() -> SkillEffect:
	if skill == null or current_effect_index >= skill.effects.size():
		return null
	return skill.effects[current_effect_index]


## 次の効果へ進む
func advance_to_next_effect() -> bool:
	current_effect_index += 1
	return current_effect_index < skill.effects.size()


## すべての効果が完了したか
func is_all_effects_done() -> bool:
	if skill == null:
		return true
	return current_effect_index >= skill.effects.size()


## コンテキストにデータを保存
func store_context(key: String, value: Variant) -> void:
	context_data[key] = value


## コンテキストからデータを取得
func get_context(key: String, default: Variant = null) -> Variant:
	return context_data.get(key, default)


## スキル名を取得
func get_skill_name() -> String:
	return skill.skill_name if skill else ""


## スキルIDを取得
func get_skill_id() -> String:
	return skill.id if skill else ""


func _to_string() -> String:
	var status_names := ["PENDING", "RESPONDING", "RESOLVING", "WAITING_CHOICE", "RESOLVED", "CANCELLED"]
	return "SkillInstance(#%d, %s, status=%s, effect=%d)" % [
		instance_id,
		get_skill_name(),
		status_names[status],
		current_effect_index
	]
