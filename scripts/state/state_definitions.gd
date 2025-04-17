extends Node
class_name StateDefinitions
## 状态定义
## 集中定义所有状态类型和结构

## 游戏状态
class GameState:
	var current_level: int = 1
	var difficulty: int = 1
	var game_mode: String = "standard"
	var is_paused: bool = false
	var is_game_over: bool = false
	var win_condition: String = "standard"
	var current_turn: int = 1
	var current_phase: String = "preparation"
	var seed_value: int = 0
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"current_level": current_level,
			"difficulty": difficulty,
			"game_mode": game_mode,
			"is_paused": is_paused,
			"is_game_over": is_game_over,
			"win_condition": win_condition,
			"current_turn": current_turn,
			"current_phase": current_phase,
			"seed_value": seed_value
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("current_level"): current_level = data.current_level
		if data.has("difficulty"): difficulty = data.difficulty
		if data.has("game_mode"): game_mode = data.game_mode
		if data.has("is_paused"): is_paused = data.is_paused
		if data.has("is_game_over"): is_game_over = data.is_game_over
		if data.has("win_condition"): win_condition = data.win_condition
		if data.has("current_turn"): current_turn = data.current_turn
		if data.has("current_phase"): current_phase = data.current_phase
		if data.has("seed_value"): seed_value = data.seed_value

## 玩家状态
class PlayerState:
	var health: int = 100
	var max_health: int = 100
	var gold: int = 0
	var experience: int = 0
	var level: int = 1
	var relics: Array = []
	var win_streak: int = 0
	var lose_streak: int = 0
	var total_wins: int = 0
	var total_losses: int = 0
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"health": health,
			"max_health": max_health,
			"gold": gold,
			"experience": experience,
			"level": level,
			"relics": relics.duplicate(),
			"win_streak": win_streak,
			"lose_streak": lose_streak,
			"total_wins": total_wins,
			"total_losses": total_losses
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("health"): health = data.health
		if data.has("max_health"): max_health = data.max_health
		if data.has("gold"): gold = data.gold
		if data.has("experience"): experience = data.experience
		if data.has("level"): level = data.level
		if data.has("relics"): relics = data.relics.duplicate()
		if data.has("win_streak"): win_streak = data.win_streak
		if data.has("lose_streak"): lose_streak = data.lose_streak
		if data.has("total_wins"): total_wins = data.total_wins
		if data.has("total_losses"): total_losses = data.total_losses

## 棋盘状态
class BoardState:
	var size: Vector2i = Vector2i(8, 8)
	var pieces: Dictionary = {}  # 位置 -> 棋子ID
	var locked: bool = false
	var battle_in_progress: bool = false
	var current_battle_id: String = ""
	var synergies: Dictionary = {}  # 羁绊ID -> 激活等级
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"size": {"x": size.x, "y": size.y},
			"pieces": pieces.duplicate(),
			"locked": locked,
			"battle_in_progress": battle_in_progress,
			"current_battle_id": current_battle_id,
			"synergies": synergies.duplicate()
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("size"): 
			size = Vector2i(data.size.x, data.size.y)
		if data.has("pieces"): pieces = data.pieces.duplicate()
		if data.has("locked"): locked = data.locked
		if data.has("battle_in_progress"): battle_in_progress = data.battle_in_progress
		if data.has("current_battle_id"): current_battle_id = data.current_battle_id
		if data.has("synergies"): synergies = data.synergies.duplicate()

## 商店状态
class ShopState:
	var is_open: bool = false
	var current_items: Array = []
	var refresh_cost: int = 2
	var refresh_count: int = 0
	var shop_tier: int = 1
	var locked_items: Array = []
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"is_open": is_open,
			"current_items": current_items.duplicate(),
			"refresh_cost": refresh_cost,
			"refresh_count": refresh_count,
			"shop_tier": shop_tier,
			"locked_items": locked_items.duplicate()
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("is_open"): is_open = data.is_open
		if data.has("current_items"): current_items = data.current_items.duplicate()
		if data.has("refresh_cost"): refresh_cost = data.refresh_cost
		if data.has("refresh_count"): refresh_count = data.refresh_count
		if data.has("shop_tier"): shop_tier = data.shop_tier
		if data.has("locked_items"): locked_items = data.locked_items.duplicate()

## 地图状态
class MapState:
	var current_map: Dictionary = {}
	var current_node: String = ""
	var visited_nodes: Array = []
	var available_nodes: Array = []
	var map_level: int = 1
	var map_seed: int = 0
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"current_map": current_map.duplicate(),
			"current_node": current_node,
			"visited_nodes": visited_nodes.duplicate(),
			"available_nodes": available_nodes.duplicate(),
			"map_level": map_level,
			"map_seed": map_seed
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("current_map"): current_map = data.current_map.duplicate()
		if data.has("current_node"): current_node = data.current_node
		if data.has("visited_nodes"): visited_nodes = data.visited_nodes.duplicate()
		if data.has("available_nodes"): available_nodes = data.available_nodes.duplicate()
		if data.has("map_level"): map_level = data.map_level
		if data.has("map_seed"): map_seed = data.map_seed

## UI状态
class UIState:
	var current_screen: String = "main_menu"
	var open_windows: Array = []
	var selected_item: String = ""
	var drag_item: String = ""
	var tooltip_text: String = ""
	var show_tooltip: bool = false
	var notification_queue: Array = []
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"current_screen": current_screen,
			"open_windows": open_windows.duplicate(),
			"selected_item": selected_item,
			"drag_item": drag_item,
			"tooltip_text": tooltip_text,
			"show_tooltip": show_tooltip,
			"notification_queue": notification_queue.duplicate()
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("current_screen"): current_screen = data.current_screen
		if data.has("open_windows"): open_windows = data.open_windows.duplicate()
		if data.has("selected_item"): selected_item = data.selected_item
		if data.has("drag_item"): drag_item = data.drag_item
		if data.has("tooltip_text"): tooltip_text = data.tooltip_text
		if data.has("show_tooltip"): show_tooltip = data.show_tooltip
		if data.has("notification_queue"): notification_queue = data.notification_queue.duplicate()

## 设置状态
class SettingsState:
	var music_volume: float = 1.0
	var sfx_volume: float = 1.0
	var master_volume: float = 1.0
	var fullscreen: bool = false
	var language: String = "zh_CN"
	var show_fps: bool = false
	var vsync_enabled: bool = true
	var particle_quality: int = 2  # 0=低, 1=中, 2=高
	var ui_scale: float = 1.0
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"master_volume": master_volume,
			"fullscreen": fullscreen,
			"language": language,
			"show_fps": show_fps,
			"vsync_enabled": vsync_enabled,
			"particle_quality": particle_quality,
			"ui_scale": ui_scale
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("music_volume"): music_volume = data.music_volume
		if data.has("sfx_volume"): sfx_volume = data.sfx_volume
		if data.has("master_volume"): master_volume = data.master_volume
		if data.has("fullscreen"): fullscreen = data.fullscreen
		if data.has("language"): language = data.language
		if data.has("show_fps"): show_fps = data.show_fps
		if data.has("vsync_enabled"): vsync_enabled = data.vsync_enabled
		if data.has("particle_quality"): particle_quality = data.particle_quality
		if data.has("ui_scale"): ui_scale = data.ui_scale

## 成就状态
class AchievementState:
	var unlocked_achievements: Dictionary = {}  # 成就ID -> 解锁时间
	var achievement_progress: Dictionary = {}  # 成就ID -> 进度值
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"unlocked_achievements": unlocked_achievements.duplicate(),
			"achievement_progress": achievement_progress.duplicate()
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("unlocked_achievements"): unlocked_achievements = data.unlocked_achievements.duplicate()
		if data.has("achievement_progress"): achievement_progress = data.achievement_progress.duplicate()

## 统计状态
class StatsState:
	var games_played: int = 0
	var games_won: int = 0
	var games_lost: int = 0
	var total_gold_earned: int = 0
	var total_damage_dealt: int = 0
	var total_damage_taken: int = 0
	var total_healing: int = 0
	var chess_pieces_bought: Dictionary = {}  # 棋子ID -> 数量
	var chess_pieces_3star: Dictionary = {}  # 棋子ID -> 数量
	var synergies_activated: Dictionary = {}  # 羁绊ID -> 次数
	
	func _init(data: Dictionary = {}):
		from_dictionary(data)
	
	func to_dictionary() -> Dictionary:
		return {
			"games_played": games_played,
			"games_won": games_won,
			"games_lost": games_lost,
			"total_gold_earned": total_gold_earned,
			"total_damage_dealt": total_damage_dealt,
			"total_damage_taken": total_damage_taken,
			"total_healing": total_healing,
			"chess_pieces_bought": chess_pieces_bought.duplicate(),
			"chess_pieces_3star": chess_pieces_3star.duplicate(),
			"synergies_activated": synergies_activated.duplicate()
		}
	
	func from_dictionary(data: Dictionary) -> void:
		if data.has("games_played"): games_played = data.games_played
		if data.has("games_won"): games_won = data.games_won
		if data.has("games_lost"): games_lost = data.games_lost
		if data.has("total_gold_earned"): total_gold_earned = data.total_gold_earned
		if data.has("total_damage_dealt"): total_damage_dealt = data.total_damage_dealt
		if data.has("total_damage_taken"): total_damage_taken = data.total_damage_taken
		if data.has("total_healing"): total_healing = data.total_healing
		if data.has("chess_pieces_bought"): chess_pieces_bought = data.chess_pieces_bought.duplicate()
		if data.has("chess_pieces_3star"): chess_pieces_3star = data.chess_pieces_3star.duplicate()
		if data.has("synergies_activated"): synergies_activated = data.synergies_activated.duplicate()

## 创建完整的应用状态
static func create_app_state() -> Dictionary:
	return {
		"game": GameState.new().to_dictionary(),
		"player": PlayerState.new().to_dictionary(),
		"board": BoardState.new().to_dictionary(),
		"shop": ShopState.new().to_dictionary(),
		"map": MapState.new().to_dictionary(),
		"ui": UIState.new().to_dictionary(),
		"settings": SettingsState.new().to_dictionary(),
		"achievements": AchievementState.new().to_dictionary(),
		"stats": StatsState.new().to_dictionary()
	}

## 从字典创建状态对象
static func create_state_from_dictionary(state_type: String, data: Dictionary):
	match state_type:
		"game": return GameState.new(data)
		"player": return PlayerState.new(data)
		"board": return BoardState.new(data)
		"shop": return ShopState.new(data)
		"map": return MapState.new(data)
		"ui": return UIState.new(data)
		"settings": return SettingsState.new(data)
		"achievements": return AchievementState.new(data)
		"stats": return StatsState.new(data)
		_: return null
