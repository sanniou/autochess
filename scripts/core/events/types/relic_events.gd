extends RefCounted
class_name RelicEvents
## 遗物事件类型
## 定义与遗物系统相关的事件

## 遗物获取事件
class RelicAcquiredEvent extends BusEvent:

	## 遗物数据
	var relic_data: Relic

	## 初始化
	func _init(p_relic_data: Relic):
		relic_data = p_relic_data

	## 获取事件类型
	static func get_type() -> String:
		return "relic.relic_acquired"

## 遗物激活事件
class RelicActivatedEvent extends BusEvent:

	## 遗物数据
	var relic: Relic

	## 初始化
	func _init( p_relic: Relic):
		relic = p_relic

	## 获取事件类型
	static func get_type() -> String:
		return "relic.relic_activated"


class RelicUpdatedEvent extends BusEvent:

	## 遗物数据
	var relic: Relic

	## 初始化
	func _init( p_relic: Relic):
		relic = p_relic

	## 获取事件类型
	static func get_type() -> String:
		return "relic.relic_updated"

class RelicEffectTriggeredEvent extends BusEvent:

	## 遗物数据
	var relic: Relic

	var effect: Dictionary
	## 初始化
	func _init( p_relic_data: Relic, p_effect: Dictionary):
		relic = p_relic_data
		effect = p_effect

	## 获取事件类型
	static func get_type() -> String:
		return "relic.relic_effect_triggered"


## 显示遗物信息事件
class ShowRelicInfoEvent extends BusEvent:
	## 遗物数据
	var relic: Relic

	## 初始化
	func _init( p_relic: Relic):
		relic = p_relic

	## 获取事件类型
	static func get_type() -> String:
		return "relic.show_relic_info"

## 隐藏遗物信息事件
class HideRelicInfoEvent extends BusEvent:
	## 遗物ID
	var relic_id: String

	## 初始化
	func _init(p_relic_id: String):
		relic_id = p_relic_id

	## 获取事件类型
	static func get_type() -> String:
		return "relic.hide_relic_info"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "HideRelicInfoEvent[relic_id=%s]" % [relic_id]

	## 克隆事件
	func clone() ->BusEvent:
		var event = HideRelicInfoEvent.new(relic_id)
		event.timestamp = timestamp
		event.canceled = canceled

		return event
