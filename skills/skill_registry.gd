class_name SkillRegistry
extends RefCounted

## スキルIDからスキルインスタンスへのマップ
var _skills: Dictionary = {}

## スキルファイルのベースパス
const SKILLS_PATH := "res://skills/"


func _init() -> void:
	_skills = {}


## 全スキルをロード
func load_all_skills() -> void:
	_skills.clear()
	_load_skills_from_directory(SKILLS_PATH)


## ディレクトリからスキルをロード
func _load_skills_from_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Failed to open skills directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			# c{数字}s{数字}.gd のパターンにマッチするファイルのみロード
			if _is_skill_file(file_name):
				_load_skill_file(path + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()


## スキルファイル名かどうかチェック
func _is_skill_file(file_name: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^c\\d+s\\d+\\.gd$")
	return regex.search(file_name) != null


## スキルファイルをロード
func _load_skill_file(file_path: String) -> void:
	var script := load(file_path)
	if script == null:
		push_warning("Failed to load skill script: %s" % file_path)
		return

	var skill: SkillBase = script.new()
	if skill == null:
		push_warning("Failed to instantiate skill: %s" % file_path)
		return

	var skill_id := skill.get_id()
	if skill_id.is_empty():
		push_warning("Skill has empty ID: %s" % file_path)
		return

	_skills[skill_id] = skill


## スキルを手動で登録
func register_skill(skill: SkillBase) -> void:
	var skill_id := skill.get_id()
	if skill_id.is_empty():
		push_warning("Cannot register skill with empty ID")
		return
	_skills[skill_id] = skill


## スキルIDからスキルを取得
func get_skill(skill_id: String) -> SkillBase:
	return _skills.get(skill_id)


## カードIDから全スキルを取得
func get_skills_for_card(card_id: int) -> Array[SkillBase]:
	var result: Array[SkillBase] = []
	for skill_id in _skills.keys():
		var skill: SkillBase = _skills[skill_id]
		if skill.get_card_id() == card_id:
			result.append(skill)
	# スキルインデックス順にソート
	result.sort_custom(func(a, b): return a.get_skill_index() < b.get_skill_index())
	return result


## スキル種類でフィルタして取得
func get_skills_by_type(skill_type: SkillState.Type) -> Array[SkillBase]:
	var result: Array[SkillBase] = []
	for skill_id in _skills.keys():
		var skill: SkillBase = _skills[skill_id]
		if skill.get_type() == skill_type:
			result.append(skill)
	return result


## 常時スキルでトリガー条件にマッチするものを取得
func get_triggerable_auto_skills(
	trigger: SkillState.TriggerCondition,
	context: Dictionary = {}
) -> Array[SkillBase]:
	var result: Array[SkillBase] = []
	for skill_id in _skills.keys():
		var skill: SkillBase = _skills[skill_id]
		if skill.get_type() != SkillState.Type.AUTO:
			continue
		if skill.get_trigger() != trigger:
			continue
		# フィルタ条件チェック
		var filter := skill.get_trigger_filter()
		var matches := true
		for key in filter.keys():
			if not context.has(key) or context[key] != filter[key]:
				matches = false
				break
		if matches:
			result.append(skill)
	return result


## 登録されているスキルIDの一覧
func get_all_skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _skills.keys():
		ids.append(key)
	ids.sort()
	return ids


## 登録されているスキル数
func get_skill_count() -> int:
	return _skills.size()


## スキルが存在するかチェック
func has_skill(skill_id: String) -> bool:
	return _skills.has(skill_id)


## デバッグ用：全スキル情報を出力
func debug_print_all_skills() -> void:
	print("=== Registered Skills ===")
	var ids := get_all_skill_ids()
	for skill_id in ids:
		var skill: SkillBase = _skills[skill_id]
		print("  %s: %s (%s)" % [
			skill_id,
			skill.get_name(),
			SkillState.Type.keys()[skill.get_type()]
		])
	print("Total: %d skills" % ids.size())
