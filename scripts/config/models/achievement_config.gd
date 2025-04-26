extends ConfigModel
class_name AchievementConfig
## 成就配置模型
## 提供成就配置数据的访问和验证

# 引入成就常量
const AC = preload("res://scripts/constants/achievement_constants.gd")

# 获取配置类型
func _get_config_type() -> String:
	return "achievement"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "成就ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "成就名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "成就描述"
		},
		"icon_path": {
			"type": "string",
			"required": false,
			"description": "成就图标路径"
		},
		"category": {
			"type": "string",
			"required": true,
			"description": "成就类别"
		},
		"hidden": {
			"type": "bool",
			"required": false,
			"description": "是否隐藏"
		},
		"requirements": {
			"type": "dictionary",
			"required": true,
			"description": "成就要求",
			"schema": {
				"type": {
					"type": "string",
					"required": true,
					"description": "要求类型"
				},
				"count": {
					"type": "float",
					"required": false,
					"description": "要求数量"
				},
				"all": {
					"type": "bool",
					"required": false,
					"description": "是否需要全部"
				},
				"exclude": {
					"type": "array",
					"required": false,
					"description": "排除项"
				},
				"rarity": {
					"type": "int",
					"required": false,
					"description": "稀有度要求"
				},
				"in_single_game": {
					"type": "bool",
					"required": false,
					"description": "是否在单局游戏中"
				},
				"difficulty_min": {
					"type": "float",
					"required": false,
					"description": "最低难度要求"
				},
				"health_max": {
					"type": "float",
					"required": false,
					"description": "最大生命值要求"
				},
				"no_loss": {
					"type": "bool",
					"required": false,
					"description": "是否不损失棋子"
				},
				"full": {
					"type": "bool",
					"required": false,
					"description": "是否满员"
				},
				"level": {
					"type": "string",
					"required": false,
					"description": "等级要求"
				},
				"star": {
					"type": "float",
					"required": false,
					"description": "星级要求"
				},
				"win": {
					"type": "bool",
					"required": false,
					"description": "是否胜利"
				},
				"time_max": {
					"type": "float",
					"required": false,
					"description": "最大时间要求"
				},
				"amount": {
					"type": "float",
					"required": false,
					"description": "数量要求"
				}
			}
		},
		"rewards": {
			"type": "dictionary",
			"required": false,
			"description": "成就奖励",
			"schema": {
				"gold": {
					"type": "float",
					"required": false,
					"description": "金币奖励"
				},
				"exp": {
					"type": "float",
					"required": false,
					"description": "经验奖励"
				},
				"unlock_item": {
					"type": "string",
					"required": false,
					"description": "解锁物品"
				},
				"skin_type": {
					"type": "string",
					"required": false,
					"description": "皮肤类型"
				}
			}
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证成就类别
	if config_data.has("category"):
		var valid_categories = AC.CATEGORY_STRINGS.values()
		if not valid_categories.has(config_data.category):
			validation_errors.append("成就类别必须是有效的类别: " + ", ".join(valid_categories))

	# 验证成就要求
	if config_data.has("requirements"):
		var requirements = config_data.requirements

		# 验证要求类型
		if requirements.has("type"):
			var valid_types = AC.TYPE_STRINGS.values()
			if not valid_types.has(requirements.type):
				validation_errors.append("要求类型必须是有效的类型: " + ", ".join(valid_types))
		else:
			validation_errors.append("成就要求必须包含类型")

		# 验证数量要求
		if requirements.has("count") and (not requirements.count is float or requirements.count <= 0):
			validation_errors.append("数量要求必须是正数")

		# 验证稀有度要求
		if requirements.has("rarity") and (not requirements.rarity is int or requirements.rarity < 0):
			validation_errors.append("稀有度要求必须是非负整数")

		# 验证难度要求
		if requirements.has("difficulty_min") and (not requirements.difficulty_min is float or requirements.difficulty_min < 0):
			validation_errors.append("难度要求必须是非负数")

		# 验证生命值要求
		if requirements.has("health_max") and (not requirements.health_max is float or requirements.health_max <= 0):
			validation_errors.append("生命值要求必须是正数")

		# 验证星级要求
		if requirements.has("star") and (not requirements.star is float or requirements.star <= 0):
			validation_errors.append("星级要求必须是正数")

		# 验证时间要求
		if requirements.has("time_max") and (not requirements.time_max is float or requirements.time_max <= 0):
			validation_errors.append("时间要求必须是正数")

		# 验证数量要求
		if requirements.has("amount") and (not requirements.amount is float or requirements.amount <= 0):
			validation_errors.append("数量要求必须是正数")

	# 验证成就奖励
	if config_data.has("rewards") and config_data.rewards is Dictionary:
		for reward_type in config_data.rewards:
			var reward_value = config_data.rewards[reward_type]

			match reward_type:
				"gold", "exp":
					if not reward_value is float or reward_value <= 0:
						validation_errors.append(reward_type + "奖励必须是正数")
				"unlock_item", "skin_type":
					if not reward_value is String or reward_value.is_empty():
						validation_errors.append(reward_type + "奖励必须是有效的字符串")

# 获取成就名称
func get_achievement_name() -> String:
	return data.get("name", "")

# 获取成就描述
func get_description() -> String:
	return data.get("description", "")

# 获取成就图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取成就类别
func get_category() -> String:
	return data.get("category", "")

# 获取成就类别枚举
func get_category_enum() -> int:
	return AC.get_category_from_string(get_category())

# 获取是否隐藏
func is_hidden() -> bool:
	return data.get("hidden", false)

# 获取成就要求
func get_requirements() -> Dictionary:
	return data.get("requirements", {})

# 获取要求类型
func get_requirement_type() -> String:
	var requirements = get_requirements()
	return requirements.get("type", "")

# 获取要求类型枚举
func get_requirement_type_enum() -> int:
	return AC.get_type_from_string(get_requirement_type())

# 获取要求数量
func get_requirement_count() -> float:
	var requirements = get_requirements()
	return requirements.get("count", 1.0)

# 获取是否需要全部
func is_requirement_all() -> bool:
	var requirements = get_requirements()
	return requirements.get("all", false)

# 获取排除项
func get_requirement_exclude() -> Array:
	var requirements = get_requirements()
	return requirements.get("exclude", [])

# 获取稀有度要求
func get_requirement_rarity() -> int:
	var requirements = get_requirements()
	return requirements.get("rarity", 0)

# 获取是否在单局游戏中
func is_requirement_in_single_game() -> bool:
	var requirements = get_requirements()
	return requirements.get("in_single_game", false)

# 获取最低难度要求
func get_requirement_difficulty_min() -> float:
	var requirements = get_requirements()
	return requirements.get("difficulty_min", 0.0)

# 获取最大生命值要求
func get_requirement_health_max() -> float:
	var requirements = get_requirements()
	return requirements.get("health_max", 0.0)

# 获取是否不损失棋子
func is_requirement_no_loss() -> bool:
	var requirements = get_requirements()
	return requirements.get("no_loss", false)

# 获取是否满员
func is_requirement_full() -> bool:
	var requirements = get_requirements()
	return requirements.get("full", false)

# 获取等级要求
func get_requirement_level() -> String:
	var requirements = get_requirements()
	return requirements.get("level", "")

# 获取星级要求
func get_requirement_star() -> float:
	var requirements = get_requirements()
	return requirements.get("star", 0.0)

# 获取是否胜利
func is_requirement_win() -> bool:
	var requirements = get_requirements()
	return requirements.get("win", false)

# 获取最大时间要求
func get_requirement_time_max() -> float:
	var requirements = get_requirements()
	return requirements.get("time_max", 0.0)

# 获取数量要求
func get_requirement_amount() -> float:
	var requirements = get_requirements()
	return requirements.get("amount", 0.0)

# 获取成就奖励
func get_rewards() -> Dictionary:
	return data.get("rewards", {})

# 检查是否为特定类别
func is_category(category: String) -> bool:
	return get_category() == category

# 检查是否为特定要求类型
func is_requirement_type(requirement_type: String) -> bool:
	return get_requirement_type() == requirement_type

# 检查是否有特定类型的奖励
func has_reward_type(reward_type: String) -> bool:
	var rewards = get_rewards()
	return rewards.has(reward_type)

# 获取特定类型的奖励
func get_reward(reward_type: String, default_value = null) -> Variant:
	var rewards = get_rewards()
	return rewards.get(reward_type, default_value)

# 检查是否达成成就
func is_achieved(progress: float) -> bool:
	var requirements = get_requirements()

	if requirements.has("count"):
		return progress >= requirements.count

	return progress >= 1.0

# 获取成就进度百分比
func get_progress_percentage(progress: float) -> float:
	var requirements = get_requirements()
	var max_progress = 1.0

	if requirements.has("count"):
		max_progress = requirements.count

	if max_progress <= 0:
		return 0.0

	return min(1.0, progress / max_progress) * 100.0
