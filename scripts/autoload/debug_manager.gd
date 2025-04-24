extends "res://scripts/managers/core/base_manager.gd"

## 调试管理器
## 负责游戏调试功能和日志记录
# 调试级别
enum DebugLevel {
	INFO,   # 信息
	WARNING, # 警告
	ERROR   # 错误
}

# 是否启用调试模式
var debug_enabled = OS.is_debug_build()

# 是否启用控制台
var console_enabled = OS.is_debug_build()

# 控制台实例
var console = null

# 是否显示性能监控
var performance_overlay_enabled = false

# 性能监控相关
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
	"frame_time_high": 33.3,   # 高帧时间警告阈值（对30FPS）
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

# 兼容性变量
var performance_monitor = self

# 性能监控UI
var performance_overlay = null

# 日志文件路径
const LOG_FILE_PATH = "user://debug_log.txt"

# 最大日志条数
const MAX_LOG_ENTRIES = 1000

# 日志条目
var log_entries = []

# 控制台命令
var console_commands = {}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "DebugManager"
	# 添加依赖
	add_dependency("SceneManager")

	# 原 _ready 函数的内容
	# 连接信号
	GlobalEventBus.debug.add_listener("debug_message", _on_debug_message)

	# 注册控制台命令
	_register_console_commands()

	# 清理旧日志文件
	if debug_enabled:
		_clear_log_file()

	# 初始化性能监控
	_initialize_performance_monitoring()

	# 初始化控制台
	if console_enabled:
		_initialize_console()

	# 记录游戏启动信息
	log_message("游戏启动，版本: " + Engine.get_version_info().string, DebugLevel.INFO)

	# 输入处理
func _input(event: InputEvent) -> void:
	# 检查是否按下了波浪键（~）或F12键
	if console_enabled and event is InputEventKey and event.pressed:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_F12:
			# 切换控制台显示
			if console:
				console.toggle_console()

## 注册控制台命令
func _register_console_commands() -> void:
	# 基本命令
	register_command("help", _cmd_help, "显示所有可用命令")
	register_command("clear_log", _cmd_clear_log, "清除调试日志")
	register_command("version", _cmd_version, "显示游戏版本信息")

	# 游戏命令
	register_command("reload_configs", _cmd_reload_configs, "重新加载所有配置文件")
	register_command("give_gold", _cmd_give_gold, "给予金币，用法: give_gold [数量]")
	register_command("give_item", _cmd_give_item, "给予物品，用法: give_item [物品ID]")
	register_command("toggle_god_mode", _cmd_toggle_god_mode, "切换无敌模式")
	register_command("teleport", _cmd_teleport, "传送到指定地图节点，用法: teleport [节点ID]")

	# 场景命令
	register_command("load_scene", _cmd_load_scene, "加载场景，用法: load_scene [场景ID]")
	register_command("reload_scene", _cmd_reload_scene, "重新加载当前场景")

	# 系统命令
	register_command("quit", _cmd_quit, "退出游戏")

## 注册控制台命令
func register_command(name: String, callback: Callable, description: String) -> void:
	console_commands[name] = {
		"callback": callback,
		"description": description
	}

## 执行控制台命令
func execute_command(command_text: String) -> String:
	var parts = command_text.strip_edges().split(" ", false)
	if parts.size() == 0:
		return "命令为空"

	var command_name = parts[0]
	var args = parts.slice(1)

	if not console_commands.has(command_name):
		return "未知命令: " + command_name

	var result = console_commands[command_name].callback.call(args)
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugCommandExecutedEvent.new(command_name, result))

	return result

## 记录调试消息
func log_message(message: String, level: int = DebugLevel.INFO) -> void:
	if not debug_enabled and level == DebugLevel.INFO:
		return

	var timestamp = Time.get_datetime_string_from_system()
	var level_str = ["INFO", "WARNING", "ERROR"][level]
	var formatted_message = "[%s] [%s] %s" % [timestamp, level_str, message]

	# 添加到日志条目
	log_entries.append({
		"timestamp": timestamp,
		"level": level,
		"message": message,
		"formatted": formatted_message
	})

	# 限制日志条数
	if log_entries.size() > MAX_LOG_ENTRIES:
		log_entries.pop_front()

	# 输出到控制台
	print(formatted_message)

	# 写入日志文件
	if debug_enabled:
		_write_to_log_file(formatted_message)

	# 发送调试消息信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new(message, level))

## 写入日志文件
func _write_to_log_file(message: String) -> void:
	var file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
		if file == null:
			print("无法创建日志文件")
			return

	file.seek_end()
	file.store_line(message)
	file.close()

## 清理日志文件
func _clear_log_file() -> void:
	var file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	if file == null:
		print("无法清理日志文件")
		return

	var timestamp = Time.get_datetime_string_from_system()
	file.store_line("[%s] [INFO] === 新日志会话开始 ===" % timestamp)
	file.close()

## 获取最近的日志条目
func get_recent_logs(count: int = 10, level: int = -1) -> Array:
	var filtered_logs = []

	if level >= 0:
		for entry in log_entries:
			if entry.level == level:
				filtered_logs.append(entry)
	else:
		filtered_logs = log_entries.duplicate()

	# 返回最近的日志
	var start_index = max(0, filtered_logs.size() - count)
	return filtered_logs.slice(start_index)

## 调试消息处理
func _on_debug_message(message: String, level: int) -> void:
	# 这里可以添加额外的处理，如显示在屏幕上的调试信息
	pass

## help命令处理
func _cmd_help(_args: Array) -> String:
	var help_text = "可用命令:\n"

	for command_name in console_commands.keys():
		help_text += "- %s: %s\n" % [command_name, console_commands[command_name].description]

	return help_text

## reload_configs命令处理
func _cmd_reload_configs(_args: Array) -> String:
	GameManager.config_manager.reload_configs()
	return "配置已重新加载"

## give_gold命令处理
func _cmd_give_gold(args: Array) -> String:
	if args.size() == 0:
		return "用法: give_gold [数量]"

	var amount = int(args[0])
	if amount <= 0:
		return "金币数量必须大于0"

	# 这里将调用玩家管理器添加金币
	# 暂时只返回成功消息
	return "已添加 %d 金币" % amount

## give_item命令处理
func _cmd_give_item(args: Array) -> String:
	if args.size() == 0:
		return "用法: give_item [物品ID]"

	var item_id = args[0]

	# 这里将调用相应的管理器添加物品
	# 暂时只返回成功消息
	return "已添加物品: %s" % item_id

## toggle_god_mode命令处理
func _cmd_toggle_god_mode(_args: Array) -> String:
	# 这里将切换无敌模式
	# 暂时只返回成功消息
	return "无敌模式已切换"

## clear_log命令处理
func _cmd_clear_log(_args: Array) -> String:
	log_entries.clear()
	_clear_log_file()
	return "日志已清除"

## show_fps命令处理
func _cmd_show_fps(_args: Array) -> String:
	# 切换性能监控显示
	performance_overlay_enabled = not performance_overlay_enabled

	# 显示或隐藏性能监控UI
	if performance_overlay_enabled:
		_show_performance_overlay()
	else:
		_hide_performance_overlay()

	return "FPS显示已" + ("开启" if performance_overlay_enabled else "关闭")

## teleport命令处理
func _cmd_teleport(args: Array) -> String:
	if args.size() == 0:
		return "用法: teleport [节点ID]"

	var node_id = args[0]

	# 这里将调用地图管理器进行传送
	# 暂时只返回成功消息
	return "已传送到节点: %s" % node_id

## 初始化性能监控
func _initialize_performance_monitoring() -> void:
	# 初始化性能历史数据
	for i in range(monitor_settings.history_length):
		performance_history.fps.append(0)
		performance_history.frame_time.append(0.0)
		performance_history.memory_total.append(0.0)

	# 初始化帧时间
	_last_frame_time = Time.get_ticks_msec()

	# 注册性能监控相关命令
	register_command("toggle_performance", _cmd_toggle_performance, "切换性能监控显示")
	register_command("performance_report", _cmd_performance_report, "生成性能报告")
	register_command("fps", _cmd_toggle_performance, "显示/隐藏FPS计数器")
	register_command("memory", _cmd_show_memory, "显示内存使用情况")

# 处理
func _process(delta: float) -> void:
	# 调用父类的 _process

	# 性能监控处理
	if monitor_settings.enabled:
		# 更新帧计数
		_frame_count += 1

		# 更新计时器
		_update_timer += delta

		# 检查是否需要更新性能数据
		if _update_timer >= monitor_settings.update_interval:
			_update_performance_data()
			_update_timer = 0.0

## 显示性能监控UI
func _show_performance_overlay() -> void:
	# 如果已经存在，直接显示
	if performance_overlay != null and is_instance_valid(performance_overlay):
		performance_overlay.visible = true
		return

	# 加载性能监控UI场景
	var overlay_scene = load("res://scenes/ui/debug/performance_overlay.tscn")
	if overlay_scene:
		performance_overlay = overlay_scene.instantiate()
		get_tree().root.add_child(performance_overlay)
		performance_overlay.visible = true

## 隐藏性能监控UI
func _hide_performance_overlay() -> void:
	if performance_overlay != null and is_instance_valid(performance_overlay):
		performance_overlay.visible = false

## 切换性能监控显示
func _cmd_toggle_performance(_args: Array) -> String:
	performance_overlay_enabled = not performance_overlay_enabled

	if performance_overlay_enabled:
		_show_performance_overlay()
		return "性能监控已开启"
	else:
		_hide_performance_overlay()
		return "性能监控已关闭"

## 生成性能报告
func _cmd_performance_report(_args: Array) -> String:
	var report = get_performance_report()
	log_message(report, DebugLevel.INFO)

	return "性能报告已生成并记录到日志"

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
func reset_performance_data() -> void:
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
		_log_performance_to_file()

	# 发送更新信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.PerformanceDataUpdatedEvent.new(performance_data))

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
	# 记录性能警告
	log_message("性能警告: " + message, level)

	# 发送性能警告信号
	GlobalEventBus.debug.dispatch_event(DebugEvents.PerformanceWarningEvent.new(message, level))

## 记录性能数据到文件
func _log_performance_to_file() -> void:
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

## 初始化控制台
func _initialize_console() -> void:
	# 加载控制台场景
	var console_scene = load("res://scenes/ui/debug/debug_console.tscn")
	if console_scene:
		console = console_scene.instantiate()
		get_tree().root.add_child(console)
		console.name = "DebugConsole"

	# 注册控制台相关命令
	register_command("console", _cmd_toggle_console, "切换控制台显示")

## 切换控制台显示
func _cmd_toggle_console(_args: Array) -> String:
	if console:
		console.toggle_console()
		return "控制台已" + ("显示" if console.visible else "隐藏")
	else:
		return "控制台未初始化"

## 显示内存使用情况
func _cmd_show_memory(_args: Array) -> String:
	var memory_info = "内存使用情况:\n"
	memory_info += "- 总内存: " + str(int(performance_data.memory_total)) + " MB\n"
	memory_info += "- 静态内存: " + str(int(performance_data.memory_static)) + " MB\n"
	memory_info += "- 动态内存: " + str(int(performance_data.memory_dynamic)) + " MB\n"
	memory_info += "- GPU内存: " + str(int(performance_data.gpu_memory)) + " MB\n"
	memory_info += "- 纹理内存: " + str(int(performance_data.texture_memory)) + " MB\n"
	memory_info += "- 对象数量: " + str(performance_data.objects) + "\n"
	memory_info += "- 节点数量: " + str(performance_data.nodes) + "\n"

	log_message(memory_info, DebugLevel.INFO)
	return memory_info

## 显示游戏版本信息
func _cmd_version(_args: Array) -> String:
	var version_info = Engine.get_version_info()
	var game_version = "1.0.0" # 游戏版本

	var version_text = "游戏版本信息:\n"
	version_text += "- 游戏版本: " + game_version + "\n"
	version_text += "- 引擎版本: " + version_info.string + "\n"
	version_text += "- 主版本: " + str(version_info.major) + "\n"
	version_text += "- 次版本: " + str(version_info.minor) + "\n"
	version_text += "- 补丁版本: " + str(version_info.patch) + "\n"
	version_text += "- 状态: " + version_info.status + "\n"

	log_message(version_text, DebugLevel.INFO)
	return version_text

## 加载场景命令处理
func _cmd_load_scene(args: Array) -> String:
	if args.size() == 0:
		return "用法: load_scene [场景ID]"

	var scene_id = args[0]

	# 这里将调用场景管理器加载场景
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.load_scene(scene_id)
		return "正在加载场景: " + scene_id
	else:
		# 如果没有场景管理器，使用传统方式
		var scene_path = "res://scenes/" + scene_id + ".tscn"
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
			return "已加载场景: " + scene_id
		else:
			return "场景不存在: " + scene_id

## 重新加载当前场景命令处理
func _cmd_reload_scene(_args: Array) -> String:
	# 获取当前场景
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path
		get_tree().reload_current_scene()
		return "已重新加载场景: " + scene_path
	else:
		return "无法重新加载场景"

## 退出游戏命令处理
func _cmd_quit(_args: Array) -> String:
	# 添加一个延迟，以便用户可以看到命令结果
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func(): get_tree().quit())
	return "正在退出游戏..."
