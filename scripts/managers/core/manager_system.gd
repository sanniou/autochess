extends Node
class_name ManagerSystem
## 管理器系统
## 提供统一的管理器注册、访问和生命周期管理

# 信号
signal manager_registered(manager_name: String, manager_instance: Node)
signal manager_initialized(manager_name: String)
signal manager_reset(manager_name: String)
signal manager_error(manager_name: String, error_message: String)

# 管理器实例字典
var _managers: Dictionary = {}

# 管理器依赖图
var _dependency_graph: Dictionary = {}

# 管理器初始化状态
var _initialized_managers: Dictionary = {}

# 调试模式
var debug_mode: bool = false

# 初始化
func _init(enable_debug: bool = false):
	debug_mode = enable_debug
	if debug_mode:
		print("[ManagerSystem] 初始化管理器系统")

# 注册管理器
func register(manager_name: String, manager_instance: Node) -> bool:
	# 检查管理器名称是否有效
	if manager_name.is_empty():
		_log_error("无效的管理器名称")
		return false
		
	# 检查管理器实例是否有效
	if not is_instance_valid(manager_instance):
		_log_error("无效的管理器实例: " + manager_name)
		return false
		
	# 检查管理器是否已注册
	if _managers.has(manager_name):
		_log_error("管理器已注册: " + manager_name)
		return false
		
	# 注册管理器
	_managers[manager_name] = manager_instance
	_initialized_managers[manager_name] = false
	
	# 如果管理器是BaseManager的子类，获取其依赖
	if manager_instance is BaseManager:
		var dependencies = manager_instance.get_dependencies()
		_dependency_graph[manager_name] = dependencies
	else:
		_dependency_graph[manager_name] = []
	
	# 发送信号
	manager_registered.emit(manager_name, manager_instance)
	
	if debug_mode:
		_log_info("管理器注册成功: " + manager_name)
		
	return true

# 初始化管理器
func initialize(manager_name: String) -> bool:
	# 检查管理器是否已注册
	if not _managers.has(manager_name):
		_log_error("管理器未注册: " + manager_name)
		return false
		
	# 检查管理器是否已初始化
	if _initialized_managers[manager_name]:
		return true
		
	# 获取管理器实例
	var manager = _managers[manager_name]
	
	# 初始化依赖
	var dependencies = _dependency_graph[manager_name]
	for dependency in dependencies:
		if not initialize(dependency):
			_log_error("初始化依赖失败: " + dependency + " (被 " + manager_name + " 依赖)")
			manager_error.emit(manager_name, "初始化依赖失败: " + dependency)
			return false
	
	# 初始化管理器
	if manager is BaseManager:
		if not manager.initialize():
			_log_error("管理器初始化失败: " + manager_name)
			manager_error.emit(manager_name, "初始化失败")
			return false
	else:
		# 对于非BaseManager子类，调用initialize方法（如果存在）
		if manager.has_method("initialize"):
			manager.initialize()
	
	# 标记为已初始化
	_initialized_managers[manager_name] = true
	
	# 发送信号
	manager_initialized.emit(manager_name)
	
	if debug_mode:
		_log_info("管理器初始化成功: " + manager_name)
		
	return true

# 初始化所有管理器
func initialize_all() -> Dictionary:
	var results = {}
	
	# 使用拓扑排序确定初始化顺序
	var initialization_order = _topological_sort()
	
	# 按顺序初始化管理器
	for manager_name in initialization_order:
		results[manager_name] = initialize(manager_name)
		
	# 输出初始化结果
	if debug_mode:
		var success_count = 0
		var failure_count = 0
		
		for manager_name in results:
			if results[manager_name]:
				success_count += 1
			else:
				failure_count += 1
				
		_log_info("管理器初始化统计: 成功=" + str(success_count) + ", 失败=" + str(failure_count))
		
	return results

# 重置管理器
func reset(manager_name: String) -> bool:
	# 检查管理器是否已注册
	if not _managers.has(manager_name):
		_log_error("管理器未注册: " + manager_name)
		return false
		
	# 获取管理器实例
	var manager = _managers[manager_name]
	
	# 重置管理器
	if manager is BaseManager:
		if not manager.reset():
			_log_error("管理器重置失败: " + manager_name)
			manager_error.emit(manager_name, "重置失败")
			return false
	else:
		# 对于非BaseManager子类，调用reset方法（如果存在）
		if manager.has_method("reset"):
			manager.reset()
	
	# 发送信号
	manager_reset.emit(manager_name)
	
	if debug_mode:
		_log_info("管理器重置成功: " + manager_name)
		
	return true

# 重置所有管理器
func reset_all() -> Dictionary:
	var results = {}
	
	# 按照依赖关系的反向顺序重置管理器
	var reset_order = _topological_sort()
	reset_order.reverse()
	
	# 按顺序重置管理器
	for manager_name in reset_order:
		results[manager_name] = reset(manager_name)
		
	return results

# 获取管理器
func get_manager(manager_name: String) -> Node:
	# 检查管理器是否已注册
	if not _managers.has(manager_name):
		_log_error("管理器未注册: " + manager_name)
		return null
		
	# 检查管理器是否已初始化
	if not _initialized_managers[manager_name]:
		# 尝试初始化管理器
		if not initialize(manager_name):
			_log_error("管理器未初始化且无法初始化: " + manager_name)
			return null
	
	return _managers[manager_name]

# 检查管理器是否已注册
func has_manager(manager_name: String) -> bool:
	return _managers.has(manager_name)

# 检查管理器是否已初始化
func is_initialized(manager_name: String) -> bool:
	if not _managers.has(manager_name):
		return false
		
	return _initialized_managers[manager_name]

# 获取所有管理器名称
func get_all_manager_names() -> Array:
	return _managers.keys()

# 获取所有已初始化的管理器名称
func get_initialized_manager_names() -> Array:
	var result = []
	
	for manager_name in _initialized_managers:
		if _initialized_managers[manager_name]:
			result.append(manager_name)
			
	return result

# 获取管理器的依赖
func get_dependencies(manager_name: String) -> Array:
	if not _dependency_graph.has(manager_name):
		return []
		
	return _dependency_graph[manager_name]

# 拓扑排序，用于确定初始化顺序
func _topological_sort() -> Array:
	var result = []
	var visited = {}
	var temp_mark = {}
	
	# 初始化访问标记
	for manager_name in _managers:
		visited[manager_name] = false
		temp_mark[manager_name] = false
	
	# 对每个未访问的节点执行深度优先搜索
	for manager_name in _managers:
		if not visited[manager_name]:
			_visit(manager_name, visited, temp_mark, result)
	
	return result

# 深度优先搜索辅助函数
func _visit(manager_name: String, visited: Dictionary, temp_mark: Dictionary, result: Array) -> void:
	# 检测循环依赖
	if temp_mark[manager_name]:
		_log_error("检测到循环依赖: " + manager_name)
		return
		
	if not visited[manager_name]:
		temp_mark[manager_name] = true
		
		# 递归访问所有依赖
		for dependency in _dependency_graph[manager_name]:
			if _managers.has(dependency):
				_visit(dependency, visited, temp_mark, result)
		
		temp_mark[manager_name] = false
		visited[manager_name] = true
		result.push_front(manager_name)

# 记录错误信息
func _log_error(message: String) -> void:
	if debug_mode:
		print("[ManagerSystem] 错误: " + message)
		
	# 发送错误事件
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus and EventBus.has_method("emit_event"):
			EventBus.debug.emit_event("debug_message", [message, 2])

# 记录信息
func _log_info(message: String) -> void:
	if debug_mode:
		print("[ManagerSystem] 信息: " + message)
		
	# 发送调试事件
	if Engine.has_singleton("EventBus"):
		var EventBus = Engine.get_singleton("EventBus")
		if EventBus and EventBus.has_method("emit_event"):
			EventBus.debug.emit_event("debug_message", [message, 0])
