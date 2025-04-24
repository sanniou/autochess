extends RefCounted
class_name EventEvents
## 事件系统事件类型
## 定义与事件系统相关的事件

## 事件开始事件
class EventStartedEvent extends Event:
	## 事件ID
	var event_id: String
	
	## 事件数据
	var event_data: Dictionary
	
	## 初始化
	func _init(p_event_id: String, p_event_data: Dictionary):
		event_id = p_event_id
		event_data = p_event_data
	
	## 获取事件类型
	func get_type() -> String:
		return "event.event_started"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EventStartedEvent[event_id=%s]" % [event_id]
	
	## 克隆事件
	func clone() -> Event:
		var event = EventStartedEvent.new(event_id, event_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 事件选项选择事件
class EventOptionSelectedEvent extends Event:
	## 事件ID
	var event_id: String
	
	## 选项ID
	var option_id: String
	
	## 选项数据
	var option_data: Dictionary
	
	## 初始化
	func _init(p_event_id: String, p_option_id: String, p_option_data: Dictionary):
		event_id = p_event_id
		option_id = p_option_id
		option_data = p_option_data
	
	## 获取事件类型
	func get_type() -> String:
		return "event.event_option_selected"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EventOptionSelectedEvent[event_id=%s, option_id=%s]" % [
			event_id, option_id
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = EventOptionSelectedEvent.new(event_id, option_id, option_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 事件完成事件
class EventCompletedEvent extends Event:
	## 事件ID
	var event_id: String
	
	## 结果
	var result: Dictionary
	
	## 初始化
	func _init(p_event_id: String, p_result: Dictionary):
		event_id = p_event_id
		result = p_result
	
	## 获取事件类型
	func get_type() -> String:
		return "event.event_completed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "EventCompletedEvent[event_id=%s, result=%s]" % [
			event_id, result
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = EventCompletedEvent.new(event_id, result.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
