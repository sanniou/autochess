extends Node
## 对象池
## 用于管理和重用游戏对象，提高性能

# 信号
signal pool_created(pool_name, initial_size)
signal pool_cleared(pool_name)
signal pool_resized(pool_name, old_size, new_size)
signal object_requested(pool_name, success)
signal object_released(pool_name)

# 对象池
var _pools = {}

# 对象池配置
var _pool_configs = {}

# 对象池状态
var _pool_stats = {}

# 自动调整设置
var auto_resize_settings = {
	"enabled": true,
	"check_interval": 5.0,  # 检查间隔（秒）
	"usage_threshold": 0.8,  # 使用率阈值
	"min_grow_size": 5,     # 最小增长大小
	"max_grow_size": 20,    # 最大增长大小
	"shrink_threshold": 0.3, # 缩小阈值
	"shrink_interval": 30.0, # 缩小检查间隔（秒）
	"min_pool_size": 10     # 最小池大小
}

# 计时器
var _resize_timer = 0.0
var _shrink_timer = 0.0

## 创建对象池
func create_pool(pool_name: String, object_scene: PackedScene, initial_size: int = 0, grow_size: int = 5, max_size: int = 100) -> void:
	if _pools.has(pool_name):
		push_error("对象池已存在: " + pool_name)
		return

	# 创建新池
	_pools[pool_name] = []

	# 保存配置
	_pool_configs[pool_name] = {
		"scene": object_scene,
		"grow_size": grow_size,
		"max_size": max_size,
		"creation_time": Time.get_unix_time_from_system(),
		"last_resize_time": 0
	}

	# 初始化统计信息
	_pool_stats[pool_name] = {
		"created": 0,
		"active": 0,
		"peak": 0,
		"total_requests": 0,
		"failed_requests": 0,
		"releases": 0,
		"auto_resizes": 0,
		"usage_rate": 0.0
	}

	# 预创建对象
	if initial_size > 0:
		_grow_pool(pool_name, initial_size)

	# 发送信号
	pool_created.emit(pool_name, initial_size)

## 从池中获取对象
func get_object(pool_name: String) -> Node:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return null

	# 更新请求统计
	_pool_stats[pool_name].total_requests += 1

	# 查找可用对象
	for obj in _pools[pool_name]:
		if not obj.is_inside_tree():
			_pool_stats[pool_name].active += 1
			if _pool_stats[pool_name].active > _pool_stats[pool_name].peak:
				_pool_stats[pool_name].peak = _pool_stats[pool_name].active

			# 更新使用率
			_update_usage_rate(pool_name)

			# 重置对象状态
			if obj.has_method("reset"):
				obj.reset()

			# 发送信号
			object_requested.emit(pool_name, true)

			return obj

	# 如果没有可用对象，尝试增长池
	var config = _pool_configs[pool_name]
	if _pools[pool_name].size() < config.max_size:
		_grow_pool(pool_name, config.grow_size)
		return get_object(pool_name)

	# 如果池已满，返回null
	_pool_stats[pool_name].failed_requests += 1
	push_warning("对象池已满: " + pool_name)

	# 发送信号
	object_requested.emit(pool_name, false)

	return null

## 释放对象回池
func release_object(pool_name: String, obj: Node) -> void:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return

	if not _pools[pool_name].has(obj):
		push_error("对象不属于此池: " + pool_name)
		return

	# 如果对象在场景树中，移除它
	if obj.is_inside_tree():
		obj.get_parent().remove_child(obj)

	_pool_stats[pool_name].active -= 1
	_pool_stats[pool_name].releases += 1

	# 更新使用率
	_update_usage_rate(pool_name)

	# 发送信号
	object_released.emit(pool_name)

## 清空对象池
func clear_pool(pool_name: String) -> void:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return

	# 销毁所有对象
	for obj in _pools[pool_name]:
		if obj.is_inside_tree():
			obj.get_parent().remove_child(obj)
		obj.queue_free()

	_pools[pool_name].clear()

	# 重置统计信息
	_pool_stats[pool_name].created = 0
	_pool_stats[pool_name].active = 0
	_pool_stats[pool_name].peak = 0
	_pool_stats[pool_name].usage_rate = 0.0

	# 发送信号
	pool_cleared.emit(pool_name)

## 获取对象池统计信息
func get_pool_stats(pool_name: String = "") -> Dictionary:
	if pool_name == "":
		return _pool_stats

	if not _pool_stats.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return {}

	return _pool_stats[pool_name]

## 更新使用率
func _update_usage_rate(pool_name: String) -> void:
	if not _pools.has(pool_name) or _pools[pool_name].is_empty():
		return

	# 计算使用率
	var total = _pools[pool_name].size()
	var active = _pool_stats[pool_name].active
	_pool_stats[pool_name].usage_rate = float(active) / float(total)

## 自动调整对象池大小
func _process(delta: float) -> void:
	if not auto_resize_settings.enabled:
		return

	# 更新增长计时器
	_resize_timer += delta

	# 更新缩小计时器
	_shrink_timer += delta

	# 检查是否需要调整增长
	if _resize_timer >= auto_resize_settings.check_interval:
		_resize_timer = 0.0
		_check_pools_for_resize()

	# 检查是否需要缩小
	if _shrink_timer >= auto_resize_settings.shrink_interval:
		_shrink_timer = 0.0
		_check_pools_for_shrink()

## 检查并调整所有对象池
func _check_pools_for_resize() -> void:
	for pool_name in _pools.keys():
		_check_pool_for_resize(pool_name)

## 检查并缩小所有对象池
func _check_pools_for_shrink() -> void:
	for pool_name in _pools.keys():
		_check_pool_for_shrink(pool_name)

## 检查并缩小单个对象池
func _check_pool_for_shrink(pool_name: String) -> void:
	if not _pools.has(pool_name) or _pools[pool_name].is_empty():
		return

	# 获取池统计信息
	var stats = _pool_stats[pool_name]
	var config = _pool_configs[pool_name]
	var current_size = _pools[pool_name].size()

	# 只有当使用率低于缩小阈值且当前大小大于最小池大小时才缩小
	if stats.usage_rate <= auto_resize_settings.shrink_threshold and current_size > auto_resize_settings.min_pool_size:
		# 计算新大小，保持在最小池大小之上
		var target_size = max(auto_resize_settings.min_pool_size, int(current_size * 0.7))

		# 缩小池
		if target_size < current_size:
			set_pool_size(pool_name, target_size)
			EventBus.debug_message.emit("对象池 " + pool_name + " 自动缩小，使用率: " + str(stats.usage_rate * 100) + "%", 0)

## 检查并调整单个对象池
func _check_pool_for_resize(pool_name: String) -> void:
	if not _pools.has(pool_name) or _pools[pool_name].is_empty():
		return

	# 获取池统计信息
	var stats = _pool_stats[pool_name]
	var config = _pool_configs[pool_name]

	# 获取当前时间
	var current_time = Time.get_unix_time_from_system()
	var current_size = _pools[pool_name].size()

	# 检查使用率
	if stats.usage_rate >= auto_resize_settings.usage_threshold:
		# 计算增长大小
		var grow_size = min(max(config.grow_size, auto_resize_settings.min_grow_size), auto_resize_settings.max_grow_size)

		# 检查是否达到最大大小
		if current_size < config.max_size:
			# 增长池
			_grow_pool(pool_name, grow_size)

			# 更新自动调整计数
			stats.auto_resizes += 1

			EventBus.debug_message.emit("对象池 " + pool_name + " 自动增长，使用率: " + str(stats.usage_rate * 100) + "%", 0)

	# 检查是否需要缩小池
	elif stats.usage_rate <= auto_resize_settings.shrink_threshold and current_size > auto_resize_settings.min_pool_size:
		# 检查上次缩小时间
		var time_since_last_resize = current_time - config.last_resize_time

		# 只有在超过缩小间隔时才缩小
		if time_since_last_resize >= auto_resize_settings.shrink_interval:
			# 计算新大小，保持在最小池大小之上
			var target_size = max(auto_resize_settings.min_pool_size, int(current_size * 0.7))

			# 缩小池
			if target_size < current_size:
				set_pool_size(pool_name, target_size)
				EventBus.debug_message.emit("对象池 " + pool_name + " 自动缩小，使用率: " + str(stats.usage_rate * 100) + "%", 0)

## 设置池大小
func set_pool_size(pool_name: String, new_size: int) -> bool:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return false

	var config = _pool_configs[pool_name]
	var current_size = _pools[pool_name].size()

	# 检查新大小是否有效
	if new_size < 0 or new_size > config.max_size:
		push_error("无效的池大小: " + str(new_size))
		return false

	# 如果需要增长
	if new_size > current_size:
		_grow_pool(pool_name, new_size - current_size)
		return true

	# 如果需要缩小
	if new_size < current_size:
		# 记录原始大小
		var old_size = current_size

		# 移除多余的对象
		while _pools[pool_name].size() > new_size:
			var obj = _pools[pool_name].pop_back()
			if obj.is_inside_tree():
				obj.get_parent().remove_child(obj)
			obj.queue_free()
			_pool_stats[pool_name].created -= 1

		# 更新最后调整时间
		_pool_configs[pool_name].last_resize_time = Time.get_unix_time_from_system()

		# 更新使用率
		_update_usage_rate(pool_name)

		# 发送信号
		pool_resized.emit(pool_name, old_size, new_size)

		EventBus.debug_message.emit("对象池 " + pool_name + " 缩小了 " + str(old_size - new_size) + " 个对象", 0)
		return true

	# 大小相同，无需调整
	return true

## 设置池最大大小
func set_pool_max_size(pool_name: String, max_size: int) -> bool:
	if not _pools.has(pool_name):
		push_error("对象池不存在: " + pool_name)
		return false

	# 检查新最大大小是否有效
	if max_size <= 0:
		push_error("无效的最大池大小: " + str(max_size))
		return false

	# 更新最大大小
	_pool_configs[pool_name].max_size = max_size

	# 如果当前大小超过新的最大大小，调整大小
	if _pools[pool_name].size() > max_size:
		set_pool_size(pool_name, max_size)

	EventBus.debug_message.emit("对象池 " + pool_name + " 最大大小已设置为 " + str(max_size), 0)
	return true

## 启用自动调整
func enable_auto_resize() -> void:
	auto_resize_settings.enabled = true
	EventBus.debug_message.emit("对象池自动调整已启用", 0)

## 禁用自动调整
func disable_auto_resize() -> void:
	auto_resize_settings.enabled = false
	EventBus.debug_message.emit("对象池自动调整已禁用", 0)

## 设置自动调整参数
func set_auto_resize_settings(settings: Dictionary) -> void:
	# 更新设置
	if settings.has("enabled"):
		auto_resize_settings.enabled = settings.enabled

	if settings.has("check_interval"):
		auto_resize_settings.check_interval = max(0.1, settings.check_interval)

	if settings.has("usage_threshold"):
		auto_resize_settings.usage_threshold = clamp(settings.usage_threshold, 0.1, 0.95)

	if settings.has("min_grow_size"):
		auto_resize_settings.min_grow_size = max(1, settings.min_grow_size)

	if settings.has("max_grow_size"):
		auto_resize_settings.max_grow_size = max(auto_resize_settings.min_grow_size, settings.max_grow_size)

	EventBus.debug_message.emit("对象池自动调整设置已更新", 0)

## 增长对象池
func _grow_pool(pool_name: String, count: int) -> void:
	var config = _pool_configs[pool_name]
	var scene = config.scene

	# 记录原始大小
	var old_size = _pools[pool_name].size()

	for i in range(count):
		if _pools[pool_name].size() >= config.max_size:
			break

		var obj = scene.instantiate()
		_pools[pool_name].append(obj)
		_pool_stats[pool_name].created += 1

		# 如果对象有初始化方法，调用它
		if obj.has_method("init_pooled"):
			obj.init_pooled()

	# 记录新大小
	var new_size = _pools[pool_name].size()

	# 更新最后调整时间
	_pool_configs[pool_name].last_resize_time = Time.get_unix_time_from_system()

	# 更新使用率
	_update_usage_rate(pool_name)

	EventBus.debug_message.emit("对象池 " + pool_name + " 增长了 " + str(new_size - old_size) + " 个对象", 0)

	# 发送信号
	pool_resized.emit(pool_name, old_size, new_size)
