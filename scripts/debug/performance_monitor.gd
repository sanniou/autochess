extends Node
# 不使用 class_name 以避免与自动加载单例冲突
## 性能监控器
## 用于监控游戏的性能指标

# 信号
signal performance_warning(message: String, level: int)
signal performance_data_updated(data: Dictionary)

# 性能指标
var performance_data = {
	"fps": 0,                  # 帧率
	"frame_time": 0.0,         # 帧时间（毫秒）
	"physics_time": 0.0,       # 物理处理时间（毫秒）
	"idle_time": 0.0,          # 空闲处理时间（毫秒）
	"draw_calls": 0,           # 绘制调用次数
	"objects": 0,              # 对象数量
	"nodes": 0,                # 节点数量
	"memory_static": 0.0,      # 静态内存（MB）
	"memory_dynamic": 0.0,     # 动态内存（MB）
	"memory_total": 0.0,       # 总内存（MB）
	"gpu_memory": 0.0,         # GPU内存（MB）
	"texture_memory": 0.0,     # 纹理内存（MB）
	"audio_latency": 0.0,      # 音频延迟（毫秒）
	"network_bandwidth": 0.0,  # 网络带宽（KB/s）
	"script_time": 0.0,        # 脚本执行时间（毫秒）
	"physics_objects": 0       # 物理对象数量
}

# 性能历史数据
var performance_history = {
	"fps": [],
	"frame_time": [],
	"memory_total": []
}

# 性能警告阈值
var warning_thresholds = {
	"fps_low": 30,             # 低帧率警告阈值
	"frame_time_high": 33.3,   # 高帧时间警告阈值（对应30FPS）
	"memory_high": 1024.0,     # 高内存警告阈值（MB）
	"draw_calls_high": 1000,   # 高绘制调用警告阈值
	"nodes_high": 1000,        # 高节点数量警告阈值
	"objects_high": 10000      # 高对象数量警告阈值
}

# 监控设置
var monitor_settings = {
	"enabled": true,           # 是否启用监控
	"update_interval": 1.0,    # 更新间隔（秒）
	"history_length": 60,      # 历史数据长度
	"warnings_enabled": true,  # 是否启用警告
	"log_to_file": false,      # 是否记录到文件
	"log_file_path": "user://performance_log.txt", # 日志文件路径
	"display_overlay": false   # 是否显示叠加层
}

# 计时器
var _update_timer = 0.0
var _last_frame_time = 0.0
var _frame_count = 0
var _last_memory_check = 0.0

# 引用
@onready var debug_manager = get_node_or_null("/root/DebugManager")

# 初始化
func _ready() -> void:
	# 初始化性能历史数据
	for i in range(monitor_settings.history_length):
		performance_history.fps.append(0)
		performance_history.frame_time.append(0.0)
		performance_history.memory_total.append(0.0)

	# 初始化帧时间
	_last_frame_time = Time.get_ticks_msec()

# 处理
func _process(delta: float) -> void:
	if not monitor_settings.enabled:
		return

	# 更新帧计数
	_frame_count += 1

	# 更新计时器
	_update_timer += delta

	# 检查是否需要更新性能数据
	if _update_timer >= monitor_settings.update_interval:
		_update_performance_data()
		_update_timer = 0.0

## 更新性能数据
func _update_performance_data() -> void:
	# 计算帧率
	var current_time = Time.get_ticks_msec()
	var elapsed_time = (current_time - _last_frame_time) / 1000.0

	if elapsed_time > 0:
		performance_data.fps = _frame_count / elapsed_time

	# 重置帧计数和时间
	_frame_count = 0
	_last_frame_time = current_time

	# 更新帧时间
	performance_data.frame_time = 1000.0 / max(performance_data.fps, 1)

	# 更新物理和空闲时间
	performance_data.physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	# Godot 4.x 中不再有 TIME_IDLE
	performance_data.idle_time = 0.0

	# 更新绘制调用
	performance_data.draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)

	# 更新对象和节点数量
	performance_data.objects = Performance.get_monitor(Performance.OBJECT_COUNT)
	performance_data.nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)

	# 更新内存使用
	performance_data.memory_static = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024 * 1024)
	# Godot 4.x 中不再有 MEMORY_DYNAMIC
	performance_data.memory_dynamic = 0.0
	performance_data.memory_total = performance_data.memory_static + performance_data.memory_dynamic

	# 更新GPU内存（如果可用）
	# Godot 4.x 中不再有 has_monitor 方法
	# 直接尝试获取监控值
	performance_data.gpu_memory = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024 * 1024)

	# 更新纹理内存
	performance_data.texture_memory = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / (1024 * 1024)

	# 更新音频延迟
	performance_data.audio_latency = Performance.get_monitor(Performance.AUDIO_OUTPUT_LATENCY) * 1000

	# 更新脚本时间
	# Godot 4.x 中不再有 TIME_SCRIPT
	performance_data.script_time = 0.0

	# 更新物理对象数量
	performance_data.physics_objects = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS) + Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)

	# 更新历史数据
	_update_history_data()

	# 检查性能警告
	if monitor_settings.warnings_enabled:
		_check_performance_warnings()

	# 记录到文件
	if monitor_settings.log_to_file:
		_log_to_file()

	# 发送更新信号
	performance_data_updated.emit(performance_data)

## 更新历史数据
func _update_history_data() -> void:
	# 移除最旧的数据
	performance_history.fps.pop_front()
	performance_history.frame_time.pop_front()
	performance_history.memory_total.pop_front()

	# 添加新数据
	performance_history.fps.append(performance_data.fps)
	performance_history.frame_time.append(performance_data.frame_time)
	performance_history.memory_total.append(performance_data.memory_total)

## 检查性能警告
func _check_performance_warnings() -> void:
	# 检查帧率
	if performance_data.fps < warning_thresholds.fps_low:
		_emit_performance_warning("低帧率: " + str(int(performance_data.fps)) + " FPS", 1)

	# 检查帧时间
	if performance_data.frame_time > warning_thresholds.frame_time_high:
		_emit_performance_warning("高帧时间: " + str(performance_data.frame_time) + " ms", 1)

	# 检查内存
	if performance_data.memory_total > warning_thresholds.memory_high:
		_emit_performance_warning("高内存使用: " + str(int(performance_data.memory_total)) + " MB", 2)

	# 检查绘制调用
	if performance_data.draw_calls > warning_thresholds.draw_calls_high:
		_emit_performance_warning("高绘制调用: " + str(performance_data.draw_calls), 1)

	# 检查节点数量
	if performance_data.nodes > warning_thresholds.nodes_high:
		_emit_performance_warning("高节点数量: " + str(performance_data.nodes), 1)

	# 检查对象数量
	if performance_data.objects > warning_thresholds.objects_high:
		_emit_performance_warning("高对象数量: " + str(performance_data.objects), 1)

## 发送性能警告
func _emit_performance_warning(message: String, level: int) -> void:
	performance_warning.emit(message, level)

	# 如果有调试管理器，也发送到那里
	if debug_manager:
		debug_manager.log_message("性能警告: " + message, level)

## 记录到文件
func _log_to_file() -> void:
	# Godot 4.x 中使用 FileAccess.WRITE 和 append_mode
	var file = FileAccess.open(monitor_settings.log_file_path, FileAccess.WRITE)
	# 将文件指针移动到文件末尾以模拟追加模式
	if file:
		file.seek_end()
	if file:
		var timestamp = Time.get_datetime_string_from_system()
		var log_line = timestamp + " - FPS: " + str(int(performance_data.fps)) + ", 内存: " + str(int(performance_data.memory_total)) + " MB, 绘制调用: " + str(performance_data.draw_calls)
		file.store_line(log_line)
		file.close()

## 获取性能数据
func get_performance_data() -> Dictionary:
	return performance_data

## 获取性能历史数据
func get_performance_history() -> Dictionary:
	return performance_history

## 获取平均帧率
func get_average_fps() -> float:
	var sum = 0.0
	for fps in performance_history.fps:
		sum += fps
	return sum / performance_history.fps.size()

## 获取最低帧率
func get_min_fps() -> float:
	var min_fps = INF
	for fps in performance_history.fps:
		if fps < min_fps and fps > 0:
			min_fps = fps
	return min_fps if min_fps != INF else 0.0

## 获取最高帧率
func get_max_fps() -> float:
	var max_fps = 0.0
	for fps in performance_history.fps:
		if fps > max_fps:
			max_fps = fps
	return max_fps

## 设置警告阈值
func set_warning_threshold(name: String, value: float) -> void:
	if warning_thresholds.has(name):
		warning_thresholds[name] = value

## 设置监控设置
func set_monitor_setting(name: String, value: Variant) -> void:
	if monitor_settings.has(name):
		monitor_settings[name] = value

## 启用监控
func enable_monitoring() -> void:
	monitor_settings.enabled = true

## 禁用监控
func disable_monitoring() -> void:
	monitor_settings.enabled = false

## 启用警告
func enable_warnings() -> void:
	monitor_settings.warnings_enabled = true

## 禁用警告
func disable_warnings() -> void:
	monitor_settings.warnings_enabled = false

## 启用日志记录
func enable_logging() -> void:
	monitor_settings.log_to_file = true

## 禁用日志记录
func disable_logging() -> void:
	monitor_settings.log_to_file = false

## 清除性能历史数据
func clear_history() -> void:
	for i in range(performance_history.fps.size()):
		performance_history.fps[i] = 0
		performance_history.frame_time[i] = 0.0
		performance_history.memory_total[i] = 0.0

## 重置性能数据
func reset_data() -> void:
	performance_data.fps = 0
	performance_data.frame_time = 0.0
	performance_data.physics_time = 0.0
	performance_data.idle_time = 0.0
	performance_data.draw_calls = 0
	performance_data.objects = 0
	performance_data.nodes = 0
	performance_data.memory_static = 0.0
	performance_data.memory_dynamic = 0.0
	performance_data.memory_total = 0.0
	performance_data.gpu_memory = 0.0
	performance_data.texture_memory = 0.0
	performance_data.audio_latency = 0.0
	performance_data.network_bandwidth = 0.0
	performance_data.script_time = 0.0
	performance_data.physics_objects = 0

	clear_history()

## 获取性能报告
func get_performance_report() -> String:
	var report = "性能报告 - " + Time.get_datetime_string_from_system() + "\n"
	report += "----------------------------------------\n"
	report += "帧率: " + str(int(performance_data.fps)) + " FPS (平均: " + str(int(get_average_fps())) + ", 最低: " + str(int(get_min_fps())) + ", 最高: " + str(int(get_max_fps())) + ")\n"
	report += "帧时间: " + str(performance_data.frame_time) + " ms\n"
	report += "物理时间: " + str(performance_data.physics_time) + " ms\n"
	report += "空闲时间: " + str(performance_data.idle_time) + " ms\n"
	report += "脚本时间: " + str(performance_data.script_time) + " ms\n"
	report += "绘制调用: " + str(performance_data.draw_calls) + "\n"
	report += "对象数量: " + str(performance_data.objects) + "\n"
	report += "节点数量: " + str(performance_data.nodes) + "\n"
	report += "物理对象: " + str(performance_data.physics_objects) + "\n"
	report += "内存使用: " + str(int(performance_data.memory_total)) + " MB (静态: " + str(int(performance_data.memory_static)) + " MB, 动态: " + str(int(performance_data.memory_dynamic)) + " MB)\n"
	report += "GPU内存: " + str(int(performance_data.gpu_memory)) + " MB\n"
	report += "纹理内存: " + str(int(performance_data.texture_memory)) + " MB\n"
	report += "音频延迟: " + str(performance_data.audio_latency) + " ms\n"
	report += "----------------------------------------\n"

	return report
