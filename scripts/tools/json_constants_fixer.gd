@tool
extends EditorScript
## JSON 常量修复工具
## 用于修复 JSON 文件中的常量引用问题

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")
const EffectConsts = preload("res://scripts/constants/effect_constants.gd")
const RelicConsts = preload("res://scripts/constants/relic_constants.gd")

# 配置文件路径
const RELICS_JSON_PATH = "res://config/relics/relics.json"
const EQUIPMENT_JSON_PATH = "res://config/equipment.json"

# 执行工具
func _run():
	print("开始修复 JSON 文件中的常量引用...")
	
	# 修复遗物配置
	_fix_relics_json()
	
	# 修复装备配置
	_fix_equipment_json()
	
	print("修复完成")

# 修复遗物配置
func _fix_relics_json():
	print("修复遗物配置...")
	
	# 加载遗物配置
	var relics_data = _load_json_file(RELICS_JSON_PATH)
	if relics_data.is_empty():
		print("无法加载遗物配置文件")
		return
	
	var fixed_count = 0
	
	# 遍历所有遗物
	for relic_id in relics_data.keys():
		var relic = relics_data[relic_id]
		
		# 修复稀有度（确保是整数）
		if relic.has("rarity") and relic.rarity is float:
			relic.rarity = int(relic.rarity)
			fixed_count += 1
		
		# 修复效果
		if relic.has("effects") and relic.effects is Array:
			for effect in relic.effects:
				# 确保触发条件有效
				if effect.has("trigger"):
					var trigger = effect.trigger
					if not EffectConsts.is_valid_trigger_type(trigger):
						# 尝试找到最接近的有效触发条件
						var valid_triggers = EffectConsts.get_trigger_type_names()
						var closest_trigger = _find_closest_string(trigger, valid_triggers)
						if closest_trigger != "":
							effect.trigger = closest_trigger
							fixed_count += 1
							print("修复触发条件: " + trigger + " -> " + closest_trigger)
				
				# 确保效果类型有效
				if effect.has("type"):
					var effect_type = effect.type
					if not EffectConsts.is_valid_effect_type(effect_type):
						# 尝试找到最接近的有效效果类型
						var valid_effect_types = EffectConsts.get_effect_type_names()
						var closest_type = _find_closest_string(effect_type, valid_effect_types)
						if closest_type != "":
							effect.type = closest_type
							fixed_count += 1
							print("修复效果类型: " + effect_type + " -> " + closest_type)
	
	print("修复了 " + str(fixed_count) + " 个遗物配置问题")
	
	# 保存修复后的配置
	if _save_json_file(RELICS_JSON_PATH, relics_data):
		print("遗物配置已保存")
	else:
		print("保存遗物配置失败")

# 修复装备配置
func _fix_equipment_json():
	print("修复装备配置...")
	
	# 加载装备配置
	var equipment_data = _load_json_file(EQUIPMENT_JSON_PATH)
	if equipment_data.is_empty():
		print("无法加载装备配置文件")
		return
	
	var fixed_count = 0
	
	# 遍历所有装备
	for equipment_id in equipment_data.keys():
		var equipment = equipment_data[equipment_id]
		
		# 修复稀有度（确保是整数）
		if equipment.has("rarity") and equipment.rarity is float:
			equipment.rarity = int(equipment.rarity)
			fixed_count += 1
		
		# 修复效果
		if equipment.has("effects") and equipment.effects is Array:
			for effect in equipment.effects:
				# 确保触发条件有效
				if effect.has("trigger"):
					var trigger = effect.trigger
					if not EffectConsts.is_valid_trigger_type(trigger):
						# 尝试找到最接近的有效触发条件
						var valid_triggers = EffectConsts.get_trigger_type_names()
						var closest_trigger = _find_closest_string(trigger, valid_triggers)
						if closest_trigger != "":
							effect.trigger = closest_trigger
							fixed_count += 1
							print("修复触发条件: " + trigger + " -> " + closest_trigger)
				
				# 确保效果类型有效
				if effect.has("type"):
					var effect_type = effect.type
					if not EffectConsts.is_valid_effect_type(effect_type):
						# 尝试找到最接近的有效效果类型
						var valid_effect_types = EffectConsts.get_effect_type_names()
						var closest_type = _find_closest_string(effect_type, valid_effect_types)
						if closest_type != "":
							effect.type = closest_type
							fixed_count += 1
							print("修复效果类型: " + effect_type + " -> " + closest_type)
	
	print("修复了 " + str(fixed_count) + " 个装备配置问题")
	
	# 保存修复后的配置
	if _save_json_file(EQUIPMENT_JSON_PATH, equipment_data):
		print("装备配置已保存")
	else:
		print("保存装备配置失败")

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

# 找到最接近的字符串
func _find_closest_string(input: String, candidates: Array) -> String:
	if candidates.has(input):
		return input
	
	var best_match = ""
	var best_score = 0
	
	for candidate in candidates:
		var score = _string_similarity(input, candidate)
		if score > best_score:
			best_score = score
			best_match = candidate
	
	# 只有当相似度大于 0.5 时才返回匹配
	if best_score > 0.5:
		return best_match
	
	return ""

# 计算字符串相似度（简单的 Levenshtein 距离）
func _string_similarity(a: String, b: String) -> float:
	if a == b:
		return 1.0
	
	var len_a = a.length()
	var len_b = b.length()
	
	if len_a == 0 or len_b == 0:
		return 0.0
	
	# 计算 Levenshtein 距离
	var matrix = []
	for i in range(len_a + 1):
		var row = []
		for j in range(len_b + 1):
			row.append(0)
		matrix.append(row)
	
	for i in range(len_a + 1):
		matrix[i][0] = i
	
	for j in range(len_b + 1):
		matrix[0][j] = j
	
	for i in range(1, len_a + 1):
		for j in range(1, len_b + 1):
			var cost = 0 if a[i-1] == b[j-1] else 1
			matrix[i][j] = min(
				matrix[i-1][j] + 1,      # 删除
				matrix[i][j-1] + 1,      # 插入
				matrix[i-1][j-1] + cost  # 替换
			)
	
	var distance = matrix[len_a][len_b]
	var max_len = max(len_a, len_b)
	
	return 1.0 - float(distance) / max_len
