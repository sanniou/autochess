extends Node
class_name ErrorReporter
## 错误报告系统
## 用于收集和报告游戏中的错误

# 信号
signal error_reported(error_data)
signal crash_reported(crash_data)

# 错误级别
enum ErrorLevel {
	INFO,
	WARNING,
	ERROR,
	FATAL
}

# 错误报告设置
var report_settings = {
	"enabled": true,
	"log_errors": true,
	"send_reports": false,  # 是否发送错误报告到服务器
	"include_system_info": true,
	"include_stack_trace": true,
	"max_reports_per_session": 10,
	"min_level_to_report": ErrorLevel.WARNING,
	"report_server_url": ""  # 错误报告服务器URL
}

# 错误报告数据
var error_reports = []

# 崩溃报告数据
var crash_reports = []

# 系统信息
var system_info = {}

# 会话ID
var session_id = ""

# 初始化
func _ready() -> void:
	# 设置进程模式
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 生成会话ID
	session_id = _generate_session_id()
	
	# 收集系统信息
	_collect_system_info()
	
	# 设置错误处理
	_setup_error_handling()

## 报告错误
func report_error(message: String, level: int = ErrorLevel.ERROR, context: Dictionary = {}) -> void:
	if not report_settings.enabled or level < report_settings.min_level_to_report:
		return
	
	# 检查是否超过最大报告数
	if error_reports.size() >= report_settings.max_reports_per_session:
		return
	
	# 创建错误报告
	var error_data = _create_error_report(message, level, context)
	
	# 添加到报告列表
	error_reports.append(error_data)
	
	# 记录错误
	if report_settings.log_errors:
		_log_error(error_data)
	
	# 发送错误报告
	if report_settings.send_reports:
		_send_error_report(error_data)
	
	# 发送错误报告信号
	error_reported.emit(error_data)

## 报告崩溃
func report_crash(error_message: String, stack_trace: Array = [], context: Dictionary = {}) -> void:
	if not report_settings.enabled:
		return
	
	# 创建崩溃报告
	var crash_data = _create_crash_report(error_message, stack_trace, context)
	
	# 添加到报告列表
	crash_reports.append(crash_data)
	
	# 记录崩溃
	_log_crash(crash_data)
	
	# 发送崩溃报告
	if report_settings.send_reports:
		_send_crash_report(crash_data)
	
	# 发送崩溃报告信号
	crash_reported.emit(crash_data)

## 设置错误报告设置
func set_report_settings(settings: Dictionary) -> void:
	# 更新设置
	for key in settings:
		if report_settings.has(key):
			report_settings[key] = settings[key]

## 启用错误报告
func enable_reporting() -> void:
	report_settings.enabled = true

## 禁用错误报告
func disable_reporting() -> void:
	report_settings.enabled = false

## 清除错误报告
func clear_reports() -> void:
	error_reports.clear()
	crash_reports.clear()

## 获取错误报告
func get_error_reports() -> Array:
	return error_reports.duplicate()

## 获取崩溃报告
func get_crash_reports() -> Array:
	return crash_reports.duplicate()

## 创建错误报告
func _create_error_report(message: String, level: int, context: Dictionary) -> Dictionary:
	var report = {
		"id": _generate_report_id(),
		"session_id": session_id,
		"timestamp": Time.get_unix_time_from_system(),
		"level": level,
		"message": message,
		"context": context.duplicate(),
		"stack_trace": []
	}
	
	# 添加堆栈跟踪
	if report_settings.include_stack_trace:
		report.stack_trace = _get_stack_trace()
	
	# 添加系统信息
	if report_settings.include_system_info:
		report.system_info = system_info.duplicate()
	
	return report

## 创建崩溃报告
func _create_crash_report(error_message: String, stack_trace: Array, context: Dictionary) -> Dictionary:
	var report = {
		"id": _generate_report_id(),
		"session_id": session_id,
		"timestamp": Time.get_unix_time_from_system(),
		"error_message": error_message,
		"stack_trace": stack_trace.duplicate(),
		"context": context.duplicate()
	}
	
	# 添加系统信息
	if report_settings.include_system_info:
		report.system_info = system_info.duplicate()
	
	return report

## 记录错误
func _log_error(error_data: Dictionary) -> void:
	var level_str = ["INFO", "WARNING", "ERROR", "FATAL"][error_data.level]
	var message = "[%s] [%s] %s" % [Time.get_datetime_string_from_system(), level_str, error_data.message]
	
	# 输出到控制台
	match error_data.level:
		ErrorLevel.INFO:
			print(message)
		ErrorLevel.WARNING:
			push_warning(message)
		ErrorLevel.ERROR, ErrorLevel.FATAL:
			push_error(message)
	
	# 记录到日志文件
	if has_node("/root/DebugManager"):
		var debug_manager = get_node("/root/DebugManager")
		debug_manager.log_message(error_data.message, error_data.level)

## 记录崩溃
func _log_crash(crash_data: Dictionary) -> void:
	var message = "[CRASH] %s" % crash_data.error_message
	
	# 输出到控制台
	push_error(message)
	
	# 记录堆栈跟踪
	for frame in crash_data.stack_trace:
		push_error("  at " + str(frame))
	
	# 记录到日志文件
	if has_node("/root/DebugManager"):
		var debug_manager = get_node("/root/DebugManager")
		debug_manager.log_message(message, 2)
		
		# 记录堆栈跟踪
		for frame in crash_data.stack_trace:
			debug_manager.log_message("  at " + str(frame), 2)

## 发送错误报告
func _send_error_report(error_data: Dictionary) -> void:
	# 检查是否配置了服务器URL
	if report_settings.report_server_url.is_empty():
		return
	
	# 这里应该实现发送错误报告到服务器的逻辑
	# 由于Godot的HTTP请求需要更多设置，这里只是示例
	EventBus.debug.emit_event("debug_message", ["发送错误报告: " + error_data.id, 0])

## 发送崩溃报告
func _send_crash_report(crash_data: Dictionary) -> void:
	# 检查是否配置了服务器URL
	if report_settings.report_server_url.is_empty():
		return
	
	# 这里应该实现发送崩溃报告到服务器的逻辑
	# 由于Godot的HTTP请求需要更多设置，这里只是示例
	EventBus.debug.emit_event("debug_message", ["发送崩溃报告: " + crash_data.id, 0])

## 设置错误处理
func _setup_error_handling() -> void:
	# 连接全局错误处理信号
	get_tree().set_auto_accept_quit(false)
	get_tree().root.connect("files_dropped", _on_files_dropped)

## 生成会话ID
func _generate_session_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000000).pad_zeros(6)

## 生成报告ID
func _generate_report_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000000).pad_zeros(6)

## 获取堆栈跟踪
func _get_stack_trace() -> Array:
	var stack = []
	
	# 获取当前堆栈跟踪
	var stack_frames = get_stack()
	
	# 跳过前两帧（当前函数和report_error函数）
	for i in range(2, stack_frames.size()):
		var frame = stack_frames[i]
		stack.append({
			"function": frame.function,
			"file": frame.source,
			"line": frame.line
		})
	
	return stack

## 收集系统信息
func _collect_system_info() -> void:
	system_info = {
		"os_name": OS.get_name(),
		"os_version": OS.get_version(),
		"model_name": OS.get_model_name(),
		"processor_count": OS.get_processor_count(),
		"processor_name": OS.get_processor_name(),
		"memory_static": OS.get_static_memory_usage() / (1024 * 1024),  # MB
		"memory_dynamic": OS.get_dynamic_memory_usage() / (1024 * 1024),  # MB
		"video_adapter": OS.get_video_adapter_driver_info(),
		"screen_size": DisplayServer.screen_get_size(),
		"screen_dpi": DisplayServer.screen_get_dpi(),
		"godot_version": Engine.get_version_info(),
		"game_version": ProjectSettings.get_setting("application/config/version", "unknown")
	}

## 文件拖放事件处理
func _on_files_dropped(files: PackedStringArray) -> void:
	# 这里可以处理拖放的文件，例如日志文件
	pass
