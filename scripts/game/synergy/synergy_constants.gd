extends Node
class_name SynergyConstants
## 羁绊系统常量
## 定义羁绊系统中使用的所有枚举和常量

## 羁绊类型
enum SynergyType {
	CLASS,   # 职业羁绊
	RACE,    # 种族羁绊
	SPECIAL  # 特殊羁绊
}

## 羁绊效果类型
enum EffectType {
	ATTRIBUTE,         # 属性效果
	ABILITY,           # 技能效果
	SPECIAL,           # 特殊效果
	CRIT,              # 暴击效果
	DODGE,             # 闪避效果
	ELEMENTAL_EFFECT,  # 元素效果
	COOLDOWN_REDUCTION,# 冷却减少
	SPELL_AMP,         # 法术增强
	DOUBLE_ATTACK,     # 双重攻击
	SUMMON_BOOST,      # 召唤物增强
	TEAM_BUFF,         # 团队增益
	STAT_BOOST         # 属性增益
}

## 目标选择器类型
enum TargetSelector {
	SAME_SYNERGY,      # 同羁绊棋子
	ALL_PLAYER_PIECES, # 所有玩家棋子
	RANDOM,            # 随机棋子
	HIGHEST_ATTRIBUTE, # 特定属性最高的棋子
	LOWEST_ATTRIBUTE,  # 特定属性最低的棋子
	CUSTOM             # 自定义选择器
}

## 将字符串转换为羁绊类型枚举
static func string_to_synergy_type(type_string: String) -> int:
	match type_string.to_lower():
		"class":
			return SynergyType.CLASS
		"race":
			return SynergyType.RACE
		"special":
			return SynergyType.SPECIAL
		_:
			push_error("无效的羁绊类型字符串: " + type_string)
			return SynergyType.SPECIAL # 默认返回特殊类型

## 将羁绊类型枚举转换为字符串
static func synergy_type_to_string(type_enum: int) -> String:
	match type_enum:
		SynergyType.CLASS:
			return "class"
		SynergyType.RACE:
			return "race"
		SynergyType.SPECIAL:
			return "special"
		_:
			push_error("无效的羁绊类型枚举: " + str(type_enum))
			return "special" # 默认返回特殊类型

## 将字符串转换为效果类型枚举
static func string_to_effect_type(type_string: String) -> int:
	match type_string.to_lower():
		"attribute":
			return EffectType.ATTRIBUTE
		"ability":
			return EffectType.ABILITY
		"special":
			return EffectType.SPECIAL
		"crit":
			return EffectType.CRIT
		"dodge":
			return EffectType.DODGE
		"elemental_effect":
			return EffectType.ELEMENTAL_EFFECT
		"cooldown_reduction":
			return EffectType.COOLDOWN_REDUCTION
		"spell_amp":
			return EffectType.SPELL_AMP
		"double_attack":
			return EffectType.DOUBLE_ATTACK
		"summon_boost":
			return EffectType.SUMMON_BOOST
		"team_buff":
			return EffectType.TEAM_BUFF
		"stat_boost":
			return EffectType.STAT_BOOST
		_:
			push_error("无效的效果类型字符串: " + type_string)
			return EffectType.SPECIAL # 默认返回特殊效果

## 将效果类型枚举转换为字符串
static func effect_type_to_string(type_enum: int) -> String:
	match type_enum:
		EffectType.ATTRIBUTE:
			return "attribute"
		EffectType.ABILITY:
			return "ability"
		EffectType.SPECIAL:
			return "special"
		EffectType.CRIT:
			return "crit"
		EffectType.DODGE:
			return "dodge"
		EffectType.ELEMENTAL_EFFECT:
			return "elemental_effect"
		EffectType.COOLDOWN_REDUCTION:
			return "cooldown_reduction"
		EffectType.SPELL_AMP:
			return "spell_amp"
		EffectType.DOUBLE_ATTACK:
			return "double_attack"
		EffectType.SUMMON_BOOST:
			return "summon_boost"
		EffectType.TEAM_BUFF:
			return "team_buff"
		EffectType.STAT_BOOST:
			return "stat_boost"
		_:
			push_error("无效的效果类型枚举: " + str(type_enum))
			return "special" # 默认返回特殊效果

## 将字符串转换为目标选择器枚举
static func string_to_target_selector(selector_string: String) -> int:
	match selector_string.to_lower():
		"same_synergy":
			return TargetSelector.SAME_SYNERGY
		"all_player_pieces":
			return TargetSelector.ALL_PLAYER_PIECES
		"random":
			return TargetSelector.RANDOM
		"highest_attribute":
			return TargetSelector.HIGHEST_ATTRIBUTE
		"lowest_attribute":
			return TargetSelector.LOWEST_ATTRIBUTE
		"custom":
			return TargetSelector.CUSTOM
		_:
			push_error("无效的目标选择器字符串: " + selector_string)
			return TargetSelector.SAME_SYNERGY # 默认返回同羁绊选择器

## 将目标选择器枚举转换为字符串
static func target_selector_to_string(selector_enum: int) -> String:
	match selector_enum:
		TargetSelector.SAME_SYNERGY:
			return "same_synergy"
		TargetSelector.ALL_PLAYER_PIECES:
			return "all_player_pieces"
		TargetSelector.RANDOM:
			return "random"
		TargetSelector.HIGHEST_ATTRIBUTE:
			return "highest_attribute"
		TargetSelector.LOWEST_ATTRIBUTE:
			return "lowest_attribute"
		TargetSelector.CUSTOM:
			return "custom"
		_:
			push_error("无效的目标选择器枚举: " + str(selector_enum))
			return "same_synergy" # 默认返回同羁绊选择器
