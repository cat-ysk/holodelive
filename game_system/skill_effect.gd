class_name SkillEffect
extends RefCounted

## 効果の種類
enum Type {
	# カード操作
	DRAW_CARDS,           # カードをドロー
	DISCARD_CARDS,        # カードを捨てる
	SWAP_CARDS,           # カードを交換
	MOVE_CARD,            # カードを移動
	RETURN_TO_DECK,       # 山札に戻す
	RETURN_TO_HAND,       # 手札に戻す

	# 対象選択
	SELECT_CARD,          # カードを選択（手札、ユニット等から）
	SELECT_PLAYER,        # プレイヤーを選択

	# スキル操作
	CANCEL_SKILL,         # スキルをキャンセル
	COPY_SKILL,           # スキルをコピー

	# 状態変更
	MODIFY_CARD,          # カードの状態を変更
	PROTECT_CARD,         # カードを保護

	# 条件分岐
	IF_CONDITION,         # 条件分岐

	# 複合効果
	CHOICE,               # プレイヤーに選択肢を提示
	SEQUENCE,             # 複数効果を順番に実行
	FOR_EACH,             # 対象それぞれに効果を適用
}

## 対象の指定方法
enum TargetType {
	NONE,                 # 対象なし
	SELF,                 # 自分
	OPPONENT,             # 相手
	BOTH,                 # 両方
	CHOICE,               # 選択
	SOURCE_CARD,          # 発動元カード
	SELECTED,             # 前の効果で選択されたもの
}

## カードの場所
enum CardLocation {
	HAND,                 # 手札
	UNIT,                 # ユニット
	BACKSTAGE,            # 楽屋
	DECK,                 # 山札
	HOME,                 # 自宅
	ANY_FIELD,            # フィールド上どこでも
}

## 効果の種類
var type: Type
## 効果のパラメータ
var params: Dictionary


func _init(p_type: Type = Type.DRAW_CARDS, p_params: Dictionary = {}) -> void:
	type = p_type
	params = p_params


func duplicate_effect() -> SkillEffect:
	return SkillEffect.new(type, params.duplicate(true))


#region ファクトリメソッド

## カードをドローする効果
static func draw_cards(target: TargetType, count: int = 1) -> SkillEffect:
	return SkillEffect.new(Type.DRAW_CARDS, {
		"target": target,
		"count": count
	})


## カードを選択させる効果
static func select_card(
	selector: TargetType,
	from_location: CardLocation,
	from_player: TargetType,
	count: int = 1,
	store_as: String = "selected"
) -> SkillEffect:
	return SkillEffect.new(Type.SELECT_CARD, {
		"selector": selector,
		"from_location": from_location,
		"from_player": from_player,
		"count": count,
		"store_as": store_as
	})


## カードを交換する効果
static func swap_cards(card_a_key: String, card_b_key: String) -> SkillEffect:
	return SkillEffect.new(Type.SWAP_CARDS, {
		"card_a": card_a_key,
		"card_b": card_b_key
	})


## カードを移動する効果
static func move_card(card_key: String, to_location: CardLocation, to_player: TargetType) -> SkillEffect:
	return SkillEffect.new(Type.MOVE_CARD, {
		"card": card_key,
		"to_location": to_location,
		"to_player": to_player
	})


## スキルをキャンセルする効果
static func cancel_skill(target_skill_key: String = "triggering_skill") -> SkillEffect:
	return SkillEffect.new(Type.CANCEL_SKILL, {
		"target_skill": target_skill_key
	})


## プレイヤーに選択肢を提示する効果
static func choice(selector: TargetType, options: Array[SkillEffect], store_as: String = "choice_result") -> SkillEffect:
	return SkillEffect.new(Type.CHOICE, {
		"selector": selector,
		"options": options,
		"store_as": store_as
	})


## 複数の効果を順番に実行
static func sequence(effects: Array[SkillEffect]) -> SkillEffect:
	return SkillEffect.new(Type.SEQUENCE, {
		"effects": effects
	})


## 条件分岐
static func if_condition(condition: Dictionary, then_effect: SkillEffect, else_effect: SkillEffect = null) -> SkillEffect:
	return SkillEffect.new(Type.IF_CONDITION, {
		"condition": condition,
		"then": then_effect,
		"else": else_effect
	})

#endregion
