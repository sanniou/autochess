extends BaseConstants
class_name EffectConstants
## 效果常量
## 定义装备和技能效果的类型和触发条件

## 效果类型
enum EffectType {
	STAT_BOOST,  # 属性提升
	DAMAGE,      # 伤害
	HEAL,        # 治疗
	GOLD,        # 金币
	SHOP,        # 商店
	SYNERGY,     # 羁绊
	SPECIAL,     # 特殊效果
	STATUS,      # 状态效果
	MOVEMENT,    # 移动效果
	VISUAL,      # 视觉效果
	SOUND        # 音效
}

## 触发条件
enum TriggerType {
	PASSIVE,         # 被动效果
	ON_ACQUIRE,      # 获取时触发
	ON_ROUND_START,  # 回合开始时触发
	ON_ROUND_END,    # 回合结束时触发
	ON_BATTLE_START, # 战斗开始时触发
	ON_BATTLE_END,   # 战斗结束时触发
	ON_BATTLE_VICTORY, # 战斗胜利时触发
	ON_BATTLE_DEFEAT,  # 战斗失败时触发
	ON_ACTIVATE,     # 主动激活时触发
	ON_ATTACK,       # 攻击时触发
	ON_HIT,          # 受到伤害时触发
	ON_TIMER,        # 定时器触发
	ON_ABILITY,      # 使用技能时触发
	ON_CRIT,         # 暴击时触发
	ON_DODGE,        # 闪避时触发
	ON_DAMAGE,       # 造成伤害时触发
	ON_LOW_HEALTH,   # 低生命值时触发
	ON_EVENT_COMPLETED, # 事件完成时触发
	ON_MAP_NODE_SELECTED # 地图节点选择时触发
}

## 条件类型
enum ConditionType {
	HEALTH_BELOW,  # 生命值低于阈值
	GOLD_ABOVE,    # 金币高于阈值
	SYNERGY_ACTIVE, # 羁绊激活
	ROUND_NUMBER,  # 回合数
	CHANCE,        # 概率触发
	CLASS,         # 棋子职业
	ATTACK,        # 攻击时
	ATTACK_COUNT,  # 攻击次数
	TAKE_DAMAGE,   # 受到伤害时
	TIMER,         # 定时器触发
	ABILITY_CAST,  # 释放技能时
	CRIT,          # 暴击时
	DODGE,         # 闪避时
	HEALTH_PERCENT # 生命值百分比
}

## 效果类型名称 - 使用自动生成的映射
static var EFFECT_TYPE_NAMES = enum_to_string_map(EffectType)

## 触发条件名称 - 使用自动生成的映射
static var TRIGGER_TYPE_NAMES = enum_to_string_map(TriggerType)

## 条件类型名称 - 使用自动生成的映射
static var CONDITION_TYPE_NAMES = enum_to_string_map(ConditionType)

## 触发类型到条件类型的映射 - 使用枚举值而不是字符串
static var TRIGGER_TO_CONDITION_MAP = {
	TriggerType.PASSIVE: null,
	TriggerType.ON_ATTACK: ConditionType.ATTACK,
	TriggerType.ON_HIT: ConditionType.TAKE_DAMAGE,
	TriggerType.ON_TIMER: ConditionType.TIMER,
	TriggerType.ON_ABILITY: ConditionType.ABILITY_CAST,
	TriggerType.ON_CRIT: ConditionType.CRIT,
	TriggerType.ON_DODGE: ConditionType.DODGE,
	TriggerType.ON_DAMAGE: ConditionType.TAKE_DAMAGE,
	TriggerType.ON_LOW_HEALTH: ConditionType.HEALTH_PERCENT,
	TriggerType.ON_ROUND_START: ConditionType.ROUND_NUMBER,
	TriggerType.ON_ROUND_END: ConditionType.ROUND_NUMBER,
	TriggerType.ON_BATTLE_START: null,
	TriggerType.ON_BATTLE_END: null,
	TriggerType.ON_ACTIVATE: null,
	TriggerType.ON_ACQUIRE: null,
	TriggerType.ON_BATTLE_VICTORY: null,
	TriggerType.ON_BATTLE_DEFEAT: null,
	TriggerType.ON_EVENT_COMPLETED: null,
	TriggerType.ON_MAP_NODE_SELECTED: null
}

## 为了向后兼容，保留字符串映射
static var TRIGGER_TO_CONDITION = {}

## 效果类型到默认触发条件的映射
static var EFFECT_TO_DEFAULT_TRIGGER = {
	EffectType.STAT_BOOST: TriggerType.PASSIVE,
	EffectType.DAMAGE: TriggerType.ON_ATTACK,
	EffectType.HEAL: TriggerType.ON_ACTIVATE,
	EffectType.GOLD: TriggerType.ON_ACQUIRE,
	EffectType.SHOP: TriggerType.PASSIVE,
	EffectType.SYNERGY: TriggerType.PASSIVE,
	EffectType.SPECIAL: TriggerType.PASSIVE,
	EffectType.STATUS: TriggerType.ON_HIT,
	EffectType.MOVEMENT: TriggerType.ON_ACTIVATE,
	EffectType.VISUAL: TriggerType.ON_ACTIVATE,
	EffectType.SOUND: TriggerType.ON_ACTIVATE
}

## 静态构造函数 - 在类加载时初始化
static func _static_init():
	# 初始化字符串映射（向后兼容）
	for trigger in TRIGGER_TO_CONDITION_MAP:
		var trigger_str = TRIGGER_TYPE_NAMES[trigger]
		var condition = TRIGGER_TO_CONDITION_MAP[trigger]
		if condition != null:
			TRIGGER_TO_CONDITION[trigger_str] = CONDITION_TYPE_NAMES[condition]
		else:
			TRIGGER_TO_CONDITION[trigger_str] = ""

# 调用静态构造函数
var _init_result = _static_init()

## 获取所有效果类型
static func get_effect_types() -> Array:
	return get_enum_values(EffectType)

## 获取所有触发条件
static func get_trigger_types() -> Array:
	return get_enum_values(TriggerType)

## 获取所有条件类型
static func get_condition_types() -> Array:
	return get_enum_values(ConditionType)

## 获取所有效果类型名称
static func get_effect_type_names() -> Array:
	return EFFECT_TYPE_NAMES.values()

## 获取所有触发条件名称
static func get_trigger_type_names() -> Array:
	return TRIGGER_TYPE_NAMES.values()

## 获取所有条件类型名称
static func get_condition_type_names() -> Array:
	return CONDITION_TYPE_NAMES.values()

## 根据触发类型获取默认条件类型
static func get_default_condition_for_trigger(trigger) -> int:
	# 支持字符串或枚举值
	var trigger_enum = trigger
	if trigger is String:
		trigger_enum = string_to_trigger_type(trigger)
		if trigger_enum == -1:
			return -1
	
	return TRIGGER_TO_CONDITION_MAP.get(trigger_enum, -1)

## 根据触发类型获取默认条件类型名称（向后兼容）
static func get_default_condition_for_trigger_name(trigger: String) -> String:
	return TRIGGER_TO_CONDITION.get(trigger, "")

## 根据效果类型获取默认触发条件
static func get_default_trigger_for_effect(effect_type) -> int:
	# 支持字符串或枚举值
	var effect_enum = effect_type
	if effect_type is String:
		effect_enum = string_to_effect_type(effect_type)
		if effect_enum == -1:
			return TriggerType.PASSIVE
	
	return EFFECT_TO_DEFAULT_TRIGGER.get(effect_enum, TriggerType.PASSIVE)

## 字符串转换为效果类型枚举
static func string_to_effect_type(effect_str: String) -> int:
	for key in EFFECT_TYPE_NAMES:
		if EFFECT_TYPE_NAMES[key] == effect_str:
			return key
	return -1

## 字符串转换为触发类型枚举
static func string_to_trigger_type(trigger_str: String) -> int:
	for key in TRIGGER_TYPE_NAMES:
		if TRIGGER_TYPE_NAMES[key] == trigger_str:
			return key
	return -1

## 字符串转换为条件类型枚举
static func string_to_condition_type(condition_str: String) -> int:
	for key in CONDITION_TYPE_NAMES:
		if CONDITION_TYPE_NAMES[key] == condition_str:
			return key
	return -1

## 检查效果类型是否有效
static func is_valid_effect_type(effect_type) -> bool:
	if effect_type is String:
		return get_effect_type_names().has(effect_type)
	return is_valid_enum_value(EffectType, effect_type)

## 检查触发条件是否有效
static func is_valid_trigger_type(trigger) -> bool:
	if trigger is String:
		return get_trigger_type_names().has(trigger)
	return is_valid_enum_value(TriggerType, trigger)

## 检查条件类型是否有效
static func is_valid_condition_type(condition) -> bool:
	if condition is String:
		return get_condition_type_names().has(condition)
	return is_valid_enum_value(ConditionType, condition)

## 获取效果类型的描述
static func get_effect_type_description(effect_type) -> String:
	var type_enum = effect_type
	if effect_type is String:
		type_enum = string_to_effect_type(effect_type)
	
	match type_enum:
		EffectType.STAT_BOOST: return "提升属性值"
		EffectType.DAMAGE: return "造成伤害"
		EffectType.HEAL: return "恢复生命值"
		EffectType.GOLD: return "获得金币"
		EffectType.SHOP: return "商店相关效果"
		EffectType.SYNERGY: return "羁绊相关效果"
		EffectType.SPECIAL: return "特殊效果"
		EffectType.STATUS: return "状态效果"
		EffectType.MOVEMENT: return "移动效果"
		EffectType.VISUAL: return "视觉效果"
		EffectType.SOUND: return "音效"
		_: return "未知效果"

## 获取触发条件的描述
static func get_trigger_type_description(trigger_type) -> String:
	var type_enum = trigger_type
	if trigger_type is String:
		type_enum = string_to_trigger_type(trigger_type)
	
	match type_enum:
		TriggerType.PASSIVE: return "被动效果"
		TriggerType.ON_ACQUIRE: return "获取时触发"
		TriggerType.ON_ROUND_START: return "回合开始时触发"
		TriggerType.ON_ROUND_END: return "回合结束时触发"
		TriggerType.ON_BATTLE_START: return "战斗开始时触发"
		TriggerType.ON_BATTLE_END: return "战斗结束时触发"
		TriggerType.ON_BATTLE_VICTORY: return "战斗胜利时触发"
		TriggerType.ON_BATTLE_DEFEAT: return "战斗失败时触发"
		TriggerType.ON_ACTIVATE: return "主动激活时触发"
		TriggerType.ON_ATTACK: return "攻击时触发"
		TriggerType.ON_HIT: return "受到伤害时触发"
		TriggerType.ON_ABILITY: return "使用技能时触发"
		TriggerType.ON_CRIT: return "暴击时触发"
		TriggerType.ON_DODGE: return "闪避时触发"
		TriggerType.ON_DAMAGE: return "造成伤害时触发"
		TriggerType.ON_LOW_HEALTH: return "低生命值时触发"
		TriggerType.ON_EVENT_COMPLETED: return "事件完成时触发"
		TriggerType.ON_MAP_NODE_SELECTED: return "地图节点选择时触发"
		_: return "未知触发条件"

## 创建效果数据
static func create_effect_data(effect_type, value = 0, trigger = null, description = "") -> Dictionary:
	# 处理效果类型
	var type_enum = effect_type
	if effect_type is String:
		type_enum = string_to_effect_type(effect_type)
		if type_enum == -1:
			type_enum = EffectType.SPECIAL
	
	# 处理触发条件
	var trigger_enum = trigger if trigger != null else get_default_trigger_for_effect(type_enum)
	if trigger is String:
		trigger_enum = string_to_trigger_type(trigger)
		if trigger_enum == -1:
			trigger_enum = TriggerType.PASSIVE
	
	# 创建效果数据
	var effect_data = {
		"type": EFFECT_TYPE_NAMES[type_enum],
		"value": value,
		"trigger": TRIGGER_TYPE_NAMES[trigger_enum],
		"description": description if description else get_effect_type_description(type_enum)
	}
	
	return effect_data
