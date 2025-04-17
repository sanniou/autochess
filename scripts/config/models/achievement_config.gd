extends "res://scripts/config/config_model.gd"
class_name AchievementConfig
## 成就配置模型
## 提供成就配置数据的访问和验证

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
		"trigger_type": {
			"type": "string",
			"required": true,
			"description": "触发类型"
		},
		"trigger_value": {
			"type": "int",
			"required": true,
			"description": "触发值"
		},
		"rewards": {
			"type": "dictionary",
			"required": false,
			"description": "成就奖励"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证成就类别
	if config_data.has("category"):
		var valid_categories = ["gameplay", "collection", "challenge", "story", "secret"]
		if not valid_categories.has(config_data.category):
			validation_errors.append("成就类别必须是有效的类别: " + ", ".join(valid_categories))
	
	# 验证触发类型
	if config_data.has("trigger_type"):
		var valid_trigger_types = ["win_battles", "collect_chess_pieces", "collect_equipment", "collect_relics", "complete_events", "reach_level", "win_with_synergy", "win_without_damage", "win_with_low_health", "custom"]
		if not valid_trigger_types.has(config_data.trigger_type):
			validation_errors.append("触发类型必须是有效的类型: " + ", ".join(valid_trigger_types))
	
	# 验证触发值
	if config_data.has("trigger_value") and config_data.trigger_value <= 0:
		validation_errors.append("触发值必须大于0")
	
	# 验证成就奖励
	if config_data.has("rewards") and config_data.rewards is Dictionary:
		for reward_type in config_data.rewards:
			var reward_value = config_data.rewards[reward_type]
			
			match reward_type:
				"gold":
					if not reward_value is int or reward_value <= 0:
						validation_errors.append("金币奖励必须是正整数")
				"experience":
					if not reward_value is int or reward_value <= 0:
						validation_errors.append("经验奖励必须是正整数")
				"equipment":
					if not reward_value is String or reward_value.is_empty():
						validation_errors.append("装备奖励必须是有效的字符串")
				"chess_piece":
					if not reward_value is String or reward_value.is_empty():
						validation_errors.append("棋子奖励必须是有效的字符串")
				"relic":
					if not reward_value is String or reward_value.is_empty():
						validation_errors.append("遗物奖励必须是有效的字符串")
				"skin":
					if not reward_value is String or reward_value.is_empty():
						validation_errors.append("皮肤奖励必须是有效的字符串")

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

# 获取是否隐藏
func is_hidden() -> bool:
	return data.get("hidden", false)

# 获取触发类型
func get_trigger_type() -> String:
	return data.get("trigger_type", "")

# 获取触发值
func get_trigger_value() -> int:
	return data.get("trigger_value", 0)

# 获取成就奖励
func get_rewards() -> Dictionary:
	return data.get("rewards", {})

# 检查是否为特定类别
func is_category(category: String) -> bool:
	return get_category() == category

# 检查是否为特定触发类型
func is_trigger_type(trigger_type: String) -> bool:
	return get_trigger_type() == trigger_type

# 检查是否有特定类型的奖励
func has_reward_type(reward_type: String) -> bool:
	var rewards = get_rewards()
	return rewards.has(reward_type)

# 获取特定类型的奖励
func get_reward(reward_type: String, default_value = null) -> Variant:
	var rewards = get_rewards()
	return rewards.get(reward_type, default_value)

# 检查是否达成成就
func is_achieved(progress: int) -> bool:
	return progress >= get_trigger_value()

# 获取成就进度百分比
func get_progress_percentage(progress: int) -> float:
	var trigger_value = get_trigger_value()
	if trigger_value <= 0:
		return 0.0
	
	return min(1.0, float(progress) / float(trigger_value)) * 100.0
