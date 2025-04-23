extends Object
class_name ConfigTypes
## 配置类型枚举
## 定义所有可用的配置类型，用于类型安全的配置访问

enum Type {
	CHESS_PIECES,      # 棋子配置
	EQUIPMENT,         # 装备配置
	MAP_CONFIG,        # 地图配置
	RELICS,            # 遗物配置
	SYNERGIES,         # 羁绊配置
	EVENTS,            # 事件配置
	DIFFICULTY,        # 难度配置
	ACHIEVEMENTS,      # 成就配置
	SKINS,             # 皮肤配置
	TUTORIALS,         # 教程配置
	ANIMATION_CONFIG,  # 动画配置
	ENVIRONMENT_EFFECTS, # 环境效果配置
	SKILL_EFFECTS,     # 技能效果配置
	BOARD_SKINS,       # 棋盘皮肤配置
	CHESS_SKINS,       # 棋子皮肤配置
	UI_SKINS,          # UI皮肤配置
}

## 将枚举值转换为字符串
static func int_to_string(type: int) -> String:
	match type:
		Type.CHESS_PIECES: return "chess_pieces"
		Type.EQUIPMENT: return "equipment"
		Type.MAP_CONFIG: return "map_config"
		Type.RELICS: return "relics"
		Type.SYNERGIES: return "synergies"
		Type.EVENTS: return "events"
		Type.DIFFICULTY: return "difficulty"
		Type.ACHIEVEMENTS: return "achievements"
		Type.SKINS: return "skins"
		Type.TUTORIALS: return "tutorials"
		Type.ANIMATION_CONFIG: return "animation_config"
		Type.ENVIRONMENT_EFFECTS: return "environment_effects"
		Type.SKILL_EFFECTS: return "skill_effects"
		Type.BOARD_SKINS: return "board_skins"
		Type.CHESS_SKINS: return "chess_skins"
		Type.UI_SKINS: return "ui_skins"
		_: return "unknown"

## 将字符串转换为枚举值
static func from_string(type_str: String) -> int:
	match type_str:
		"chess_pieces": return Type.CHESS_PIECES
		"equipment": return Type.EQUIPMENT
		"map_config": return Type.MAP_CONFIG
		"relics": return Type.RELICS
		"synergies": return Type.SYNERGIES
		"events": return Type.EVENTS
		"difficulty": return Type.DIFFICULTY
		"achievements": return Type.ACHIEVEMENTS
		"skins": return Type.SKINS
		"tutorials": return Type.TUTORIALS
		"animation_config": return Type.ANIMATION_CONFIG
		"environment_effects": return Type.ENVIRONMENT_EFFECTS
		"skill_effects": return Type.SKILL_EFFECTS
		"board_skins": return Type.BOARD_SKINS
		"chess_skins": return Type.CHESS_SKINS
		"ui_skins": return Type.UI_SKINS
		_: return -1
