extends "res://scripts/config/config_model.gd"
class_name DifficultyConfig
## 难度配置模型
## 提供难度配置数据的访问和验证

# 获取配置类型
func _get_config_type() -> String:
	return "difficulty"

# 获取默认架构
func _get_default_schema() -> Dictionary:
	return {
		"id": {
			"type": "string",
			"required": true,
			"description": "难度ID"
		},
		"name": {
			"type": "string",
			"required": true,
			"description": "难度名称"
		},
		"description": {
			"type": "string",
			"required": true,
			"description": "难度描述"
		},
		"enemy_health_multiplier": {
			"type": "float",
			"required": true,
			"description": "敌人生命值乘数"
		},
		"enemy_damage_multiplier": {
			"type": "float",
			"required": true,
			"description": "敌人伤害乘数"
		},
		"gold_reward_multiplier": {
			"type": "float",
			"required": true,
			"description": "金币奖励乘数"
		},
		"exp_reward_multiplier": {
			"type": "float",
			"required": true,
			"description": "经验奖励乘数"
		},
		"starting_gold": {
			"type": "int",
			"required": true,
			"description": "初始金币"
		},
		"starting_health": {
			"type": "int",
			"required": true,
			"description": "初始生命值"
		},
		"shop_refresh_cost": {
			"type": "int",
			"required": true,
			"description": "商店刷新费用"
		},
		"max_health": {
			"type": "int",
			"required": true,
			"description": "最大生命值"
		},
		"enemy_scaling": {
			"type": "dictionary",
			"required": false,
			"description": "敌人缩放"
		},
		"player_gold_multiplier": {
			"type": "float",
			"required": true,
			"description": "玩家金币乘数"
		}
	}

# 验证自定义规则
func _validate_custom_rules(config_data: Dictionary) -> void:
	# 验证乘数范围
	for multiplier_field in ["enemy_health_multiplier", "enemy_damage_multiplier", "gold_reward_multiplier", "exp_reward_multiplier", "player_gold_multiplier"]:
		if config_data.has(multiplier_field):
			var value = config_data[multiplier_field]
			if value <= 0:
				validation_errors.append(multiplier_field + "必须大于0")

	# 验证初始金币
	if config_data.has("starting_gold") and config_data.starting_gold < 0:
		validation_errors.append("初始金币必须大于等于0")

	# 验证初始生命值
	if config_data.has("starting_health") and config_data.starting_health <= 0:
		validation_errors.append("初始生命值必须大于0")

	# 验证商店刷新费用
	if config_data.has("shop_refresh_cost") and config_data.shop_refresh_cost < 0:
		validation_errors.append("商店刷新费用必须大于等于0")

	# 验证最大生命值
	if config_data.has("max_health") and config_data.max_health <= 0:
		validation_errors.append("最大生命值必须大于0")

	# 验证敌人缩放
	if config_data.has("enemy_scaling") and config_data.enemy_scaling is Dictionary:
		for round_key in config_data.enemy_scaling:
			if not round_key.is_valid_int():
				validation_errors.append("敌人缩放的回合键必须是整数")
				continue

			var round_value = config_data.enemy_scaling[round_key]
			if not round_value is Dictionary:
				validation_errors.append("敌人缩放的回合值必须是字典")
				continue

			for stat in round_value:
				if not ["health", "damage"].has(stat):
					validation_errors.append("敌人缩放的统计类型必须是health或damage")
					continue

				var stat_value = round_value[stat]
				if not (stat_value is int or stat_value is float) or stat_value <= 0:
					validation_errors.append("敌人缩放的统计值必须是大于0的数字")

# 获取难度名称
func get_difficulty_name() -> String:
	return data.get("name", "")

# 获取难度描述
func get_description() -> String:
	return data.get("description", "")

# 获取敌人生命值乘数
func get_enemy_health_multiplier() -> float:
	return data.get("enemy_health_multiplier", 1.0)

# 获取敌人伤害乘数
func get_enemy_damage_multiplier() -> float:
	return data.get("enemy_damage_multiplier", 1.0)

# 获取金币奖励乘数
func get_gold_reward_multiplier() -> float:
	return data.get("gold_reward_multiplier", 1.0)

# 获取经验奖励乘数
func get_exp_reward_multiplier() -> float:
	return data.get("exp_reward_multiplier", 1.0)

# 获取初始金币
func get_starting_gold() -> int:
	return data.get("starting_gold", 0)

# 获取初始生命值
func get_starting_health() -> int:
	return data.get("starting_health", 100)

# 获取商店刷新费用
func get_shop_refresh_cost() -> int:
	return data.get("shop_refresh_cost", 2)

# 获取最大生命值
func get_max_health() -> int:
	return data.get("max_health", 100)

# 获取敌人缩放
func get_enemy_scaling() -> Dictionary:
	return data.get("enemy_scaling", {})

# 获取玩家金币乘数
func get_player_gold_multiplier() -> float:
	return data.get("player_gold_multiplier", 1.0)

# 获取特定回合的敌人缩放
func get_enemy_scaling_for_round(round_number: int) -> Dictionary:
	var scaling = get_enemy_scaling()
	var result = {"health": 1.0, "damage": 1.0}

	for round_key in scaling:
		var round_value = int(round_key)
		if round_number >= round_value:
			if scaling[round_key].has("health"):
				result.health = scaling[round_key].health
			if scaling[round_key].has("damage"):
				result.damage = scaling[round_key].damage

	return result

# 计算特定回合的敌人生命值乘数
func calculate_enemy_health_multiplier(round_number: int) -> float:
	var base_multiplier = get_enemy_health_multiplier()
	var scaling = get_enemy_scaling_for_round(round_number)

	return base_multiplier * scaling.health

# 计算特定回合的敌人伤害乘数
func calculate_enemy_damage_multiplier(round_number: int) -> float:
	var base_multiplier = get_enemy_damage_multiplier()
	var scaling = get_enemy_scaling_for_round(round_number)

	return base_multiplier * scaling.damage
