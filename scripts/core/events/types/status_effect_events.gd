extends RefCounted
class_name StatusEffectEvents
## 状态效果事件类型
## 定义与状态效果系统相关的事件

## 状态效果添加事件
class StatusEffectAddedEvent extends Event:
	## 目标实体
	var target
	
	## 效果ID
	var effect_id: String
	
	## 效果数据
	var effect_data: Dictionary
	
	## 效果来源
	var source
	
	## 初始化
	func _init(p_target, p_effect_id: String, p_effect_data: Dictionary, p_source = null):
		target = p_target
		effect_id = p_effect_id
		effect_data = p_effect_data
		source = p_source
	
	## 获取事件类型
	func get_type() -> String:
		return "status_effect.status_effect_added"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "StatusEffectAddedEvent[target=%s, effect_id=%s, source=%s]" % [
			target, effect_id, source
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = StatusEffectAddedEvent.new(target, effect_id, effect_data.duplicate(true), source)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 状态效果移除事件
class StatusEffectRemovedEvent extends Event:
	## 目标实体
	var target
	
	## 效果ID
	var effect_id: String
	
	## 初始化
	func _init(p_target, p_effect_id: String):
		target = p_target
		effect_id = p_effect_id
	
	## 获取事件类型
	func get_type() -> String:
		return "status_effect.status_effect_removed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "StatusEffectRemovedEvent[target=%s, effect_id=%s]" % [
			target, effect_id
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = StatusEffectRemovedEvent.new(target, effect_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 状态效果抵抗事件
class StatusEffectResistedEvent extends Event:
	## 目标实体
	var target
	
	## 效果ID
	var effect_id: String
	
	## 效果来源
	var source
	
	## 初始化
	func _init(p_target, p_effect_id: String, p_source = null):
		target = p_target
		effect_id = p_effect_id
		source = p_source
	
	## 获取事件类型
	func get_type() -> String:
		return "status_effect.status_effect_resisted"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "StatusEffectResistedEvent[target=%s, effect_id=%s, source=%s]" % [
			target, effect_id, source
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = StatusEffectResistedEvent.new(target, effect_id, source)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 状态效果触发事件
class StatusEffectTriggeredEvent extends Event:
	## 目标实体
	var target
	
	## 效果ID
	var effect_id: String
	
	## 效果数据
	var effect_data: Dictionary
	
	## 初始化
	func _init(p_target, p_effect_id: String, p_effect_data: Dictionary):
		target = p_target
		effect_id = p_effect_id
		effect_data = p_effect_data
	
	## 获取事件类型
	func get_type() -> String:
		return "status_effect.status_effect_triggered"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "StatusEffectTriggeredEvent[target=%s, effect_id=%s]" % [
			target, effect_id
		]
	
	## 克隆事件
	func clone() -> Event:
		var event = StatusEffectTriggeredEvent.new(target, effect_id, effect_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
