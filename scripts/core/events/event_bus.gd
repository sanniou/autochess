extends Node
class_name EventBus
## 事件总线
## 全局事件管理系统，提供事件分组和命名空间

## 事件分发器
var _dispatcher: EventDispatcher = EventDispatcher.new()

## 事件分组映射 {分组名称 -> 事件分组}
var _groups: Dictionary = {}

## 事件历史
var _event_history: Array = []

## 事件历史最大长度
var max_history_length: int = 100

## 是否启用事件历史记录
var enable_history: bool = false

## 是否启用调试日志
var debug_logging: bool = false

## 批处理器
var _batch_processor = null

## 初始化
func _ready() -> void:
	# 设置调试模式
	var debug_mode = OS.is_debug_build()
	debug_logging = debug_mode
	enable_history = debug_mode

	# 设置分发器调试日志
	_dispatcher.debug_logging = debug_mode

	# 初始化事件分组
	_initialize_groups()

	# 初始化批处理器
	_initialize_batch_processor()

	print("[EventBus] 事件总线初始化完成")

## 初始化事件分组
func _initialize_groups() -> void:
	# 创建标准分组
	var standard_groups = [
		"game", "map", "board", "chess", "battle", "economy",
		"equipment", "relic", "event", "story", "curse", "ui",
		"achievement", "tutorial", "save", "localization",
		"audio", "skin", "status_effect", "debug"
	]

	for group_name in standard_groups:
		create_group(group_name)

## 初始化批处理器
func _initialize_batch_processor() -> void:
	# 加载批处理器
	var BatchProcessor = load("res://scripts/core/events/utils/batch_processor.gd")
	_batch_processor = BatchProcessor.new(self)

	# 添加需要批处理的事件类型
	var batch_event_types = [
		"debug.message",
		"ui.update",
		"battle.damage_dealt",
		"battle.heal_received"
	]

	for event_type in batch_event_types:
		_batch_processor.add_batch_event_type(event_type)

## 处理批处理
func _process(delta: float) -> void:
	if _batch_processor:
		_batch_processor.process(delta)

## 创建事件分组
## @param group_name 分组名称
## @return 事件分组
func create_group(group_name: String) -> EventGroup:
	if _groups.has(group_name):
		return _groups[group_name]

	var group = EventGroup.new(self, group_name)
	_groups[group_name] = group
	add_child(group)

	if debug_logging:
		print("[EventBus] 创建事件分组: %s" % [group_name])

	return group

## 获取事件分组
## @param group_name 分组名称
## @return 事件分组
func get_group(group_name: String) -> EventGroup:
	if not _groups.has(group_name):
		return create_group(group_name)
	return _groups[group_name]

## 添加事件监听器
## @param event_type 事件类型
## @param callback 回调函数
## @param priority 优先级
## @param filter_func 过滤函数
## @param process_canceled 是否处理已取消的事件
## @param once 是否只触发一次
## @deprecated 请使用 add_class_listener 代替
func add_listener(event_type: String, callback: Callable, priority: int = 0,
				 filter_func: Callable = Callable(), process_canceled: bool = false,
				 once: bool = false) -> void:
	# 输出警告信息
	if debug_logging:
		print("[EventBus] 警告：add_listener 方法已过时，请使用 add_class_listener 代替")

	# 调用底层方法
	_dispatcher.add_listener(event_type, callback, priority, filter_func, process_canceled, once)

## 添加基于类的事件监听器
## @param event_class 事件类
## @param callback 回调函数
## @param priority 优先级
## @param filter_func 过滤函数
## @param process_canceled 是否处理已取消的事件
## @param once 是否只触发一次
func add_class_listener(event_class:GDScript, callback: Callable, priority: int = 0,
				 filter_func: Callable = Callable(), process_canceled: bool = false,
				 once: bool = false) -> void:
	# 获取事件类型
	var event_type = _get_event_type_from_class(event_class)

	# 添加监听器
	_dispatcher.add_listener(event_type, callback, priority, filter_func, process_canceled, once)

## 从事件类获取事件类型
## @param event_class 事件类
## @return 事件类型
func _get_event_type_from_class(event_class:GDScript) -> String:
	# 获取事件类的脚本路径
	var script_path = event_class.get_script().get_path()

	# 获取父类名称（如果是内部类）
	var parent_basename = script_path.get_file().get_basename()

	# 检查是否是内部类
	var is_inner_class = false
	var inner_class_name = ""

	# 如果是BattleEvents.DamageDealtEvent这样的内部类
	if "." in str(event_class):
		is_inner_class = true
		# 从完整类名中提取内部类名
		inner_class_name = str(event_class).split(".")[-1]

	# 如果是内部类
	if is_inner_class:
		# 获取父类名称，提取事件组
		var event_group = ""
		if parent_basename.ends_with("Events"):
			event_group = parent_basename.split("Events")[0].to_lower()

		# 将内部类名转换为事件类型
		# 例如：DamageDealtEvent -> damage_dealt
		var event_name = inner_class_name.replace("Event", "")

		# 将驼峰命名转换为蛇形命名
		var snake_case_name = ""
		for i in range(event_name.length()):
			var c = event_name[i]
			if c == c.to_upper() and i > 0:
				snake_case_name += "_" + c.to_lower()
			else:
				snake_case_name += c.to_lower()

		# 返回完整事件类型
		return event_group + "." + snake_case_name
	else:
		# 如果是普通类，从类名中提取事件类型
		var class_basename = script_path.get_file().get_basename()

		# 从类名中提取事件名
		# 例如：DamageDealtEvent -> damage_dealt
		var event_name = class_basename.replace("Event", "")

		# 将驼峰命名转换为蛇形命名
		var snake_case_name = ""
		for i in range(event_name.length()):
			var c = event_name[i]
			if c == c.to_upper() and i > 0:
				snake_case_name += "_" + c.to_lower()
			else:
				snake_case_name += c.to_lower()

		return snake_case_name

## 移除事件监听器
## @param event_type 事件类型
## @param callback 回调函数
## @deprecated 请使用 remove_class_listener 代替
func remove_listener(event_type: String, callback: Callable) -> void:
	# 输出警告信息
	if debug_logging:
		print("[EventBus] 警告：remove_listener 方法已过时，请使用 remove_class_listener 代替")

	# 调用底层方法
	_dispatcher.remove_listener(event_type, callback)

## 移除基于类的事件监听器
## @param event_class 事件类
## @param callback 回调函数
func remove_class_listener(event_class:GDScript, callback: Callable) -> void:
	# 获取事件类型
	var event_type = _get_event_type_from_class(event_class)

	# 移除监听器
	_dispatcher.remove_listener(event_type, callback)

## 分发事件
## @param event 要分发的事件
## @return 是否有监听器处理了事件
func dispatch_event(event:BusEvent) -> bool:
	# 检查是否需要批处理
	if _batch_processor and _batch_processor.should_batch(event):
		return _batch_processor.add_event(event)

	# 记录事件历史
	if enable_history:
		_add_to_history(event)

	# 分发事件
	return _dispatcher.dispatch_event(event)

## 添加到事件历史
## @param event 事件
func _add_to_history(event:BusEvent) -> void:
	# 克隆事件以避免引用问题
	var cloned_event = event.clone() if event.has_method("clone") else event

	_event_history.append({
		"timestamp": Time.get_unix_time_from_system(),
		"event": cloned_event
	})

	# 限制历史长度
	if _event_history.size() > max_history_length:
		_event_history.pop_front()

## 获取事件历史
## @return 事件历史数组
func get_event_history() -> Array:
	return _event_history.duplicate()

## 清除事件历史
func clear_event_history() -> void:
	_event_history.clear()

## 清除所有监听器
func clear_listeners() -> void:
	_dispatcher.clear_listeners()

## 事件分组类
class EventGroup extends Node:
	## 事件总线引用
	var _event_bus: EventBus

	## 分组名称
	var _group_name: String

	## 初始化
	func _init(p_event_bus: EventBus, p_group_name: String):
		_event_bus = p_event_bus
		_group_name = p_group_name
		name = p_group_name + "_events"

	## 分发事件
	## @param event 要分发的事件
	## @return 是否有监听器处理了事件
	func dispatch_event(event:BusEvent) -> bool:
		# 确保事件类型包含分组前缀
		var event_type = event.get_type()
		if not event_type.begins_with(_group_name + "."):
			# 这是一个内部实现细节，不应该被外部代码依赖
			#var original_get_type = event.get_type
			#event.get_type = func(): return _group_name + "." + original_get_type.call()
			assert(false,"event_type.begins_with(_group_name + ):")

		return _event_bus.dispatch_event(event)

	## 添加事件监听器
	## @param event_type 事件类型（不含分组前缀）
	## @param callback 回调函数
	## @param priority 优先级
	## @param filter_func 过滤函数
	## @param process_canceled 是否处理已取消的事件
	## @param once 是否只触发一次
	## @deprecated 请使用 add_class_listener 代替
	func add_listener(event_type: String, callback: Callable, priority: int = 0,
					 filter_func: Callable = Callable(), process_canceled: bool = false,
					 once: bool = false) -> void:
		# 输出警告信息
		if _event_bus.debug_logging:
			print("[EventGroup] 警告：add_listener 方法已过时，请使用 add_class_listener 代替")

		var full_event_type = _group_name + "." + event_type
		_event_bus.add_listener(full_event_type, callback, priority, filter_func, process_canceled, once)

	## 添加基于类的事件监听器
	## @param event_class 事件类
	## @param callback 回调函数
	## @param priority 优先级
	## @param filter_func 过滤函数
	## @param process_canceled 是否处理已取消的事件
	## @param once 是否只触发一次
	func add_class_listener(event_class:GDScript, callback: Callable, priority: int = 0,
					 filter_func: Callable = Callable(), process_canceled: bool = false,
					 once: bool = false) -> void:
		# 直接调用事件总线的add_class_listener方法
		_event_bus.add_class_listener(event_class, callback, priority, filter_func, process_canceled, once)


	## 移除事件监听器
	## @param event_type 事件类型（不含分组前缀）
	## @param callback 回调函数
	## @deprecated 请使用 remove_class_listener 代替
	func remove_listener(event_type: String, callback: Callable) -> void:
		# 输出警告信息
		if _event_bus.debug_logging:
			print("[EventGroup] 警告：remove_listener 方法已过时，请使用 remove_class_listener 代替")

		var full_event_type = _group_name + "." + event_type
		_event_bus.remove_listener(full_event_type, callback)

	## 移除基于类的事件监听器
	## @param event_class 事件类
	## @param callback 回调函数
	func remove_class_listener(event_class:GDScript, callback: Callable) -> void:
		# 直接调用事件总线的remove_class_listener方法
		_event_bus.remove_class_listener(event_class, callback)

	## 获取分组名称
	## @return 分组名称
	func get_group_name() -> String:
		return _group_name
