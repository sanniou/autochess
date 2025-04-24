extends RefCounted
class_name EventDispatcher
## 事件分发器
## 负责注册、分发和管理事件监听器

## 事件监听器类
class EventListener:
	## 回调函数
	var callback: Callable
	
	## 优先级（数值越大优先级越高）
	var priority: int
	
	## 过滤函数（可选）
	var filter_func: Callable
	
	## 是否处理已取消的事件
	var process_canceled: bool
	
	## 是否只触发一次
	var once: bool
	
	## 初始化监听器
	func _init(p_callback: Callable, p_priority: int = 0, p_filter_func: Callable = Callable(), 
			   p_process_canceled: bool = false, p_once: bool = false):
		callback = p_callback
		priority = p_priority
		filter_func = p_filter_func
		process_canceled = p_process_canceled
		once = p_once
	
	## 检查是否应该处理事件
	func should_handle(event:BusEvent) -> bool:
		# 检查事件是否已取消
		if event.is_canceled() and not process_canceled:
			return false
			
		# 应用过滤函数
		if filter_func.is_valid():
			return filter_func.call(event)
			
		return true

## 事件监听器映射 {事件类型 -> 监听器数组}
var _listeners: Dictionary = {}

## 通配符监听器（处理所有事件）
var _wildcard_listeners: Array[EventListener] = []

## 是否启用调试日志
var debug_logging: bool = false

## 添加事件监听器
## @param event_type 事件类型
## @param callback 回调函数
## @param priority 优先级（数值越大优先级越高）
## @param filter_func 过滤函数（可选）
## @param process_canceled 是否处理已取消的事件
## @param once 是否只触发一次
func add_listener(event_type: String, callback: Callable, priority: int = 0, 
				 filter_func: Callable = Callable(), process_canceled: bool = false, 
				 once: bool = false) -> void:
	# 处理通配符监听器
	if event_type == "*":
		var listener = EventListener.new(callback, priority, filter_func, process_canceled, once)
		_wildcard_listeners.append(listener)
		_wildcard_listeners.sort_custom(func(a, b): return a.priority > b.priority)
		return
	
	# 创建监听器数组（如果不存在）
	if not _listeners.has(event_type):
		_listeners[event_type] = []
	
	# 检查是否已存在相同的监听器
	for listener in _listeners[event_type]:
		if listener.callback == callback:
			if debug_logging:
				print("[EventDispatcher] 监听器已存在: %s -> %s" % [event_type, callback])
			return
	
	# 创建并添加监听器
	var listener = EventListener.new(callback, priority, filter_func, process_canceled, once)
	_listeners[event_type].append(listener)
	
	# 按优先级排序
	_listeners[event_type].sort_custom(func(a, b): return a.priority > b.priority)
	
	if debug_logging:
		print("[EventDispatcher] 添加监听器: %s -> %s (优先级: %d)" % [event_type, callback, priority])

## 移除事件监听器
## @param event_type 事件类型
## @param callback 回调函数
func remove_listener(event_type: String, callback: Callable) -> void:
	# 处理通配符监听器
	if event_type == "*":
		for i in range(_wildcard_listeners.size() - 1, -1, -1):
			if _wildcard_listeners[i].callback == callback:
				_wildcard_listeners.remove_at(i)
				if debug_logging:
					print("[EventDispatcher] 移除通配符监听器: %s" % [callback])
				break
		return
	
	# 检查事件类型是否存在
	if not _listeners.has(event_type):
		return
	
	# 查找并移除监听器
	for i in range(_listeners[event_type].size() - 1, -1, -1):
		if _listeners[event_type][i].callback == callback:
			_listeners[event_type].remove_at(i)
			
			if debug_logging:
				print("[EventDispatcher] 移除监听器: %s -> %s" % [event_type, callback])
			
			# 如果没有更多监听器，移除事件类型
			if _listeners[event_type].is_empty():
				_listeners.erase(event_type)
			
			break

## 分发事件
## @param event 要分发的事件
## @return 是否有监听器处理了事件
func dispatch_event(event:BusEvent) -> bool:
	var event_type = event.get_type()
	var handled = false
	var once_listeners = []
	
	if debug_logging:
		print("[EventDispatcher] 分发事件: %s" % [event])
	
	# 处理特定事件类型的监听器
	if _listeners.has(event_type):
		for listener in _listeners[event_type]:
			if listener.should_handle(event):
				listener.callback.call(event)
				handled = true
				
				# 记录一次性监听器
				if listener.once:
					once_listeners.append({"type": event_type, "callback": listener.callback})
	
	# 处理通配符监听器
	for listener in _wildcard_listeners:
		if listener.should_handle(event):
			listener.callback.call(event)
			handled = true
			
			# 记录一次性监听器
			if listener.once:
				once_listeners.append({"type": "*", "callback": listener.callback})
	
	# 移除一次性监听器
	for listener_info in once_listeners:
		remove_listener(listener_info.type, listener_info.callback)
	
	return handled

## 检查是否有特定事件类型的监听器
## @param event_type 事件类型
## @return 是否有监听器
func has_listeners(event_type: String) -> bool:
	return _listeners.has(event_type) and not _listeners[event_type].is_empty()

## 获取特定事件类型的监听器数量
## @param event_type 事件类型
## @return 监听器数量
func get_listener_count(event_type: String) -> int:
	if not _listeners.has(event_type):
		return 0
	return _listeners[event_type].size()

## 清除所有监听器
func clear_listeners() -> void:
	_listeners.clear()
	_wildcard_listeners.clear()
	
	if debug_logging:
		print("[EventDispatcher] 清除所有监听器")

## 清除特定事件类型的所有监听器
## @param event_type 事件类型
func clear_event_listeners(event_type: String) -> void:
	if _listeners.has(event_type):
		_listeners.erase(event_type)
		
		if debug_logging:
			print("[EventDispatcher] 清除事件类型的所有监听器: %s" % [event_type])
