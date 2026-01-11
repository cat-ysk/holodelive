class_name SkillContext
extends RefCounted

## 発動したプレイヤーID
var owner_player_id: int
## 発動元のカードID
var source_card_id: String
## スキルインスタンス（スタック上の状態）
var instance: SkillInstanceState
## アクション記録用コールバック
var on_action: Callable
## 実行中の効果フェーズ（複数段階ある場合）
var phase: int
## コンテキストデータ（選択結果等を保存）
var data: Dictionary


func _init(
	p_owner: int = 0,
	p_source_card: String = "",
	p_instance: SkillInstanceState = null
) -> void:
	owner_player_id = p_owner
	source_card_id = p_source_card
	instance = p_instance
	on_action = func(_action: GameAction): pass
	phase = 0
	data = {}


## 相手プレイヤーIDを取得
func get_opponent_id() -> int:
	return 1 - owner_player_id


## コンテキストにデータを保存
func store(key: String, value: Variant) -> void:
	data[key] = value
	if instance:
		instance.store_context(key, value)


## コンテキストからデータを取得
func get_data(key: String, default: Variant = null) -> Variant:
	if data.has(key):
		return data[key]
	if instance:
		return instance.get_context(key, default)
	return default


## フェーズを進める
func advance_phase() -> void:
	phase += 1


## アクションを記録
func record_action(action: GameAction) -> void:
	on_action.call(action)


## 複製
func duplicate_context() -> SkillContext:
	var copy := SkillContext.new(owner_player_id, source_card_id, instance)
	copy.on_action = on_action
	copy.phase = phase
	copy.data = data.duplicate(true)
	return copy


## スキルインスタンスから生成
static func from_instance(inst: SkillInstanceState, action_callback: Callable = Callable()) -> SkillContext:
	var ctx := SkillContext.new(
		inst.owner_player_id,
		inst.source_card_id,
		inst
	)
	if action_callback.is_valid():
		ctx.on_action = action_callback
	ctx.data = inst.context_data.duplicate(true)
	return ctx
