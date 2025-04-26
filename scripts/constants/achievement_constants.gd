extends RefCounted
class_name AchievementConstants
## 成就系统常量
## 定义成就系统中使用的所有枚举和常量

## 成就类型枚举
enum Type {
	CHESS,           # 棋子相关
	CHESS_STAR,      # 棋子星级相关
	VICTORY,         # 胜利相关
	BATTLE,          # 战斗相关
	EVENT,           # 事件相关
	RELIC,           # 遗物相关
	GOLD,            # 金币相关
	BOARD,           # 棋盘相关
	SYNERGY,         # 羁绊相关
	STREAK,          # 连胜相关
	EQUIPMENT,       # 装备相关
	ACHIEVEMENT,     # 成就相关（如完美主义者）
	STAT             # 统计数据相关
}

## 成就类别枚举
enum Category {
	GAMEPLAY,        # 游戏玩法
	COLLECTION,      # 收集
	CHALLENGE,       # 挑战
	STORY,           # 故事
	SECRET           # 秘密
}

## 成就类型字符串映射
static var TYPE_STRINGS = {
	Type.CHESS: "chess",
	Type.CHESS_STAR: "chess_star",
	Type.VICTORY: "victory",
	Type.BATTLE: "battle",
	Type.EVENT: "event",
	Type.RELIC: "relic",
	Type.GOLD: "gold",
	Type.BOARD: "board",
	Type.SYNERGY: "synergy",
	Type.STREAK: "streak",
	Type.EQUIPMENT: "equipment",
	Type.ACHIEVEMENT: "achievement",
	Type.STAT: "stat"
}

## 成就类别字符串映射
static var CATEGORY_STRINGS = {
	Category.GAMEPLAY: "gameplay",
	Category.COLLECTION: "collection",
	Category.CHALLENGE: "challenge",
	Category.STORY: "story",
	Category.SECRET: "secret"
}

## 从字符串获取成就类型枚举
static func get_type_from_string(type_str: String) -> int:
	for type_enum in TYPE_STRINGS:
		if TYPE_STRINGS[type_enum] == type_str:
			return type_enum
	return -1

## 从字符串获取成就类别枚举
static func get_category_from_string(category_str: String) -> int:
	for category_enum in CATEGORY_STRINGS:
		if CATEGORY_STRINGS[category_enum] == category_str:
			return category_enum
	return -1

## 获取成就类型字符串
static func get_type_string(type_enum: int) -> String:
	return TYPE_STRINGS.get(type_enum, "unknown")

## 获取成就类别字符串
static func get_category_string(category_enum: int) -> String:
	return CATEGORY_STRINGS.get(category_enum, "unknown")
