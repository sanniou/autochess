extends RefCounted
class_name DebugEvents
## 调试事件类型
## 定义与调试相关的事件

## 调试消息事件
class DebugMessageEvent extends BusEvent:
	## 消息内容
	var message: String

	## 消息级别（0=信息，1=警告，2=错误）
	var level: int

	## 消息标签
	var tag: String

	## 初始化
	func _init(p_message: String, p_level: int = 0, p_tag: String = ""):
		message = p_message
		level = p_level
		tag = p_tag

	## 获取事件类型
	static func get_type() -> String:
		return "debug.debug_message"

	## 获取事件的字符串表示
	func _to_string() -> String:
		var level_str = ["INFO", "WARNING", "ERROR"][level] if level >= 0 and level < 3 else "UNKNOWN"
		return "DebugMessageEvent[level=%s, tag=%s, message=%s]" % [level_str, tag, message]

	## 克隆事件
	func clone() ->BusEvent:
		var event = DebugMessageEvent.new(message, level, tag)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 调试命令执行事件
class DebugCommandExecutedEvent extends BusEvent:
	## 命令名称
	var command: String

	## 命令参数
	var args: Array

	## 执行结果
	var result: String

	## 初始化
	func _init(p_command: String, p_args: Array = [], p_result: String = ""):
		command = p_command
		args = p_args
		result = p_result

	## 获取事件类型
	static func get_type() -> String:
		return "debug.debug_command_executed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "DebugCommandExecutedEvent[command=%s, args=%s, result=%s]" % [command, args, result]

	## 克隆事件
	func clone() ->BusEvent:
		var event = DebugCommandExecutedEvent.new(command, args.duplicate(), result)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 调试控制台切换事件
class DebugConsoleToggledEvent extends BusEvent:
	## 是否可见
	var visible: bool

	## 初始化
	func _init(p_visible: bool):
		visible = p_visible

	## 获取事件类型
	static func get_type() -> String:
		return "debug.debug_console_toggled"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "DebugConsoleToggledEvent[visible=%s]" % [visible]

	## 克隆事件
	func clone() ->BusEvent:
		var event = DebugConsoleToggledEvent.new(visible)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 性能警告事件
class PerformanceWarningEvent extends BusEvent:
	## 警告类型
	var warning_type: String

	## 警告详情
	var details: String

	## 初始化
	func _init(p_warning_type: String, p_details: String):
		warning_type = p_warning_type
		details = p_details
	
	static func get_type() -> String:
		return "debug.performance_warning"


class PerformanceDataUpdatedEvent extends BusEvent:
	## 警告详情
	var details: Dictionary
	
	func _init(p_details: Dictionary = {}):
		details = p_details

	static func get_type() -> String:
		return "debug.performance_data_updated"
