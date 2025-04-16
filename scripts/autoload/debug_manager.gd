extends Node
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

# 性能监控器
var performance_monitor = null

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

func _ready():
	# 连接信号
	EventBus.debug_message.connect(_on_debug_message)

	# 注册控制台命令
	_register_console_commands()

	# 清理旧日志文件
	if debug_enabled:
		_clear_log_file()

	# 初始化性能监控器
	_initialize_performance_monitor()

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
	EventBus.debug_command_executed.emit(command_name, result)

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
	EventBus.debug_message.emit(message, level)

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
	ConfigManager.reload_configs()
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

## 初始化性能监控器
func _initialize_performance_monitor() -> void:
	# 获取自动加载的性能监控器
	performance_monitor = get_node_or_null("/root/PerformanceMonitor")

	# 如果没有找到，创建一个新的实例
	if not performance_monitor:
		performance_monitor = load("res://scripts/debug/performance_monitor.gd").new()
		add_child(performance_monitor)

	# 连接性能警告信号
	performance_monitor.performance_warning.connect(_on_performance_warning)

	# 注册性能监控相关命令
	register_command("toggle_performance", _cmd_toggle_performance, "切换性能监控显示")
	register_command("performance_report", _cmd_performance_report, "生成性能报告")
	register_command("fps", _cmd_toggle_performance, "显示/隐藏FPS计数器")
	register_command("memory", _cmd_show_memory, "显示内存使用情况")

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
	if performance_monitor == null:
		return "性能监控器未初始化"

	var report = performance_monitor.get_performance_report()
	log_message(report, DebugLevel.INFO)

	return "性能报告已生成并记录到日志"

## 性能警告处理
func _on_performance_warning(message: String, level: int) -> void:
	# 记录性能警告
	log_message("性能警告: " + message, level)

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
	if performance_monitor == null:
		return "性能监控器未初始化"

	var data = performance_monitor.get_performance_data()
	var memory_info = "内存使用情况:\n"
	memory_info += "- 总内存: " + str(int(data.memory_total)) + " MB\n"
	memory_info += "- 静态内存: " + str(int(data.memory_static)) + " MB\n"
	memory_info += "- 动态内存: " + str(int(data.memory_dynamic)) + " MB\n"
	memory_info += "- GPU内存: " + str(int(data.gpu_memory)) + " MB\n"
	memory_info += "- 纹理内存: " + str(int(data.texture_memory)) + " MB\n"
	memory_info += "- 对象数量: " + str(data.objects) + "\n"
	memory_info += "- 节点数量: " + str(data.nodes) + "\n"

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
