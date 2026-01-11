class_name GameState
extends RefCounted

## ターンのステップ
enum Step {
	TURN_START,    # ターン開始ステップ
	ACTION,        # アクションステップ
	PLAY,          # プレイステップ
	TURN_END       # ターン終了ステップ
}

## ユニットのランク（役）- 上から強い順
enum Rank {
	MIRACLE,   # 同じアイコンかつ同じスートが3つ
	TRIO,      # 同じアイコンが3つ
	FLUSH,     # 同じスートが3つ
	DUO,       # 同じアイコンが2つ
	CASUAL     # 役なし
}

## 現在のラウンド番号（1-5）
var current_round: int = 1
## 現在のターンプレイヤー（0 or 1）
var current_player: int = 0
## 現在のステップ
var current_step: Step = Step.TURN_START
## 先行プレイヤー（ラウンド開始時のプレイヤー）
var first_player: int = 0
## プレイヤー状態
var players: Array[PlayerState]
## 山札
var deck: DeckState
## 自宅
var home: HomeState
## スキルスタック（スキル解決の状態）
var skill_stack: SkillStackState
## ゲーム終了フラグ
var is_game_over: bool = false
## 勝者（ゲーム終了時に設定、-1は未決定）
var winner: int = -1

## 勝利に必要なラウンド数
const ROUNDS_TO_WIN := 3
## 最大ラウンド数
const MAX_ROUNDS := 5


func _init() -> void:
	players = [PlayerState.new(0), PlayerState.new(1)]
	deck = DeckState.new()
	home = HomeState.new()
	skill_stack = SkillStackState.new()


func get_current_player_state() -> PlayerState:
	return players[current_player]


func get_opponent_player_state() -> PlayerState:
	return players[1 - current_player]


func get_player_state(player_id: int) -> PlayerState:
	if player_id < 0 or player_id >= players.size():
		return null
	return players[player_id]


func is_round_over() -> bool:
	for player in players:
		if player.round_wins >= ROUNDS_TO_WIN:
			return true
	return false


func check_game_winner() -> int:
	for player in players:
		if player.round_wins >= ROUNDS_TO_WIN:
			return player.player_id
	return -1


func duplicate_state() -> GameState:
	var copy := GameState.new()
	copy.current_round = current_round
	copy.current_player = current_player
	copy.current_step = current_step
	copy.first_player = first_player
	copy.players = [players[0].duplicate_state(), players[1].duplicate_state()]
	copy.deck = deck.duplicate_state()
	copy.home = home.duplicate_state()
	copy.skill_stack = skill_stack.duplicate_state()
	copy.is_game_over = is_game_over
	copy.winner = winner
	return copy


## スキル解決中かどうか
func is_resolving_skills() -> bool:
	return skill_stack.phase != SkillStackState.Phase.IDLE


## プレイヤーの選択待ちかどうか
func is_waiting_player_choice() -> bool:
	return skill_stack.is_waiting_choice()
