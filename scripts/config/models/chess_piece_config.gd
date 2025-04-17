extends "res://scripts/config/config_model.gd"
class_name ChessPieceConfig
## 棋子配置模型
## 提供棋子配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "chess_piece"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "棋子ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "棋子名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "棋子描述"
		},
		"rarity": {
			"type": "int",
			"required": true,
			"description": "棋子稀有度"
		},
		"cost": {
			"type": "int",
			"required": true,
			"description": "棋子费用"
		},
		"health": {
			"type": "int",
			"required": true,
			"description": "棋子生命值"
		},
		"attack_damage": {
			"type": "int",
			"required": true,
			"description": "棋子攻击力"
		},
		"attack_speed": {
			"type": "float",
			"required": true,
			"description": "棋子攻击速度"
		},
		"armor": {
			"type": "int",
			"required": true,
			"description": "棋子护甲"
		},
		"magic_resist": {
			"type": "int",
			"required": true,
			"description": "棋子魔法抗性"
		},
		"attack_range": {
			"type": "int",
			"required": true,
			"description": "棋子攻击范围"
		},
		"move_speed": {
			"type": "int",
			"required": true,
			"description": "棋子移动速度"
		},
		"ability": {
			"type": "dictionary",
			"required": true,
			"description": "棋子技能"
		},
		"synergies": {
			"type": "array[string]",
			"required": true,
			"description": "棋子羁绊"
		},
		"tier": {
			"type": "int",
			"required": true,
			"description": "棋子等级"
		},
		"icon": {
			"type": "string",
			"required": false,
			"description": "棋子图标"
		},
		"model": {
			"type": "string",
			"required": false,
			"description": "棋子模型"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证稀有度范围
	if config_data.has("rarity") and (config_data.rarity < 0 or config_data.rarity > 5):
		validation_errors.append("稀有度必须在0-5之间")
	
	# 验证费用范围
	if config_data.has("cost") and (config_data.cost < 1 or config_data.cost > 5):
		validation_errors.append("费用必须在1-5之间")
	
	# 验证攻击范围
	if config_data.has("attack_range") and config_data.attack_range < 1:
		validation_errors.append("攻击范围必须大于0")
	
	# 验证技能
	if config_data.has("ability") and config_data.ability is Dictionary:
		var ability = config_data.ability
		
		# 验证技能名称
		if not ability.has("name") or not ability.name is String or ability.name.is_empty():
			validation_errors.append("技能必须有有效的名称")
		
		# 验证技能描述
		if not ability.has("description") or not ability.description is String or ability.description.is_empty():
			validation_errors.append("技能必须有有效的描述")
		
		# 验证技能类型
		if not ability.has("type") or not ability.type is String or ability.type.is_empty():
			validation_errors.append("技能必须有有效的类型")
		elif not ["damage", "area_damage", "chain", "teleport", "aura", "summon"].has(ability.type):
			validation_errors.append("技能类型必须是有效的类型: damage, area_damage, chain, teleport, aura, summon")
		
		# 验证技能冷却
		if not ability.has("cooldown") or not (ability.cooldown is int or ability.cooldown is float) or ability.cooldown <= 0:
			validation_errors.append("技能必须有有效的冷却时间")
	
	# 验证羁绊
	if config_data.has("synergies") and config_data.synergies is Array:
		if config_data.synergies.is_empty():
			validation_errors.append("棋子必须至少有一个羁绊")
		
		for synergy in config_data.synergies:
			if not synergy is String or synergy.is_empty():
				validation_errors.append("羁绊必须是有效的字符串")

# 获取棋子名称
func get_name() -> String:
	return data.get("name", "")

# 获取棋子描述
func get_description() -> String:
	return data.get("description", "")

# 获取棋子稀有度
func get_rarity() -> int:
	return data.get("rarity", 0)

# 获取棋子费用
func get_cost() -> int:
	return data.get("cost", 0)

# 获取棋子生命值
func get_health() -> int:
	return data.get("health", 0)

# 获取棋子攻击力
func get_attack_damage() -> int:
	return data.get("attack_damage", 0)

# 获取棋子攻击速度
func get_attack_speed() -> float:
	return data.get("attack_speed", 0.0)

# 获取棋子护甲
func get_armor() -> int:
	return data.get("armor", 0)

# 获取棋子魔法抗性
func get_magic_resist() -> int:
	return data.get("magic_resist", 0)

# 获取棋子攻击范围
func get_attack_range() -> int:
	return data.get("attack_range", 1)

# 获取棋子移动速度
func get_move_speed() -> int:
	return data.get("move_speed", 0)

# 获取棋子技能
func get_ability() -> Dictionary:
	return data.get("ability", {})

# 获取棋子羁绊
func get_synergies() -> Array:
	return data.get("synergies", [])

# 获取棋子等级
func get_tier() -> int:
	return data.get("tier", 1)

# 获取棋子图标
func get_icon() -> String:
	return data.get("icon", "")

# 获取棋子模型
func get_model() -> String:
	return data.get("model", "")
