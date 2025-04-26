extends RefCounted
class_name TutorialEvents
## 教程事件类型
## 定义与教程系统相关的事件

## 开始教程事件
class StartTutorialEvent extends BusEvent:
	## 教程ID
	var tutorial_id: String
	
	## 初始化
	func _init(p_tutorial_id: String):
		tutorial_id = p_tutorial_id
	
	## 获取事件类型
	static func get_type() -> String:
		return "tutorial.start_tutorial"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "StartTutorialEvent[tutorial_id=%s]" % [tutorial_id]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = StartTutorialEvent.new(tutorial_id)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 跳过教程事件
class SkipTutorialEvent extends BusEvent:
	## 教程ID
	var tutorial_id: String
	
	## 初始化
	func _init(p_tutorial_id: String):
		tutorial_id = p_tutorial_id
	
	## 获取事件类型
	static func get_type() -> String:
		return "tutorial.skip_tutorial"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "SkipTutorialEvent[tutorial_id=%s]" % [tutorial_id]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = SkipTutorialEvent.new(tutorial_id)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 完成教程事件
class CompleteTutorialEvent extends BusEvent:
	## 教程ID
	var tutorial_id: String
	
	## 初始化
	func _init(p_tutorial_id: String):
		tutorial_id = p_tutorial_id
	
	## 获取事件类型
	static func get_type() -> String:
		return "tutorial.complete_tutorial"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "CompleteTutorialEvent[tutorial_id=%s]" % [tutorial_id]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = CompleteTutorialEvent.new(tutorial_id)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 教程步骤变更事件
class TutorialStepChangedEvent extends BusEvent:
	## 教程ID
	var tutorial_id: String
	
	## 步骤索引
	var step_index: int
	
	## 总步骤数
	var total_steps: int
	
	## 初始化
	func _init(p_tutorial_id: String, p_step_index: int, p_total_steps: int):
		tutorial_id = p_tutorial_id
		step_index = p_step_index
		total_steps = p_total_steps
	
	## 获取事件类型
	static func get_type() -> String:
		return "tutorial.step_changed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "TutorialStepChangedEvent[tutorial_id=%s, step=%d/%d]" % [
			tutorial_id, step_index, total_steps
		]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = TutorialStepChangedEvent.new(tutorial_id, step_index, total_steps)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 教程步骤完成事件
class TutorialStepCompletedEvent extends BusEvent:
	## 教程ID
	var tutorial_id: String
	
	## 步骤索引
	var step_index: int
	
	## 初始化
	func _init(p_tutorial_id: String, p_step_index: int):
		tutorial_id = p_tutorial_id
		step_index = p_step_index
	
	## 获取事件类型
	static func get_type() -> String:
		return "tutorial.step_completed"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "TutorialStepCompletedEvent[tutorial_id=%s, step=%d]" % [
			tutorial_id, step_index
		]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = TutorialStepCompletedEvent.new(tutorial_id, step_index)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 教程高亮显示事件
class TutorialHighlightShownEvent extends BusEvent:
	## 目标节点路径
	var target_path: String
	
	## 持续时间
	var duration: float
	
	## 初始化
	func _init(p_target_path: String, p_duration: float = 3.0):
		target_path = p_target_path
		duration = p_duration
	
	## 获取事件类型
	static func get_type() -> String:
		return "tutorial.highlight_shown"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "TutorialHighlightShownEvent[target=%s, duration=%.1f]" % [
			target_path, duration
		]
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = TutorialHighlightShownEvent.new(target_path, duration)
		event.timestamp = timestamp
		event.canceled = canceled
		return event

## 教程高亮隐藏事件
class TutorialHighlightHiddenEvent extends BusEvent:
	## 初始化
	func _init():
		pass
	
	## 获取事件类型
	static func get_type() -> String:
		return "tutorial.highlight_hidden"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "TutorialHighlightHiddenEvent[]"
	
	## 克隆事件
	func clone() -> BusEvent:
		var event = TutorialHighlightHiddenEvent.new()
		event.timestamp = timestamp
		event.canceled = canceled
		return event
