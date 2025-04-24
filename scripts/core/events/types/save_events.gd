extends RefCounted
class_name SaveEvents
## 存档事件类型
## 定义与存档系统相关的事件

## 存档请求事件
class SaveGameRequestedEvent extends BusEvent:
	## 存档ID
	var save_id: String
	
	## 存档数据
	var save_data: Dictionary
	
	## 初始化
	func _init(p_save_id: String, p_save_data: Dictionary):
		save_id = p_save_id
		save_data = p_save_data
	
	## 获取事件类型
	func get_type() -> String:
		return "save.save_game_requested"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "SaveGameRequestedEvent[save_id=%s]" % [save_id]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = SaveGameRequestedEvent.new(save_id, save_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 加载请求事件
class LoadGameRequestedEvent extends BusEvent:
	## 存档ID
	var save_id: String
	
	## 初始化
	func _init(p_save_id: String):
		save_id = p_save_id
	
	## 获取事件类型
	func get_type() -> String:
		return "save.load_game_requested"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "LoadGameRequestedEvent[save_id=%s]" % [save_id]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = LoadGameRequestedEvent.new(save_id)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 游戏已加载事件
class GameLoadedEvent extends BusEvent:
	## 存档ID
	var save_id: String
	
	## 存档数据
	var save_data: Dictionary
	
	## 初始化
	func _init(p_save_id: String, p_save_data: Dictionary):
		save_id = p_save_id
		save_data = p_save_data
	
	## 获取事件类型
	func get_type() -> String:
		return "save.game_loaded"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "GameLoadedEvent[save_id=%s]" % [save_id]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = GameLoadedEvent.new(save_id, save_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 自动存档触发事件
class AutosaveTriggeredEvent extends BusEvent:
	## 初始化
	func _init():
		pass
	
	## 获取事件类型
	func get_type() -> String:
		return "save.autosave_triggered"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AutosaveTriggeredEvent[]"
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = AutosaveTriggeredEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event
