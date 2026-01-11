class_name GameLoop
extends RefCounted

## アクションが適用された時に発火
signal action_applied(commit: GameStateCommit)
## ステップが変更された時に発火
signal step_changed(old_step: GameState.Step, new_step: GameState.Step)
## ラウンドが終了した時に発火
signal round_ended(round_number: int, winner: int)
## ゲームが終了した時に発火
signal game_ended(winner: int)

## 現在のゲーム状態
var state: GameState
## コミット履歴
var history: Array[GameStateCommit]
## 初期カードデータ（外部から設定）
var card_pool: Array[CardState]


func _init() -> void:
	state = GameState.new()
	history = []
	card_pool = []


#region 初期化

## ゲームを初期化する
func initialize_game(cards: Array[CardState], first_player: int = -1) -> void:
	state = GameState.new()
	history.clear()
	card_pool = cards

	# 先行プレイヤーを決定（-1ならランダム）
	if first_player < 0:
		first_player = randi() % 2
	state.first_player = first_player
	state.current_player = first_player

	# 山札にカードをセット
	for card in cards:
		state.deck.add_card(card.duplicate_state())

	# 初期コミットを記録
	_commit(GameAction.game_start())


## ラウンドを開始する
func start_round() -> void:
	# 山札をシャッフル
	state.deck.shuffle()
	_commit(GameAction.shuffle_deck())

	# ラウンド開始を記録
	_commit(GameAction.round_start(state.current_round, state.first_player))

	# 各プレイヤーに初期手札を配る
	for player in state.players:
		_draw_card_for_player(player.player_id)

	# ターン開始
	_start_turn()

#endregion


#region ターン進行

## ターンを開始する
func _start_turn() -> void:
	_commit(GameAction.turn_start(state.current_player))
	_change_step(GameState.Step.TURN_START)

	# ターン開始ステップ: 自動ドロー
	_draw_card_for_player(state.current_player)

	# アクションステップへ移行
	_change_step(GameState.Step.ACTION)


## ステップを進める（プレイヤー入力後に呼ぶ）
func advance_step() -> void:
	match state.current_step:
		GameState.Step.ACTION:
			_change_step(GameState.Step.PLAY)
		GameState.Step.PLAY:
			_change_step(GameState.Step.TURN_END)
			_process_turn_end()
		GameState.Step.TURN_END:
			_end_turn()


## ターン終了処理
func _process_turn_end() -> void:
	var player := state.get_current_player_state()

	# 手札上限チェック: 超過分を自宅へ
	var excess := player.get_excess_hand_cards()
	for card in excess:
		state.home.add_card(card)
		_commit(GameAction.discard_to_home(player.player_id, card.id))

	# 自宅のカードが5枚以上なら山札へ戻す
	var to_return := state.home.get_cards_to_return()
	for card in to_return:
		state.deck.add_card(card)
		_commit(GameAction.new(GameAction.Type.RETURN_TO_DECK, -1, {"card_id": card.id}))

	# ライブチェック
	_check_live()


## ライブチェック処理
func _check_live() -> void:
	var player := state.get_current_player_state()

	# ユニットが3枚揃っているか
	if player.unit.is_full():
		if not player.unit.is_live_ready:
			player.unit.is_live_ready = true
			_commit(GameAction.live_ready(player.player_id))

	# ライブ開催判定（次のターン開始時に判定するため、ここでは準備状態のみ）


## ターンを終了して次のプレイヤーへ
func _end_turn() -> void:
	_commit(GameAction.turn_end(state.current_player))

	# 次のプレイヤーのターン開始前にライブ開催チェック
	var current := state.get_current_player_state()
	var opponent := state.get_opponent_player_state()

	if current.unit.is_live_ready:
		# 相手もライブ準備状態ならショウダウン
		if opponent.unit.is_live_ready:
			_do_showdown()
		else:
			# 自分だけライブ準備 → ラウンド勝利
			_win_round(current.player_id)
		return

	# ターン交代
	state.current_player = 1 - state.current_player
	_start_turn()


## ショウダウン処理
func _do_showdown() -> void:
	var rank1 := _calculate_rank(state.players[0].unit)
	var rank2 := _calculate_rank(state.players[1].unit)

	var winner: int
	if rank1 < rank2:  # enumは小さいほど強い
		winner = 0
	elif rank2 < rank1:
		winner = 1
	else:
		# 同ランクなら先にライブ準備になった方が勝ち（現在のプレイヤー）
		winner = state.current_player

	_commit(GameAction.showdown(winner, rank1, rank2))
	_win_round(winner)


## ランクを計算する
func _calculate_rank(unit: UnitState) -> GameState.Rank:
	if unit.cards.size() < 3:
		return GameState.Rank.CASUAL

	var cards := unit.cards
	var suits: Array[CardState.Suit] = []
	var all_icons: Array[CardState.Icon] = []

	for card in cards:
		suits.append(card.suit)
		all_icons.append_array(card.icons)

	# スートが全て同じか
	var same_suit := suits[0] == suits[1] and suits[1] == suits[2]

	# アイコンのカウント
	var icon_counts := {}
	for icon in all_icons:
		icon_counts[icon] = icon_counts.get(icon, 0) + 1

	var max_icon_count := 0
	for count in icon_counts.values():
		max_icon_count = max(max_icon_count, count)

	# ミラクル: 同じスートかつ同じアイコン3つ
	if same_suit and max_icon_count >= 3:
		return GameState.Rank.MIRACLE

	# トリオ: 同じアイコン3つ
	if max_icon_count >= 3:
		return GameState.Rank.TRIO

	# フラッシュ: 同じスート3つ
	if same_suit:
		return GameState.Rank.FLUSH

	# デュオ: 同じアイコン2つ
	if max_icon_count >= 2:
		return GameState.Rank.DUO

	# カジュアル: 役なし
	return GameState.Rank.CASUAL


## ラウンド勝利処理
func _win_round(winner_id: int) -> void:
	state.players[winner_id].round_wins += 1
	_commit(GameAction.round_end(winner_id))
	round_ended.emit(state.current_round, winner_id)

	# ゲーム終了チェック
	if state.players[winner_id].round_wins >= GameState.ROUNDS_TO_WIN:
		_end_game(winner_id)
	else:
		_prepare_next_round(winner_id)


## 次のラウンドを準備
func _prepare_next_round(last_round_winner: int) -> void:
	state.current_round += 1

	# 敗者が先行
	state.first_player = 1 - last_round_winner
	state.current_player = state.first_player

	# ユニットと自宅のカードを山札へ戻す
	for player in state.players:
		for card in player.unit.cards:
			state.deck.add_card(card)
		player.unit.clear()

		# 楽屋のカードをユニットへ移動
		if player.backstage.has_card():
			var backstage_card := player.backstage.remove_card()
			backstage_card.is_guest = false
			player.unit.add_card(backstage_card)

	for card in state.home.get_all_cards():
		state.deck.add_card(card)
	state.home.clear()

	# 新ラウンド開始
	start_round()


## ゲーム終了処理
func _end_game(winner_id: int) -> void:
	state.is_game_over = true
	state.winner = winner_id
	_commit(GameAction.game_end(winner_id))
	game_ended.emit(winner_id)

#endregion


#region プレイヤーアクション

## カードをユニットにプレイ
func play_card_to_unit(card_id: String) -> bool:
	var player := state.get_current_player_state()
	var card := _find_card_in_hand(player, card_id)

	if card == null:
		return false
	if player.unit.is_full():
		return false

	player.remove_from_hand(card)
	player.unit.add_card(card)
	_commit(GameAction.play_to_unit(player.player_id, card_id))
	return true


## カードを楽屋にプレイ（ゲストとして）
func play_card_to_backstage(card_id: String) -> bool:
	var player := state.get_current_player_state()
	var card := _find_card_in_hand(player, card_id)

	if card == null:
		return false
	if player.backstage.has_card():
		return false

	player.remove_from_hand(card)
	player.backstage.set_card(card)
	_commit(GameAction.play_to_backstage(player.player_id, card_id))
	return true


## ゲストを公開
func reveal_guest() -> bool:
	var player := state.get_current_player_state()

	if not player.backstage.is_guest():
		return false

	player.backstage.reveal_guest()
	_commit(GameAction.reveal_guest(player.player_id))
	return true


## アクションをパス
func pass_action() -> void:
	_commit(GameAction.pass_action(state.current_player))

#endregion


#region ユーティリティ

## 手札からカードを探す
func _find_card_in_hand(player: PlayerState, card_id: String) -> CardState:
	for card in player.hand:
		if card.id == card_id:
			return card
	return null


## プレイヤーにカードをドローさせる
func _draw_card_for_player(player_id: int) -> bool:
	var card := state.deck.draw()
	if card == null:
		return false

	var player := state.get_player_state(player_id)
	player.add_to_hand(card)
	_commit(GameAction.draw_card(player_id, card.id))
	return true


## ステップを変更
func _change_step(new_step: GameState.Step) -> void:
	var old_step := state.current_step
	state.current_step = new_step
	_commit(GameAction.step_change(new_step))
	step_changed.emit(old_step, new_step)


## コミットを作成して履歴に追加
func _commit(action: GameAction) -> GameStateCommit:
	var commit := GameStateCommit.new(
		history.size(),
		action,
		state.duplicate_state()
	)
	history.append(commit)
	action_applied.emit(commit)
	return commit

#endregion


#region 履歴操作

## 履歴の長さを取得
func get_history_length() -> int:
	return history.size()


## 指定インデックスのコミットを取得
func get_commit(index: int) -> GameStateCommit:
	if index < 0 or index >= history.size():
		return null
	return history[index]


## 最新のコミットを取得
func get_latest_commit() -> GameStateCommit:
	if history.is_empty():
		return null
	return history.back()


## 指定インデックスの状態に巻き戻す
func rewind_to(index: int) -> bool:
	var commit := get_commit(index)
	if commit == null:
		return false

	state = commit.get_state_snapshot()
	# 履歴は保持したまま（将来的にredo可能にするため）
	return true


## 全履歴を取得
func get_all_history() -> Array[GameStateCommit]:
	return history.duplicate()

#endregion
