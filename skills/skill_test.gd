extends Control

## UI要素
@onready var preset_option: OptionButton = %PresetOption
@onready var load_preset_button: Button = %LoadPresetButton
@onready var skill_id_input: LineEdit = %SkillIdInput
@onready var player_option: OptionButton = %PlayerOption
@onready var activate_skill_button: Button = %ActivateSkillButton
@onready var step_button: Button = %StepButton
@onready var resolve_all_button: Button = %ResolveAllButton
@onready var choice_status_label: Label = %ChoiceStatusLabel
@onready var choice_option: OptionButton = %ChoiceOption
@onready var submit_choice_button: Button = %SubmitChoiceButton
@onready var state_label: RichTextLabel = %StateLabel
@onready var log_text: TextEdit = %LogText

## ゲームシステム
var game_state: GameState
var skill_registry: SkillRegistry
var skill_resolver: SkillResolver

## 選択用データ
var _choice_card_ids: Array[String] = []


func _ready() -> void:
	_setup_game_system()
	_setup_ui()
	_update_display()


func _setup_game_system() -> void:
	# スキルレジストリをセットアップ
	skill_registry = SkillRegistry.new()
	skill_registry.load_all_skills()

	# スキルリゾルバをセットアップ
	skill_resolver = SkillResolver.new()
	skill_resolver.set_registry(skill_registry)
	skill_resolver.on_action = _on_game_action

	# ゲーム状態を初期化
	game_state = GameState.new()

	_add_log("スキルレジストリ読込完了: %d スキル" % skill_registry.get_skill_count())
	skill_registry.debug_print_all_skills()


func _setup_ui() -> void:
	# プリセット選択肢
	preset_option.clear()
	preset_option.add_item("c1s1 テスト (ドローブースト)", 0)
	preset_option.add_item("c2s1 テスト (カード交換)", 1)
	preset_option.add_item("c3s1 テスト (カウンター)", 2)

	# プレイヤー選択肢
	player_option.clear()
	player_option.add_item("P1", 0)
	player_option.add_item("P2", 1)

	# デフォルト値
	skill_id_input.text = "c1s1"


func _on_load_preset_button_pressed() -> void:
	var preset_index := preset_option.selected

	var preset_data: Dictionary
	match preset_index:
		0:
			preset_data = TestCardFactory.preset_c1s1_test()
			_add_log("=== c1s1テストプリセット読込 ===")
		1:
			preset_data = TestCardFactory.preset_c2s1_test()
			_add_log("=== c2s1テストプリセット読込 ===")
		2:
			preset_data = TestCardFactory.preset_c3s1_test()
			_add_log("=== c3s1テストプリセット読込 ===")
		_:
			_add_log("不明なプリセット")
			return

	_apply_preset(preset_data)
	_update_display()


func _apply_preset(data: Dictionary) -> void:
	# ゲーム状態をリセット
	game_state = GameState.new()

	# P1の手札
	var p1_hand: Array = data.get("p1_hand", [])
	for card in p1_hand:
		game_state.players[0].add_to_hand(card)

	# P2の手札
	var p2_hand: Array = data.get("p2_hand", [])
	for card in p2_hand:
		game_state.players[1].add_to_hand(card)

	# P1のユニット
	var p1_unit: Array = data.get("p1_unit", [])
	for card in p1_unit:
		game_state.players[0].unit.add_card(card)

	# P2のユニット
	var p2_unit: Array = data.get("p2_unit", [])
	for card in p2_unit:
		game_state.players[1].unit.add_card(card)

	# P1の楽屋
	var p1_backstage = data.get("p1_backstage")
	if p1_backstage:
		game_state.players[0].backstage.set_card(p1_backstage)

	# P2の楽屋
	var p2_backstage = data.get("p2_backstage")
	if p2_backstage:
		game_state.players[1].backstage.set_card(p2_backstage)

	# 山札
	var deck: Array = data.get("deck", [])
	for card in deck:
		game_state.deck.add_card(card)

	# 自宅
	var home: Array = data.get("home", [])
	for card in home:
		game_state.home.add_card(card)

	_add_log("盤面セットアップ完了")
	_add_log("  P1手札: %d枚, P2手札: %d枚" % [
		game_state.players[0].hand.size(),
		game_state.players[1].hand.size()
	])
	_add_log("  山札: %d枚" % game_state.deck.get_remaining_count())


func _on_activate_skill_button_pressed() -> void:
	var skill_id := skill_id_input.text.strip_edges()
	var player_id := player_option.selected

	if skill_id.is_empty():
		_add_log("エラー: スキルIDを入力してください")
		return

	var skill := skill_registry.get_skill(skill_id)
	if skill == null:
		_add_log("エラー: スキル '%s' が見つかりません" % skill_id)
		return

	# 発動元カードを探す（手札から最初のカード、またはスキルを持つカード）
	var source_card_id := ""
	var player := game_state.players[player_id]

	# 手札からスキルを持つカードを探す
	for card in player.hand:
		if card.play_skill_id == skill_id or skill_id in card.action_skill_ids:
			source_card_id = card.id
			break

	# 見つからなければダミーIDを使用
	if source_card_id.is_empty():
		source_card_id = "test_source"

	_add_log("スキル発動: %s (%s) by P%d" % [skill.get_name(), skill_id, player_id + 1])

	var instance := skill_resolver.activate_skill(game_state, skill_id, player_id, source_card_id)
	if instance:
		_add_log("  → インスタンス #%d 作成" % instance.instance_id)
	else:
		_add_log("  → 発動失敗")

	_update_display()


func _on_step_button_pressed() -> void:
	if game_state.skill_stack.is_waiting_choice():
		_add_log("選択待ち中です。選択を入力してください。")
		return

	var continued := skill_resolver.resolve_step(game_state)
	if continued:
		_add_log("1ステップ実行完了")
	else:
		_add_log("実行するスキルがありません")

	_update_display()


func _on_resolve_all_button_pressed() -> void:
	var steps := 0
	var max_steps := 100  # 無限ループ防止

	while steps < max_steps:
		if game_state.skill_stack.is_waiting_choice():
			_add_log("選択待ちで停止 (計 %d ステップ)" % steps)
			break

		var continued := skill_resolver.resolve_step(game_state)
		if not continued:
			_add_log("全て実行完了 (計 %d ステップ)" % steps)
			break

		steps += 1

	if steps >= max_steps:
		_add_log("警告: 最大ステップ数に到達")

	_update_display()


func _on_submit_choice_button_pressed() -> void:
	if not game_state.skill_stack.is_waiting_choice():
		_add_log("選択待ちではありません")
		return

	var selected_index := choice_option.selected
	if selected_index < 0 or selected_index >= _choice_card_ids.size():
		_add_log("選択肢を選んでください")
		return

	var answer := _choice_card_ids[selected_index]
	var request := game_state.skill_stack.get_pending_choice()

	_add_log("選択確定: %s (by P%d)" % [answer, request.player_id + 1])

	skill_resolver.handle_choice_answer(game_state, request.player_id, answer)

	_update_display()


func _on_game_action(action: GameAction) -> void:
	var action_name = GameAction.Type.keys()[action.type]
	var player_str := ""
	if action.player_id >= 0:
		player_str = " (P%d)" % (action.player_id + 1)
	_add_log("  [Action] %s%s" % [action_name, player_str])


func _update_display() -> void:
	_update_state_display()
	_update_choice_display()


func _update_state_display() -> void:
	var text := ""

	# スキルスタック状態
	var stack := game_state.skill_stack
	var phase_names := ["IDLE", "COLLECTING", "RESOLVING", "WAITING_CHOICE"]
	text += "[b]スキルスタック:[/b] %s (サイズ: %d)\n" % [phase_names[stack.phase], stack.size()]

	if not stack.is_empty():
		text += "  スタック内容:\n"
		for i in range(stack.stack.size() - 1, -1, -1):
			var inst: SkillInstanceState = stack.stack[i]
			var status_names := ["PENDING", "RESPONDING", "RESOLVING", "WAITING", "RESOLVED", "CANCELLED"]
			text += "    [%d] %s (%s)\n" % [i, inst.get_skill_name(), status_names[inst.status]]

	text += "\n"

	# 山札・自宅
	text += "[b]山札:[/b] %d枚  [b]自宅:[/b] %d枚\n\n" % [
		game_state.deck.get_remaining_count(),
		game_state.home.get_card_count()
	]

	# 各プレイヤー
	for i in range(2):
		var player := game_state.players[i]
		text += "[b]===== P%d =====[/b]\n" % (i + 1)

		# 手札
		text += "手札 (%d枚):\n" % player.hand.size()
		for card in player.hand:
			var skill_info := ""
			if not card.play_skill_id.is_empty():
				skill_info = " [Play: %s]" % card.play_skill_id
			if not card.action_skill_ids.is_empty():
				skill_info += " [Action: %s]" % ", ".join(card.action_skill_ids)
			if not card.auto_skill_id.is_empty():
				skill_info += " [Auto: %s]" % card.auto_skill_id
			text += "  - %s (%s)%s\n" % [card.card_name, card.id, skill_info]

		# ユニット
		text += "ユニット (%d/3):\n" % player.unit.get_card_count()
		for card in player.unit.cards:
			text += "  - %s (%s)\n" % [card.card_name, card.id]

		# 楽屋
		if player.backstage.has_card():
			var bs := player.backstage.card
			var guest_str := " [ゲスト]" if bs.is_guest else ""
			text += "楽屋: %s (%s)%s\n" % [bs.card_name, bs.id, guest_str]
		else:
			text += "楽屋: なし\n"

		text += "\n"

	state_label.text = text


func _update_choice_display() -> void:
	choice_option.clear()
	_choice_card_ids.clear()

	if not game_state.skill_stack.is_waiting_choice():
		choice_status_label.text = "選択待ちなし"
		submit_choice_button.disabled = true
		return

	var request := game_state.skill_stack.get_pending_choice()
	var type_names := ["SELECT_CARDS", "SELECT_YES_NO", "SELECT_OPTION", "SELECT_PLAYER", "SELECT_SKILL", "CONFIRM_TRIGGER"]
	choice_status_label.text = "P%d が %s" % [request.player_id + 1, type_names[request.type]]
	submit_choice_button.disabled = false

	match request.type:
		ChoiceRequestState.Type.SELECT_CARDS:
			_populate_card_choices(request)
		ChoiceRequestState.Type.SELECT_YES_NO:
			choice_option.add_item("はい", 0)
			choice_option.add_item("いいえ", 1)
			_choice_card_ids = ["yes", "no"]
		ChoiceRequestState.Type.CONFIRM_TRIGGER:
			choice_option.add_item("発動する", 0)
			choice_option.add_item("発動しない", 1)
			_choice_card_ids = ["yes", "no"]
		_:
			choice_status_label.text += " (未対応の選択タイプ)"


func _populate_card_choices(request: ChoiceRequestState) -> void:
	var from_player_id: int = request.params.get("from_player_id", 0)
	var from_location: int = request.params.get("from_location", SkillEffect.CardLocation.HAND)

	var cards: Array[CardState] = []

	match from_location:
		SkillEffect.CardLocation.HAND:
			cards.assign(game_state.players[from_player_id].hand)
		SkillEffect.CardLocation.UNIT:
			cards.assign(game_state.players[from_player_id].unit.cards)
		_:
			pass

	for card in cards:
		choice_option.add_item("%s (%s)" % [card.card_name, card.id])
		_choice_card_ids.append(card.id)


func _add_log(message: String) -> void:
	var time_str := Time.get_time_string_from_system()
	log_text.text += "[%s] %s\n" % [time_str, message]
	log_text.scroll_vertical = log_text.get_line_count()
