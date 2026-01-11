extends Control

@onready var start_button: Button = %StartButton
@onready var pause_button: Button = %PauseButton
@onready var interval_spin_box: SpinBox = %IntervalSpinBox
@onready var step_button: Button = %StepButton
@onready var state_label: RichTextLabel = %StateLabel
@onready var log_text_edit: TextEdit = %LogTextEdit

var game_loop: GameLoop
var update_timer: Timer
var is_paused: bool = false


func _ready() -> void:
	game_loop = GameLoop.new()
	game_loop.action_applied.connect(_on_action_applied)
	game_loop.step_changed.connect(_on_step_changed)
	game_loop.round_ended.connect(_on_round_ended)
	game_loop.game_ended.connect(_on_game_ended)

	update_timer = Timer.new()
	update_timer.one_shot = false
	update_timer.wait_time = interval_spin_box.value
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)

	_update_state_display()


func _on_start_button_pressed() -> void:
	_add_log("=== ゲーム開始 ===")

	# テスト用のダミーカードを生成
	var test_cards := _create_test_cards()
	game_loop.initialize_game(test_cards)
	game_loop.start_round()

	start_button.disabled = true
	pause_button.disabled = false
	step_button.disabled = false

	if not is_paused:
		update_timer.start()

	_update_state_display()


func _on_pause_button_toggled(toggled_on: bool) -> void:
	is_paused = toggled_on
	if is_paused:
		update_timer.stop()
		_add_log("[一時停止]")
	else:
		if not game_loop.state.is_game_over:
			update_timer.start()
		_add_log("[再開]")


func _on_interval_spin_box_value_changed(value: float) -> void:
	update_timer.wait_time = value
	_add_log("更新間隔を %.1f 秒に変更" % value)


func _on_step_button_pressed() -> void:
	if game_loop.state.is_game_over:
		_add_log("ゲームは終了しています")
		return

	_process_one_step()
	_update_state_display()


func _on_update_timer_timeout() -> void:
	if game_loop.state.is_game_over:
		update_timer.stop()
		return

	_process_one_step()
	_update_state_display()


func _process_one_step() -> void:
	var current_step := game_loop.state.current_step

	match current_step:
		GameState.Step.ACTION:
			# アクションステップ: 自動でパスする（テスト用）
			game_loop.pass_action()
			game_loop.advance_step()

		GameState.Step.PLAY:
			# プレイステップ: 手札があればユニットにプレイ
			var player := game_loop.state.get_current_player_state()
			if player.hand.size() > 0 and not player.unit.is_full():
				var card := player.hand[0]
				game_loop.play_card_to_unit(card.id)
			game_loop.advance_step()

		GameState.Step.TURN_END:
			# ターン終了: 次へ進める
			game_loop.advance_step()

		_:
			# その他: 次へ進める
			game_loop.advance_step()


func _on_action_applied(commit: GameStateCommit) -> void:
	var action_name = GameAction.Type.keys()[commit.action.type]
	var player_str := ""
	if commit.action.player_id >= 0:
		player_str = " (P%d)" % (commit.action.player_id + 1)
	_add_log("#%d %s%s" % [commit.index, action_name, player_str])


func _on_step_changed(old_step: GameState.Step, new_step: GameState.Step) -> void:
	var step_names := ["ターン開始", "アクション", "プレイ", "ターン終了"]
	_add_log("  → ステップ: %s" % step_names[new_step])


func _on_round_ended(round_number: int, winner: int) -> void:
	_add_log("=== ラウンド %d 終了: P%d 勝利 ===" % [round_number, winner + 1])


func _on_game_ended(winner: int) -> void:
	_add_log("=============================")
	_add_log("ゲーム終了! 勝者: P%d" % (winner + 1))
	_add_log("=============================")
	update_timer.stop()
	step_button.disabled = true


func _update_state_display() -> void:
	var state := game_loop.state
	var text := ""

	# 基本情報
	text += "[b]ラウンド:[/b] %d / %d\n" % [state.current_round, GameState.MAX_ROUNDS]
	text += "[b]現在のプレイヤー:[/b] P%d\n" % (state.current_player + 1)

	var step_names := ["ターン開始", "アクション", "プレイ", "ターン終了"]
	text += "[b]ステップ:[/b] %s\n" % step_names[state.current_step]
	text += "\n"

	# 山札・自宅
	text += "[b]山札:[/b] %d 枚\n" % state.deck.get_remaining_count()
	text += "[b]自宅:[/b] %d 枚\n" % state.home.get_card_count()
	text += "\n"

	# 各プレイヤーの情報
	for i in range(2):
		var player := state.players[i]
		var marker := " ◀" if i == state.current_player else ""
		text += "[b]===== P%d%s =====[/b]\n" % [i + 1, marker]
		text += "ラウンド勝利: %d\n" % player.round_wins
		text += "手札: %d 枚\n" % player.get_hand_count()

		# 手札のカード名
		if player.hand.size() > 0:
			var hand_names: Array[String] = []
			for card in player.hand:
				hand_names.append(card.card_name)
			text += "  [%s]\n" % ", ".join(hand_names)

		# ユニット
		text += "ユニット: %d / 3" % player.unit.get_card_count()
		if player.unit.is_live_ready:
			text += " [color=yellow][LIVE READY][/color]"
		text += "\n"

		if player.unit.cards.size() > 0:
			var unit_names: Array[String] = []
			for card in player.unit.cards:
				unit_names.append(card.card_name)
			text += "  [%s]\n" % ", ".join(unit_names)

		# 楽屋
		if player.backstage.has_card():
			var bs_card := player.backstage.card
			var guest_str := " (ゲスト)" if bs_card.is_guest else ""
			text += "楽屋: %s%s\n" % [bs_card.card_name, guest_str]
		else:
			text += "楽屋: なし\n"

		text += "\n"

	# 履歴数
	text += "[b]コミット数:[/b] %d" % game_loop.get_history_length()

	state_label.text = text


func _add_log(message: String) -> void:
	var time_str := Time.get_time_string_from_system()
	log_text_edit.text += "[%s] %s\n" % [time_str, message]
	# 自動スクロール
	log_text_edit.scroll_vertical = log_text_edit.get_line_count()


## テスト用のダミーカードを生成
func _create_test_cards() -> Array[CardState]:
	var cards: Array[CardState] = []
	var suits := [
		CardState.Suit.LOVELY,
		CardState.Suit.COOL,
		CardState.Suit.HOT,
		CardState.Suit.ENGLISH,
		CardState.Suit.INDONESIA
	]
	var icons := [
		CardState.Icon.SEISO,
		CardState.Icon.CHARISMA,
		CardState.Icon.OTAKU,
		CardState.Icon.VOCAL,
		CardState.Icon.ENJOY
	]

	# 30枚のテストカードを生成
	for i in range(30):
		var suit: CardState.Suit = suits[i % suits.size()]
		var icon: CardState.Icon = icons[i % icons.size()]
		var icon_array: Array[CardState.Icon] = [icon]

		var card := CardState.new(
			"card_%03d" % i,
			"テストカード %d" % (i + 1),
			suit,
			icon_array
		)
		cards.append(card)

	return cards
