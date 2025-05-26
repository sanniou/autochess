extends RefCounted
class_name GameFlowEvents
## 游戏流程事件类型
## 定义与游戏主要状态流程相关的事件

## 主菜单状态进入事件
class MainMenuStateEnteredEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.main_menu_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MainMenuStateEnteredEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = MainMenuStateEnteredEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 地图状态进入事件
class MapStateEnteredEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.map_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "MapStateEnteredEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = MapStateEnteredEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 战斗状态进入事件
class BattleStateEnteredEvent extends BusEvent:
	var params: Dictionary
	## 初始化
	func _init(p_params: Dictionary = {}):
		params = p_params

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.battle_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BattleStateEnteredEvent[params=%s]" % [params]

	## 克隆事件
	func clone() -> BusEvent:
		var event = BattleStateEnteredEvent.new(params.duplicate(true) if params else {})
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 战斗状态退出事件
class BattleStateExitedEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.battle_state_exited"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BattleStateExitedEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = BattleStateExitedEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 商店状态进入事件
class ShopStateEnteredEvent extends BusEvent:
	var params: Dictionary
	## 初始化
	func _init(p_params: Dictionary = {}):
		params = p_params

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.shop_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShopStateEnteredEvent[params=%s]" % [params]

	## 克隆事件
	func clone() -> BusEvent:
		var event = ShopStateEnteredEvent.new(params.duplicate(true) if params else {})
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 商店状态退出事件
class ShopStateExitedEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.shop_state_exited"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShopStateExitedEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = ShopStateExitedEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 事件状态进入事件 (叙事/奇遇)
class EventStateEnteredEvent extends BusEvent:
	var params: Dictionary
	## 初始化
	func _init(p_params: Dictionary = {}):
		params = p_params

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.event_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EventStateEnteredEvent[params=%s]" % [params]

	## 克隆事件
	func clone() -> BusEvent:
		var event = EventStateEnteredEvent.new(params.duplicate(true) if params else {})
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 事件状态退出事件 (叙事/奇遇)
class EventStateExitedEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.event_state_exited"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EventStateExitedEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = EventStateExitedEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 祭坛状态进入事件
class AltarStateEnteredEvent extends BusEvent:
	var params: Dictionary
	## 初始化
	func _init(p_params: Dictionary = {}):
		params = p_params

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.altar_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AltarStateEnteredEvent[params=%s]" % [params]

	## 克隆事件
	func clone() -> BusEvent:
		var event = AltarStateEnteredEvent.new(params.duplicate(true) if params else {})
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 祭坛状态退出事件
class AltarStateExitedEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.altar_state_exited"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AltarStateExitedEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = AltarStateExitedEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 铁匠铺状态进入事件
class BlacksmithStateEnteredEvent extends BusEvent:
	var params: Dictionary
	## 初始化
	func _init(p_params: Dictionary = {}):
		params = p_params

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.blacksmith_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BlacksmithStateEnteredEvent[params=%s]" % [params]

	## 克隆事件
	func clone() -> BusEvent:
		var event = BlacksmithStateEnteredEvent.new(params.duplicate(true) if params else {})
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 铁匠铺状态退出事件
class BlacksmithStateExitedEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.blacksmith_state_exited"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BlacksmithStateExitedEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = BlacksmithStateExitedEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 游戏结束状态进入事件
class GameOverStateEnteredEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.game_over_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "GameOverStateEnteredEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = GameOverStateEnteredEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 游戏胜利状态进入事件
class VictoryStateEnteredEvent extends BusEvent:
	## 初始化
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "gameflow.victory_state_entered"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "VictoryStateEnteredEvent[]"

	## 克隆事件
	func clone() -> BusEvent:
		var event = VictoryStateEnteredEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event
