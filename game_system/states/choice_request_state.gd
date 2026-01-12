class_name ChoiceRequestState
extends RefCounted

## 選択の種類
enum Type {
	SELECT_CARDS,      # カードを選択
	SELECT_YES_NO,     # はい/いいえの選択
	SELECT_OPTION,     # オプションから選択
	SELECT_PLAYER,     # プレイヤーを選択
	SELECT_SKILL,      # 発動するスキルを選択
	CONFIRM_TRIGGER,   # 常時スキルを発動するか確認
}

## 選択リクエストの状態
enum Status {
	PENDING,    # 回答待ち
	ANSWERED,   # 回答済み
	CANCELLED,  # キャンセルされた
}

## リクエストの一意ID
var request_id: int
## 選択の種類
var type: Type
## 選択するプレイヤーID
var player_id: int
## 関連するスキルインスタンスID
var skill_instance_id: int
## リクエストの詳細パラメータ
var params: Dictionary
## 現在の状態
var status: Status
## プレイヤーの回答
var answer: Variant

## リクエストIDのカウンター
static var _next_request_id: int = 0


func _init(
	p_type: Type = Type.SELECT_CARDS,
	p_player_id: int = 0,
	p_skill_instance_id: int = -1,
	p_params: Dictionary = {}
) -> void:
	request_id = _next_request_id
	_next_request_id += 1

	type = p_type
	player_id = p_player_id
	skill_instance_id = p_skill_instance_id
	params = p_params
	status = Status.PENDING
	answer = null


func duplicate_state() -> ChoiceRequestState:
	var copy := ChoiceRequestState.new(type, player_id, skill_instance_id, params.duplicate(true))
	copy.request_id = request_id
	copy.status = status
	copy.answer = answer
	return copy


## 回答を設定
func set_answer(p_answer: Variant) -> void:
	answer = p_answer
	status = Status.ANSWERED


## キャンセル
func cancel() -> void:
	status = Status.CANCELLED


## 回答済みかどうか
func is_answered() -> bool:
	return status == Status.ANSWERED


## 待機中かどうか
func is_pending() -> bool:
	return status == Status.PENDING


#region ファクトリメソッド

## カード選択リクエストを作成
static func select_cards(
	player_id: int,
	skill_instance_id: int,
	from_location: SkillEffect.CardLocation,
	from_player_id: int,
	count: int = 1,
	card_filter: Dictionary = {}
) -> ChoiceRequestState:
	return ChoiceRequestState.new(Type.SELECT_CARDS, player_id, skill_instance_id, {
		"from_location": from_location,
		"from_player_id": from_player_id,
		"count": count,
		"filter": card_filter,
		"optional": false
	})


## はい/いいえ選択を作成
static func yes_no(
	player_id: int,
	skill_instance_id: int,
	message: String
) -> ChoiceRequestState:
	return ChoiceRequestState.new(Type.SELECT_YES_NO, player_id, skill_instance_id, {
		"message": message
	})


## 常時スキル発動確認を作成
static func confirm_trigger(
	player_id: int,
	triggering_skill_id: String,
	auto_skill_instance_id: int
) -> ChoiceRequestState:
	return ChoiceRequestState.new(Type.CONFIRM_TRIGGER, player_id, auto_skill_instance_id, {
		"triggering_skill_id": triggering_skill_id,
		"message": "常時スキルを発動しますか？"
	})


## オプション選択を作成
static func select_option(
	player_id: int,
	skill_instance_id: int,
	options: Array[String],
	message: String = ""
) -> ChoiceRequestState:
	return ChoiceRequestState.new(Type.SELECT_OPTION, player_id, skill_instance_id, {
		"options": options,
		"message": message
	})

#endregion


func _to_string() -> String:
	var type_names := ["SELECT_CARDS", "SELECT_YES_NO", "SELECT_OPTION", "SELECT_PLAYER", "SELECT_SKILL", "CONFIRM_TRIGGER"]
	var status_names := ["PENDING", "ANSWERED", "CANCELLED"]
	return "ChoiceRequest(#%d, type=%s, player=%d, status=%s)" % [
		request_id,
		type_names[type],
		player_id,
		status_names[status]
	]
