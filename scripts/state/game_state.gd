extends RefCounted
class_name GameState
## 游戏状态类
## 定义游戏状态的结构和默认值

# 类型定义
## 游戏状态类型
class GameStateType:
	var current_state: int
	var current_phase: int
	var is_paused: bool
	var current_round: int
	var difficulty_level: int
	var is_game_over: bool
	var win: bool
	var seed: int
	var game_mode: String
	var start_time: int
	var play_time: int

## 玩家状态类型
class PlayerStateType:
	var health: int
	var max_health: int
	var gold: int
	var level: int
	var experience: int
	var experience_to_level: int
	var relics: Array
	var equipment: Array
	var battle_history: Array
	var win_streak: int
	var lose_streak: int

## 棋盘状态类型
class BoardStateType:
	var size: Vector2i
	var pieces: Dictionary
	var locked: bool
	var battle_in_progress: bool
	var battle_id: String
	var synergies: Dictionary

## 商店状态类型
class ShopStateType:
	var is_open: bool
	var items: Array
	var locked_items: Array
	var refresh_cost: int
	var tier: int
	var tier_chances: Dictionary

## 地图状态类型
class MapStateType:
	var nodes: Dictionary
	var edges: Array
	var current_node: String
	var available_nodes: Array
	var visited_nodes: Array
	var level: int
	var max_level: int

## UI状态类型
class UIStateType:
	var current_screen: String
	var open_windows: Array
	var selected_item: String
	var drag_item: String
	var tooltip: Dictionary
	var notifications: Array

## 设置状态类型
class SettingsStateType:
	var volume: Dictionary
	var fullscreen: bool
	var vsync: bool
	var language: String
	var show_fps: bool
	var particle_quality: int
	var ui_scale: float

## 成就状态类型
class AchievementsStateType:
	var unlocked: Array
	var progress: Dictionary

## 统计状态类型
class StatsStateType:
	var games_played: int
	var games_won: int
	var win_rate: float
	var total_gold_earned: int
	var total_damage_dealt: int
	var total_damage_taken: int
	var total_healing: int
	var chess_pieces_bought: Dictionary
	var chess_pieces_3star: Dictionary
	var synergies_activated: Dictionary

## 应用状态类型
class AppStateType:
	var game: Dictionary
	var player: Dictionary
	var board: Dictionary
	var shop: Dictionary
	var map: Dictionary
	var ui: Dictionary
	var settings: Dictionary
	var achievements: Dictionary
	var stats: Dictionary

# 游戏状态枚举
enum State {
	NONE,           # 初始状态
	MAIN_MENU,      # 主菜单
	MAP,            # 地图界面
	BATTLE,         # 战斗界面
	SHOP,           # 商店界面
	EVENT,          # 事件界面
	ALTAR,          # 祭坛界面
	BLACKSMITH,     # 铁匠铺界面
	GAME_OVER,      # 游戏结束
	VICTORY         # 游戏胜利
}

# 游戏阶段枚举
enum Phase {
	PREPARATION,    # 准备阶段
	BATTLE,         # 战斗阶段
	SHOPPING,       # 购物阶段
	MAP,            # 地图阶段
	EVENT           # 事件阶段
}

# 创建默认游戏状态
static func create_default() -> Dictionary:
	return {
		"current_state": State.NONE,
		"current_phase": Phase.PREPARATION,
		"is_paused": false,
		"current_round": 0,
		"difficulty_level": 1,
		"is_game_over": false,
		"win": false,
		"seed": 0,
		"game_mode": "standard",
		"start_time": 0,
		"play_time": 0
	}

# 创建默认玩家状态
static func create_default_player() -> Dictionary:
	return {
		"health": 100,
		"max_health": 100,
		"gold": 0,
		"level": 1,
		"experience": 0,
		"experience_to_level": 2,
		"relics": [],
		"equipment": [],
		"battle_history": [],
		"total_wins": 0,
		"total_losses": 0,
		"win_streak": 0,
		"lose_streak": 0
	}

# 创建默认棋盘状态
static func create_default_board() -> Dictionary:
	return {
		"size": Vector2i(8, 8),
		"pieces": {},
		"locked": false,
		"battle_in_progress": false,
		"battle_id": "",
		"synergies": {}
	}

# 创建默认商店状态
static func create_default_shop() -> Dictionary:
	return {
		"is_open": false,
		"items": [],
		"locked_items": [],
		"refresh_cost": 2,
		"tier": 1,
		"tier_chances": {
			"1": 100,
			"2": 0,
			"3": 0,
			"4": 0,
			"5": 0
		}
	}

# 创建默认地图状态
static func create_default_map() -> Dictionary:
	return {
		"nodes": {},
		"edges": [],
		"current_node": "",
		"available_nodes": [],
		"visited_nodes": [],
		"level": 1,
		"max_level": 8
	}

# 创建默认UI状态
static func create_default_ui() -> Dictionary:
	return {
		"current_screen": "main_menu",
		"open_windows": [],
		"selected_item": "",
		"drag_item": "",
		"tooltip": {
			"text": "",
			"visible": false
		},
		"notifications": []
	}

# 创建默认设置状态
static func create_default_settings() -> Dictionary:
	return {
		"volume": {
			"master": 1.0,
			"music": 0.8,
			"sfx": 0.8,
			"ui": 0.8
		},
		"fullscreen": false,
		"vsync": true,
		"language": "zh_CN",
		"show_fps": false,
		"particle_quality": 2,
		"ui_scale": 1.0
	}

# 创建默认成就状态
static func create_default_achievements() -> Dictionary:
	return {
		"unlocked": [],
		"progress": {}
	}

# 创建默认统计状态
static func create_default_stats() -> Dictionary:
	return {
		# 游戏统计
		"games_played": 0,
		"games_won": 0,
		"games_lost": 0,
		"win_rate": 0.0,
		"total_play_time": 0,

		# 战斗统计
		"battles_played": 0,
		"battles_won": 0,
		"battles_lost": 0,
		"total_damage_dealt": 0,
		"total_damage_taken": 0,
		"total_healing": 0,
		"highest_damage": 0,

		# 经济统计
		"total_gold_earned": 0,
		"total_gold_spent": 0,
		"items_purchased": 0,
		"items_sold": 0,
		"shop_refreshes": 0,

		# 棋子统计
		"chess_pieces_purchased": 0,
		"chess_pieces_sold": 0,
		"chess_pieces_upgraded": 0,
		"chess_pieces_bought": {},  # 按棋子ID记录
		"chess_pieces_3star": {},   # 按棋子ID记录

		# 装备统计
		"equipments_purchased": 0,
		"equipments_sold": 0,

		# 羁结统计
		"synergies_activated": {},  # 按羁结ID记录

		# 其他统计
		"exp_purchased": 0,
		"start_time": 0            # 会话统计用，不保存
	}

# 创建完整的默认状态
static func create_default_state() -> Dictionary:
	return {
		"game": create_default(),
		"player": create_default_player(),
		"board": create_default_board(),
		"shop": create_default_shop(),
		"map": create_default_map(),
		"ui": create_default_ui(),
		"settings": create_default_settings(),
		"achievements": create_default_achievements(),
		"stats": create_default_stats()
	}

# 验证状态
static func validate_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["game", "player", "board", "shop", "map", "ui", "settings", "achievements", "stats"]
	for field in required_fields:
		if not state.has(field) or not state[field] is Dictionary:
			return false

	# 验证各个子状态
	return validate_game_state(state.game) and \
		validate_player_state(state.player) and \
		validate_board_state(state.board) and \
		validate_shop_state(state.shop) and \
		validate_map_state(state.map) and \
		validate_ui_state(state.ui) and \
		validate_settings_state(state.settings) and \
		validate_achievements_state(state.achievements) and \
		validate_stats_state(state.stats)

# 验证游戏状态
static func validate_game_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["current_state", "current_phase", "is_paused", "current_round", "difficulty_level", "is_game_over"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.current_state is int or \
		not state.current_phase is int or \
		not state.is_paused is bool or \
		not state.current_round is int or \
		not state.difficulty_level is int or \
		not state.is_game_over is bool:
		return false

	return true

# 验证玩家状态
static func validate_player_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["health", "max_health", "gold", "level", "experience"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.health is int or \
		not state.max_health is int or \
		not state.gold is int or \
		not state.level is int or \
		not state.experience is int:
		return false

	return true

# 验证棋盘状态
static func validate_board_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["pieces", "locked", "battle_in_progress"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.pieces is Dictionary or \
		not state.locked is bool or \
		not state.battle_in_progress is bool:
		return false

	return true

# 验证商店状态
static func validate_shop_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["is_open", "items", "refresh_cost"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.is_open is bool or \
		not state.items is Array or \
		not state.refresh_cost is int:
		return false

	return true

# 验证地图状态
static func validate_map_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["nodes", "edges", "current_node", "visited_nodes"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.nodes is Dictionary or \
		not state.edges is Array or \
		not state.current_node is String or \
		not state.visited_nodes is Array:
		return false

	return true

# 验证UI状态
static func validate_ui_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["current_screen", "open_windows"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.current_screen is String or \
		not state.open_windows is Array:
		return false

	return true

# 验证设置状态
static func validate_settings_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["volume", "fullscreen", "language"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.volume is Dictionary or \
		not state.fullscreen is bool or \
		not state.language is String:
		return false

	return true

# 验证成就状态
static func validate_achievements_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["unlocked", "progress"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.unlocked is Array or \
		not state.progress is Dictionary:
		return false

	return true

# 验证统计状态
static func validate_stats_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false

	# 检查必要的字段
	var required_fields = ["games_played", "games_won"]
	for field in required_fields:
		if not state.has(field):
			return false

	# 检查字段类型
	if not state.games_played is int or \
		not state.games_won is int:
		return false

	return true
