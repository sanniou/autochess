extends BaseConstants
class_name GameConstants
## 游戏全局常量
## 定义游戏中通用的常量，如稀有度、属性类型等

## 稀有度
enum Rarity {
	COMMON = 0,    # 普通
	UNCOMMON = 1,  # 优秀
	RARE = 2,      # 稀有
	EPIC = 3,      # 史诗
	LEGENDARY = 4  # 传说
}

## 稀有度名称
static var RARITY_NAMES = {
	Rarity.COMMON: "普通",
	Rarity.UNCOMMON: "优秀",
	Rarity.RARE: "稀有",
	Rarity.EPIC: "史诗",
	Rarity.LEGENDARY: "传说"
}

## 稀有度颜色
static var RARITY_COLORS = {
	Rarity.COMMON: Color(0.8, 0.8, 0.8, 1.0),     # 灰白色
	Rarity.UNCOMMON: Color(0.2, 0.8, 0.2, 1.0),   # 绿色
	Rarity.RARE: Color(0.2, 0.6, 1.0, 1.0),       # 蓝色
	Rarity.EPIC: Color(0.8, 0.4, 1.0, 1.0),       # 紫色
	Rarity.LEGENDARY: Color(1.0, 0.8, 0.2, 1.0)   # 金色
}

## 伤害类型
enum DamageType {
	PHYSICAL,   # 物理伤害
	MAGICAL,    # 魔法伤害
	TRUE,       # 真实伤害
	FIRE,       # 火焰伤害
	ICE,        # 冰冻伤害
	LIGHTNING,  # 闪电伤害
	POISON      # 毒素伤害
}

## 伤害类型名称
static var DAMAGE_TYPE_NAMES = {
	DamageType.PHYSICAL: "物理",
	DamageType.MAGICAL: "魔法",
	DamageType.TRUE: "真实",
	DamageType.FIRE: "火焰",
	DamageType.ICE: "冰冻",
	DamageType.LIGHTNING: "闪电",
	DamageType.POISON: "毒素"
}

## 伤害类型颜色
static var DAMAGE_TYPE_COLORS = {
	DamageType.PHYSICAL: Color(0.8, 0.2, 0.2, 0.8),  # 红色
	DamageType.MAGICAL: Color(0.2, 0.2, 0.8, 0.8),   # 蓝色
	DamageType.TRUE: Color(0.8, 0.8, 0.2, 0.8),      # 黄色
	DamageType.FIRE: Color(0.8, 0.4, 0.0, 0.8),      # 橙色
	DamageType.ICE: Color(0.0, 0.8, 0.8, 0.8),       # 青色
	DamageType.LIGHTNING: Color(0.8, 0.8, 0.0, 0.8), # 黄色
	DamageType.POISON: Color(0.0, 0.8, 0.0, 0.8)     # 绿色
}

## 获取所有稀有度
static func get_all_rarities() -> Array:
	return get_enum_values(Rarity)

## 获取稀有度名称
static func get_rarity_name(rarity: int) -> String:
	return RARITY_NAMES.get(rarity, "未知")

## 获取稀有度颜色
static func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

## 检查稀有度是否有效
static func is_valid_rarity(rarity: int) -> bool:
	return is_valid_enum_value(Rarity, rarity)

## 获取按等级可用的稀有度
static func get_rarities_by_level(level: int) -> Array:
	var rarities = [Rarity.COMMON]
	
	if level >= 2:
		rarities.append(Rarity.UNCOMMON)
	if level >= 4:
		rarities.append(Rarity.RARE)
	if level >= 6:
		rarities.append(Rarity.EPIC)
	if level >= 8:
		rarities.append(Rarity.LEGENDARY)
	
	return rarities

## 获取所有伤害类型
static func get_all_damage_types() -> Array:
	return get_enum_values(DamageType)

## 获取伤害类型名称
static func get_damage_type_name(damage_type: int) -> String:
	return DAMAGE_TYPE_NAMES.get(damage_type, "未知")

## 获取伤害类型颜色
static func get_damage_type_color(damage_type: int) -> Color:
	return DAMAGE_TYPE_COLORS.get(damage_type, Color.WHITE)

## 检查伤害类型是否有效
static func is_valid_damage_type(damage_type: int) -> bool:
	return is_valid_enum_value(DamageType, damage_type)
