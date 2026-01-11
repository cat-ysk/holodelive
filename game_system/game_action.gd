class_name GameAction
extends RefCounted

## アクションの種類
enum Type {
	# システムアクション
	GAME_START,          # ゲーム開始
	ROUND_START,         # ラウンド開始
	ROUND_END,           # ラウンド終了
	TURN_START,          # ターン開始
	TURN_END,            # ターン終了
	STEP_CHANGE,         # ステップ移行

	# 自動アクション
	DRAW_CARD,           # カードをドロー
	SHUFFLE_DECK,        # 山札をシャッフル

	# プレイヤーアクション
	PLAY_TO_UNIT,        # カードをユニットにプレイ
	PLAY_TO_BACKSTAGE,   # カードを楽屋にプレイ（ゲストとして）
	REVEAL_GUEST,        # ゲストを公開
	USE_ACTION_SKILL,    # アクションスキルを使用
	PASS_ACTION,         # アクションをパス

	# カード移動
	MOVE_CARD,           # カードを移動（汎用）
	DISCARD_TO_HOME,     # 自宅へ捨てる
	RETURN_TO_DECK,      # 山札へ戻す

	# ライブ関連
	LIVE_READY,          # ライブ準備状態になる
	LIVE_CHECK,          # ライブチェック
	SHOWDOWN,            # ショウダウン

	# ゲーム終了
	GAME_END             # ゲーム終了
}

## アクションの種類
var type: Type
## 実行したプレイヤー（-1はシステム）
var player_id: int
## アクションのパラメータ（アクション種類によって内容が異なる）
var params: Dictionary


func _init(p_type: Type = Type.GAME_START, p_player_id: int = -1, p_params: Dictionary = {}) -> void:
	type = p_type
	player_id = p_player_id
	params = p_params


## アクションの文字列表現
func _to_string() -> String:
	return "GameAction(%s, player=%d, params=%s)" % [Type.keys()[type], player_id, params]


## 複製を作成
func duplicate_action() -> GameAction:
	return GameAction.new(type, player_id, params.duplicate(true))


# ファクトリメソッド

static func game_start() -> GameAction:
	return GameAction.new(Type.GAME_START)


static func round_start(round_number: int, first_player: int) -> GameAction:
	return GameAction.new(Type.ROUND_START, -1, {
		"round": round_number,
		"first_player": first_player
	})


static func round_end(winner: int) -> GameAction:
	return GameAction.new(Type.ROUND_END, -1, {"winner": winner})


static func turn_start(player_id: int) -> GameAction:
	return GameAction.new(Type.TURN_START, player_id)


static func turn_end(player_id: int) -> GameAction:
	return GameAction.new(Type.TURN_END, player_id)


static func step_change(new_step: GameState.Step) -> GameAction:
	return GameAction.new(Type.STEP_CHANGE, -1, {"step": new_step})


static func draw_card(player_id: int, card_id: String = "") -> GameAction:
	return GameAction.new(Type.DRAW_CARD, player_id, {"card_id": card_id})


static func shuffle_deck() -> GameAction:
	return GameAction.new(Type.SHUFFLE_DECK)


static func play_to_unit(player_id: int, card_id: String, slot: int = -1) -> GameAction:
	return GameAction.new(Type.PLAY_TO_UNIT, player_id, {
		"card_id": card_id,
		"slot": slot
	})


static func play_to_backstage(player_id: int, card_id: String) -> GameAction:
	return GameAction.new(Type.PLAY_TO_BACKSTAGE, player_id, {"card_id": card_id})


static func reveal_guest(player_id: int) -> GameAction:
	return GameAction.new(Type.REVEAL_GUEST, player_id)


static func use_action_skill(player_id: int, card_id: String, skill_id: String, targets: Array = []) -> GameAction:
	return GameAction.new(Type.USE_ACTION_SKILL, player_id, {
		"card_id": card_id,
		"skill_id": skill_id,
		"targets": targets
	})


static func pass_action(player_id: int) -> GameAction:
	return GameAction.new(Type.PASS_ACTION, player_id)


static func discard_to_home(player_id: int, card_id: String) -> GameAction:
	return GameAction.new(Type.DISCARD_TO_HOME, player_id, {"card_id": card_id})


static func live_ready(player_id: int) -> GameAction:
	return GameAction.new(Type.LIVE_READY, player_id)


static func showdown(winner: int, player1_rank: GameState.Rank, player2_rank: GameState.Rank) -> GameAction:
	return GameAction.new(Type.SHOWDOWN, -1, {
		"winner": winner,
		"player1_rank": player1_rank,
		"player2_rank": player2_rank
	})


static func game_end(winner: int) -> GameAction:
	return GameAction.new(Type.GAME_END, -1, {"winner": winner})
