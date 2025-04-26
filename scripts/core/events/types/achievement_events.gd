extends RefCounted
class_name AchievementEvents
## 成就事件类型
## 定义与成就系统相关的事件

## 成就解锁事件
class AchievementUnlockedEvent extends BusEvent:
	## 成就ID
	var achievement_id: String
	
	## 成就数据
	var achievement_data: Dictionary
	
	## 初始化
	func _init(p_achievement_id: String, p_achievement_data: Dictionary):
		achievement_id = p_achievement_id
		achievement_data = p_achievement_data
	
	## 获取事件类型
	static func get_type() -> String:
		return "achievement.achievement_unlocked"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AchievementUnlockedEvent[achievement_id=%s]" % [achievement_id]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = AchievementUnlockedEvent.new(achievement_id, achievement_data.duplicate(true))
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 成就进度更新事件
class AchievementProgressUpdatedEvent extends BusEvent:
	## 成就ID
	var achievement_id: String
	
	## 旧进度
	var old_progress: float
	
	## 新进度
	var new_progress: float
	
	## 目标进度
	var target_progress: float
	
	## 初始化
	func _init(p_achievement_id: String, p_old_progress: float, p_new_progress: float, p_target_progress: float):
		achievement_id = p_achievement_id
		old_progress = p_old_progress
		new_progress = p_new_progress
		target_progress = p_target_progress
	
	## 获取事件类型
	static func get_type() -> String:
		return "achievement.achievement_progress_updated"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AchievementProgressUpdatedEvent[achievement_id=%s, old_progress=%.1f, new_progress=%.1f, target_progress=%.1f]" % [
			achievement_id, old_progress, new_progress, target_progress
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = AchievementProgressUpdatedEvent.new(achievement_id, old_progress, new_progress, target_progress)
		event.timestamp = timestamp
		event.canceled = canceled

		return event
