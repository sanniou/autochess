extends "res://scripts/config/config_model.gd"
class_name SynergyConfig
## 羁绊配置模型
## 提供羁绊配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "synergy"

# 获取默认架构
func _get_default_schema() -> Dictionary:
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
		"icon_path": {
			"type": "string",
			"required": false,
			"description": "羁绊图标路径"
		},
		"type": {
			"type": "string",
			"required": false,
			"description": "羁绊类型(class/race/special)"
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

				"effects": {
					"type": "array[dictionary]",
					"required": true,
					"description": "阈值效果数组",
					"schema": {
						"type": {
							"type": "string",
							"required": true,
							"description": "效果类型"
						},
						"stats": {
							"type": "dictionary",
							"required": false,
							"description": "效果属性修改",
							"schema": {
								"attack_damage": {
									"type": "float",
									"required": false,
									"description": "攻击力"
								},
								"attack_speed": {
									"type": "float",
									"required": false,
									"description": "攻击速度"
								},
								"armor": {
									"type": "float",
									"required": false,
									"description": "护甲"
								},
								"magic_resist": {
									"type": "float",
									"required": false,
									"description": "魔抗"
								},
								"spell_power": {
									"type": "float",
									"required": false,
									"description": "法术强度"
								}
							}
						},
						"is_percentage": {
							"type": "bool",
							"required": false,
							"description": "是否为百分比值"
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

			# 验证 effects 数组
			if not threshold.has("effects") or not threshold.effects is Array:
				validation_errors.append("阈值必须有有效的效果数组")
			else:
				for effect in threshold.effects:
					if not effect is Dictionary:
						validation_errors.append("效果必须是字典")
						continue

					# 验证效果类型
					if not effect.has("type") or not effect.type is String or effect.type.is_empty():
						validation_errors.append("效果必须有有效的类型")

					# 验证效果统计
					if effect.has("stats") and effect.stats is Dictionary:
						for stat_name in effect.stats:
							var stat_value = effect.stats[stat_name]

							if not (stat_value is int or stat_value is float):
								validation_errors.append("统计值必须是数字: " + stat_name)

					# 验证是否为百分比
					if effect.has("is_percentage") and not effect.is_percentage is bool:
						validation_errors.append("is_percentage必须是布尔值")

# 获取羁绊名称
func get_synergy_name() -> String:
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

# 获取羁绊阈值
func get_thresholds() -> Array:
	return data.get("thresholds", [])

# 获取特定数量的阈值
func get_threshold_for_count(count: int) -> Dictionary:
	var thresholds = get_thresholds()

	for threshold in thresholds:
		if threshold.has("count") and threshold.count <= count:
			if threshold == thresholds.back() or thresholds[thresholds.find(threshold) + 1].count > count:
				return threshold

	return {}

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

# 检查是否为职业羁绊
func is_class_synergy() -> bool:
	return get_type() == "class"

# 检查是否为种族羁绊
func is_race_synergy() -> bool:
	return get_type() == "race"

# 检查是否为特殊羁绊
func is_special_synergy() -> bool:
	return get_type() == "special"
