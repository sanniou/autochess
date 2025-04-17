extends Node
class_name PerformanceMonitor
## 性能监控工具
## 用于监控和分析游戏性能

# 性能数据
var performance_data = {
	"fps": [],
	"memory": [],
	"draw_calls": [],
	"objects": [],
	"physics_objects": [],
	"script_time": {},
	"render_time": 0,
	"physics_time": 0,
	"frame_time": 0
}

# 监控设置
var monitor_settings = {
	"enabled": true,
	"log_interval": 5.0,  # 日志记录间隔（秒）
	"sample_count": 60,   # 样本数量
	"script_profiling": false,  # 是否启用脚本性能分析
	"warning_threshold": {
		"fps": 30,
		"memory": 500,  # MB
		"draw_calls": 1000,
		"objects": 1000
	}
}

# 计时器
var _log_timer = 0.0
var _frame_count = 0
var _last_frame_time = 0

# 初始化
func _ready() -> void:
	# 设置进程模式
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 初始化性能数据
	_initialize_performance_data()

# 进程
func _process(delta: float) -> void:
	if not monitor_settings.enabled:
		return
	
	# 更新帧计数
	_frame_count += 1
	
	# 收集性能数据
	_collect_performance_data()
	
	# 更新日志计时器
	_log_timer += delta
	if _log_timer >= monitor_settings.log_interval:
		_log_performance_data()
		_log_timer = 0.0

# 物理进程
func _physics_process(delta: float) -> void:
	if not monitor_settings.enabled:
		return
	
	# 收集物理性能数据
	performance_data.physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)

# 初始化性能数据
func _initialize_performance_data() -> void:
	# 初始化数组
	for i in range(monitor_settings.sample_count):
		performance_data.fps.append(0)
		performance_data.memory.append(0)
		performance_data.draw_calls.append(0)
		performance_data.objects.append(0)
		performance_data.physics_objects.append(0)

# 收集性能数据
func _collect_performance_data() -> void:
	# 计算帧时间
	var current_time = Time.get_ticks_msec()
	if _last_frame_time > 0:
		performance_data.frame_time = current_time - _last_frame_time
	_last_frame_time = current_time
	
	# 收集FPS
	var fps = Engine.get_frames_per_second()
	performance_data.fps.push_back(fps)
	if performance_data.fps.size() > monitor_settings.sample_count:
		performance_data.fps.pop_front()
	
	# 收集内存使用
	var memory = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024 * 1024)  # 转换为MB
	performance_data.memory.push_back(memory)
	if performance_data.memory.size() > monitor_settings.sample_count:
		performance_data.memory.pop_front()
	
	# 收集绘制调用
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	performance_data.draw_calls.push_back(draw_calls)
	if performance_data.draw_calls.size() > monitor_settings.sample_count:
		performance_data.draw_calls.pop_front()
	
	# 收集对象数量
	var objects = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	performance_data.objects.push_back(objects)
	if performance_data.objects.size() > monitor_settings.sample_count:
		performance_data.objects.pop_front()
	
	# 收集物理对象数量
	var physics_objects = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
	performance_data.physics_objects.push_back(physics_objects)
	if performance_data.physics_objects.size() > monitor_settings.sample_count:
		performance_data.physics_objects.pop_front()
	
	# 收集渲染时间
	performance_data.render_time = Performance.get_monitor(Performance.TIME_PROCESS)
	
	# 收集脚本性能数据
	if monitor_settings.script_profiling:
		_collect_script_performance()

# 收集脚本性能数据
func _collect_script_performance() -> void:
	# 这里应该使用Godot的脚本性能分析API
	# 但在Godot 4中，这个API可能有所变化
	# 暂时使用简单的方法记录关键函数的执行时间
	pass

# 记录性能数据
func _log_performance_data() -> void:
	# 计算平均值
	var avg_fps = _calculate_average(performance_data.fps)
	var avg_memory = _calculate_average(performance_data.memory)
	var avg_draw_calls = _calculate_average(performance_data.draw_calls)
	var avg_objects = _calculate_average(performance_data.objects)
	var avg_physics_objects = _calculate_average(performance_data.physics_objects)
	
	# 创建日志消息
	var log_message = "性能报告:\n"
	log_message += "FPS: %.1f" % avg_fps
	log_message += " | 内存: %.1f MB" % avg_memory
	log_message += " | 绘制调用: %d" % avg_draw_calls
	log_message += " | 对象数量: %d" % avg_objects
	log_message += " | 物理对象: %d" % avg_physics_objects
	log_message += " | 帧时间: %.2f ms" % performance_data.frame_time
	log_message += " | 渲染时间: %.2f ms" % performance_data.render_time
	log_message += " | 物理时间: %.2f ms" % performance_data.physics_time
	
	# 检查性能警告
	var warnings = _check_performance_warnings(avg_fps, avg_memory, avg_draw_calls, avg_objects)
	if not warnings.is_empty():
		log_message += "\n警告: " + warnings.join(", ")
	
	# 输出日志
	EventBus.debug.emit_event("debug_message", [log_message, 0])

# 计算平均值
func _calculate_average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += value
	
	return sum / values.size()

# 检查性能警告
func _check_performance_warnings(fps: float, memory: float, draw_calls: int, objects: int) -> Array:
	var warnings = []
	
	if fps < monitor_settings.warning_threshold.fps:
		warnings.append("FPS过低 (%.1f)" % fps)
	
	if memory > monitor_settings.warning_threshold.memory:
		warnings.append("内存使用过高 (%.1f MB)" % memory)
	
	if draw_calls > monitor_settings.warning_threshold.draw_calls:
		warnings.append("绘制调用过多 (%d)" % draw_calls)
	
	if objects > monitor_settings.warning_threshold.objects:
		warnings.append("对象数量过多 (%d)" % objects)
	
	return warnings

# 启用性能监控
func enable() -> void:
	monitor_settings.enabled = true
	EventBus.debug.emit_event("debug_message", ["性能监控已启用", 0])

# 禁用性能监控
func disable() -> void:
	monitor_settings.enabled = false
	EventBus.debug.emit_event("debug_message", ["性能监控已禁用", 0])

# 设置日志间隔
func set_log_interval(interval: float) -> void:
	monitor_settings.log_interval = max(0.1, interval)
	EventBus.debug.emit_event("debug_message", ["性能监控日志间隔已设置为 %.1f 秒" % monitor_settings.log_interval, 0])

# 设置样本数量
func set_sample_count(count: int) -> void:
	monitor_settings.sample_count = max(10, count)
	_initialize_performance_data()
	EventBus.debug.emit_event("debug_message", ["性能监控样本数量已设置为 %d" % monitor_settings.sample_count, 0])

# 启用脚本性能分析
func enable_script_profiling() -> void:
	monitor_settings.script_profiling = true
	EventBus.debug.emit_event("debug_message", ["脚本性能分析已启用", 0])

# 禁用脚本性能分析
func disable_script_profiling() -> void:
	monitor_settings.script_profiling = false
	EventBus.debug.emit_event("debug_message", ["脚本性能分析已禁用", 0])

# 获取性能报告
func get_performance_report() -> Dictionary:
	var report = {
		"fps": _calculate_average(performance_data.fps),
		"memory": _calculate_average(performance_data.memory),
		"draw_calls": _calculate_average(performance_data.draw_calls),
		"objects": _calculate_average(performance_data.objects),
		"physics_objects": _calculate_average(performance_data.physics_objects),
		"frame_time": performance_data.frame_time,
		"render_time": performance_data.render_time,
		"physics_time": performance_data.physics_time
	}
	
	return report
