extends "res://scripts/config/config_model.gd"
class_name RelicConfig
## 遗物配置模型
## 提供遗物配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "relic"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "遗物ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "遗物名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "遗物描述"
		},
		"rarity": {
			"type": "int",
			"required": true,
			"description": "遗物稀有度"
		},
		"icon_path": {
			"type": "string",
			"required": false,
			"description": "遗物图标路径"
		},
		"is_passive": {
			"type": "bool",
			"required": false,
			"description": "是否为被动遗物"
		},
		"cooldown": {
			"type": "int",
			"required": false,
			"description": "遗物冷却时间"
		},
		"charges": {
			"type": "int",
			"required": false,
			"description": "遗物充能次数"
		},
		"effects": {
			"type": "array[dictionary]",
			"required": true,
			"description": "遗物效果"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证稀有度范围
	if config_data.has("rarity") and (config_data.rarity < 0 or config_data.rarity > 5):
		validation_errors.append("稀有度必须在0-5之间")
	
	# 验证冷却时间
	if config_data.has("cooldown") and config_data.cooldown < 0:
		validation_errors.append("冷却时间必须大于等于0")
	
	# 验证充能次数
	if config_data.has("charges") and config_data.charges < 0:
		validation_errors.append("充能次数必须大于等于0")
	
	# 验证效果
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
			
			# 验证触发条件
			if effect.has("trigger"):
				var valid_triggers = ["on_acquire", "on_round_start", "on_round_end", "on_battle_start", "on_battle_end", "on_activate"]
				if not valid_triggers.has(effect.trigger):
					validation_errors.append("触发条件必须是有效的类型: " + ", ".join(valid_triggers))
			
			# 验证效果值
			if effect.has("value"):
				if not (effect.value is int or effect.value is float):
					validation_errors.append("效果值必须是数字")

# 获取遗物名称
func get_name() -> String:
	return data.get("name", "")

# 获取遗物描述
func get_description() -> String:
	return data.get("description", "")

# 获取遗物稀有度
func get_rarity() -> int:
	return data.get("rarity", 0)

# 获取遗物图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取是否为被动遗物
func is_passive() -> bool:
	return data.get("is_passive", true)

# 获取遗物冷却时间
func get_cooldown() -> int:
	return data.get("cooldown", 0)

# 获取遗物充能次数
func get_charges() -> int:
	return data.get("charges", 1)

# 获取遗物效果
func get_effects() -> Array:
	return data.get("effects", [])

# 获取特定类型的效果
func get_effects_by_type(effect_type: String) -> Array:
	var effects = get_effects()
	var result = []
	
	for effect in effects:
		if effect.has("type") and effect.type == effect_type:
			result.append(effect)
	
	return result

# 获取特定触发条件的效果
func get_effects_by_trigger(trigger: String) -> Array:
	var effects = get_effects()
	var result = []
	
	for effect in effects:
		if effect.has("trigger") and effect.trigger == trigger:
			result.append(effect)
	
	return result

# 检查是否有特定类型的效果
func has_effect_type(effect_type: String) -> bool:
	var effects = get_effects()
	
	for effect in effects:
		if effect.has("type") and effect.type == effect_type:
			return true
	
	return false

# 检查是否有特定触发条件的效果
func has_trigger(trigger: String) -> bool:
	var effects = get_effects()
	
	for effect in effects:
		if effect.has("trigger") and effect.trigger == trigger:
			return true
	
	return false
