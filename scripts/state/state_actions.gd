extends Node
class_name StateActions
## 状态动作定义
## 集中定义所有可能的状态更新动作

## 基础动作类
class Action:
	var type: String

	func _init(action_type: String):
		type = action_type

	func to_dictionary() -> Dictionary:
		return {
			"type": type
		}

## 游戏状态动作
class GameActions:
	## 设置游戏难度
	class SetDifficulty extends Action:
		var difficulty: int

		func _init(difficulty_level: int):
			super._init("SET_DIFFICULTY")
			difficulty = difficulty_level

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["difficulty"] = difficulty
			return dict

	## 设置游戏模式
	class SetGameMode extends Action:
		var game_mode: String

		func _init(mode: String):
			super._init("SET_GAME_MODE")
			game_mode = mode

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["game_mode"] = game_mode
			return dict

	## 设置游戏暂停状态
	class SetPaused extends Action:
		var is_paused: bool

		func _init(paused: bool):
			super._init("SET_PAUSED")
			is_paused = paused

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["is_paused"] = is_paused
			return dict

	## 设置游戏结束状态
	class SetGameOver extends Action:
		var is_game_over: bool
		var win: bool

		func _init(game_over: bool, is_win: bool = false):
			super._init("SET_GAME_OVER")
			is_game_over = game_over
			win = is_win

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["is_game_over"] = is_game_over
			dict["win"] = win
			return dict

	## 进入下一回合
	class NextTurn extends Action:
		func _init():
			super._init("NEXT_TURN")

	## 设置游戏阶段
	class SetPhase extends Action:
		var phase: String

		func _init(game_phase: String):
			super._init("SET_PHASE")
			phase = game_phase

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["phase"] = phase
			return dict

	## 设置随机种子
	class SetSeed extends Action:
		var seed_value: int

		func _init(seed_val: int):
			super._init("SET_SEED")
			seed_value = seed_val

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["seed_value"] = seed_value
			return dict

	## 设置游戏状态
	class SetGameState extends Action:
		var state: int

		func _init(game_state: int):
			super._init("SET_GAME_STATE")
			state = game_state

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["state"] = state
			return dict

## 玩家状态动作
class PlayerActions:
	## 设置玩家生命值
	class SetHealth extends Action:
		var health: int

		func _init(health_value: int):
			super._init("SET_HEALTH")
			health = health_value

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["health"] = health
			return dict

	## 改变玩家生命值
	class ChangeHealth extends Action:
		var amount: int

		func _init(health_change: int):
			super._init("CHANGE_HEALTH")
			amount = health_change

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["amount"] = amount
			return dict

	## 设置玩家金币
	class SetGold extends Action:
		var gold: int

		func _init(gold_value: int):
			super._init("SET_GOLD")
			gold = gold_value

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["gold"] = gold
			return dict

	## 改变玩家金币
	class ChangeGold extends Action:
		var amount: int

		func _init(gold_change: int):
			super._init("CHANGE_GOLD")
			amount = gold_change

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["amount"] = amount
			return dict

	## 设置玩家经验
	class SetExperience extends Action:
		var experience: int

		func _init(exp_value: int):
			super._init("SET_EXPERIENCE")
			experience = exp_value

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["experience"] = experience
			return dict

	## 改变玩家经验
	class ChangeExperience extends Action:
		var amount: int

		func _init(exp_change: int):
			super._init("CHANGE_EXPERIENCE")
			amount = exp_change

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["amount"] = amount
			return dict

	## 添加遗物
	class AddRelic extends Action:
		var relic_id: String

		func _init(relic: String):
			super._init("ADD_RELIC")
			relic_id = relic

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["relic_id"] = relic_id
			return dict

	## 移除遗物
	class RemoveRelic extends Action:
		var relic_id: String

		func _init(relic: String):
			super._init("REMOVE_RELIC")
			relic_id = relic

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["relic_id"] = relic_id
			return dict

	## 记录战斗结果
	class RecordBattleResult extends Action:
		var win: bool

		func _init(is_win: bool):
			super._init("RECORD_BATTLE_RESULT")
			win = is_win

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["win"] = win
			return dict

## 棋盘状态动作
class BoardActions:
	## 设置棋盘大小
	class SetBoardSize extends Action:
		var size: Vector2i

		func _init(board_size: Vector2i):
			super._init("SET_BOARD_SIZE")
			size = board_size

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["size"] = {"x": size.x, "y": size.y}
			return dict

	## 放置棋子
	class PlacePiece extends Action:
		var piece_id: String
		var position: Vector2i

		func _init(piece: String, pos: Vector2i):
			super._init("PLACE_PIECE")
			piece_id = piece
			position = pos

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["piece_id"] = piece_id
			dict["position"] = {"x": position.x, "y": position.y}
			return dict

	## 移除棋子
	class RemovePiece extends Action:
		var position: Vector2i

		func _init(pos: Vector2i):
			super._init("REMOVE_PIECE")
			position = pos

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["position"] = {"x": position.x, "y": position.y}
			return dict

	## 移动棋子
	class MovePiece extends Action:
		var from_position: Vector2i
		var to_position: Vector2i

		func _init(from_pos: Vector2i, to_pos: Vector2i):
			super._init("MOVE_PIECE")
			from_position = from_pos
			to_position = to_pos

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["from_position"] = {"x": from_position.x, "y": from_position.y}
			dict["to_position"] = {"x": to_position.x, "y": to_position.y}
			return dict

	## 锁定棋盘
	class LockBoard extends Action:
		var locked: bool

		func _init(is_locked: bool):
			super._init("LOCK_BOARD")
			locked = is_locked

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["locked"] = locked
			return dict

	## 设置战斗状态
	class SetBattleState extends Action:
		var battle_in_progress: bool
		var battle_id: String

		func _init(in_progress: bool, id: String = ""):
			super._init("SET_BATTLE_STATE")
			battle_in_progress = in_progress
			battle_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["battle_in_progress"] = battle_in_progress
			dict["battle_id"] = battle_id
			return dict

	## 更新羁绊
	class UpdateSynergy extends Action:
		var synergy_id: String
		var level: int

		func _init(synergy: String, synergy_level: int):
			super._init("UPDATE_SYNERGY")
			synergy_id = synergy
			level = synergy_level

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["synergy_id"] = synergy_id
			dict["level"] = level
			return dict

	## 清空棋盘
	class ClearBoard extends Action:
		func _init():
			super._init("CLEAR_BOARD")

## 商店状态动作
class ShopActions:
	## 设置商店开关状态
	class SetShopOpen extends Action:
		var is_open: bool

		func _init(open: bool):
			super._init("SET_SHOP_OPEN")
			is_open = open

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["is_open"] = is_open
			return dict

	## 设置商店物品
	class SetShopItems extends Action:
		var items: Array

		func _init(shop_items: Array):
			super._init("SET_SHOP_ITEMS")
			items = shop_items

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["items"] = items.duplicate()
			return dict

	## 刷新商店
	class RefreshShop extends Action:
		func _init():
			super._init("REFRESH_SHOP")

	## 购买物品
	class BuyItem extends Action:
		var item_index: int

		func _init(index: int):
			super._init("BUY_ITEM")
			item_index = index

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["item_index"] = item_index
			return dict

	## 锁定物品
	class LockItem extends Action:
		var item_index: int
		var locked: bool

		func _init(index: int, is_locked: bool):
			super._init("LOCK_ITEM")
			item_index = index
			locked = is_locked

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["item_index"] = item_index
			dict["locked"] = locked
			return dict

	## 设置商店等级
	class SetShopTier extends Action:
		var tier: int

		func _init(shop_tier: int):
			super._init("SET_SHOP_TIER")
			tier = shop_tier

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["tier"] = tier
			return dict

## 地图状态动作
class MapActions:
	## 设置当前地图
	class SetMap extends Action:
		var map_data: Dictionary

		func _init(map: Dictionary):
			super._init("SET_MAP")
			map_data = map

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["map_data"] = map_data.duplicate()
			return dict

	## 选择地图节点
	class SelectNode extends Action:
		var node_id: String

		func _init(id: String):
			super._init("SELECT_NODE")
			node_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["node_id"] = node_id
			return dict

	## 访问地图节点
	class VisitNode extends Action:
		var node_id: String

		func _init(id: String):
			super._init("VISIT_NODE")
			node_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["node_id"] = node_id
			return dict

	## 设置可用节点
	class SetAvailableNodes extends Action:
		var nodes: Array

		func _init(available_nodes: Array):
			super._init("SET_AVAILABLE_NODES")
			nodes = available_nodes

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["nodes"] = nodes.duplicate()
			return dict

	## 设置地图等级
	class SetMapLevel extends Action:
		var level: int

		func _init(map_level: int):
			super._init("SET_MAP_LEVEL")
			level = map_level

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["level"] = level
			return dict

## UI状态动作
class UIActions:
	## 设置当前屏幕
	class SetScreen extends Action:
		var screen: String

		func _init(screen_name: String):
			super._init("SET_SCREEN")
			screen = screen_name

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["screen"] = screen
			return dict

	## 打开窗口
	class OpenWindow extends Action:
		var window: String

		func _init(window_name: String):
			super._init("OPEN_WINDOW")
			window = window_name

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["window"] = window
			return dict

	## 关闭窗口
	class CloseWindow extends Action:
		var window: String

		func _init(window_name: String):
			super._init("CLOSE_WINDOW")
			window = window_name

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["window"] = window
			return dict

	## 选择物品
	class SelectItem extends Action:
		var item_id: String

		func _init(id: String):
			super._init("SELECT_ITEM")
			item_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["item_id"] = item_id
			return dict

	## 设置拖拽物品
	class SetDragItem extends Action:
		var item_id: String

		func _init(id: String):
			super._init("SET_DRAG_ITEM")
			item_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["item_id"] = item_id
			return dict

	## 显示工具提示
	class ShowTooltip extends Action:
		var text: String
		var show: bool

		func _init(tooltip_text: String, visible: bool = true):
			super._init("SHOW_TOOLTIP")
			text = tooltip_text
			show = visible

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["text"] = text
			dict["show"] = show
			return dict

	## 添加通知
	class AddNotification extends Action:
		var message: String
		var notification_type: String
		var duration: float

		func _init(notification_message: String, notification_type: String = "info", notification_duration: float = 3.0):
			super._init("ADD_NOTIFICATION")
			message = notification_message
			self.notification_type = notification_type
			duration = notification_duration

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["message"] = message
			dict["type"] = notification_type
			dict["duration"] = duration
			return dict

	## 清除通知
	class ClearNotifications extends Action:
		func _init():
			super._init("CLEAR_NOTIFICATIONS")

## 设置状态动作
class SettingsActions:
	## 设置音量
	class SetVolume extends Action:
		var volume_type: String
		var volume: float

		func _init(type: String, volume_level: float):
			super._init("SET_VOLUME")
			volume_type = type
			volume = volume_level

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["volume_type"] = volume_type
			dict["volume"] = volume
			return dict

	## 设置全屏
	class SetFullscreen extends Action:
		var fullscreen: bool

		func _init(is_fullscreen: bool):
			super._init("SET_FULLSCREEN")
			fullscreen = is_fullscreen

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["fullscreen"] = fullscreen
			return dict

	## 设置语言
	class SetLanguage extends Action:
		var language: String

		func _init(language_code: String):
			super._init("SET_LANGUAGE")
			language = language_code

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["language"] = language
			return dict

	## 设置显示FPS
	class SetShowFPS extends Action:
		var show_fps: bool

		func _init(show: bool):
			super._init("SET_SHOW_FPS")
			show_fps = show

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["show_fps"] = show_fps
			return dict

	## 设置垂直同步
	class SetVSync extends Action:
		var vsync_enabled: bool

		func _init(enabled: bool):
			super._init("SET_VSYNC")
			vsync_enabled = enabled

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["vsync_enabled"] = vsync_enabled
			return dict

	## 设置粒子质量
	class SetParticleQuality extends Action:
		var quality: int

		func _init(quality_level: int):
			super._init("SET_PARTICLE_QUALITY")
			quality = quality_level

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["quality"] = quality
			return dict

	## 设置UI缩放
	class SetUIScale extends Action:
		var scale: float

		func _init(scale_factor: float):
			super._init("SET_UI_SCALE")
			scale = scale_factor

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["scale"] = scale
			return dict

## 成就状态动作
class AchievementActions:
	## 解锁成就
	class UnlockAchievement extends Action:
		var achievement_id: String

		func _init(id: String):
			super._init("UNLOCK_ACHIEVEMENT")
			achievement_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["achievement_id"] = achievement_id
			return dict

	## 更新成就进度
	class UpdateAchievementProgress extends Action:
		var achievement_id: String
		var progress: int

		func _init(id: String, progress_value: int):
			super._init("UPDATE_ACHIEVEMENT_PROGRESS")
			achievement_id = id
			progress = progress_value

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["achievement_id"] = achievement_id
			dict["progress"] = progress
			return dict

## 统计状态动作
class StatsActions:
	## 记录游戏结果
	class RecordGameResult extends Action:
		var win: bool

		func _init(is_win: bool):
			super._init("RECORD_GAME_RESULT")
			win = is_win

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["win"] = win
			return dict

	## 记录金币获取
	class RecordGoldEarned extends Action:
		var amount: int

		func _init(gold_amount: int):
			super._init("RECORD_GOLD_EARNED")
			amount = gold_amount

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["amount"] = amount
			return dict

	## 记录伤害
	class RecordDamage extends Action:
		var amount: int
		var is_dealt: bool

		func _init(damage_amount: int, dealt: bool = true):
			super._init("RECORD_DAMAGE")
			amount = damage_amount
			is_dealt = dealt

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["amount"] = amount
			dict["is_dealt"] = is_dealt
			return dict

	## 记录治疗
	class RecordHealing extends Action:
		var amount: int

		func _init(healing_amount: int):
			super._init("RECORD_HEALING")
			amount = healing_amount

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["amount"] = amount
			return dict

	## 记录棋子购买
	class RecordChessPieceBought extends Action:
		var piece_id: String

		func _init(id: String):
			super._init("RECORD_CHESS_PIECE_BOUGHT")
			piece_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["piece_id"] = piece_id
			return dict

	## 记录3星棋子
	class RecordChessPiece3Star extends Action:
		var piece_id: String

		func _init(id: String):
			super._init("RECORD_CHESS_PIECE_3STAR")
			piece_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["piece_id"] = piece_id
			return dict

	## 记录羁绊激活
	class RecordSynergyActivated extends Action:
		var synergy_id: String

		func _init(id: String):
			super._init("RECORD_SYNERGY_ACTIVATED")
			synergy_id = id

		func to_dictionary() -> Dictionary:
			var dict = super.to_dictionary()
			dict["synergy_id"] = synergy_id
			return dict
