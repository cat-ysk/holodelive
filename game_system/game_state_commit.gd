class_name GameStateCommit
extends RefCounted

## コミットの連番インデックス
var index: int
## 実行されたアクション
var action: GameAction
## アクション適用後のゲーム状態
var state_after: GameState
## コミット作成時のタイムスタンプ（ミリ秒）
var timestamp: int


func _init(
	p_index: int = 0,
	p_action: GameAction = null,
	p_state_after: GameState = null
) -> void:
	index = p_index
	action = p_action
	state_after = p_state_after
	timestamp = Time.get_ticks_msec()


## コミット情報の文字列表現
func _to_string() -> String:
	var action_str := action.to_string() if action else "null"
	return "Commit #%d [%s] at %d" % [index, action_str, timestamp]


## 状態のスナップショットを取得
func get_state_snapshot() -> GameState:
	if state_after:
		return state_after.duplicate_state()
	return null


## アクションの種類を取得
func get_action_type() -> GameAction.Type:
	if action:
		return action.type
	return GameAction.Type.GAME_START


## アクションを実行したプレイヤーを取得
func get_player_id() -> int:
	if action:
		return action.player_id
	return -1
