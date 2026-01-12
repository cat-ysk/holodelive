class_name SkillState
extends RefCounted

## スキルの種類
enum Type {
	PLAY,    # プレイスキル（カードをプレイ時に発動）
	ACTION,  # アクションスキル（アクションステップで任意発動）
	AUTO     # 常時スキル（条件を満たすと自動発動）
}

## 常時スキルのトリガー条件
enum TriggerCondition {
	NONE,                    # トリガーなし（プレイ/アクションスキル用）
	ON_SKILL_ACTIVATED,      # スキルが発動された時
	ON_CARD_PLAYED,          # カードがプレイされた時
	ON_CARD_DRAWN,           # カードがドローされた時
	ON_CARD_DISCARDED,       # カードが捨てられた時
	ON_TURN_START,           # ターン開始時
	ON_TURN_END,             # ターン終了時
	ON_LIVE_READY,           # ライブ準備状態になった時
	ON_UNIT_FULL,            # ユニットが3枚揃った時
}

## スキルID
var id: String
## スキル名
var skill_name: String
## スキルの種類
var type: Type
## トリガー条件（常時スキル用）
var trigger_condition: TriggerCondition
## トリガーの追加条件（Dictionary形式）
var trigger_filter: Dictionary
## 効果のリスト
var effects: Array[SkillEffect]
## スキルの説明文
var description: String


func _init(
	p_id: String = "",
	p_name: String = "",
	p_type: Type = Type.PLAY,
	p_trigger: TriggerCondition = TriggerCondition.NONE,
	p_effects: Array[SkillEffect] = []
) -> void:
	id = p_id
	skill_name = p_name
	type = p_type
	trigger_condition = p_trigger
	trigger_filter = {}
	effects = p_effects
	description = ""


func duplicate_state() -> SkillState:
	var copy := SkillState.new(id, skill_name, type, trigger_condition)
	copy.trigger_filter = trigger_filter.duplicate(true)
	for effect in effects:
		copy.effects.append(effect.duplicate_effect())
	copy.description = description
	return copy


## 常時スキルかどうか
func is_auto_skill() -> bool:
	return type == Type.AUTO


## 指定されたトリガーで発動可能か
func can_trigger_on(condition: TriggerCondition, context: Dictionary = {}) -> bool:
	if type != Type.AUTO:
		return false
	if trigger_condition != condition:
		return false
	# 追加のフィルター条件をチェック
	return _check_trigger_filter(context)


func _check_trigger_filter(context: Dictionary) -> bool:
	if trigger_filter.is_empty():
		return true

	# フィルター条件のチェック
	for key in trigger_filter.keys():
		if not context.has(key):
			return false
		if context[key] != trigger_filter[key]:
			return false

	return true


#region ファクトリメソッド

## プレイスキルを作成
static func create_play_skill(id: String, name: String, effects: Array[SkillEffect]) -> SkillState:
	return SkillState.new(id, name, Type.PLAY, TriggerCondition.NONE, effects)


## アクションスキルを作成
static func create_action_skill(id: String, name: String, effects: Array[SkillEffect]) -> SkillState:
	return SkillState.new(id, name, Type.ACTION, TriggerCondition.NONE, effects)


## 常時スキル（カウンター）を作成
static func create_counter_skill(id: String, name: String, effects: Array[SkillEffect]) -> SkillState:
	return SkillState.new(id, name, Type.AUTO, TriggerCondition.ON_SKILL_ACTIVATED, effects)


## 常時スキル（任意トリガー）を作成
static func create_auto_skill(
	id: String,
	name: String,
	trigger: TriggerCondition,
	effects: Array[SkillEffect]
) -> SkillState:
	return SkillState.new(id, name, Type.AUTO, trigger, effects)

#endregion
