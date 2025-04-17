extends Node
class_name BaseManager
## 管理器基类
## 所有管理器应继承此类，提供统一的接口和生命周期管理

# 信号
signal initialized()
signal reset_completed()
signal cleaned_up()
signal dependency_added(dependency_name: String)
signal dependency_removed(dependency_name: String)
signal error_occurred(error_message: String)

# 初始化状态
var _initialized: bool = false

# 管理器名称
var manager_name: String = ""

# 依赖的管理器
var _dependencies: Array[String] = []

# 错误信息
var _error: String = ""

# 初始化方法
func initialize() -> bool:
	# 如果已经初始化，直接返回成功
	if _initialized:
		return true

	# 清空错误信息
	_error = ""

	# 检查依赖
	if not _check_dependencies():
		_error = "管理器初始化失败，依赖未满足: " + manager_name
		EventBus.debug.debug_message.emit(_error, 2)
		error_occurred.emit(_error)
		return false

	# 执行初始化
	_do_initialize()
	_initialized = true
	EventBus.debug.debug_message.emit(manager_name + " 初始化完成", 0)
	initialized.emit()
	return true

# 子类重写此方法实现具体初始化逻辑
func _do_initialize() -> void:
	pass

# 清理方法
func cleanup() -> bool:
	# 如果未初始化，直接返回成功
	if not _initialized:
		return true

	# 清空错误信息
	_error = ""

	# 执行清理
	_do_cleanup()
	_initialized = false
	EventBus.debug.debug_message.emit(manager_name + " 清理完成", 0)
	cleaned_up.emit()
	return true

# 子类重写此方法实现具体清理逻辑
func _do_cleanup() -> void:
	pass

# 重置方法
func reset() -> bool:
	# 清空错误信息
	_error = ""

	# 执行重置
	_do_reset()
	EventBus.debug.debug_message.emit(manager_name + " 重置完成", 0)
	reset_completed.emit()
	return true

# 子类重写此方法实现具体重置逻辑
func _do_reset() -> void:
	pass

# 检查是否已初始化
func is_initialized() -> bool:
	return _initialized

# 设置管理器名称
func set_manager_name(name: String) -> void:
	manager_name = name

# 添加依赖
func add_dependency(dependency_name: String) -> bool:
	# 检查是否已经有这个依赖
	if _dependencies.has(dependency_name):
		return true

	# 添加依赖
	_dependencies.append(dependency_name)
	EventBus.debug.debug_message.emit("添加依赖: " + manager_name + " -> " + dependency_name, 0)
	dependency_added.emit(dependency_name)
	return true

# 移除依赖
func remove_dependency(dependency_name: String) -> bool:
	# 检查是否有这个依赖
	if not _dependencies.has(dependency_name):
		return true

	# 移除依赖
	_dependencies.erase(dependency_name)
	EventBus.debug.debug_message.emit("移除依赖: " + manager_name + " -> " + dependency_name, 0)
	dependency_removed.emit(dependency_name)
	return true

# 检查依赖是否满足
func _check_dependencies() -> bool:
	# 如果没有依赖，直接返回成功
	if _dependencies.is_empty():
		return true

	# 获取GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		_error = "无法获取GameManager"
		EventBus.debug.debug_message.emit(_error, 2)
		return false

	# 检查每个依赖
	for dependency in _dependencies:
		# 检查依赖的管理器是否存在
		if not game_manager.has_manager(dependency):
			_error = "依赖的管理器不存在: " + dependency
			EventBus.debug.debug_message.emit(_error, 2)
			return false

		# 检查依赖的管理器是否已初始化
		var dependency_manager = game_manager.get_manager(dependency)
		if not dependency_manager or not dependency_manager.is_initialized():
			_error = "依赖的管理器未初始化: " + dependency
			EventBus.debug.debug_message.emit(_error, 2)
			return false

	# 所有依赖都满足
	return true

# 获取依赖列表
func get_dependencies() -> Array[String]:
	return _dependencies

# 获取错误信息
func get_error() -> String:
	return _error

# 检查是否有错误
func has_error() -> bool:
	return not _error.is_empty()

# 清空错误信息
func clear_error() -> void:
	_error = ""

# 获取管理器状态
func get_status() -> Dictionary:
	return {
		"name": manager_name,
		"initialized": _initialized,
		"dependencies": _dependencies,
		"error": _error
	}
