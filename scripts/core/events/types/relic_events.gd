extends RefCounted
class_name RelicEvents
## 遗物事件类型
## 定义与遗物系统相关的事件

## 遗物获取事件
class RelicAcquiredEvent extends Event:
	## 遗物ID
	var relic_id: String
	
	## 遗物数据
	var relic_data: Dictionary
	
	## 初始化
	func _init(p_relic_id: String, p_relic_data: Dictionary):
		relic_id = p_relic_id
		relic_data = p_relic_data
	
	## 获取事件类型
	func get_type() -> String:
		return "relic.relic_acquired"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RelicAcquiredEvent[relic_id=%s]" % [relic_id]
	
	## 克隆事件
	func clone() -> Event:
		var event = RelicAcquiredEvent.new(relic_id, relic_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 遗物激活事件
class RelicActivatedEvent extends Event:
	## 遗物ID
	var relic_id: String
	
	## 遗物数据
	var relic_data: Dictionary
	
	## 初始化
	func _init(p_relic_id: String, p_relic_data: Dictionary):
		relic_id = p_relic_id
		relic_data = p_relic_data
	
	## 获取事件类型
	func get_type() -> String:
		return "relic.relic_activated"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RelicActivatedEvent[relic_id=%s]" % [relic_id]
	
	## 克隆事件
	func clone() -> Event:
		var event = RelicActivatedEvent.new(relic_id, relic_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 显示遗物信息事件
class ShowRelicInfoEvent extends Event:
	## 遗物ID
	var relic_id: String
	
	## 遗物数据
	var relic_data: Dictionary
	
	## 初始化
	func _init(p_relic_id: String, p_relic_data: Dictionary):
		relic_id = p_relic_id
		relic_data = p_relic_data
	
	## 获取事件类型
	func get_type() -> String:
		return "relic.show_relic_info"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShowRelicInfoEvent[relic_id=%s]" % [relic_id]
	
	## 克隆事件
	func clone() -> Event:
		var event = ShowRelicInfoEvent.new(relic_id, relic_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 隐藏遗物信息事件
class HideRelicInfoEvent extends Event:
	## 遗物ID
	var relic_id: String
	
	## 初始化
	func _init(p_relic_id: String):
		relic_id = p_relic_id
	
	## 获取事件类型
	func get_type() -> String:
		return "relic.hide_relic_info"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "HideRelicInfoEvent[relic_id=%s]" % [relic_id]
	
	## 克隆事件
	func clone() -> Event:
		var event = HideRelicInfoEvent.new(relic_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
