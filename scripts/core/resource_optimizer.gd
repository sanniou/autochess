extends Node
class_name ResourceOptimizer
## 资源优化器
## 用于优化资源加载和卸载，减少内存占用

# 信号
signal resource_loaded(resource_path, resource_type)
signal resource_unloaded(resource_path, resource_type)
signal memory_warning(current_usage, threshold)

# 资源类型
enum ResourceType {
	TEXTURE,
	AUDIO,
	SCENE,
	SHADER,
	FONT,
	OTHER
}

# 资源优先级
enum ResourcePriority {
	LOW,    # 低优先级，可随时卸载
	MEDIUM, # 中优先级，在内存压力下卸载
	HIGH,   # 高优先级，尽量不卸载
	CRITICAL # 关键资源，不卸载
}

# 资源缓存
var _resource_cache = {}

# 资源引用计数
var _resource_refs = {}

# 资源优先级
var _resource_priorities = {}

# 资源最后访问时间
var _resource_last_access = {}

# 资源类型
var _resource_types = {}

# 资源大小（估计值，单位：字节）
var _resource_sizes = {}

# 内存使用统计
var _memory_stats = {
	"total_resources": 0,
	"total_size": 0,
	"by_type": {
		ResourceType.TEXTURE: {"count": 0, "size": 0},
		ResourceType.AUDIO: {"count": 0, "size": 0},
		ResourceType.SCENE: {"count": 0, "size": 0},
		ResourceType.SHADER: {"count": 0, "size": 0},
		ResourceType.FONT: {"count": 0, "size": 0},
		ResourceType.OTHER: {"count": 0, "size": 0}
	}
}

# 优化设置
var optimization_settings = {
	"auto_unload_enabled": true,
	"check_interval": 30.0,  # 检查间隔（秒）
	"memory_threshold": 500 * 1024 * 1024,  # 内存阈值（字节）
	"unused_time_threshold": 60.0,  # 未使用时间阈值（秒）
	"batch_unload_count": 5  # 批量卸载数量
}

# 计时器
var _check_timer = 0.0

# 初始化
func _ready() -> void:
	# 设置进程模式
	process_mode = Node.PROCESS_MODE_ALWAYS

# 进程
func _process(delta: float) -> void:
	if not optimization_settings.auto_unload_enabled:
		return
	
	# 更新计时器
	_check_timer += delta
	
	# 检查是否需要卸载资源
	if _check_timer >= optimization_settings.check_interval:
		_check_timer = 0.0
		_check_memory_usage()

## 加载资源
func load_resource(path: String, type: int = ResourceType.OTHER, priority: int = ResourcePriority.MEDIUM) -> Resource:
	# 检查资源是否已加载
	if _resource_cache.has(path):
		# 更新引用计数
		_resource_refs[path] += 1
		
		# 更新最后访问时间
		_resource_last_access[path] = Time.get_unix_time_from_system()
		
		return _resource_cache[path]
	
	# 加载资源
	var resource = load(path)
	if resource == null:
		push_error("无法加载资源: " + path)
		return null
	
	# 缓存资源
	_resource_cache[path] = resource
	
	# 初始化引用计数
	_resource_refs[path] = 1
	
	# 设置资源优先级
	_resource_priorities[path] = priority
	
	# 设置资源类型
	_resource_types[path] = type
	
	# 设置最后访问时间
	_resource_last_access[path] = Time.get_unix_time_from_system()
	
	# 估计资源大小
	var size = _estimate_resource_size(resource, type)
	_resource_sizes[path] = size
	
	# 更新内存统计
	_update_memory_stats_add(path, type, size)
	
	# 发送信号
	resource_loaded.emit(path, type)
	
	return resource

## 卸载资源
func unload_resource(path: String) -> bool:
	# 检查资源是否已加载
	if not _resource_cache.has(path):
		return false
	
	# 更新引用计数
	_resource_refs[path] -= 1
	
	# 如果引用计数为0，卸载资源
	if _resource_refs[path] <= 0:
		var type = _resource_types[path]
		var size = _resource_sizes[path]
		
		# 从缓存中移除
		_resource_cache.erase(path)
		_resource_refs.erase(path)
		_resource_priorities.erase(path)
		_resource_last_access.erase(path)
		_resource_types.erase(path)
		_resource_sizes.erase(path)
		
		# 更新内存统计
		_update_memory_stats_remove(type, size)
		
		# 发送信号
		resource_unloaded.emit(path, type)
		
		return true
	
	return false

## 预加载资源
func preload_resource(path: String, type: int = ResourceType.OTHER, priority: int = ResourcePriority.MEDIUM) -> Resource:
	return load_resource(path, type, priority)

## 获取资源
func get_resource(path: String) -> Resource:
	# 检查资源是否已加载
	if _resource_cache.has(path):
		# 更新引用计数
		_resource_refs[path] += 1
		
		# 更新最后访问时间
		_resource_last_access[path] = Time.get_unix_time_from_system()
		
		return _resource_cache[path]
	
	# 资源未加载，尝试加载
	return load_resource(path)

## 释放资源
func release_resource(path: String) -> bool:
	# 检查资源是否已加载
	if not _resource_cache.has(path):
		return false
	
	# 更新引用计数
	_resource_refs[path] -= 1
	
	# 更新最后访问时间
	_resource_last_access[path] = Time.get_unix_time_from_system()
	
	return true

## 设置资源优先级
func set_resource_priority(path: String, priority: int) -> bool:
	# 检查资源是否已加载
	if not _resource_cache.has(path):
		return false
	
	# 设置优先级
	_resource_priorities[path] = priority
	
	return true

## 获取内存统计
func get_memory_stats() -> Dictionary:
	return _memory_stats

## 清除所有资源
func clear_all_resources() -> void:
	# 清除所有资源
	_resource_cache.clear()
	_resource_refs.clear()
	_resource_priorities.clear()
	_resource_last_access.clear()
	_resource_types.clear()
	_resource_sizes.clear()
	
	# 重置内存统计
	_reset_memory_stats()
	
	# 强制垃圾回收
	OS.delay_msec(100)  # 给GC一些时间
	
	EventBus.debug.emit_event("debug_message", ["所有资源已清除", 0])

## 检查内存使用情况
func _check_memory_usage() -> void:
	# 获取当前内存使用
	var current_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	
	# 检查是否超过阈值
	if current_memory > optimization_settings.memory_threshold:
		# 发送内存警告
		memory_warning.emit(current_memory, optimization_settings.memory_threshold)
		
		# 卸载低优先级资源
		_unload_low_priority_resources()
	else:
		# 卸载长时间未使用的资源
		_unload_unused_resources()

## 卸载低优先级资源
func _unload_low_priority_resources() -> void:
	# 获取当前时间
	var current_time = Time.get_unix_time_from_system()
	
	# 创建资源列表
	var resources = []
	
	# 收集低优先级资源
	for path in _resource_cache.keys():
		if _resource_refs[path] <= 0 and _resource_priorities[path] < ResourcePriority.HIGH:
			resources.append({
				"path": path,
				"priority": _resource_priorities[path],
				"last_access": _resource_last_access[path],
				"unused_time": current_time - _resource_last_access[path]
			})
	
	# 按优先级和未使用时间排序
	resources.sort_custom(func(a, b):
		# 首先按优先级排序
		if a.priority != b.priority:
			return a.priority < b.priority
		
		# 然后按未使用时间排序
		return a.unused_time > b.unused_time
	)
	
	# 卸载一批资源
	var unload_count = min(resources.size(), optimization_settings.batch_unload_count)
	for i in range(unload_count):
		unload_resource(resources[i].path)
	
	if unload_count > 0:
		EventBus.debug.emit_event("debug_message", ["已卸载 " + str(unload_count]) + " 个低优先级资源", 0)

## 卸载未使用资源
func _unload_unused_resources() -> void:
	# 获取当前时间
	var current_time = Time.get_unix_time_from_system()
	
	# 创建资源列表
	var resources = []
	
	# 收集长时间未使用的资源
	for path in _resource_cache.keys():
		var unused_time = current_time - _resource_last_access[path]
		if _resource_refs[path] <= 0 and unused_time > optimization_settings.unused_time_threshold:
			resources.append({
				"path": path,
				"priority": _resource_priorities[path],
				"unused_time": unused_time
			})
	
	# 按未使用时间排序
	resources.sort_custom(func(a, b): return a.unused_time > b.unused_time)
	
	# 卸载一批资源
	var unload_count = min(resources.size(), optimization_settings.batch_unload_count)
	for i in range(unload_count):
		unload_resource(resources[i].path)
	
	if unload_count > 0:
		EventBus.debug.emit_event("debug_message", ["已卸载 " + str(unload_count]) + " 个长时间未使用的资源", 0)

## 估计资源大小
func _estimate_resource_size(resource: Resource, type: int) -> int:
	match type:
		ResourceType.TEXTURE:
			if resource is Texture2D:
				var texture = resource as Texture2D
				return texture.get_width() * texture.get_height() * 4  # 假设RGBA格式
			return 1024 * 1024  # 默认1MB
		
		ResourceType.AUDIO:
			if resource is AudioStream:
				# 音频大小估计比较复杂，这里使用一个粗略值
				return 1024 * 1024  # 默认1MB
			return 512 * 1024  # 默认512KB
		
		ResourceType.SCENE:
			# 场景大小很难估计，这里使用一个粗略值
			return 2 * 1024 * 1024  # 默认2MB
		
		ResourceType.SHADER:
			# 着色器通常较小
			return 64 * 1024  # 默认64KB
		
		ResourceType.FONT:
			# 字体大小也很难估计
			return 512 * 1024  # 默认512KB
		
		_:  # ResourceType.OTHER
			return 256 * 1024  # 默认256KB

## 更新内存统计（添加资源）
func _update_memory_stats_add(path: String, type: int, size: int) -> void:
	_memory_stats.total_resources += 1
	_memory_stats.total_size += size
	
	_memory_stats.by_type[type].count += 1
	_memory_stats.by_type[type].size += size

## 更新内存统计（移除资源）
func _update_memory_stats_remove(type: int, size: int) -> void:
	_memory_stats.total_resources -= 1
	_memory_stats.total_size -= size
	
	_memory_stats.by_type[type].count -= 1
	_memory_stats.by_type[type].size -= size

## 重置内存统计
func _reset_memory_stats() -> void:
	_memory_stats = {
		"total_resources": 0,
		"total_size": 0,
		"by_type": {
			ResourceType.TEXTURE: {"count": 0, "size": 0},
			ResourceType.AUDIO: {"count": 0, "size": 0},
			ResourceType.SCENE: {"count": 0, "size": 0},
			ResourceType.SHADER: {"count": 0, "size": 0},
			ResourceType.FONT: {"count": 0, "size": 0},
			ResourceType.OTHER: {"count": 0, "size": 0}
		}
	}

## 启用自动卸载
func enable_auto_unload() -> void:
	optimization_settings.auto_unload_enabled = true
	EventBus.debug.emit_event("debug_message", ["资源自动卸载已启用", 0])

## 禁用自动卸载
func disable_auto_unload() -> void:
	optimization_settings.auto_unload_enabled = false
	EventBus.debug.emit_event("debug_message", ["资源自动卸载已禁用", 0])

## 设置优化参数
func set_optimization_settings(settings: Dictionary) -> void:
	# 更新设置
	if settings.has("auto_unload_enabled"):
		optimization_settings.auto_unload_enabled = settings.auto_unload_enabled
	
	if settings.has("check_interval"):
		optimization_settings.check_interval = max(1.0, settings.check_interval)
	
	if settings.has("memory_threshold"):
		optimization_settings.memory_threshold = max(100 * 1024 * 1024, settings.memory_threshold)
	
	if settings.has("unused_time_threshold"):
		optimization_settings.unused_time_threshold = max(10.0, settings.unused_time_threshold)
	
	if settings.has("batch_unload_count"):
		optimization_settings.batch_unload_count = max(1, settings.batch_unload_count)
	
	EventBus.debug.emit_event("debug_message", ["资源优化设置已更新", 0])
