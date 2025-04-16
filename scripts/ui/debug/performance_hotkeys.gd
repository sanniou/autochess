extends Node
## 性能监控快捷键处理
## 用于处理性能监控相关的快捷键

# 引用
@onready var debug_manager = get_node_or_null("/root/DebugManager")
@onready var performance_monitor = get_node_or_null("/root/PerformanceMonitor")

# 快捷键设置
var hotkey_settings = {
	"toggle_overlay": KEY_F3,       # 切换性能监控显示
	"toggle_details": KEY_F4,       # 切换详细信息显示
	"generate_report": KEY_F5,      # 生成性能报告
	"reset_stats": KEY_F6,          # 重置性能统计
	"toggle_warnings": KEY_F7,      # 切换性能警告
	"toggle_logging": KEY_F8        # 切换性能日志记录
}

# 初始化
func _ready() -> void:
	# 检查是否有调试管理器
	if not debug_manager:
		push_error("无法获取调试管理器引用")
	
	# 检查是否有性能监控器
	if not performance_monitor:
		push_error("无法获取性能监控器引用")

# 输入处理
func _input(event: InputEvent) -> void:
	# 只处理按键事件
	if not event is InputEventKey:
		return
	
	var key_event = event as InputEventKey
	
	# 只处理按下事件
	if not key_event.pressed:
		return
	
	# 处理快捷键
	match key_event.keycode:
		hotkey_settings.toggle_overlay:
			_toggle_performance_overlay()
		hotkey_settings.toggle_details:
			_toggle_performance_details()
		hotkey_settings.generate_report:
			_generate_performance_report()
		hotkey_settings.reset_stats:
			_reset_performance_stats()
		hotkey_settings.toggle_warnings:
			_toggle_performance_warnings()
		hotkey_settings.toggle_logging:
			_toggle_performance_logging()

## 切换性能监控显示
func _toggle_performance_overlay() -> void:
	if debug_manager:
		debug_manager.execute_command("toggle_performance")

## 切换详细信息显示
func _toggle_performance_details() -> void:
	var overlay = _get_performance_overlay()
	if overlay:
		overlay.toggle_details()

## 生成性能报告
func _generate_performance_report() -> void:
	if debug_manager:
		debug_manager.execute_command("performance_report")

## 重置性能统计
func _reset_performance_stats() -> void:
	if performance_monitor:
		performance_monitor.reset_data()

## 切换性能警告
func _toggle_performance_warnings() -> void:
	if performance_monitor:
		var current = performance_monitor.monitor_settings.warnings_enabled
		performance_monitor.set_monitor_setting("warnings_enabled", not current)
		
		if debug_manager:
			debug_manager.log_message("性能警告已" + ("开启" if not current else "关闭"), 0)

## 切换性能日志记录
func _toggle_performance_logging() -> void:
	if performance_monitor:
		var current = performance_monitor.monitor_settings.log_to_file
		performance_monitor.set_monitor_setting("log_to_file", not current)
		
		if debug_manager:
			debug_manager.log_message("性能日志记录已" + ("开启" if not current else "关闭"), 0)

## 获取性能监控UI
func _get_performance_overlay() -> Control:
	if debug_manager:
		return debug_manager.performance_overlay
	return null

## 设置快捷键
func set_hotkey(action: String, key: int) -> void:
	if hotkey_settings.has(action):
		hotkey_settings[action] = key
