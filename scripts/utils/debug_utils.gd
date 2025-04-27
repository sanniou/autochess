extends Node
## 调试工具
## 提供调试和性能分析功能

# 是否启用调试
var debug_enabled = OS.is_debug_build()

# 性能计时器
var _performance_timers = {}

# FPS计数器
var _fps_samples = []
var _fps_sample_time = 0.0
const FPS_SAMPLE_INTERVAL = 1.0
const FPS_SAMPLE_COUNT = 60

# 内存使用计数器
var _memory_samples = []
var _memory_sample_time = 0.0
const MEMORY_SAMPLE_INTERVAL = 5.0
const MEMORY_SAMPLE_COUNT = 12

func _ready():
	# 初始化调试工具
	if debug_enabled:
		_initialize_debug_tools()

func _process(delta):
	# 更新FPS计数器
	if debug_enabled:
		_update_fps_counter(delta)
		_update_memory_counter(delta)

## 初始化调试工具
func _initialize_debug_tools() -> void:
	# 初始化FPS计数器
	_fps_samples.resize(FPS_SAMPLE_COUNT)
	_fps_samples.fill(0)
	
	# 初始化内存计数器
	_memory_samples.resize(MEMORY_SAMPLE_COUNT)
	_memory_samples.fill(0)

## 更新FPS计数器
func _update_fps_counter(delta: float) -> void:
	_fps_sample_time += delta
	
	if _fps_sample_time >= FPS_SAMPLE_INTERVAL:
		_fps_sample_time = 0.0
		
		# 移除最旧的样本
		_fps_samples.pop_front()
		
		# 添加新样本
		_fps_samples.append(Engine.get_frames_per_second())

## 更新内存计数器
func _update_memory_counter(delta: float) -> void:
	_memory_sample_time += delta
	
	if _memory_sample_time >= MEMORY_SAMPLE_INTERVAL:
		_memory_sample_time = 0.0
		
		# 移除最旧的样本
		_memory_samples.pop_front()
		
		# 添加新样本（静态内存，单位MB）
		_memory_samples.append(OS.get_static_memory_usage() / 1048576.0)

## 开始性能计时
func start_timer(timer_name: String) -> void:
	if not debug_enabled:
		return
	
	_performance_timers[timer_name] = Time.get_ticks_usec()

## 结束性能计时并返回耗时（毫秒）
func end_timer(timer_name: String) -> float:
	if not debug_enabled or not _performance_timers.has(timer_name):
		return 0.0
	
	var end_time = Time.get_ticks_usec()
	var start_time = _performance_timers[timer_name]
	var duration = (end_time - start_time) / 1000.0  # 转换为毫秒
	
	_performance_timers.erase(timer_name)
	
	return duration

## 记录性能计时
func log_timer(timer_name: String) -> void:
	if not debug_enabled or not _performance_timers.has(timer_name):
		return
	
	var duration = end_timer(timer_name)
	DebugManager.log_message("性能计时 [%s]: %.2f ms" % [timer_name, duration], DebugManager.DebugLevel.INFO)

## 获取平均FPS
func get_average_fps() -> float:
	if _fps_samples.size() == 0:
		return 0.0
	
	var sum = 0.0
	for fps in _fps_samples:
		sum += fps
	
	return sum / _fps_samples.size()

## 获取最小FPS
func get_min_fps() -> float:
	if _fps_samples.size() == 0:
		return 0.0
	
	var min_fps = _fps_samples[0]
	for fps in _fps_samples:
		min_fps = min(min_fps, fps)
	
	return min_fps

## 获取最大FPS
func get_max_fps() -> float:
	if _fps_samples.size() == 0:
		return 0.0
	
	var max_fps = _fps_samples[0]
	for fps in _fps_samples:
		max_fps = max(max_fps, fps)
	
	return max_fps

## 获取当前内存使用量（MB）
func get_memory_usage() -> float:
	return OS.get_static_memory_usage() / 1048576.0

## 获取内存使用趋势
func get_memory_trend() -> Array:
	return _memory_samples

## 打印对象信息
func print_object_info(obj: Object) -> void:
	if not debug_enabled or obj == null:
		return
	
	var clazz_name = obj.get_class()
	var script = obj.get_script()
	var script_path = script.resource_path if script else "无脚本"
	
	var info = "对象信息:\n"
	info += "- 类: " + clazz_name + "\n"
	info += "- 脚本: " + script_path + "\n"
	
	# 打印属性
	info += "- 属性:\n"
	var property_list = obj.get_property_list()
	for property in property_list:
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = obj.get(property.name)
			info += "  - " + property.name + ": " + str(value) + "\n"
	
	DebugManager.log_message(info, DebugManager.DebugLevel.INFO)

## 打印节点树
func print_node_tree(node: Node, max_depth: int = -1, current_depth: int = 0) -> void:
	if not debug_enabled or node == null:
		return
	
	if max_depth >= 0 and current_depth > max_depth:
		return
	
	var indent = "  ".repeat(current_depth)
	var node_info = indent + node.name + " (" + node.get_class() + ")"
	
	if node.get_script():
		node_info += " [脚本: " + node.get_script().resource_path.get_file() + "]"
	
	DebugManager.log_message(node_info, DebugManager.DebugLevel.INFO)
	
	for child in node.get_children():
		print_node_tree(child, max_depth, current_depth + 1)

## 检查节点是否有循环引用
func check_circular_references(node: Node) -> bool:
	if not debug_enabled or node == null:
		return false
	
	var visited = {}
	var has_circular = _check_circular_references_recursive(node, visited)
	
	if has_circular:
		DebugManager.log_message("检测到循环引用!", DebugManager.DebugLevel.ERROR)
	
	return has_circular

## 递归检查循环引用
func _check_circular_references_recursive(obj: Object, visited: Dictionary) -> bool:
	if visited.has(obj):
		return true
	
	visited[obj] = true
	
	var property_list = obj.get_property_list()
	for property in property_list:
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = obj.get(property.name)
			if value is Object and value != null:
				if _check_circular_references_recursive(value, visited.duplicate()):
					return true
	
	return false

## 打印调用堆栈
func print_stack_trace() -> void:
	if not debug_enabled:
		return
	
	var stack = get_stack()
	var trace = "调用堆栈:\n"
	
	for i in range(stack.size()):
		var frame = stack[i]
		trace += "%d: %s:%d - %s\n" % [i, frame.source, frame.line, frame.function]
	
	DebugManager.log_message(trace, DebugManager.DebugLevel.INFO)

## 获取调用堆栈
func get_stack() -> Array:
	return get_stack_depth_skip(0, 0)

## 获取指定深度的调用堆栈，跳过指定数量的帧
func get_stack_depth_skip(depth: int = 16, skip: int = 1) -> Array:
	var stack = []
	var i = skip
	var frame = get_stack_frame_info(i)
	
	while frame.has("function") and (depth <= 0 or i - skip < depth):
		stack.append(frame)
		i += 1
		frame = get_stack_frame_info(i)
	
	return stack

## 获取指定索引的堆栈帧信息
func get_stack_frame_info(index: int) -> Dictionary:
	# 这是一个模拟实现，Godot实际上没有提供这个API
	# 在实际项目中，可以使用其他方法获取堆栈信息
	return {
		"function": "",
		"source": "",
		"line": 0
	}
