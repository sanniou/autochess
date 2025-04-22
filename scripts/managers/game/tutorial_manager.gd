extends "res://scripts/managers/core/base_manager.gd"
class_name TutorialManager
## 教程管理器
## 负责管理游戏教程的显示和进度

# 信号
signal tutorial_started(tutorial_id: String)
signal tutorial_step_changed(tutorial_id: String, step: int)
signal tutorial_completed(tutorial_id: String)
signal tutorial_skipped(tutorial_id: String)

# 教程状态
enum TutorialState {
	INACTIVE,  # 未激活
	ACTIVE,    # 激活
	COMPLETED, # 已完成
	SKIPPED    # 已跳过
}

# 教程配置
var tutorial_configs = {}

# 已完成的教程
var completed_tutorials = {}

# 已跳过的教程
var skipped_tutorials = {}

# 当前激活的教程
var active_tutorial = ""

# 当前教程步骤
var current_step = 0

# 教程面板
var tutorial_panel = null

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "TutorialManager"
	# 添加依赖
	add_dependency("SaveManager")

	# 原 _ready 函数的内容
	# 加载教程配置
	_load_tutorial_configs()

	# 连接信号
	_connect_signals()

	# 加载教程数据
	_load_tutorial_data()

# 加载教程配置
func _load_tutorial_configs() -> void:
	tutorial_configs = GameManager.config_manager.get_all_tutorials()

# 连接信号
func _connect_signals() -> void:
	# 连接游戏状态变化信号
	EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

	# 连接教程相关信号
	EventBus.tutorial.connect_event("start_tutorial", start_tutorial)
	EventBus.tutorial.connect_event("skip_tutorial", skip_tutorial)
	EventBus.tutorial.connect_event("complete_tutorial", complete_tutorial)

# 加载教程数据
func _load_tutorial_data() -> void:
	# 获取存档数据
	var tutorial_data = SaveManager.load_tutorial_data()

	# 加载已完成的教程
	if tutorial_data.has("completed_tutorials"):
		completed_tutorials = tutorial_data.completed_tutorials.duplicate()

	# 加载已跳过的教程
	if tutorial_data.has("skipped_tutorials"):
		skipped_tutorials = tutorial_data.skipped_tutorials.duplicate()

# 保存教程数据
func _save_tutorial_data() -> void:
	# 创建教程存档数据
	var tutorial_data = {
		"completed_tutorials": completed_tutorials.duplicate(),
		"skipped_tutorials": skipped_tutorials.duplicate()
	}

	# 保存教程数据
	SaveManager.save_tutorial_data(tutorial_data)

# 开始教程
func start_tutorial(tutorial_id: String) -> bool:
	# 检查教程是否存在
	if not tutorial_configs.has(tutorial_id):
		EventBus.debug.emit_event("debug_message", ["教程不存在: " + tutorial_id, 1])
		return false

	# 检查教程是否已完成或已跳过
	if completed_tutorials.has(tutorial_id) or skipped_tutorials.has(tutorial_id):
		return false

	# 如果有其他激活的教程，先停止它
	if active_tutorial != "":
		_stop_active_tutorial()

	# 设置当前教程
	active_tutorial = tutorial_id
	current_step = 0

	# 获取教程配置
	var tutorial_config = tutorial_configs[tutorial_id]

	# 显示教程面板
	_show_tutorial_panel(tutorial_id)

	# 发送教程开始信号
	tutorial_started.emit(tutorial_id)

	# 显示第一步
	_show_tutorial_step(0)

	return true

# 下一步教程
func next_tutorial_step() -> bool:
	# 检查是否有激活的教程
	if active_tutorial == "":
		return false

	# 获取教程配置
	var tutorial_config = tutorial_configs[active_tutorial]

	# 检查是否已经是最后一步
	if current_step >= tutorial_config.steps.size() - 1:
		# 完成教程
		complete_tutorial(active_tutorial)
		return true

	# 增加步骤
	current_step += 1

	# 显示下一步
	_show_tutorial_step(current_step)

	# 发送步骤变化信号
	tutorial_step_changed.emit(active_tutorial, current_step)

	return true

# 上一步教程
func previous_tutorial_step() -> bool:
	# 检查是否有激活的教程
	if active_tutorial == "":
		return false

	# 检查是否已经是第一步
	if current_step <= 0:
		return false

	# 减少步骤
	current_step -= 1

	# 显示上一步
	_show_tutorial_step(current_step)

	# 发送步骤变化信号
	tutorial_step_changed.emit(active_tutorial, current_step)

	return true

# 完成教程
func complete_tutorial(tutorial_id: String) -> bool:
	# 检查教程是否存在
	if not tutorial_configs.has(tutorial_id):
		return false

	# 检查教程是否已完成
	if completed_tutorials.has(tutorial_id):
		return false

	# 标记教程为已完成
	mark_tutorial_completed(tutorial_id)

	# 如果是当前激活的教程，停止它
	if active_tutorial == tutorial_id:
		_stop_active_tutorial()

	# 发送教程完成信号
	tutorial_completed.emit(tutorial_id)

	# 检查是否有后续教程
	_check_next_tutorial(tutorial_id)

	return true

# 标记教程为已完成
func mark_tutorial_completed(tutorial_id: String) -> void:
	# 检查教程是否存在
	if not tutorial_configs.has(tutorial_id):
		return

	# 标记教程为已完成
	completed_tutorials[tutorial_id] = {
		"completion_time": Time.get_unix_time_from_system(),
		"skipped": false
	}

	# 保存教程数据
	_save_tutorial_data()

# 跳过教程
func skip_tutorial(tutorial_id: String) -> bool:
	# 检查教程是否存在
	if not tutorial_configs.has(tutorial_id):
		return false

	# 检查教程是否已跳过
	if skipped_tutorials.has(tutorial_id):
		return false

	# 标记教程为已跳过
	mark_tutorial_skipped(tutorial_id)

	# 如果是当前激活的教程，停止它
	if active_tutorial == tutorial_id:
		_stop_active_tutorial()

	# 发送教程跳过信号
	tutorial_skipped.emit(tutorial_id)

	return true

# 标记教程为已跳过
func mark_tutorial_skipped(tutorial_id: String) -> void:
	# 检查教程是否存在
	if not tutorial_configs.has(tutorial_id):
		return

	# 标记教程为已跳过
	skipped_tutorials[tutorial_id] = {
		"skip_time": Time.get_unix_time_from_system()
	}

	# 保存教程数据
	_save_tutorial_data()

# 获取教程状态
func get_tutorial_state(tutorial_id: String) -> int:
	# 检查教程是否存在
	if not tutorial_configs.has(tutorial_id):
		return TutorialState.INACTIVE

	# 检查教程是否已完成
	if completed_tutorials.has(tutorial_id):
		return TutorialState.COMPLETED

	# 检查教程是否已跳过
	if skipped_tutorials.has(tutorial_id):
		return TutorialState.SKIPPED

	# 检查教程是否激活
	if active_tutorial == tutorial_id:
		return TutorialState.ACTIVE

	return TutorialState.INACTIVE

# 获取所有教程
func get_all_tutorials() -> Dictionary:
	return tutorial_configs.duplicate()

# 获取已完成的教程
func get_completed_tutorials() -> Dictionary:
	return completed_tutorials.duplicate()

# 获取已跳过的教程
func get_skipped_tutorials() -> Dictionary:
	return skipped_tutorials.duplicate()

# 获取当前激活的教程
func get_active_tutorial() -> String:
	return active_tutorial

# 获取当前教程步骤
func get_current_step() -> int:
	return current_step

# 检查教程是否已完成
func is_tutorial_completed(tutorial_id: String) -> bool:
	return completed_tutorials.has(tutorial_id)

# 检查教程是否已跳过
func is_tutorial_skipped(tutorial_id: String) -> bool:
	return skipped_tutorials.has(tutorial_id)

# 检查教程是否激活
func is_tutorial_active(tutorial_id: String) -> bool:
	return active_tutorial == tutorial_id

# 重置教程进度
func reset_tutorial_progress() -> void:
	# 清空已完成的教程
	completed_tutorials.clear()

	# 清空已跳过的教程
	skipped_tutorials.clear()

	# 停止当前激活的教程
	if active_tutorial != "":
		_stop_active_tutorial()

	# 保存教程数据
	_save_tutorial_data()

# 停止当前激活的教程
func _stop_active_tutorial() -> void:
	# 隐藏教程面板
	_hide_tutorial_panel()

	# 重置当前教程
	active_tutorial = ""
	current_step = 0

# 显示教程面板
func _show_tutorial_panel(tutorial_id: String) -> void:
	# 获取UI管理器
	var ui_manager = GameManager.ui_manager
	if ui_manager == null:
		return

	# 显示教程面板
	tutorial_panel = ui_manager.show_popup("tutorial_panel", {
		"tutorial_id": tutorial_id,
		"tutorial_manager": self
	})

# 隐藏教程面板
func _hide_tutorial_panel() -> void:
	# 获取UI管理器
	var ui_manager = GameManager.ui_manager
	if ui_manager == null:
		return

	# 隐藏教程面板
	if tutorial_panel != null:
		ui_manager.close_popup(tutorial_panel)
		tutorial_panel = null

# 显示教程步骤
func _show_tutorial_step(step: int) -> void:
	# 检查是否有激活的教程
	if active_tutorial == "":
		return

	# 获取教程配置
	var tutorial_config:TutorialConfig = tutorial_configs[active_tutorial]

	# 检查步骤是否有效
	if step < 0 or step >= tutorial_config.get_step_count():
		return

	# 获取步骤数据
	var step_data = tutorial_config.steps[step]

	# 更新教程面板
	if tutorial_panel != null and tutorial_panel.has_method("set_step_data"):
		tutorial_panel.set_step_data(step_data, step, tutorial_config.steps.size())

	# 执行步骤动作
	_execute_step_actions(step_data)

# 执行步骤动作
func _execute_step_actions(step_data: Dictionary) -> void:
	# 检查是否有动作
	if not step_data.has("actions"):
		return

	# 获取动作列表
	var actions = step_data.actions

	# 执行每个动作
	for action in actions:
		match action.type:
			"highlight":
				# 高亮UI元素
				_highlight_ui_element(action.target, action.get("duration", 3.0))
			"focus":
				# 聚焦UI元素
				_focus_ui_element(action.target)
			"disable":
				# 禁用UI元素
				_disable_ui_elements(action.targets)
			"enable":
				# 启用UI元素
				_enable_ui_elements(action.targets)
			"wait":
				# 等待事件
				_wait_for_event(action.event, action.get("timeout", 0.0))
			"show":
				# 显示UI元素
				_show_ui_elements(action.targets)
			"hide":
				# 隐藏UI元素
				_hide_ui_elements(action.targets)
			"move_camera":
				# 移动相机
				_move_camera(action.position, action.get("duration", 1.0))
			"play_animation":
				# 播放动画
				_play_animation(action.target, action.animation, action.get("speed", 1.0))

# 高亮UI元素
func _highlight_ui_element(target_path: String, duration: float) -> void:
	# 获取UI管理器
	var ui_manager = GameManager.ui_manager
	if ui_manager == null:
		return

	# 获取UI元素
	var target = get_node_or_null(target_path)
	if target == null:
		return

	# 高亮UI元素
	if ui_manager.has_method("highlight_ui_element"):
		ui_manager.highlight_ui_element(target, duration)

# 聚焦UI元素
func _focus_ui_element(target_path: String) -> void:
	# 获取UI元素
	var target = get_node_or_null(target_path)
	if target == null:
		return

	# 聚焦UI元素
	if target.has_method("grab_focus"):
		target.grab_focus()

# 禁用UI元素
func _disable_ui_elements(target_paths: Array) -> void:
	for target_path in target_paths:
		# 获取UI元素
		var target = get_node_or_null(target_path)
		if target == null:
			continue

		# 禁用UI元素
		if target.has_property("disabled"):
			target.disabled = true

# 启用UI元素
func _enable_ui_elements(target_paths: Array) -> void:
	for target_path in target_paths:
		# 获取UI元素
		var target = get_node_or_null(target_path)
		if target == null:
			continue

		# 启用UI元素
		if target.has_property("disabled"):
			target.disabled = false

# 等待事件
func _wait_for_event(event_name: String, timeout: float) -> void:
	# 连接事件
	var connection = EventBus.get_signal_connection_list(event_name)
	if connection.is_empty():
		EventBus.connect(event_name, func(): next_tutorial_step())

	# 如果有超时，设置超时定时器
	if timeout > 0:
		var timer = get_tree().create_timer(timeout)
		timer.timeout.connect(func(): next_tutorial_step())

# 显示UI元素
func _show_ui_elements(target_paths: Array) -> void:
	for target_path in target_paths:
		# 获取UI元素
		var target = get_node_or_null(target_path)
		if target == null:
			continue

		# 显示UI元素
		if target.has_property("visible"):
			target.visible = true

# 隐藏UI元素
func _hide_ui_elements(target_paths: Array) -> void:
	for target_path in target_paths:
		# 获取UI元素
		var target = get_node_or_null(target_path)
		if target == null:
			continue

		# 隐藏UI元素
		if target.has_property("visible"):
			target.visible = false

# 移动相机
func _move_camera(position: Vector2, duration: float) -> void:
	# 获取相机
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	# 移动相机
	var tween = create_tween()
	tween.tween_property(camera, "global_position", position, duration)

# 播放动画
func _play_animation(target_path: String, animation_name: String, speed: float) -> void:
	# 获取目标节点
	var target = get_node_or_null(target_path)
	if target == null:
		return

	# 获取动画播放器
	var animation_player = null
	if target.has_node("AnimationPlayer"):
		animation_player = target.get_node("AnimationPlayer")
	elif target is AnimationPlayer:
		animation_player = target

	# 播放动画
	if animation_player != null:
		animation_player.play(animation_name)
		animation_player.speed_scale = speed

# 检查后续教程
func _check_next_tutorial(tutorial_id: String) -> void:
	# 获取教程配置
	var tutorial_config = tutorial_configs[tutorial_id]

	# 检查是否有后续教程
	if tutorial_config.has("next_tutorial"):
		var next_tutorial_id = tutorial_config.next_tutorial

		# 检查后续教程是否存在
		if tutorial_configs.has(next_tutorial_id):
			# 检查后续教程是否已完成或已跳过
			if not completed_tutorials.has(next_tutorial_id) and not skipped_tutorials.has(next_tutorial_id):
				# 开始后续教程
				start_tutorial(next_tutorial_id)

# 游戏状态变化处理
func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# 根据游戏状态自动开始相应的教程
	match new_state:
		GameManager.GameState.MAIN_MENU:
			# 检查是否需要显示主菜单教程
			if not completed_tutorials.has("main_menu") and not skipped_tutorials.has("main_menu"):
				start_tutorial("main_menu")
		GameManager.GameState.MAP:
			# 检查是否需要显示地图教程
			if not completed_tutorials.has("map") and not skipped_tutorials.has("map"):
				start_tutorial("map")
		GameManager.GameState.BATTLE:
			# 检查是否需要显示战斗教程
			if not completed_tutorials.has("battle") and not skipped_tutorials.has("battle"):
				start_tutorial("battle")
		GameManager.GameState.SHOP:
			# 检查是否需要显示商店教程
			if not completed_tutorials.has("shop") and not skipped_tutorials.has("shop"):
				start_tutorial("shop")
		GameManager.GameState.EVENT:
			# 检查是否需要显示事件教程
			if not completed_tutorials.has("event") and not skipped_tutorials.has("event"):
				start_tutorial("event")


# 重写重置方法
func _do_reset() -> void:
	# 重置教程进度
	reset_tutorial_progress()

	# 重新加载教程配置
	_load_tutorial_configs()

	_log_info("教程管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.game.disconnect_event("game_state_changed", _on_game_state_changed)
	EventBus.tutorial.disconnect_event("start_tutorial", start_tutorial)
	EventBus.tutorial.disconnect_event("skip_tutorial", skip_tutorial)
	EventBus.tutorial.disconnect_event("complete_tutorial", complete_tutorial)

	# 停止当前激活的教程
	if active_tutorial != "":
		_stop_active_tutorial()

	# 清空教程数据
	tutorial_configs.clear()
	completed_tutorials.clear()
	skipped_tutorials.clear()

	_log_info("教程管理器清理完成")
