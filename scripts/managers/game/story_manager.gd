extends "res://scripts/managers/core/base_manager.gd"
class_name StoryManager
## 剧情管理器
## 负责管理游戏中的剧情标记和分支

# 剧情标记
var story_flags = {}  # {标记名: 值}

# 剧情分支
var story_branches = {}  # {分支名: 选择的路径}

# 剧情进度
var story_progress = 0  # 主线剧情进度

# 已触发的剧情事件
var triggered_story_events = []  # 已触发的剧情事件ID列表

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "StoryManager"
	
	# 原 _ready 函数的内容
	# 连接信号
	EventBus.event.connect_event("event_completed", _on_event_completed)
	
# 设置剧情标记
func set_flag(flag_name: String, value = true) -> void:
	story_flags[flag_name] = value
	
	# 发送剧情标记设置信号
	EventBus.debug.emit_event("debug_message", ["设置剧情标记: " + flag_name + " = " + str(value), 0])
	
	# 检查是否触发新的剧情事件
	_check_story_triggers()

# 获取剧情标记
func get_flag(flag_name: String, default_value = false) -> Variant:
	if story_flags.has(flag_name):
		return story_flags[flag_name]
	return default_value

# 设置剧情分支
func set_branch(branch_name: String, path: String) -> void:
	story_branches[branch_name] = path
	
	# 发送剧情分支设置信号
	EventBus.debug.emit_event("debug_message", ["设置剧情分支: " + branch_name + " = " + path, 0])
	
	# 检查是否触发新的剧情事件
	_check_story_triggers()

# 获取剧情分支
func get_branch(branch_name: String, default_path: String = "") -> String:
	if story_branches.has(branch_name):
		return story_branches[branch_name]
	return default_path

# 增加剧情进度
func advance_story(amount: int = 1) -> void:
	story_progress += amount
	
	# 发送剧情进度更新信号
	EventBus.debug.emit_event("debug_message", ["剧情进度更新: " + str(story_progress), 0])
	
	# 检查是否触发新的剧情事件
	_check_story_triggers()

# 获取剧情进度
func get_story_progress() -> int:
	return story_progress

# 检查是否已触发剧情事件
func is_story_event_triggered(event_id: String) -> bool:
	return triggered_story_events.has(event_id)

# 标记剧情事件为已触发
func mark_story_event_triggered(event_id: String) -> void:
	if not triggered_story_events.has(event_id):
		triggered_story_events.append(event_id)

# 检查剧情触发条件
func _check_story_triggers() -> void:
	# 检查主线剧情触发
	_check_main_story_triggers()
	
	# 检查分支剧情触发
	_check_branch_story_triggers()

# 检查主线剧情触发
func _check_main_story_triggers() -> void:
	var event_manager = get_node("/root/GameManager/EventManager")
	if not event_manager:
		return
	
	# 根据剧情进度触发对应事件
	match story_progress:
		3:
			if not is_story_event_triggered("story_introduction"):
				event_manager.trigger_event("story_introduction")
				mark_story_event_triggered("story_introduction")
		
		6:
			if not is_story_event_triggered("story_first_challenge"):
				event_manager.trigger_event("story_first_challenge")
				mark_story_event_triggered("story_first_challenge")
		
		10:
			if not is_story_event_triggered("story_midpoint"):
				event_manager.trigger_event("story_midpoint")
				mark_story_event_triggered("story_midpoint")
		
		15:
			if not is_story_event_triggered("story_final_challenge"):
				event_manager.trigger_event("story_final_challenge")
				mark_story_event_triggered("story_final_challenge")

# 检查分支剧情触发
func _check_branch_story_triggers() -> void:
	var event_manager = get_node("/root/GameManager/EventManager")
	if not event_manager:
		return
	
	# 检查力量之路分支
	if get_flag("chose_power") and not is_story_event_triggered("story_power_path"):
		event_manager.trigger_event("story_power_path")
		mark_story_event_triggered("story_power_path")
	
	# 检查智慧之路分支
	if get_flag("chose_wisdom") and not is_story_event_triggered("story_wisdom_path"):
		event_manager.trigger_event("story_wisdom_path")
		mark_story_event_triggered("story_wisdom_path")
	
	# 检查财富之路分支
	if get_flag("chose_wealth") and not is_story_event_triggered("story_wealth_path"):
		event_manager.trigger_event("story_wealth_path")
		mark_story_event_triggered("story_wealth_path")
	
	# 检查特殊组合
	if get_flag("chose_power") and get_flag("found_ancient_artifact") and not is_story_event_triggered("story_power_artifact"):
		event_manager.trigger_event("story_power_artifact")
		mark_story_event_triggered("story_power_artifact")

# 事件完成事件处理
func _on_event_completed(event: Event, result: Dictionary) -> void:
	# 检查是否是剧情事件
	if event.event_type == "story":
		# 增加剧情进度
		advance_story()

# 保存剧情状态
func save_story_state() -> Dictionary:
	return {
		"story_flags": story_flags.duplicate(),
		"story_branches": story_branches.duplicate(),
		"story_progress": story_progress,
		"triggered_story_events": triggered_story_events.duplicate()
	}

# 加载剧情状态
func load_story_state(save_data: Dictionary) -> void:
	if save_data.has("story_flags"):
		story_flags = save_data.story_flags.duplicate()
	
	if save_data.has("story_branches"):
		story_branches = save_data.story_branches.duplicate()
	
	if save_data.has("story_progress"):
		story_progress = save_data.story_progress
	
	if save_data.has("triggered_story_events"):
		triggered_story_events = save_data.triggered_story_events.duplicate()

# 重置管理器
func reset() -> bool:
	story_flags.clear()
	story_branches.clear()
	story_progress = 0
	triggered_story_events.clear()
	return true

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])
