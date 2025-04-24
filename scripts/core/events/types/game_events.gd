extends RefCounted
class_name GameEvents
## 游戏事件类型
## 定义与游戏状态相关的事件

class PlayerRelicUpdatedEvent extends BusEvent:
	var relic_size: int

	## 初始化
	func _init(relic_size: int):
		self.relic_size = relic_size

class PlayerEquipmentUpdatedEvent extends BusEvent:
	var equipment_size: int

	## 初始化
	func _init(equipment_size: int):
		self.equipment_size = equipment_size

class PlayerInventoryUpdatedEvent extends BusEvent:
	var gold: int

	## 初始化
	func _init(gold: int):
		self.gold = gold

class PlayerChessUpdatedEvent extends BusEvent:
	var chess_pieces_size: int

	var bench_pieces_size: int

	## 初始化
	func _init(chess_pieces_size: int, bench_pieces_size: int):
		self.chess_pieces_size = chess_pieces_size
		self.bench_pieces_size = bench_pieces_size

class PlayerStateChangedEvent extends BusEvent:
	## 旧状态
	var old_state: int

	## 新状态
	var new_state: int

	## 初始化
	func _init(p_old_state: int, p_new_state: int):
		old_state = p_old_state
		new_state = p_new_state

## 游戏状态变更事件
class GameStateChangedEvent extends BusEvent:
	## 旧状态
	var old_state: int

	## 新状态
	var new_state: int

	## 初始化
	func _init(p_old_state: int, p_new_state: int):
		old_state = p_old_state
		new_state = p_new_state

	## 获取事件类型
	func get_type() -> String:
		return "game.state_changed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "GameStateChangedEvent[old_state=%d, new_state=%d]" % [old_state, new_state]

	## 克隆事件
	func clone() ->BusEvent:
		var event = GameStateChangedEvent.new(old_state, new_state)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 游戏暂停事件
class GamePausedEvent extends BusEvent:
	## 是否暂停
	var is_paused: bool

	## 初始化
	func _init(p_is_paused: bool):
		is_paused = p_is_paused

	## 获取事件类型
	func get_type() -> String:
		return "game.paused"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "GamePausedEvent[is_paused=%s]" % [is_paused]

	## 克隆事件
	func clone() ->BusEvent:
		var event = GamePausedEvent.new(is_paused)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 游戏开始事件
class GameStartedEvent extends BusEvent:
	## 难度级别
	var difficulty_level: int

	## 初始化
	func _init(p_difficulty_level: int = 1):
		difficulty_level = p_difficulty_level

	## 获取事件类型
	func get_type() -> String:
		return "game.started"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "GameStartedEvent[difficulty_level=%d]" % [difficulty_level]

	## 克隆事件
	func clone() ->BusEvent:
		var event = GameStartedEvent.new(difficulty_level)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 游戏结束事件
class GameEndedEvent extends BusEvent:
	## 是否胜利
	var is_victory: bool

	## 游戏时长（秒）
	var play_time: float

	## 得分
	var score: int

	## 初始化
	func _init(p_is_victory: bool, p_play_time: float = 0.0, p_score: int = 0):
		is_victory = p_is_victory
		play_time = p_play_time
		score = p_score

	## 获取事件类型
	func get_type() -> String:
		return "game.ended"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "GameEndedEvent[is_victory=%s, play_time=%.2f, score=%d]" % [is_victory, play_time, score]

	## 克隆事件
	func clone() ->BusEvent:
		var event = GameEndedEvent.new(is_victory, play_time, score)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

class PlayerExpChangedEvent extends BusEvent:
	var old_exp: float
	
	var new_exp: float

	## 初始化
	func _init(p_old_exp: float, p_new_exp: float):
		old_exp = p_old_exp
		new_exp = p_new_exp
		
## 玩家生命值变更事件
class PlayerHealthChangedEvent extends BusEvent:
	## 旧生命值
	var old_health: float

	## 新生命值
	var new_health: float

	## 最大生命值
	var max_health: float

	## 初始化
	func _init(p_old_health: float, p_new_health: float, p_max_health: float):
		old_health = p_old_health
		new_health = p_new_health
		max_health = p_max_health

	## 获取事件类型
	func get_type() -> String:
		return "game.player_health_changed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PlayerHealthChangedEvent[old_health=%.1f, new_health=%.1f, max_health=%.1f]" % [old_health, new_health, max_health]

	## 克隆事件
	func clone() ->BusEvent:
		var event = PlayerHealthChangedEvent.new(old_health, new_health, max_health)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 玩家等级变更事件
class PlayerLevelChangedEvent extends BusEvent:
	## 旧等级
	var old_level: int

	## 新等级
	var new_level: int

	## 初始化
	func _init(p_old_level: int, p_new_level: int):
		old_level = p_old_level
		new_level = p_new_level

	## 获取事件类型
	func get_type() -> String:
		return "game.player_level_changed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PlayerLevelChangedEvent[old_level=%d, new_level=%d]" % [old_level, new_level]

	## 克隆事件
	func clone() ->BusEvent:
		var event = PlayerLevelChangedEvent.new(old_level, new_level)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## AI对手初始化事件
class AIOpponentsInitializedEvent extends BusEvent:
	## AI对手数组
	var ai_opponents: Array[Player]

	## 初始化
	func _init(p_ai_opponents: Array[Player]):
		ai_opponents = p_ai_opponents

	## 获取事件类型
	func get_type() -> String:
		return "game.ai_opponents_initialized"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AIOpponentsInitializedEvent[ai_opponents_count=%d]" % [ai_opponents.size()]

	## 克隆事件
	func clone() -> BusEvent:
		var event = AIOpponentsInitializedEvent.new(ai_opponents.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 玩家初始化事件
class PlayerInitializedEvent extends BusEvent:
	## 玩家实例
	var player: Player

	## 初始化
	func _init(p_player: Player):
		player = p_player

	## 获取事件类型
	func get_type() -> String:
		return "game.player_initialized"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "PlayerInitializedEvent[player=%s]" % [player]

	## 克隆事件
	func clone() -> BusEvent:
		var event = PlayerInitializedEvent.new(player)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 难度变更事件
class DifficultyChangedEvent extends BusEvent:
	## 旧难度
	var old_level: int

	## 新难度
	var new_level: int

	## 初始化
	func _init(p_old_level: int, p_new_level: int):
		old_level = p_old_level
		new_level = p_new_level

	## 获取事件类型
	func get_type() -> String:
		return "game.difficulty_changed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "DifficultyChangedEvent[old_level=%d, new_level=%d]" % [old_level, new_level]

	## 克隆事件
	func clone() ->BusEvent:
		var event = DifficultyChangedEvent.new(old_level, new_level)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 玩家死亡事件
class PlayerDiedEvent extends BusEvent:
	## 初始化
	func _init():
		pass  # 不需要额外参数
