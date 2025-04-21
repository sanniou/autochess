extends ConfigModel
class_name SynergyConfig
## 羁绊配置模型
## 用于验证和管理羁绊配置数据

# 获取默认模式
func get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "羁绊ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "羁绊名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "羁绊描述"
		},
		"type": {
			"type": "string",
			"required": true,
			"description": "羁绊类型（职业、种族、特殊）"
		},
		"icon_path": {
			"type": "string",
			"required": true,
			"description": "羁绊图标路径"
		},
		"color": {
			"type": "string",
			"required": false,
			"description": "羁绊颜色（十六进制）"
		},
		"thresholds": {
			"type": "array[dictionary]",
			"required": true,
			"description": "羁绊阈值",
			"schema": {
				"count": {
					"type": "int",
					"required": true,
					"description": "激活所需棋子数量"
				},
				"description": {
					"type": "string",
					"required": true,
					"description": "阈值描述"
				},
				"effects": {
					"type": "array[dictionary]",
					"required": true,
					"description": "阈值效果",
					"schema": {
						"id": {
							"type": "string",
							"required": true,
							"description": "效果ID"
						},
						"type": {
							"type": "string",
							"required": true,
							"description": "效果类型"
						},
						"description": {
							"type": "string",
							"required": true,
							"description": "效果描述"
						}
					}
				}
			}
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证羁绊类型
	if config_data.has("type"):
		var valid_types = ["class", "race", "special"]
		if not valid_types.has(config_data.type):
			validation_errors.append("羁绊类型必须是有效的类型: " + ", ".join(valid_types))

	# 验证羁绊阈值
	if config_data.has("thresholds") and config_data.thresholds is Array:
		if config_data.thresholds.is_empty():
			validation_errors.append("羁绊必须至少有一个阈值")

		var last_count = 0

		for threshold in config_data.thresholds:
			if not threshold is Dictionary:
				validation_errors.append("阈值必须是字典")
				continue

			# 验证阈值数量
			if not threshold.has("count") or not threshold.count is int:
				validation_errors.append("阈值必须有有效的数量")
			elif threshold.count <= last_count:
				validation_errors.append("阈值数量必须递增")
			else:
				last_count = threshold.count

			# 验证阈值效果
			if not threshold.has("effects"):
				validation_errors.append("阈值必须有效果数组")
			elif not threshold.effects is Array:
				validation_errors.append("阈值效果必须是数组")
			elif threshold.effects.is_empty():
				validation_errors.append("阈值效果数组不能为空")
			else:
				# 验证每个效果
				for effect in threshold.effects:
					if not effect is Dictionary:
						validation_errors.append("效果必须是字典")
						continue

					# 验证效果ID
					if not effect.has("id") or not effect.id is String or effect.id.is_empty():
						validation_errors.append("效果必须有有效的ID")

					# 验证效果类型
					if not effect.has("type") or not effect.type is String or effect.type.is_empty():
						validation_errors.append("效果必须有有效的类型")
					else:
						# 根据效果类型验证必要字段
						match effect.type:
							"attribute":
								if not effect.has("attribute") or not effect.attribute is String or effect.attribute.is_empty():
									validation_errors.append("属性效果必须指定属性名称")
								if not effect.has("value") or (not effect.value is int and not effect.value is float):
									validation_errors.append("属性效果必须指定数值")
								if not effect.has("operation") or not effect.operation is String or effect.operation.is_empty():
									validation_errors.append("属性效果必须指定操作类型")
							"ability":
								if not effect.has("ability_id") or not effect.ability_id is String or effect.ability_id.is_empty():
									validation_errors.append("技能效果必须指定技能ID")
							"special":
								if not effect.has("special_id") or not effect.special_id is String or effect.special_id.is_empty():
									validation_errors.append("特殊效果必须指定特殊ID")

# 获取羁绊ID
func get_id() -> String:
	return data.get("id", "")

# 获取羁绊名称
func get_name() -> String:
	return data.get("name", "")

# 获取羁绊描述
func get_description() -> String:
	return data.get("description", "")

# 获取羁绊类型
func get_type() -> String:
	return data.get("type", "")

# 获取羁绊图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取羁绊颜色
func get_color() -> String:
	return data.get("color", "#FFFFFF")

# 获取羁绊阈值
func get_thresholds() -> Array:
	return data.get("thresholds", [])

# 获取特定数量的阈值
func get_threshold_for_count(count: int) -> Dictionary:
	var thresholds = get_thresholds()
	var matching_threshold = {}

	for threshold in thresholds:
		if threshold.has("count") and threshold.count <= count:
			if matching_threshold.is_empty() or threshold.count > matching_threshold.count:
				matching_threshold = threshold

	return matching_threshold

# 获取所有阈值数量
func get_all_threshold_counts() -> Array:
	var thresholds = get_thresholds()
	var counts = []

	for threshold in thresholds:
		if threshold.has("count"):
			counts.append(threshold.count)

	return counts

# 获取最大阈值数量
func get_max_threshold_count() -> int:
	var thresholds = get_thresholds()
	var max_count = 0

	for threshold in thresholds:
		if threshold.has("count") and threshold.count > max_count:
			max_count = threshold.count

	return max_count

# 获取特定阈值的效果
func get_effects_for_threshold(count: int) -> Array:
	var threshold = get_threshold_for_count(count)

	if threshold.has("effects"):
		return threshold.effects

	return []

# 获取特定等级的效果
func get_effects_for_level(level: int) -> Array:
	return get_effects_for_threshold(level)

# 检查是否为职业羁绊
func is_class_synergy() -> bool:
	return get_type() == "class"

# 检查是否为种族羁绊
func is_race_synergy() -> bool:
	return get_type() == "race"

# 检查是否为特殊羁绊
func is_special_synergy() -> bool:
	return get_type() == "special"
