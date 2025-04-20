extends Resource
class_name BattleConfig
## 战斗配置
## 定义战斗的规则和奖励

# 基本信息
@export var id: String = ""
@export var name: String = ""
@export var min_units: int = 3
@export var max_units: int = 6
@export var difficulty_multiplier: float = 1.0

# 奖励配置
@export var rewards: Dictionary = {}

# 特殊规则
@export var special_rules: Dictionary = {}

## 从字典创建战斗配置
static func from_dict(dict: Dictionary) -> BattleConfig:
	var battle_config = BattleConfig.new()
	
	# 设置基本信息
	battle_config.id = dict.get("id", "")
	battle_config.name = dict.get("name", "")
	battle_config.min_units = dict.get("min_units", 3)
	battle_config.max_units = dict.get("max_units", 6)
	battle_config.difficulty_multiplier = dict.get("difficulty_multiplier", 1.0)
	
	# 设置奖励和特殊规则
	battle_config.rewards = dict.get("rewards", {}).duplicate()
	battle_config.special_rules = dict.get("special_rules", {}).duplicate()
	
	return battle_config

## 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"min_units": min_units,
		"max_units": max_units,
		"difficulty_multiplier": difficulty_multiplier,
		"rewards": rewards.duplicate(),
		"special_rules": special_rules.duplicate()
	}

## 获取随机单位数量
func get_random_units_count() -> int:
	return randi_range(min_units, max_units)

## 获取金币奖励
func get_gold_reward(difficulty_level: int = 1) -> int:
	var gold_config = rewards.get("gold", {})
	var base_gold = gold_config.get("base", 2)
	var per_difficulty = gold_config.get("per_difficulty", 1)
	
	return base_gold + per_difficulty * difficulty_level

## 获取装备掉落概率
func get_item_drop_chance() -> float:
	return rewards.get("item_drop_chance", 0.3)

## 是否有保证的遗物
func has_guaranteed_relic() -> bool:
	return rewards.get("guaranteed_relic", false)

## 获取特殊规则
func get_special_rule(rule_name: String, default_value = null):
	return special_rules.get(rule_name, default_value)

## 是否有时间限制
func has_time_limit() -> bool:
	return special_rules.has("time_limit")

## 获取时间限制
func get_time_limit() -> int:
	return special_rules.get("time_limit", 0)

## 是否限制技能
func has_restricted_abilities() -> bool:
	return special_rules.get("restricted_abilities", false)

## 验证战斗配置是否有效
func is_valid() -> bool:
	if id.is_empty() or name.is_empty():
		return false
	
	if min_units <= 0 or max_units < min_units:
		return false
	
	if difficulty_multiplier <= 0:
		return false
	
	return true
