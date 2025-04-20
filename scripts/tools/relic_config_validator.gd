@tool
extends EditorScript
## 遗物配置验证工具
## 用于检查和修复 relics.json 文件中的不一致

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")
const EffectConsts = preload("res://scripts/constants/effect_constants.gd")
const RelicConsts = preload("res://scripts/constants/relic_constants.gd")

# 遗物配置文件路径
const RELICS_JSON_PATH = "res://config/relics/relics.json"

# 执行工具
func _run():
	print("开始验证遗物配置...")

	# 加载遗物配置
	var relics_data = _load_json_file(RELICS_JSON_PATH)
	if relics_data.is_empty():
		print("无法加载遗物配置文件")
		return

	# 验证并修复配置
	var fixed_data = _validate_and_fix_relics(relics_data)

	# 保存修复后的配置
	if _save_json_file(RELICS_JSON_PATH, fixed_data):
		print("遗物配置已验证并修复")
	else:
		print("保存修复后的配置失败")

# 加载 JSON 文件
func _load_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("文件不存在: " + file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("无法打开文件: " + file_path)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("解析 JSON 失败: " + file_path + ", 行 " + str(json.get_error_line()) + ": " + json.get_error_message())
		return {}

	return json.get_data()

# 保存 JSON 文件
func _save_json_file(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("无法打开文件进行写入: " + file_path)
		return false

	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()

	return true

# 验证并修复遗物配置
func _validate_and_fix_relics(relics_data: Dictionary) -> Dictionary:
	var fixed_data = relics_data.duplicate(true)
	var valid_triggers = RelicConsts.get_valid_triggers()
	var issues_count = 0

	# 遍历所有遗物
	for relic_id in fixed_data.keys():
		var relic = fixed_data[relic_id]

		# 检查并修复基本字段
		issues_count += _check_and_fix_basic_fields(relic, relic_id)

		# 检查并修复效果
		if relic.has("effects") and relic.effects is Array:
			for effect in relic.effects:
				issues_count += _check_and_fix_effect(effect, valid_triggers)

		# 检查并修复触发条件
		if not relic.has("trigger_conditions"):
			relic["trigger_conditions"] = {}
			issues_count += 1
			print("添加缺失的 trigger_conditions 字段: " + relic_id)
		elif not relic.trigger_conditions is Dictionary:
			relic["trigger_conditions"] = {}
			issues_count += 1
			print("修复无效的 trigger_conditions 字段: " + relic_id)

	print("共发现并修复 " + str(issues_count) + " 个问题")
	return fixed_data

# 检查并修复基本字段
func _check_and_fix_basic_fields(relic: Dictionary, relic_id: String) -> int:
	var issues = 0

	# 确保 ID 字段存在且正确
	if not relic.has("id"):
		relic["id"] = relic_id
		issues += 1
		print("添加缺失的 id 字段: " + relic_id)
	elif relic.id != relic_id:
		relic["id"] = relic_id
		issues += 1
		print("修复不匹配的 id 字段: " + relic_id)

	# 确保必要字段存在
	var required_fields = {
		"name": "未命名遗物",
		"description": "无描述",
		"rarity": 0,
		"is_passive": true,
		"effects": []
	}

	for field in required_fields:
		if not relic.has(field):
			relic[field] = required_fields[field]
			issues += 1
			print("添加缺失的 " + field + " 字段: " + relic_id)

	# 确保数值字段是整数
	var int_fields = ["rarity", "cooldown", "charges"]
	for field in int_fields:
		if relic.has(field) and relic[field] is float:
			relic[field] = int(relic[field])
			issues += 1
			print("将 " + field + " 从浮点数转换为整数: " + relic_id)

	return issues

# 检查并修复效果
func _check_and_fix_effect(effect: Dictionary, valid_triggers: Array) -> int:
	var issues = 0

	# 检查触发条件
	if effect.has("trigger"):
		# 修复 "passive" 触发条件
		if effect.trigger == "passive" and not valid_triggers.has("passive"):
			effect["trigger"] = "passive"
			issues += 1
			print("修复触发条件 'passive'")

	# 确保效果类型有效
	if effect.has("type"):
		var valid_effect_types = RelicConsts.get_valid_effect_types()
		if not valid_effect_types.has(effect.type):
			# 尝试根据其他字段推断类型
			var inferred_type = _infer_effect_type(effect)
			if inferred_type != "":
				effect["type"] = inferred_type
				issues += 1
				print("修复无效的效果类型: " + effect.type + " -> " + inferred_type)

	# 确保数值字段是数字
	if effect.has("value") and not (effect.value is int or effect.value is float):
		effect["value"] = 0
		issues += 1
		print("修复无效的效果值")

	return issues

# 推断效果类型
func _infer_effect_type(effect: Dictionary) -> String:
	if effect.has("stats"):
		return "stat_boost"
	elif effect.has("operation") and effect.operation in ["discount", "refresh"]:
		return "shop"
	elif effect.has("synergy_id"):
		return "synergy"
	elif effect.has("special_effect"):
		return "special"
	elif effect.has("value"):
		if effect.has("trigger") and effect.trigger == "on_acquire":
			return "gold"
		else:
			return "heal"

	return "special"  # 默认为特殊效果
