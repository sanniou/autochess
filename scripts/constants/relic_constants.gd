extends BaseConstants
class_name RelicConstants
## 遗物相关常量
## 集中管理遗物的特定常量

## 遗物类型
enum RelicType {
	OFFENSIVE,  # 攻击型遗物
	DEFENSIVE,  # 防御型遗物
	UTILITY,    # 功能型遗物
	SPECIAL     # 特殊遗物
}

## 遗物类型名称 - 使用自动生成的映射
static var RELIC_TYPE_NAMES = enum_to_string_map(RelicType)

## 遗物类型描述
static var RELIC_TYPE_DESCRIPTIONS = {
	RelicType.OFFENSIVE: "提高攻击能力的遗物",
	RelicType.DEFENSIVE: "提高防御能力的遗物",
	RelicType.UTILITY: "提供实用功能的遗物",
	RelicType.SPECIAL: "具有特殊效果的遗物"
}

## 遗物类型颜色
static var RELIC_TYPE_COLORS = {
	RelicType.OFFENSIVE: Color(0.8, 0.2, 0.2, 1.0),  # 红色
	RelicType.DEFENSIVE: Color(0.2, 0.2, 0.8, 1.0),  # 蓝色
	RelicType.UTILITY: Color(0.2, 0.8, 0.2, 1.0),    # 绿色
	RelicType.SPECIAL: Color(0.8, 0.8, 0.2, 1.0)     # 黄色
}

## 获取所有遗物类型
static func get_relic_types() -> Array:
	return get_enum_values(RelicType)

## 获取所有遗物类型名称
static func get_relic_type_names() -> Array:
	return RELIC_TYPE_NAMES.values()

## 获取遗物类型名称
static func get_relic_type_name(relic_type: int) -> String:
	return RELIC_TYPE_NAMES.get(relic_type, "unknown")

## 获取遗物类型描述
static func get_relic_type_description(relic_type: int) -> String:
	return RELIC_TYPE_DESCRIPTIONS.get(relic_type, "未知遗物类型")

## 获取遗物类型颜色
static func get_relic_type_color(relic_type: int) -> Color:
	return RELIC_TYPE_COLORS.get(relic_type, Color.WHITE)

## 字符串转换为遗物类型枚举
static func string_to_relic_type(type_str: String) -> int:
	for key in RELIC_TYPE_NAMES:
		if RELIC_TYPE_NAMES[key] == type_str:
			return key
	return -1

## 检查遗物类型是否有效
static func is_valid_relic_type(relic_type) -> bool:
	if relic_type is String:
		return get_relic_type_names().has(relic_type)
	return is_valid_enum_value(RelicType, relic_type)

## 获取所有有效的触发条件字符串
static func get_valid_triggers() -> Array:
	return EffectConstants.get_trigger_type_names()

## 获取所有有效的效果类型字符串
static func get_valid_effect_types() -> Array:
	return EffectConstants.get_effect_type_names()

## 获取所有有效的条件类型字符串
static func get_valid_condition_types() -> Array:
	return EffectConstants.get_condition_type_names()

## 根据稀有度获取遗物价格
static func get_relic_price_by_rarity(rarity: int) -> int:
	match rarity:
		GameConstants.Rarity.COMMON: return 3
		GameConstants.Rarity.UNCOMMON: return 5
		GameConstants.Rarity.RARE: return 8
		GameConstants.Rarity.EPIC: return 12
		GameConstants.Rarity.LEGENDARY: return 20
		_: return 5

## 创建遗物数据
static func create_relic_data(id: String, name: String, description: String, rarity: int, 
							  relic_type: int = RelicType.UTILITY, is_passive: bool = true, 
							  effects: Array = [], trigger_conditions: Dictionary = {}) -> Dictionary:
	# 验证参数
	if not GameConstants.is_valid_rarity(rarity):
		rarity = GameConstants.Rarity.COMMON
	
	if not is_valid_relic_type(relic_type):
		relic_type = RelicType.UTILITY
	
	# 创建基本数据
	var relic_data = {
		"id": id,
		"name": name,
		"description": description,
		"rarity": rarity,
		"type": RELIC_TYPE_NAMES[relic_type],
		"is_passive": is_passive,
		"effects": effects.duplicate(),
		"trigger_conditions": trigger_conditions.duplicate()
	}
	
	# 如果没有效果，添加一个默认效果
	if effects.is_empty():
		relic_data.effects.append(EffectConstants.create_effect_data(
			EffectConstants.EffectType.SPECIAL, 
			0, 
			EffectConstants.TriggerType.PASSIVE,
			"无效果"
		))
	
	return relic_data

## 添加触发条件
static func add_trigger_condition(relic_data: Dictionary, trigger: String, condition_type: String, 
								 value = 0, description: String = "") -> Dictionary:
	# 确保触发条件字典存在
	if not relic_data.has("trigger_conditions"):
		relic_data["trigger_conditions"] = {}
	
	# 确保触发条件数组存在
	if not relic_data.trigger_conditions.has(trigger):
		relic_data.trigger_conditions[trigger] = []
	
	# 创建条件
	var condition = {
		"type": condition_type,
		"value": value
	}
	
	if not description.is_empty():
		condition["description"] = description
	
	# 添加条件
	relic_data.trigger_conditions[trigger].append(condition)
	
	return relic_data
