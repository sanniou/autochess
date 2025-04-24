extends Node
class_name ComponentUpdateSystem
## 组件更新系统
## 提供分层更新机制，优化组件更新性能

## 更新频率枚举
enum UpdateFrequency {
	EVERY_FRAME,    # 每帧更新
	EVERY_PHYSICS,  # 每物理帧更新
	EVERY_SECOND,   # 每秒更新
	ON_DEMAND       # 按需更新
}

## 更新组
var _update_groups: Dictionary = {
	UpdateFrequency.EVERY_FRAME: [],
	UpdateFrequency.EVERY_PHYSICS: [],
	UpdateFrequency.EVERY_SECOND: [],
	UpdateFrequency.ON_DEMAND: []
}

## 组件映射 {组件ID: 更新频率}
var _component_frequency_map: Dictionary = {}

## 计时器
var _second_timer: float = 0.0

## 性能统计
var _performance_stats: Dictionary = {}
var _collect_stats: bool = false

## 初始化
func _ready() -> void:
	# 设置进程模式
	set_process(true)
	set_physics_process(true)
	
	# 在调试模式下收集性能统计
	_collect_stats = OS.is_debug_build()

## 注册组件
## @param component 要注册的组件
## @param frequency 更新频率
func register_component(component: Component, frequency: int = UpdateFrequency.EVERY_FRAME) -> void:
	# 检查频率是否有效
	if not _update_groups.has(frequency):
		push_error("无效的更新频率: " + str(frequency))
		return
	
	# 如果组件已注册，先取消注册
	if _component_frequency_map.has(component.get_id()):
		unregister_component(component)
	
	# 添加到更新组
	_update_groups[frequency].append(component)
	_component_frequency_map[component.get_id()] = frequency
	
	# 初始化性能统计
	if _collect_stats:
		_performance_stats[component.get_id()] = {
			"update_count": 0,
			"total_time": 0.0,
			"average_time": 0.0,
			"max_time": 0.0,
			"last_time": 0.0
		}

## 取消注册组件
## @param component 要取消注册的组件
func unregister_component(component: Component) -> void:
	# 检查组件是否已注册
	if not _component_frequency_map.has(component.get_id()):
		return
	
	# 获取组件的更新频率
	var frequency = _component_frequency_map[component.get_id()]
	
	# 从更新组中移除
	_update_groups[frequency].erase(component)
	_component_frequency_map.erase(component.get_id())
	
	# 清除性能统计
	if _collect_stats and _performance_stats.has(component.get_id()):
		_performance_stats.erase(component.get_id())

## 处理更新
func _process(delta: float) -> void:
	# 更新每帧组件
	_update_group(UpdateFrequency.EVERY_FRAME, delta)
	
	# 更新每秒组件
	_second_timer += delta
	if _second_timer >= 1.0:
		_update_group(UpdateFrequency.EVERY_SECOND, 1.0)
		_second_timer -= 1.0

## 物理处理更新
func _physics_process(delta: float) -> void:
	# 更新每物理帧组件
	_update_group(UpdateFrequency.EVERY_PHYSICS, delta)

## 更新组件组
## @param frequency 更新频率
## @param delta 时间增量
func _update_group(frequency: int, delta: float) -> void:
	for component in _update_groups[frequency]:
		if is_instance_valid(component) and component.is_enabled:
			_update_component(component, delta)

## 更新单个组件
## @param component 要更新的组件
## @param delta 时间增量
func _update_component(component: Component, delta: float) -> void:
	if _collect_stats:
		var start_time = Time.get_ticks_usec()
		component.update(delta)
		var end_time = Time.get_ticks_usec()
		_update_performance_stats(component, end_time - start_time)
	else:
		component.update(delta)

## 按需更新组件
## @param component 要更新的组件
## @param delta 时间增量
func update_on_demand(component: Component, delta: float) -> void:
	if is_instance_valid(component) and component.is_enabled:
		var frequency = _component_frequency_map.get(component.get_id(), -1)
		if frequency == UpdateFrequency.ON_DEMAND:
			_update_component(component, delta)

## 更新性能统计
## @param component 组件
## @param update_time 更新时间（微秒）
func _update_performance_stats(component: Component, update_time: int) -> void:
	var component_id = component.get_id()
	if not _performance_stats.has(component_id):
		return
	
	var stats = _performance_stats[component_id]
	var time_ms = update_time / 1000.0  # 转换为毫秒
	
	stats.update_count += 1
	stats.total_time += time_ms
	stats.last_time = time_ms
	stats.average_time = stats.total_time / stats.update_count
	stats.max_time = max(stats.max_time, time_ms)

## 获取性能统计
## @return 性能统计字典
func get_performance_stats() -> Dictionary:
	return _performance_stats.duplicate(true)

## 获取昂贵的组件
## @param threshold_ms 阈值（毫秒）
## @return 昂贵组件列表
func get_expensive_components(threshold_ms: float = 1.0) -> Array:
	var expensive_components = []
	
	for component_id in _performance_stats:
		var stats = _performance_stats[component_id]
		if stats.average_time > threshold_ms:
			expensive_components.append({
				"component_id": component_id,
				"average_time": stats.average_time,
				"max_time": stats.max_time,
				"update_count": stats.update_count
			})
	
	# 按平均时间排序
	expensive_components.sort_custom(func(a, b): return a.average_time > b.average_time)
	
	return expensive_components

## 清除性能统计
func clear_performance_stats() -> void:
	for component_id in _performance_stats:
		_performance_stats[component_id] = {
			"update_count": 0,
			"total_time": 0.0,
			"average_time": 0.0,
			"max_time": 0.0,
			"last_time": 0.0
		}

## 获取组件数量
## @return 组件数量字典
func get_component_counts() -> Dictionary:
	var counts = {}
	
	for frequency in _update_groups:
		counts[frequency] = _update_groups[frequency].size()
	
	return counts

## 设置是否收集性能统计
## @param collect 是否收集
func set_collect_stats(collect: bool) -> void:
	_collect_stats = collect
	
	# 如果禁用统计，清除现有数据
	if not _collect_stats:
		clear_performance_stats()
