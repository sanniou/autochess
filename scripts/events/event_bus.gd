extends Node
## 事件总线系统
## 负责全局事件的分发和处理，实现系统间的松耦合通信

# 事件定义
var event_definitions = preload("res://scripts/events/event_definitions.gd")

# 事件处理器
var _event_handlers = {}

# 事件历史
var _event_history = []

# 事件历史最大长度
var max_history_length = 100

# 是否启用事件记录
var enable_event_logging = false

# 是否启用事件历史
var enable_event_history = false

# 是否处于调试模式
var debug_mode = false

# 事件统计
var _event_stats = {}

# 游戏事件
var game = null

# 地图事件
var map = null

# 棋盘事件
var board = null

# 棋子事件
var chess = null

# 战斗事件
var battle = null

# 经济事件
var economy = null

# 装备事件
var equipment = null

# 遗物事件
var relic = null

# 事件系统事件
var event = null

# 剧情事件
var story = null

# 诅咒事件
var curse = null

# UI事件
var ui = null

# 成就事件
var achievement = null

# 教程事件
var tutorial = null

# 存档事件
var save = null

# 本地化事件
var localization = null

# 音频事件
var audio = null

# 皮肤事件
var skin = null

# 状态效果事件
var status_effect = null

# 调试事件
var debug = null

# 初始化
func _ready():
	# 设置调试模式
	debug_mode = OS.is_debug_build()

	# 如果处于调试模式，启用事件记录和历史
	if debug_mode:
		enable_event_logging = true
		enable_event_history = true

	# 初始化事件分组
	_initialize_event_groups()

	# 初始化事件统计
	_initialize_event_stats()

	print("[EventBus] 事件总线初始化完成")

## 初始化事件分组
func _initialize_event_groups():
	# 创建事件分组
	game = EventGroup.new(self, "game")
	map = EventGroup.new(self, "map")
	board = EventGroup.new(self, "board")
	chess = EventGroup.new(self, "chess")
	battle = EventGroup.new(self, "battle")
	economy = EventGroup.new(self, "economy")
	equipment = EventGroup.new(self, "equipment")
	relic = EventGroup.new(self, "relic")
	event = EventGroup.new(self, "event")
	story = EventGroup.new(self, "story")
	curse = EventGroup.new(self, "curse")
	ui = EventGroup.new(self, "ui")
	achievement = EventGroup.new(self, "achievement")
	tutorial = EventGroup.new(self, "tutorial")
	save = EventGroup.new(self, "save")
	localization = EventGroup.new(self, "localization")
	audio = EventGroup.new(self, "audio")
	skin = EventGroup.new(self, "skin")
	status_effect = EventGroup.new(self, "status_effect")
	debug = EventGroup.new(self, "debug")

	# 添加为子节点以便生命周期管理
	add_child(game)
	add_child(map)
	add_child(board)
	add_child(chess)
	add_child(battle)
	add_child(economy)
	add_child(equipment)
	add_child(relic)
	add_child(event)
	add_child(story)
	add_child(curse)
	add_child(ui)
	add_child(achievement)
	add_child(tutorial)
	add_child(save)
	add_child(localization)
	add_child(audio)
	add_child(skin)
	add_child(status_effect)
	add_child(debug)

## 初始化事件统计
func _initialize_event_stats():
	# 获取所有事件类别
	var categories = event_definitions.get_all_event_categories()

	# 初始化每个类别的事件统计
	for category in categories:
		var events = event_definitions.get_events_for_category(category)

		for event_name in events:
			var event_id = events[event_name]
			_event_stats[event_id] = {
				"emit_count": 0,
				"last_emit_time": 0,
				"handler_count": 0
			}

## 注册事件处理器
## 将事件处理器注册到指定的事件
func register_handler(event_name: String, target: Object, method: String, priority: int = 0) -> bool:
	# 检查参数有效性
	if event_name.is_empty() or not is_instance_valid(target) or method.is_empty():
		_log_error("注册事件处理器失败：无效的参数")
		return false

	# 如果事件不存在，创建事件
	if not _event_handlers.has(event_name):
		_event_handlers[event_name] = []

	# 检查是否已经注册
	for handler in _event_handlers[event_name]:
		if handler.target == target and handler.method == method:
			_log_warning("事件处理器已经注册：" + event_name)
			return false

	# 注册事件处理器
	_event_handlers[event_name].append({
		"target": target,
		"method": method,
		"priority": priority
	})

	# 按优先级排序
	_event_handlers[event_name].sort_custom(func(a, b): return a.priority > b.priority)

	# 更新事件统计
	if _event_stats.has(event_name):
		_event_stats[event_name].handler_count += 1

	_log_info("注册事件处理器：" + event_name + " -> " + target.get_class() + "." + method)
	return true

## 注销事件处理器
## 从指定的事件中注销事件处理器
func unregister_handler(event_name: String, target: Object, method: String) -> bool:
	# 检查参数有效性
	if event_name.is_empty() or not is_instance_valid(target) or method.is_empty():
		_log_error("注销事件处理器失败：无效的参数")
		return false

	# 如果事件不存在，返回失败
	if not _event_handlers.has(event_name):
		_log_warning("注销事件处理器失败：事件不存在 - " + event_name)
		return false

	# 查找并移除事件处理器
	for i in range(_event_handlers[event_name].size()):
		var handler = _event_handlers[event_name][i]
		if handler.target == target and handler.method == method:
			_event_handlers[event_name].remove_at(i)

			# 更新事件统计
			if _event_stats.has(event_name):
				_event_stats[event_name].handler_count -= 1

			_log_info("注销事件处理器：" + event_name + " -> " + target.get_class() + "." + method)
			return true

	_log_warning("注销事件处理器失败：处理器不存在 - " + event_name)
	return false

## 注销对象的所有事件处理器
## 从所有事件中注销指定对象的所有事件处理器
func unregister_all_handlers(target: Object) -> int:
	# 检查参数有效性
	if not is_instance_valid(target):
		_log_error("注销所有事件处理器失败：无效的目标对象")
		return 0

	var count = 0

	# 遍历所有事件
	for event_name in _event_handlers.keys():
		var handlers = _event_handlers[event_name]
		var i = 0

		# 查找并移除事件处理器
		while i < handlers.size():
			if handlers[i].target == target:
				handlers.remove_at(i)
				count += 1

				# 更新事件统计
				if _event_stats.has(event_name):
					_event_stats[event_name].handler_count -= 1
			else:
				i += 1

	if count > 0:
		_log_info("注销所有事件处理器：" + target.get_class() + " - " + str(count) + " 个处理器")

	return count

## 触发事件
## 触发指定的事件，并传递参数
func emit_event(event_name: String, args: Array = []) -> int:
	# 检查参数有效性
	if event_name.is_empty():
		_log_error("触发事件失败：无效的事件名称")
		return 0

	# 获取调用堆栈信息以确定发送方
	var sender_info = "未知"
	if debug_mode:
		var stack = get_stack()
		# 尝试找到真正的发送方，而不是 EventBus 本身
		var found_sender = false
		for i in range(1, stack.size()):
			var caller = stack[i]
			# 跳过 EventBus 和 EventGroup 类的调用
			if not ("event_bus.gd" in caller["source"] or "EventGroup" in caller["function"]):
				sender_info = caller["source"] + ":" + str(caller["line"]) + " in " + caller["function"]
				found_sender = true
				break

		# 如果没有找到其他发送方，使用第一个非 EventBus 的调用者
		if not found_sender and stack.size() > 1:
			var caller = stack[1]
			sender_info = caller["source"] + ":" + str(caller["line"]) + " in " + caller["function"]

	# 记录事件
	if enable_event_logging:
		_log_event(event_name, args, sender_info)

	# 添加到事件历史
	if enable_event_history:
		_add_to_history(event_name, args, sender_info)

	# 更新事件统计
	if _event_stats.has(event_name):
		_event_stats[event_name].emit_count += 1
		_event_stats[event_name].last_emit_time = Time.get_unix_time_from_system()

	# 如果事件不存在，返回0
	if not _event_handlers.has(event_name):
		return 0

	var count = 0

	# 调用事件处理器
	for handler in _event_handlers[event_name]:
		if is_instance_valid(handler.target):
			if args.size() > 0:
				handler.target.callv(handler.method, args)
			else:
				handler.target.call(handler.method)
			count += 1

	return count

## 获取事件处理器数量
## 获取指定事件的处理器数量
func get_handler_count(event_name: String) -> int:
	if not _event_handlers.has(event_name):
		return 0

	return _event_handlers[event_name].size()

## 获取所有已注册的事件
## 获取所有已注册的事件名称
func get_registered_events() -> Array:
	return _event_handlers.keys()

## 获取事件历史
## 获取事件历史记录
func get_event_history() -> Array:
	return _event_history

## 清除事件历史
## 清除事件历史记录
func clear_event_history() -> void:
	_event_history.clear()
	_log_info("事件历史已清除")

## 设置事件历史最大长度
## 设置事件历史记录的最大长度
func set_max_history_length(length: int) -> void:
	if length < 0:
		_log_error("设置事件历史最大长度失败：无效的长度")
		return

	max_history_length = length

	# 如果当前历史记录超过最大长度，裁剪历史记录
	while _event_history.size() > max_history_length:
		_event_history.pop_front()

	_log_info("事件历史最大长度已设置为：" + str(length))

## 启用事件记录
## 启用事件记录功能
func enable_logging(enable: bool = true) -> void:
	enable_event_logging = enable
	_log_info("事件记录已" + ("启用" if enable else "禁用"))

## 启用事件历史
## 启用事件历史记录功能
func enable_history(enable: bool = true) -> void:
	enable_event_history = enable

	if not enable:
		_event_history.clear()

	_log_info("事件历史已" + ("启用" if enable else "禁用"))

## 获取事件统计
## 获取事件统计信息
func get_event_stats() -> Dictionary:
	return _event_stats

## 添加到事件历史
## 将事件添加到历史记录
func _add_to_history(event_name: String, args: Array, sender_info: String = "未知") -> void:
	# 创建事件记录
	var event_record = {
		"event": event_name,
		"args": args,
		"time": Time.get_unix_time_from_system(),
		"sender": sender_info
	}

	# 添加到历史记录
	_event_history.append(event_record)

	# 如果历史记录超过最大长度，移除最旧的记录
	while _event_history.size() > max_history_length:
		_event_history.pop_front()

## 记录事件
## 记录事件信息
func _log_event(event_name: String, args: Array, sender_info: String = "未知") -> void:
	var args_str = ""

	if args.size() > 0:
		args_str = " - 参数: " + str(args)

	_log_info("事件触发：" + event_name + args_str + " - 发送方: " + sender_info)

## 记录错误信息
func _log_error(message: String) -> void:
	if debug_mode:
		print("[EventBus] 错误: " + message)

## 记录警告信息
func _log_warning(message: String) -> void:
	if debug_mode:
		print("[EventBus] 警告: " + message)

## 记录信息
func _log_info(message: String) -> void:
	if debug_mode:
		print("[EventBus] 信息: " + message)

## 事件组类
## 用于组织和管理相关的事件
class EventGroup extends Node:
	# 事件总线引用
	var _event_bus = null

	# 事件组名称
	var _group_name = ""

	# 初始化
	func _init(event_bus, group_name: String):
		_event_bus = event_bus
		_group_name = group_name
		name = group_name + "_events"

	# 添加信号
	func add_event_signal(signal_name: String) -> void:
		if not has_user_signal(signal_name):
			add_user_signal(signal_name)

	# 触发事件
	func emit_event(signal_name: String, args: Array = []) -> void:
		# 先确保信号存在
		if not has_user_signal(signal_name):
			add_event_signal(signal_name)

		# 获取调用堆栈信息以确定发送方
		var sender_info = "未知"
		if _event_bus.debug_mode:
			var stack = get_stack()
			# 尝试找到真正的发送方，而不是 EventBus 本身
			var found_sender = false
			for i in range(1, stack.size()):
				var caller = stack[i]
				# 跳过 EventBus 和 EventGroup 类的调用
				if not ("event_bus.gd" in caller["source"] or "EventGroup" in caller["function"]):
					sender_info = caller["source"] + ":" + str(caller["line"]) + " in " + caller["function"]
					found_sender = true
					break

			# 如果没有找到其他发送方，使用第一个非 EventBus 的调用者
			if not found_sender and stack.size() > 1:
				var caller = stack[1]
				sender_info = caller["source"] + ":" + str(caller["line"]) + " in " + caller["function"]

		# 触发信号
		if args.size() > 0:
			var call_args = [signal_name]
			call_args.append_array(args)
			callv("emit_signal", call_args)
		else:
			emit_signal(signal_name)

		# 同时触发事件总线的事件
		var event_name = _group_name + "." + signal_name

		# 调用 EventBus 的 emit_event 方法，它会自己获取调用堆栈信息
		# 所以我们不需要传递 sender_info
		_event_bus.emit_event(event_name, args)

	# 连接事件
	func connect_event(signal_name: String, callable: Callable, flags: int = 0) -> Error:
		# 如果信号不存在，添加信号
		if not has_user_signal(signal_name):
			add_event_signal(signal_name)

		# 调用父类的connect方法
		var result = connect(signal_name, callable, flags)

		# 同时注册到事件总线
		var event_name = _group_name + "." + signal_name
		_event_bus.register_handler(event_name, callable.get_object(), callable.get_method())

		return result

	# 断开事件
	func disconnect_event(signal_name: String, callable: Callable) -> void:
		# 如果信号存在且已连接，断开连接
		if has_user_signal(signal_name) and is_connected(signal_name, callable):
			disconnect(signal_name, callable)

		# 同时从事件总线注销
		var event_name = _group_name + "." + signal_name
		_event_bus.unregister_handler(event_name, callable.get_object(), callable.get_method())

	# 获取事件连接数量
	func get_event_connection_count(signal_name: String) -> int:
		return get_signal_connection_list(signal_name).size()

	# 是否有事件
	func has_event(signal_name: String) -> bool:
		return has_user_signal(signal_name)

	# 是否已连接事件
	func is_event_connected(signal_name: String, callable: Callable) -> bool:
		return is_connected(signal_name, callable)
