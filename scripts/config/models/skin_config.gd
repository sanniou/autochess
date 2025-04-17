extends "res://scripts/config/config_model.gd"
class_name SkinConfig
## 皮肤配置模型
## 提供皮肤配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "skin"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "皮肤ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "皮肤名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "皮肤描述"
		},
		"entity_type": {
			"type": "string",
			"required": true,
			"description": "实体类型"
		},
		"entity_id": {
			"type": "string",
			"required": true,
			"description": "实体ID"
		},
		"rarity": {
			"type": "int",
			"required": true,
			"description": "皮肤稀有度"
		},
		"icon_path": {
			"type": "string",
			"required": false,
			"description": "皮肤图标路径"
		},
		"model_path": {
			"type": "string",
			"required": true,
			"description": "皮肤模型路径"
		},
		"unlock_condition": {
			"type": "dictionary",
			"required": false,
			"description": "解锁条件"
		},
		"effects": {
			"type": "array[dictionary]",
			"required": false,
			"description": "皮肤效果"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证实体类型
	if config_data.has("entity_type"):
		var valid_types = ["chess_piece", "equipment", "map", "ui"]
		if not valid_types.has(config_data.entity_type):
			validation_errors.append("实体类型必须是有效的类型: " + ", ".join(valid_types))
	
	# 验证稀有度范围
	if config_data.has("rarity") and (config_data.rarity < 0 or config_data.rarity > 5):
		validation_errors.append("稀有度必须在0-5之间")
	
	# 验证解锁条件
	if config_data.has("unlock_condition") and config_data.unlock_condition is Dictionary:
		for condition_type in config_data.unlock_condition:
			var condition_value = config_data.unlock_condition[condition_type]
			
			match condition_type:
				"achievement":
					if not condition_value is String or condition_value.is_empty():
						validation_errors.append("成就解锁条件必须是有效的字符串")
				"level":
					if not condition_value is int or condition_value <= 0:
						validation_errors.append("等级解锁条件必须是正整数")
				"gold":
					if not condition_value is int or condition_value <= 0:
						validation_errors.append("金币解锁条件必须是正整数")
				"win_count":
					if not condition_value is int or condition_value <= 0:
						validation_errors.append("胜利次数解锁条件必须是正整数")
				"synergy":
					if not condition_value is Dictionary or not condition_value.has("id") or not condition_value.has("count"):
						validation_errors.append("羁绊解锁条件必须包含id和count字段")
					elif not condition_value.id is String or condition_value.id.is_empty():
						validation_errors.append("羁绊ID必须是有效的字符串")
					elif not condition_value.count is int or condition_value.count <= 0:
						validation_errors.append("羁绊数量必须是正整数")
	
	# 验证皮肤效果
	if config_data.has("effects") and config_data.effects is Array:
		for effect in config_data.effects:
			if not effect is Dictionary:
				validation_errors.append("效果必须是字典")
				continue
			
			# 验证效果类型
			if not effect.has("type") or not effect.type is String or effect.type.is_empty():
				validation_errors.append("效果必须有有效的类型")
			
			# 验证效果描述
			if not effect.has("description") or not effect.description is String or effect.description.is_empty():
				validation_errors.append("效果必须有有效的描述")
			
			# 验证效果值
			if effect.has("value") and not (effect.value is int or effect.value is float or effect.value is String):
				validation_errors.append("效果值必须是数字或字符串")

# 获取皮肤名称
func get_name() -> String:
	return data.get("name", "")

# 获取皮肤描述
func get_description() -> String:
	return data.get("description", "")

# 获取实体类型
func get_entity_type() -> String:
	return data.get("entity_type", "")

# 获取实体ID
func get_entity_id() -> String:
	return data.get("entity_id", "")

# 获取皮肤稀有度
func get_rarity() -> int:
	return data.get("rarity", 0)

# 获取皮肤图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取皮肤模型路径
func get_model_path() -> String:
	return data.get("model_path", "")

# 获取解锁条件
func get_unlock_condition() -> Dictionary:
	return data.get("unlock_condition", {})

# 获取皮肤效果
func get_effects() -> Array:
	return data.get("effects", [])

# 检查是否为特定实体类型
func is_entity_type(entity_type: String) -> bool:
	return get_entity_type() == entity_type

# 检查是否适用于特定实体
func is_for_entity(entity_id: String) -> bool:
	return get_entity_id() == entity_id

# 检查是否有特定类型的效果
func has_effect_type(effect_type: String) -> bool:
	var effects = get_effects()
	
	for effect in effects:
		if effect.has("type") and effect.type == effect_type:
			return true
	
	return false

# 获取特定类型的效果
func get_effects_by_type(effect_type: String) -> Array:
	var effects = get_effects()
	var result = []
	
	for effect in effects:
		if effect.has("type") and effect.type == effect_type:
			result.append(effect)
	
	return result

# 检查是否满足解锁条件
func meets_unlock_condition(player_data: Dictionary) -> bool:
	var unlock_condition = get_unlock_condition()
	
	if unlock_condition.is_empty():
		return true
	
	for condition_type in unlock_condition:
		var condition_value = unlock_condition[condition_type]
		
		match condition_type:
			"achievement":
				if not player_data.has("achievements") or not player_data.achievements.has(condition_value) or not player_data.achievements[condition_value]:
					return false
			"level":
				if not player_data.has("level") or player_data.level < condition_value:
					return false
			"gold":
				if not player_data.has("gold") or player_data.gold < condition_value:
					return false
			"win_count":
				if not player_data.has("win_count") or player_data.win_count < condition_value:
					return false
			"synergy":
				if not player_data.has("synergies") or not player_data.synergies.has(condition_value.id) or player_data.synergies[condition_value.id] < condition_value.count:
					return false
	
	return true
