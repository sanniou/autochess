extends Node
## 全局事件总线
## 提供全局访问的事件总线实例

## 事件总线实例
var event_bus: EventBus

## 初始化
func _ready() -> void:
	# 创建事件总线实例
	event_bus = EventBus.new()
	add_child(event_bus)

	# 设置调试模式
	var debug_mode = OS.is_debug_build()
	event_bus.debug_logging = debug_mode
	event_bus.enable_history = debug_mode

	print("[GlobalEventBus] 全局事件总线初始化完成")

## 获取事件分组
## @param group_name 分组名称
## @return 事件分组
func get_group(group_name: String) -> EventBus.EventGroup:
	return event_bus.get_group(group_name)

## 添加事件监听器
## @param event_type 事件类型
## @param callback 回调函数
## @param priority 优先级
## @param filter_func 过滤函数
## @param process_canceled 是否处理已取消的事件
## @param once 是否只触发一次
func add_listener(event_type: String, callback: Callable, priority: int = 0,
				 filter_func: Callable = Callable(), process_canceled: bool = false,
				 once: bool = false) -> void:
	event_bus.add_listener(event_type, callback, priority, filter_func, process_canceled, once)

## 移除事件监听器
## @param event_type 事件类型
## @param callback 回调函数
func remove_listener(event_type: String, callback: Callable) -> void:
	event_bus.remove_listener(event_type, callback)

## 分发事件
## @param event 要分发的事件
## @return 是否有监听器处理了事件
func dispatch_event(event:BusEvent) -> bool:
	return event_bus.dispatch_event(event)

## 获取事件历史
## @return 事件历史数组
func get_event_history() -> Array:
	return event_bus.get_event_history()

## 清除事件历史
func clear_event_history() -> void:
	event_bus.clear_event_history()

## 清除所有监听器
func clear_listeners() -> void:
	event_bus.clear_listeners()

## 便捷属性：游戏事件分组
var game: EventBus.EventGroup:
	get: return get_group("game")

## 便捷属性：地图事件分组
var map: EventBus.EventGroup:
	get: return get_group("map")

## 便捷属性：棋盘事件分组
var board: EventBus.EventGroup:
	get: return get_group("board")

## 便捷属性：棋子事件分组
var chess: EventBus.EventGroup:
	get: return get_group("chess")

## 便捷属性：战斗事件分组
var battle: EventBus.EventGroup:
	get: return get_group("battle")

## 便捷属性：经济事件分组
var economy: EventBus.EventGroup:
	get: return get_group("economy")

## 便捷属性：装备事件分组
var equipment: EventBus.EventGroup:
	get: return get_group("equipment")

## 便捷属性：遗物事件分组
var relic: EventBus.EventGroup:
	get: return get_group("relic")

## 便捷属性：事件事件分组
var BusEvent: EventBus.EventGroup:
	get: return get_group("event")

## 便捷属性：故事事件分组
var story: EventBus.EventGroup:
	get: return get_group("story")

## 便捷属性：诅咒事件分组
var curse: EventBus.EventGroup:
	get: return get_group("curse")

## 便捷属性：UI事件分组
var ui: EventBus.EventGroup:
	get: return get_group("ui")

## 便捷属性：成就事件分组
var achievement: EventBus.EventGroup:
	get: return get_group("achievement")

## 便捷属性：教程事件分组
var tutorial: EventBus.EventGroup:
	get: return get_group("tutorial")

## 便捷属性：保存事件分组
var save: EventBus.EventGroup:
	get: return get_group("save")

## 便捷属性：本地化事件分组
var localization: EventBus.EventGroup:
	get: return get_group("localization")

## 便捷属性：音频事件分组
var audio: EventBus.EventGroup:
	get: return get_group("audio")

## 便捷属性：皮肤事件分组
var skin: EventBus.EventGroup:
	get: return get_group("skin")

## 便捷属性：状态效果事件分组
var status_effect: EventBus.EventGroup:
	get: return get_group("status_effect")

## 便捷属性：调试事件分组
var debug: EventBus.EventGroup:
	get: return get_group("debug")
