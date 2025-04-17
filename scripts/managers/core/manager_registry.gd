extends Node
class_name ManagerRegistry
## 管理器注册表
## 负责所有管理器的注册、初始化和获取

# 信号
signal manager_registered(manager_name: String)
signal manager_initialized(manager_name: String)
signal manager_reset(manager_name: String)
signal manager_error(manager_name: String, error_message: String)

# 存储所有管理器的字典
var _managers = {}

# 管理器依赖关系
var _dependencies = {}

# 管理器初始化状态
var _initialized = {}

# 管理器错误记录
var _errors = {}

# 注册管理器
func register(manager_name: String, manager_instance, dependencies: Array = []) -> void:
	# 检查管理器是否已存在
	if _managers.has(manager_name):
		var error_message = "管理器已存在: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 1])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return

	# 检查管理器实例是否有效
	if manager_instance == null:
		var error_message = "管理器实例为空: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return

	# 注册管理器
	_managers[manager_name] = manager_instance
	_dependencies[manager_name] = dependencies
	_initialized[manager_name] = false
	_errors[manager_name] = ""

	# 输出调试信息
	EventBus.debug.emit_event("debug_message", ["管理器注册成功: " + manager_name, 0])

	# 发送信号
	manager_registered.emit(manager_name)

# 初始化管理器
func initialize(manager_name: String) -> bool:
	# 如果已经初始化，直接返回成功
	if _initialized.get(manager_name, false):
		return true

	# 如果管理器不存在，返回失败
	if not _managers.has(manager_name):
		var error_message = "管理器不存在: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return false

	# 先初始化依赖
	var dependencies = _dependencies.get(manager_name, [])
	for dep in dependencies:
		if not initialize(dep):
			var error_message = "初始化依赖失败: " + dep + " (被 " + manager_name + " 依赖)"
			EventBus.debug.emit_event("debug_message", [error_message, 2])
			_errors[manager_name] = error_message
			manager_error.emit(manager_name, error_message)
			return false

	# 初始化管理器
	var manager = _managers[manager_name]
	if manager.has_method("initialize"):
		manager.initialize()

	_initialized[manager_name] = true
	_errors[manager_name] = ""
	EventBus.debug.emit_event("debug_message", ["管理器初始化成功: " + manager_name, 0])
	manager_initialized.emit(manager_name)
	return true

# 初始化所有管理器
func initialize_all() -> Dictionary:
	# 初始化结果字典
	var results = {}

	# 遍历所有管理器
	for manager_name in _managers.keys():
		var success = initialize(manager_name)
		results[manager_name] = success

	# 输出初始化结果
	var success_count = 0
	var failure_count = 0
	for manager_name in results.keys():
		if results[manager_name]:
			success_count += 1
		else:
			failure_count += 1

	EventBus.debug.emit_event("debug_message", ["管理器初始化统计: 成功=" + str(success_count) + ", 失败=" + str(failure_count), 0])

	# 返回结果
	return results

# 获取管理器
func get_manager(manager_name: String):
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		var error_message = "管理器不存在: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return null

	# 确保管理器已初始化
	if not _initialized.get(manager_name, false):
		EventBus.debug.emit_event("debug_message", ["尝试自动初始化管理器: " + manager_name, 0])
		if not initialize(manager_name):
			var error_message = "无法初始化管理器: " + manager_name
			EventBus.debug.emit_event("debug_message", [error_message, 2])
			_errors[manager_name] = error_message
			manager_error.emit(manager_name, error_message)
			return null

	# 返回管理器实例
	return _managers[manager_name]

# 检查管理器是否存在
func has_manager(manager_name: String) -> bool:
	return _managers.has(manager_name)

# 检查管理器是否已初始化
func is_initialized(manager_name: String) -> bool:
	return _initialized.get(manager_name, false)

# 获取所有管理器名称
func get_all_manager_names() -> Array:
	return _managers.keys()

# 获取所有已初始化的管理器名称
func get_initialized_manager_names() -> Array:
	var result = []
	for manager_name in _managers.keys():
		if _initialized.get(manager_name, false):
			result.append(manager_name)
	return result

# 获取管理器的依赖
func get_dependencies(manager_name: String) -> Array:
	return _dependencies.get(manager_name, [])

# 重置管理器
func reset_manager(manager_name: String) -> bool:
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		var error_message = "管理器不存在: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return false

	# 重置管理器
	var manager = _managers[manager_name]
	if manager.has_method("reset"):
		manager.reset()
		EventBus.debug.emit_event("debug_message", ["管理器重置成功: " + manager_name, 0])
		manager_reset.emit(manager_name)
		return true
	else:
		var error_message = "管理器没有reset方法: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 1])
		_errors[manager_name] = error_message
		return false

# 重置所有管理器
func reset_all() -> Dictionary:
	# 重置结果字典
	var results = {}

	# 遍历所有管理器
	for manager_name in _managers.keys():
		var success = reset_manager(manager_name)
		results[manager_name] = success

	# 输出重置结果
	var success_count = 0
	var failure_count = 0
	for manager_name in results.keys():
		if results[manager_name]:
			success_count += 1
		else:
			failure_count += 1

	EventBus.debug.emit_event("debug_message", ["管理器重置统计: 成功=" + str(success_count) + ", 失败=" + str(failure_count), 0])

	# 返回结果
	return results

# 清理管理器
func cleanup_manager(manager_name: String) -> bool:
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		var error_message = "管理器不存在: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return false

	# 清理管理器
	var manager = _managers[manager_name]
	if manager.has_method("cleanup"):
		manager.cleanup()
		EventBus.debug.emit_event("debug_message", ["管理器清理成功: " + manager_name, 0])
		return true
	else:
		var error_message = "管理器没有cleanup方法: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 1])
		_errors[manager_name] = error_message
		return false

# 清理所有管理器
func cleanup_all() -> Dictionary:
	# 清理结果字典
	var results = {}

	# 遍历所有管理器
	for manager_name in _managers.keys():
		var success = cleanup_manager(manager_name)
		results[manager_name] = success

	# 输出清理结果
	var success_count = 0
	var failure_count = 0
	for manager_name in results.keys():
		if results[manager_name]:
			success_count += 1
		else:
			failure_count += 1

	EventBus.debug.emit_event("debug_message", ["管理器清理统计: 成功=" + str(success_count) + ", 失败=" + str(failure_count), 0])

	# 返回结果
	return results

# 获取管理器错误信息
func get_error(manager_name: String) -> String:
	return _errors.get(manager_name, "")

# 获取所有管理器错误信息
func get_all_errors() -> Dictionary:
	return _errors

# 获取有错误的管理器
func get_managers_with_errors() -> Array:
	var result = []
	for manager_name in _errors.keys():
		if not _errors[manager_name].is_empty():
			result.append(manager_name)
	return result

# 添加管理器依赖
func add_dependency(manager_name: String, dependency: String) -> bool:
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		var error_message = "管理器不存在: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return false

	# 检查依赖是否存在
	if not _managers.has(dependency):
		var error_message = "依赖管理器不存在: " + dependency
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return false

	# 检查是否已经有这个依赖
	if dependency in _dependencies[manager_name]:
		return true

	# 添加依赖
	_dependencies[manager_name].append(dependency)
	EventBus.debug.emit_event("debug_message", ["添加依赖成功: " + manager_name + " -> " + dependency, 0])
	return true

# 移除管理器依赖
func remove_dependency(manager_name: String, dependency: String) -> bool:
	# 检查管理器是否存在
	if not _managers.has(manager_name):
		var error_message = "管理器不存在: " + manager_name
		EventBus.debug.emit_event("debug_message", [error_message, 2])
		_errors[manager_name] = error_message
		manager_error.emit(manager_name, error_message)
		return false

	# 检查是否有这个依赖
	if not dependency in _dependencies[manager_name]:
		return true

	# 移除依赖
	_dependencies[manager_name].erase(dependency)
	EventBus.debug.emit_event("debug_message", ["移除依赖成功: " + manager_name + " -> " + dependency, 0])
	return true
