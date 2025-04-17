extends "res://scripts/config/config_model.gd"
class_name EquipmentConfig
## 装备配置模型
## 提供装备配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "equipment"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "装备ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "装备名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "装备描述"
		},
		"rarity": {
			"type": "int",
			"required": true,
			"description": "装备稀有度"
		},
		"icon_path": {
			"type": "string",
			"required": false,
			"description": "装备图标路径"
		},
		"stats": {
			"type": "dictionary",
			"required": true,
			"description": "装备属性"
		},
		"effects": {
			"type": "array[dictionary]",
			"required": false,
			"description": "装备效果"
		},
		"components": {
			"type": "array[string]",
			"required": false,
			"description": "装备合成材料"
		},
		"restricted_classes": {
			"type": "array[string]",
			"required": false,
			"description": "装备限制职业"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证稀有度范围
	if config_data.has("rarity") and (config_data.rarity < 0 or config_data.rarity > 5):
		validation_errors.append("稀有度必须在0-5之间")
	
	# 验证属性
	if config_data.has("stats") and config_data.stats is Dictionary:
		var stats = config_data.stats
		
		# 验证属性值
		for stat_name in stats:
			var stat_value = stats[stat_name]
			
			if not (stat_value is int or stat_value is float):
				validation_errors.append("属性值必须是数字: " + stat_name)
			
			# 验证特定属性的范围
			match stat_name:
				"attack_speed":
					if stat_value < -0.5 or stat_value > 2.0:
						validation_errors.append("攻击速度必须在-0.5到2.0之间")
	
	# 验证效果
	if config_data.has("effects") and config_data.effects is Array:
		for effect in config_data.effects:
			if not effect is Dictionary:
				validation_errors.append("效果必须是字典")
				continue
			
			# 验证效果类型
			if not effect.has("type") or not effect.type is String or effect.type.is_empty():
				validation_errors.append("效果必须有有效的类型")
			elif not ["passive", "active", "trigger"].has(effect.type):
				validation_errors.append("效果类型必须是有效的类型: passive, active, trigger")
			
			# 验证效果描述
			if not effect.has("description") or not effect.description is String or effect.description.is_empty():
				validation_errors.append("效果必须有有效的描述")
			
			# 验证触发条件
			if effect.has("trigger") and not effect.trigger is String:
				validation_errors.append("触发条件必须是字符串")
			
			# 验证冷却时间
			if effect.has("cooldown") and not (effect.cooldown is int or effect.cooldown is float):
				validation_errors.append("冷却时间必须是数字")
	
	# 验证合成材料
	if config_data.has("components") and config_data.components is Array:
		for component in config_data.components:
			if not component is String or component.is_empty():
				validation_errors.append("合成材料必须是有效的字符串")
	
	# 验证限制职业
	if config_data.has("restricted_classes") and config_data.restricted_classes is Array:
		for restricted_class in config_data.restricted_classes:
			if not restricted_class is String or restricted_class.is_empty():
				validation_errors.append("限制职业必须是有效的字符串")

# 获取装备名称
func get_equipment_name() -> String:
	return data.get("name", "")

# 获取装备描述
func get_description() -> String:
	return data.get("description", "")

# 获取装备稀有度
func get_rarity() -> int:
	return data.get("rarity", 0)

# 获取装备图标路径
func get_icon_path() -> String:
	return data.get("icon_path", "")

# 获取装备属性
func get_stats() -> Dictionary:
	return data.get("stats", {})

# 获取装备效果
func get_effects() -> Array:
	return data.get("effects", [])

# 获取装备合成材料
func get_components() -> Array:
	return data.get("components", [])

# 获取装备限制职业
func get_restricted_classes() -> Array:
	return data.get("restricted_classes", [])

# 获取特定属性值
func get_stat(stat_name: String, default_value: Variant = 0) -> Variant:
	var stats = get_stats()
	return stats.get(stat_name, default_value)

# 检查是否有特定效果类型
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

# 检查是否可以被特定职业使用
func can_be_used_by_class(class_names: String) -> bool:
	var restricted_classes = get_restricted_classes()
	
	# 如果没有限制职业，所有职业都可以使用
	if restricted_classes.is_empty():
		return true
	
	return restricted_classes.has(class_names)
