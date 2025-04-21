extends "res://scripts/managers/core/base_manager.gd"
class_name UIManager
## UI管理器
## 负责管理游戏中的所有UI元素，包括弹窗、提示、过渡效果等

# 信号
signal popup_opened(popup_name: String)
signal popup_closed(popup_name: String)
signal toast_shown(message: String)
signal transition_started(transition_type: String)
signal transition_finished(transition_type: String)

# 常量
const TOAST_DURATION = 2.0  # 提示显示时间
const TRANSITION_DURATION = 0.5  # 过渡动画时间

# UI资源路径
const UI_POPUP_PATH = "res://scenes/ui/popups/"
const UI_HUD_PATH = "res://scenes/ui/hud/"
const UI_ACHIEVEMENT_PATH = "res://scenes/ui/achievement/"

# 弹窗路径映射
const POPUP_MAPPING = {
	"confirm_dialog": "confirm_dialog_popup",
	"event_result": "event_result_popup",
	"battle_result": "battle_result_popup",
	"save_select": "save_select_popup",
	"save_game": "save_game_popup",
	"load_game": "load_game_popup",
	"settings": "settings_popup",
	"node_details": "node_details_popup"
}

# UI状态
enum UIState {
	NORMAL,  # 正常状态
	POPUP,   # 弹窗状态
	LOADING, # 加载状态
	TRANSITION # 过渡状态
}

# 当前UI状态
var current_state: UIState = UIState.NORMAL

# 当前活动的弹窗
var active_popups: Array = []

# 弹窗堆栈
var popup_stack: Array = []

# 弹窗缓存
var popup_cache: Dictionary = {}

# UI容器
var ui_containers: Dictionary = {}

# 当前场景的HUD
var current_hud: Control = null

# 过渡动画节点
var transition_node: Control = null

# 提示节点
var toast_node: Control = null

# 成就通知容器
var achievement_notification_container: Control = null

# UI节流管理器
var ui_throttle_manager: UIThrottleManager = null

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "UIManager"
	# 添加依赖
	add_dependency("ConfigManager")
	# 添加依赖
	add_dependency("GameManager")
	# 添加依赖
	add_dependency("AudioManager")
	# 添加依赖
	add_dependency("SceneManager")
	# 添加UI节流管理器依赖
	add_dependency("UIThrottleManager")

	# 获取UI节流管理器
	ui_throttle_manager = GameManager.get_manager("UIThrottleManager")

	# 连接信号
	EventBus.ui.connect_event("show_toast", show_toast)
	EventBus.ui.connect_event("show_popup", show_popup)
	EventBus.ui.connect_event("close_popup", close_popup)
	EventBus.ui.connect_event("start_transition", start_transition)
	EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

	# 创建 UI 容器
	_create_ui_containers()

	# 创建过渡动画节点
	_create_transition_node()

	# 创建提示节点
	_create_toast_node()

	# 创建成就通知容器
	_create_achievement_notification_container()

	# 设置UI更新频率
	_configure_ui_throttling()

# 创建 UI 容器
func _create_ui_containers() -> void:
	# 创建 HUD 容器
	var hud_container = Control.new()
	hud_container.name = "HUDContainer"
	hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hud_container)
	ui_containers["hud"] = hud_container

	# 创建弹窗容器
	var popup_container = Control.new()
	popup_container.name = "PopupContainer"
	popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(popup_container)
	ui_containers["popup"] = popup_container

# 获取 HUD 容器
func get_hud_container() -> Control:
	return ui_containers.get("hud")

# 获取弹窗容器
func get_popup_container() -> Control:
	return ui_containers.get("popup")

# 创建过渡动画节点
func _create_transition_node() -> void:
	transition_node = Control.new()
	transition_node.name = "TransitionNode"
	transition_node.visible = false
	transition_node.set_anchors_preset(Control.PRESET_FULL_RECT)

	var color_rect = ColorRect.new()
	color_rect.name = "ColorRect"
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	transition_node.add_child(color_rect)
	add_child(transition_node)

# 创建提示节点
func _create_toast_node() -> void:
	toast_node = Control.new()
	toast_node.name = "ToastNode"
	toast_node.visible = false
	toast_node.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 80)

	var label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	panel.add_child(label)
	toast_node.add_child(panel)
	add_child(toast_node)

# 显示提示
func show_toast(message: String, duration: float = TOAST_DURATION) -> void:
	# 检查是否已经有相同的提示正在显示
	var label = toast_node.get_node("Panel/Label")
	if toast_node.visible and label.text == message:
		# 如果相同的提示已经在显示，只重置定时器
		if toast_node.has_meta("timer"):
			var old_timer = toast_node.get_meta("timer")
			if old_timer and is_instance_valid(old_timer):
				old_timer.timeout.disconnect(toast_node.get_meta("timer_callback"))
		else:
			return

	# 设置提示文本
	label.text = message

	# 显示提示
	toast_node.visible = true

	# 发送信号
	toast_shown.emit(message)

	# 创建定时器
	var timer = get_tree().create_timer(duration)
	var callback = func(): toast_node.visible = false
	timer.timeout.connect(callback)

	# 存储定时器和回调函数引用
	toast_node.set_meta("timer", timer)
	toast_node.set_meta("timer_callback", callback)

# 显示弹窗
func show_popup(popup_name: String, popup_data: Dictionary = {}, options: Dictionary = {}) -> Node:
	# 检查是否已经有相同类型的弹窗正在显示
	for popup in active_popups:
		if popup.name.begins_with(popup_name) or popup.name.begins_with(POPUP_MAPPING.get(popup_name, popup_name)):
			# 如果已经有相同类型的弹窗，更新数据并返回
			if options.get("update_existing", true):
				# 更新弹窗数据
				popup.set_popup_data(popup_data)

				# 强制更新UI
				force_update_ui("popup", popup.name)

				return popup

	# 获取弹窗文件名
	var popup_file_name = POPUP_MAPPING.get(popup_name, popup_name)

	# 检查是否有缓存
	var popup_instance = null
	if popup_cache.has(popup_name) and options.get("use_cache", false):
		popup_instance = popup_cache[popup_name]

		# 如果弹窗已经有父节点，则不使用缓存
		if popup_instance.get_parent() != null:
			popup_instance = null

	if popup_instance == null:
		# 加载弹窗场景
		var popup_path = UI_POPUP_PATH + popup_file_name + ".tscn"
		var popup_scene = load(popup_path)

		if popup_scene == null:
			EventBus.debug.emit_event("debug_message", ["无法加载弹窗: " + popup_path, 1])
			return null

		# 实例化弹窗
		popup_instance = popup_scene.instantiate()

		# 如果需要缓存
		if options.get("cache", false):
			popup_cache[popup_name] = popup_instance

	# 添加到容器
	var popup_container = get_popup_container()
	if popup_container:
		popup_container.add_child(popup_instance)
	else:
		add_child(popup_instance)

	# 设置弹窗数据
	popup_instance.set_popup_data(popup_data)

	# 初始化弹窗
	popup_instance.initialize()

	# 设置弹窗层级
	var popup_layer = options.get("layer", active_popups.size())
	_set_popup_layer(popup_instance, popup_layer)

	# 显示弹窗
	var transition = options.get("transition", "fade")
	_show_popup_with_transition(popup_instance, transition)

	# 更新UI状态
	current_state = UIState.POPUP
	active_popups.append(popup_instance)
	popup_stack.push_back(popup_instance)

	# 发送信号
	popup_opened.emit(popup_name)

	# 连接关闭信号
	if popup_instance.has_signal("popup_closed"):
		# 先断开之前的连接，避免重复连接
		if popup_instance.is_connected("popup_closed", Callable(self, "_on_popup_closed")):
			popup_instance.disconnect("popup_closed", Callable(self, "_on_popup_closed"))

		# 连接新的信号
		popup_instance.popup_closed.connect(func(): _on_popup_closed(popup_instance, popup_name))

	return popup_instance

# 关闭弹窗
func close_popup(popup_instance: Node = null) -> void:
	if popup_instance == null and active_popups.size() > 0:
		# 关闭最后一个弹窗
		popup_instance = active_popups.back()

	if popup_instance != null:
		# 检查弹窗类型
		if popup_instance.has_method("close_popup"):
			# 调用弹窗的close_popup方法
			popup_instance.close_popup()
		elif popup_instance is Window:
			# 对于Window类型，直接隐藏
			popup_instance.hide()
			# 如果Window有popup_closed信号，发送该信号
			if popup_instance.has_signal("popup_closed"):
				popup_instance.emit_signal("popup_closed")
		elif popup_instance is Control:
			# 对于Control类型，直接隐藏
			popup_instance.visible = false
			# 如果Control有popup_closed信号，发送该信号
			if popup_instance.has_signal("popup_closed"):
				popup_instance.emit_signal("popup_closed")

		# 从活动弹窗列表中移除
		active_popups.erase(popup_instance)

		# 如果没有活动弹窗，恢复正常状态
		if active_popups.size() == 0:
			current_state = UIState.NORMAL

# 设置弹窗层级
func _set_popup_layer(popup: Node, layer: int) -> void:
	# 检查是否是 Window 类型
	if popup is Window or popup.get_class() == "Window":
		# Window 类型弹窗不需要设置层级
		return

	# 确保是 Control 类型
	if not popup is Control:
		return

	# 设置 z_index
	popup.z_index = layer

	# 如果有背景，设置背景的 z_index
	if popup.has_node("Background"):
		popup.get_node("Background").z_index = layer - 1

# 使用过渡效果显示弹窗
func _show_popup_with_transition(popup: Node, transition: String) -> void:
	# 检查是否是 Window 类型
	if popup is Window or popup.get_class() == "Window":
		# Window 类型弹窗使用内置的显示方法
		if popup.has_method("show_popup"):
			popup.show_popup()
		else:
			popup.popup_centered()
		return

	match transition:
		"fade":
			# 淡入效果
			popup.modulate.a = 0
			popup.visible = true

			var tween = create_tween()
			tween.tween_property(popup, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
		"scale":
			# 缩放效果
			popup.scale = Vector2(0.5, 0.5)
			popup.modulate.a = 0
			popup.visible = true

			var tween = create_tween()
			tween.parallel().tween_property(popup, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(popup, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
		"slide":
			# 滑动效果
			var original_position = popup.position
			popup.position.y = -popup.size.y
			popup.visible = true

			var tween = create_tween()
			tween.tween_property(popup, "position", original_position, 0.3).set_ease(Tween.EASE_OUT)
		_:
			# 默认直接显示
			popup.visible = true
			if popup.has_method("show_popup"):
				popup.show_popup()

# 弹窗关闭处理
func _on_popup_closed(popup_instance: Node, popup_name: String) -> void:
	# 从活动弹窗列表中移除
	active_popups.erase(popup_instance)

	# 从弹窗堆栈中移除
	popup_stack.erase(popup_instance)

	# 如果没有活动弹窗，恢复正常状态
	if active_popups.size() == 0:
		current_state = UIState.NORMAL

	# 发送信号
	popup_closed.emit(popup_name)

	# 如果弹窗不在缓存中，则销毁它
	var is_cached = false
	for cached_popup in popup_cache.values():
		if cached_popup == popup_instance:
			is_cached = true
			break

	if not is_cached:
		# 延迟销毁弹窗
		popup_instance.queue_free()

# 开始过渡动画
func start_transition(transition_type: String = "fade", duration: float = TRANSITION_DURATION) -> void:
	# 检查是否已经有过渡动画正在进行
	if current_state == UIState.TRANSITION:
		# 如果已经有过渡动画正在进行，取消当前的过渡动画
		var tween = transition_node.get_meta("tween") if transition_node.has_meta("tween") else null
		if tween and is_instance_valid(tween):
			tween.kill()

	# 更新UI状态
	current_state = UIState.TRANSITION

	# 显示过渡动画节点
	transition_node.visible = true

	# 获取颜色矩形
	var color_rect = transition_node.get_node("ColorRect")

	# 发送信号
	transition_started.emit(transition_type)

	# 根据过渡类型执行不同的动画
	match transition_type:
		"fade_in":
			# 淡入动画
			var tween = create_tween()
			transition_node.set_meta("tween", tween)
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration)
			tween.tween_callback(func(): _on_transition_finished(transition_type))
		"fade_out":
			# 淡出动画
			color_rect.color = Color(0, 0, 0, 1)
			var tween = create_tween()
			transition_node.set_meta("tween", tween)
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration)
			tween.tween_callback(func(): _on_transition_finished(transition_type))
		"fade":
			# 淡入淡出动画
			var tween = create_tween()
			transition_node.set_meta("tween", tween)
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration / 2)
			tween.tween_callback(func(): EventBus.ui.emit_event("transition_midpoint", []))
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration / 2)
			tween.tween_callback(func(): _on_transition_finished(transition_type))
		_:
			# 默认淡入淡出
			var tween = create_tween()
			transition_node.set_meta("tween", tween)
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration / 2)
			tween.tween_callback(func(): EventBus.ui.emit_event("transition_midpoint", []))
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration / 2)
			tween.tween_callback(func(): _on_transition_finished(transition_type))

# 过渡动画完成处理
func _on_transition_finished(transition_type: String) -> void:
	# 隐藏过渡动画节点
	transition_node.visible = false

	# 恢复正常状态
	current_state = UIState.NORMAL

	# 发送信号
	transition_finished.emit(transition_type)

# 获取当前HUD
func get_current_hud() -> Control:
	return current_hud

# 设置当前HUD
func set_current_hud(hud: Control) -> void:
	# 卸载当前HUD
	if current_hud != null:
		current_hud.queue_free()

	# 设置新HUD
	current_hud = hud

# 游戏状态变化处理
func _on_game_state_changed(_old_state: int, _new_state: int) -> void:
	# 游戏状态变化时的处理
	# 注意：HUD的加载由HUDManager处理
	pass

# 获取当前UI状态
func get_current_state() -> UIState:
	return current_state

# 是否有活动弹窗
func has_active_popup() -> bool:
	return active_popups.size() > 0

# 配置UI节流
func _configure_ui_throttling() -> void:
	# 检查UI节流管理器是否可用
	if not ui_throttle_manager:
		return

	# 设置全局配置
	var config = {
		"enabled": true,
		"default_interval": 0.1,
		"high_fps_interval": 0.2,
		"low_fps_interval": 0.05,
		"fps_threshold": 40,
		"adaptive": true
	}

	# 应用配置
	ui_throttle_manager.set_global_config(config)

	# 注册常用UI节流器
	EventBus.ui.emit_event("register_ui_throttler", ["hud", config])
	EventBus.ui.emit_event("register_ui_throttler", ["popup", config])
	EventBus.ui.emit_event("register_ui_throttler", ["battle", config])
	EventBus.ui.emit_event("register_ui_throttler", ["shop", config])
	EventBus.ui.emit_event("register_ui_throttler", ["map", config])

# 获取UI节流器
func get_throttler(ui_id: String) -> UIThrottler:
	if ui_throttle_manager:
		return ui_throttle_manager.get_throttler(ui_id)
	return null

# 检查是否应该更新UI
func should_update_ui(ui_id: String, component_id: String, delta: float, custom_interval: float = -1) -> bool:
	if ui_throttle_manager:
		return ui_throttle_manager.should_update(ui_id, component_id, delta, custom_interval)
	return true

# 强制更新UI
func force_update_ui(ui_id: String, component_id: String = "") -> void:
	if ui_throttle_manager:
		ui_throttle_manager.force_update(ui_id, component_id)



# 创建成就通知容器
func _create_achievement_notification_container() -> void:
	# 创建容器
	achievement_notification_container = Control.new()
	achievement_notification_container.name = "AchievementNotificationContainer"
	achievement_notification_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(achievement_notification_container)

	# 创建垂直布局
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vbox.offset_left = -400
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = 500
	vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	vbox.add_theme_constant_override("separation", 10)
	achievement_notification_container.add_child(vbox)

# 显示成就通知
func show_achievement_notification(achievement_id: String, achievement_data: Dictionary) -> void:
	# 加载成就通知场景
	var notification_path = UI_ACHIEVEMENT_PATH + "achievement_notification.tscn"
	var notification_scene = load(notification_path)

	if notification_scene == null:
		EventBus.debug.emit_event("debug_message", ["无法加载成就通知: " + notification_path, 1])
		return

	# 实例化成就通知
	var notification_instance = notification_scene.instantiate()
	var vbox = achievement_notification_container.get_node("VBoxContainer")
	vbox.add_child(notification_instance)

	# 设置成就数据
	notification_instance.set_achievement_data(achievement_id, achievement_data)

	# 播放音效
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sfx("achievement_unlock.ogg")

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
