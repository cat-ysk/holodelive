class_name SkillStackState
extends RefCounted

## スキルスタックの状態
enum Phase {
	IDLE,             # スタックが空で待機中
	COLLECTING,       # 常時スキルの反応を収集中
	RESOLVING,        # スタックを解決中
	WAITING_CHOICE,   # プレイヤーの選択待ち
}

## 現在のフェーズ
var phase: Phase
## スキルインスタンスのスタック（後入れ先出し）
var stack: Array[SkillInstanceState]
## 現在の選択リクエスト
var pending_choice: ChoiceRequestState
## 解決済みのスキルインスタンス（履歴用）
var resolved_instances: Array[SkillInstanceState]


func _init() -> void:
	phase = Phase.IDLE
	stack = []
	pending_choice = null
	resolved_instances = []


func duplicate_state() -> SkillStackState:
	var copy := SkillStackState.new()
	copy.phase = phase
	for instance in stack:
		copy.stack.append(instance.duplicate_state())
	if pending_choice:
		copy.pending_choice = pending_choice.duplicate_state()
	for instance in resolved_instances:
		copy.resolved_instances.append(instance.duplicate_state())
	return copy


## スタックにスキルを追加
func push(instance: SkillInstanceState) -> void:
	stack.append(instance)
	if phase == Phase.IDLE:
		phase = Phase.COLLECTING


## スタックからスキルを取り出し
func pop() -> SkillInstanceState:
	if stack.is_empty():
		return null
	return stack.pop_back()


## スタックの一番上を参照（取り出さない）
func peek() -> SkillInstanceState:
	if stack.is_empty():
		return null
	return stack.back()


## スタックが空かどうか
func is_empty() -> bool:
	return stack.is_empty()


## スタックのサイズ
func size() -> int:
	return stack.size()


## 選択待ち状態にする
func set_waiting_choice(request: ChoiceRequestState) -> void:
	pending_choice = request
	phase = Phase.WAITING_CHOICE


## 選択が完了したことを通知
func complete_choice() -> void:
	pending_choice = null
	if stack.is_empty():
		phase = Phase.IDLE
	else:
		phase = Phase.RESOLVING


## 解決中にする
func set_resolving() -> void:
	phase = Phase.RESOLVING


## 常時スキル収集中にする
func set_collecting() -> void:
	phase = Phase.COLLECTING


## アイドル状態にリセット
func reset_to_idle() -> void:
	phase = Phase.IDLE
	pending_choice = null


## スキルが解決完了したことを記録
func mark_resolved(instance: SkillInstanceState) -> void:
	instance.status = SkillInstanceState.Status.RESOLVED
	resolved_instances.append(instance)


## スキルがキャンセルされたことを記録
func mark_cancelled(instance: SkillInstanceState) -> void:
	instance.status = SkillInstanceState.Status.CANCELLED
	resolved_instances.append(instance)


## 指定IDのスキルインスタンスをスタックから探す
func find_instance_by_id(instance_id: int) -> SkillInstanceState:
	for instance in stack:
		if instance.instance_id == instance_id:
			return instance
	return null


## 指定IDのスキルインスタンスをキャンセル
func cancel_instance(instance_id: int) -> bool:
	for i in range(stack.size()):
		if stack[i].instance_id == instance_id:
			var cancelled := stack[i]
			stack.remove_at(i)
			mark_cancelled(cancelled)
			return true
	return false


## スタックと解決済みをクリア
func clear() -> void:
	stack.clear()
	resolved_instances.clear()
	pending_choice = null
	phase = Phase.IDLE


## 選択待ちかどうか
func is_waiting_choice() -> bool:
	return phase == Phase.WAITING_CHOICE and pending_choice != null


## 現在の選択リクエストを取得
func get_pending_choice() -> ChoiceRequestState:
	return pending_choice


func _to_string() -> String:
	var phase_names := ["IDLE", "COLLECTING", "RESOLVING", "WAITING_CHOICE"]
	return "SkillStack(phase=%s, stack_size=%d, resolved=%d)" % [
		phase_names[phase],
		stack.size(),
		resolved_instances.size()
	]
