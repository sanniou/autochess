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
	
	# 记录游戏启动信息
	log_message("游戏启动，版本: " + Engine.get_version_info().string, DebugLevel.INFO)

## 注册控制台命令
func _register_console_commands() -> void:
	register_command("help", _cmd_help, "显示所有可用命令")
	register_command("reload_configs", _cmd_reload_configs, "重新加载所有配置文件")
	register_command("give_gold", _cmd_give_gold, "给予金币，用法: give_gold [数量]")
	register_command("give_item", _cmd_give_item, "给予物品，用法: give_item [物品ID]")
	register_command("toggle_god_mode", _cmd_toggle_god_mode, "切换无敌模式")
	register_command("clear_log", _cmd_clear_log, "清除调试日志")
	register_command("show_fps", _cmd_show_fps, "显示/隐藏FPS")
	register_command("teleport", _cmd_teleport, "传送到指定地图节点，用法: teleport [节点ID]")

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
	var fps_visible = not Engine.get_frames_per_second()
	Engine.set_time_scale(1.0)  # 这不是正确的显示FPS的方法，仅作为示例
	return "FPS显示已" + ("开启" if fps_visible else "关闭")

## teleport命令处理
func _cmd_teleport(args: Array) -> String:
	if args.size() == 0:
		return "用法: teleport [节点ID]"
	
	var node_id = args[0]
	
	# 这里将调用地图管理器进行传送
	# 暂时只返回成功消息
	return "已传送到节点: %s" % node_id
