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
signal theme_changed(theme_name: String) # Added from ThemeManager
# UIAnimator Signals
signal anim_animation_started(animation_id: String)
signal anim_animation_completed(animation_id: String)
signal anim_animation_cancelled(animation_id: String)
# NotificationSystem Signals
signal noti_notification_shown(notification_id: String, notification_type: String)
signal noti_notification_hidden(notification_id: String)
# TooltipSystem Signals
signal tip_tooltip_shown(control: Control)
signal tip_tooltip_hidden(control: Control)
# No signals from UIThrottleManager to merge


# 常量
const TOAST_DURATION = 2.0  # 提示显示时间
# TooltipSystem Constants
const TIP_TOOLTIP_DELAY = 0.5  # Display delay time
const TIP_TOOLTIP_OFFSET = Vector2(10, 10) # Tooltip offset
# NotificationSystem Constants
const NOTI_NOTIFICATION_DURATION = 3.0  # Default notification display time
const NOTI_MAX_NOTIFICATIONS = 5      # Max simultaneously displayed notifications
# UIAnimator Constants
const ANIM_ANIMATION_DURATION = 0.3  # Default animation time (prefixed)
# ThemeManager Constants
const DEFAULT_THEME = "default" # Added from ThemeManager
const THEME_PATH = "res://themes/" # Added from ThemeManager
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

# UIAnimator Properties
enum AnimState { # Renamed from AnimationState to avoid conflict if UIManager has its own
	IDLE,
	PLAYING,
	PAUSED,
	COMPLETED
}
var active_animations: Dictionary = {} # From UIAnimator

# NotificationSystem Properties
enum NotiType { # Renamed from NotificationType
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
	SYSTEM
}
var global_notification_container: Control = null # Adapted from notification_container
var noti_active_notifications: Dictionary = {} # Renamed from active_notifications
var noti_notification_queue: Array = [] # Renamed from notification_queue

# TooltipSystem Properties
var tip_current_tooltip: Control = null
var tip_current_target: Control = null
var tip_delay_timer: Timer = null
var tip_mouse_position: Vector2 = Vector2.ZERO

# UIThrottleManager Properties
var throt_throttlers: Dictionary = {}
var throt_global_config = { # Default values from UIThrottleManager
	"enabled": true,
	"default_interval": 0.1,
	"high_fps_interval": 0.2,
	"low_fps_interval": 0.05,
	"fps_threshold": 40,
	"adaptive": true
}
var throt_current_fps: float = 60.0 # Changed from int to float for consistency
var throt_fps_timer: float = 0.0

# RelicUIManager Instance
var relic_ui_instance: Node = null


# ThemeManager Properties
enum ThemeType { LIGHT, DARK, CUSTOM } # Added from ThemeManager
var current_theme: String = DEFAULT_THEME # Added from ThemeManager
var current_theme_type: ThemeType = ThemeType.LIGHT # Added from ThemeManager
var theme_cache: Dictionary = {} # Added from ThemeManager
var theme_colors: Dictionary = { # Added from ThemeManager
	"light": {
		"background": Color(0.95, 0.95, 0.95),
		"panel": Color(1, 1, 1),
		"text": Color(0.1, 0.1, 0.1),
		"primary": Color(0.2, 0.4, 0.8),
		"secondary": Color(0.5, 0.5, 0.5),
		"success": Color(0.2, 0.8, 0.2),
		"warning": Color(0.9, 0.7, 0.1),
		"danger": Color(0.8, 0.2, 0.2)
	},
	"dark": {
		"background": Color(0.15, 0.15, 0.15),
		"panel": Color(0.2, 0.2, 0.2),
		"text": Color(0.9, 0.9, 0.9),
		"primary": Color(0.3, 0.5, 0.9),
		"secondary": Color(0.6, 0.6, 0.6),
		"success": Color(0.3, 0.9, 0.3),
		"warning": Color(1, 0.8, 0.2),
		"danger": Color(0.9, 0.3, 0.3)
	}
}
var theme_font_sizes: Dictionary = { # Added from ThemeManager
	"title": 24,
	"subtitle": 20,
	"body": 16,
	"small": 14,
	"tiny": 12
}
var theme_margins: Dictionary = { # Added from ThemeManager
	"small": 5,
	"medium": 10,
	"large": 20
}


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
	# 添加UI节流管理器依赖 - No longer a separate manager
	# add_dependency("UIThrottleManager") # Removed

	# 获取UI节流管理器 - No longer a separate manager
	# ui_throttle_manager = GameManager.get_manager("UIThrottleManager") # Removed

	# 连接信号
	GlobalEventBus.ui.add_class_listener(UIEvents.ShowToastEvent, _on_show_toast)
	GlobalEventBus.ui.add_class_listener(UIEvents.ShowPopupEvent, _on_show_popup)
	GlobalEventBus.ui.add_class_listener(UIEvents.ClosePopupEvent, _on_close_popup)
	GlobalEventBus.ui.add_class_listener(UIEvents.StartTransitionEvent, _on_start_transition)
	GlobalEventBus.game.add_class_listener(GameEvents.GameStateChangedEvent, _on_game_state_changed)

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

	# Initialize Theme (from ThemeManager)
	load_theme(DEFAULT_THEME) # Using self.DEFAULT_THEME implicitly
	# The original ThemeManager listened to GlobalEventBus.ui.add_listener("theme_changed", _on_theme_changed)
	# This is removed as UIManager now directly manages theme changes.

	# Initialize Notification System (from NotificationSystem)
	_noti_create_notification_container()
	# Add listeners for NotificationSystem events (assuming UIEvents exist)
	GlobalEventBus.ui.add_class_listener(UIEvents.ShowNotificationEvent, _on_ui_show_notification_event)
	GlobalEventBus.ui.add_class_listener(UIEvents.HideNotificationEvent, _on_ui_hide_notification_event)
	GlobalEventBus.ui.add_class_listener(UIEvents.ClearNotificationsEvent, _on_ui_clear_notifications_event)

	# Initialize Tooltip System (from TooltipSystem)
	tip_delay_timer = Timer.new()
	tip_delay_timer.name = "TooltipDelayTimer" # Good practice to name nodes
	tip_delay_timer.one_shot = true
	tip_delay_timer.timeout.connect(self._tip_on_delay_timer_timeout)
	add_child(tip_delay_timer)
	if get_viewport(): # Ensure viewport is available
		get_viewport().gui_focus_changed.connect(self._tip_on_gui_focus_changed)
	else: # Connect when viewport is ready
		scene_tree_ready.connect(func(): 
			if get_viewport(): get_viewport().gui_focus_changed.connect(self._tip_on_gui_focus_changed), CONNECT_ONE_SHOT)
	
	# Initialize UIThrottleManager logic
	_throt_update_fps() # Initial FPS update
	# Event listeners for UIThrottleManager functionality
	GlobalEventBus.ui.add_class_listener(UIEvents.RegisterUIThrottlerEvent, _throt_on_register_ui_throttler_event)
	GlobalEventBus.ui.add_class_listener(UIEvents.UnregisterUIThrottlerEvent, _throt_on_unregister_ui_throttler_event)
	GlobalEventBus.ui.add_class_listener(UIEvents.ForceUIUpdateEvent, _throt_on_force_ui_update_event)

	set_process_input(true) # UIManager now needs to process input for tooltips
	set_process(true) # UIManager now needs _process for FPS updates

	# Instantiate and setup RelicUIManager
	var relic_ui_script = load("res://scripts/managers/ui/relic_ui_manager.gd")
	if relic_ui_script:
		self.relic_ui_instance = relic_ui_script.new()
		self.relic_ui_instance.name = "RelicUIManagerInstance"
		add_child(self.relic_ui_instance)

		var relic_manager_ref = GameManager.get_manager("RelicManager")
		if relic_manager_ref and self.relic_ui_instance.has_method("set_relic_manager"):
			self.relic_ui_instance.set_relic_manager(relic_manager_ref)
		elif not relic_manager_ref:
			push_warning("UIManager: RelicManager not found for RelicUIManager injection.")
		elif not self.relic_ui_instance.has_method("set_relic_manager"):
			push_warning("UIManager: RelicUIManagerInstance is missing set_relic_manager method.")
	else:
		push_error("UIManager: Failed to load RelicUIManager script.")

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

# 显示提示事件处理
func _on_show_toast(event: UIEvents.ShowToastEvent) -> void:
	show_toast(event.message, event.duration)

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

# 显示弹窗事件处理
func _on_show_popup(event: UIEvents.ShowPopupEvent) -> void:
	show_popup(event.popup_name, event.popup_data, event.options)

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
			GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法加载弹窗: " + popup_path, 1))
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

# 关闭弹窗事件处理
func _on_close_popup(event: UIEvents.ClosePopupEvent) -> void:
	close_popup(event.popup_instance)

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

# 开始过渡动画事件处理
func _on_start_transition(event: UIEvents.StartTransitionEvent) -> void:
	start_transition(event.type, event.duration)

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
			tween.tween_callback(func(): GlobalEventBus.ui.dispatch_event(UIEvents.TransitionMidpointEvent.new()))
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration / 2)
			tween.tween_callback(func(): _on_transition_finished(transition_type))
		_:
			# 默认淡入淡出
			var tween = create_tween()
			transition_node.set_meta("tween", tween)
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration / 2)
			tween.tween_callback(func(): GlobalEventBus.ui.dispatch_event(UIEvents.TransitionMidpointEvent.new()))
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
func _on_game_state_changed(_event: GameEvents.GameStateChangedEvent) -> void:
	# 游戏状态变化时的处理
	# 注意：HUD的加载由HUDManager处理
	pass

# 获取当前UI状态
func get_current_state() -> UIState:
	return current_state

# 是否有活动弹窗
func has_active_popup() -> bool:
	return active_popups.size() > 0

# 配置UI节流 - Refactored to use internal throt_* properties/methods
func _configure_ui_throttling() -> void:
	# Global config is already set by default in throt_global_config
	# To change it, one would call throt_set_global_config directly.
	# This method now primarily ensures default throttlers are registered if needed.

	# Example: Registering default throttlers using the new internal method
	# This assumes UIEvents.RegisterUIThrottlerEvent still exists and is handled by _throt_on_register_ui_throttler_event
	var default_throttler_config = throt_global_config.duplicate(true) # Use a copy

	GlobalEventBus.ui.dispatch_event(UIEvents.RegisterUIThrottlerEvent.new("hud", default_throttler_config))
	GlobalEventBus.ui.dispatch_event(UIEvents.RegisterUIThrottlerEvent.new("popup", default_throttler_config))
	GlobalEventBus.ui.dispatch_event(UIEvents.RegisterUIThrottlerEvent.new("battle", default_throttler_config))
	GlobalEventBus.ui.dispatch_event(UIEvents.RegisterUIThrottlerEvent.new("shop", default_throttler_config))
	GlobalEventBus.ui.dispatch_event(UIEvents.RegisterUIThrottlerEvent.new("map", default_throttler_config))

# 获取UI节流器 - Refactored to use internal throt_* methods
func get_throttler(id: String) -> UIThrottler: # This is now the primary method
	return _throt_get_throttler(id)

# 检查是否应该更新UI - Refactored to use internal throt_* methods
func should_update_ui(ui_id: String, component_id: String, delta: float, custom_interval: float = -1) -> bool: # This is now the primary method
	return _throt_should_update(ui_id, component_id, delta, custom_interval)

# 强制更新UI - Refactored to use internal throt_* methods
func force_update_ui(ui_id: String, component_id: String = "") -> void: # This is now the primary method
	_throt_force_update(ui_id, component_id)


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
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法加载成就通知: " + notification_path, 1))
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

# ThemeManager Methods (Copied and adapted for UIManager)

# 加载主题
func load_theme(theme_name: String) -> void:
	# 检查主题缓存
	if theme_cache.has(theme_name):
		_apply_theme(theme_cache[theme_name])
		current_theme = theme_name
		theme_changed.emit(theme_name)
		return

	# 构建主题路径
	var theme_file_path = THEME_PATH + theme_name + ".tres" # Renamed from theme_path to avoid conflict

	# 检查主题是否存在
	if not ResourceLoader.exists(theme_file_path):
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("主题不存在: " + theme_file_path, 1))
		return

	# 加载主题
	var theme_resource = ResourceLoader.load(theme_file_path) # Renamed from theme to avoid conflict
	if theme_resource == null:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法加载主题: " + theme_file_path, 1))
		return

	# 缓存主题
	theme_cache[theme_name] = theme_resource

	# 应用主题
	_apply_theme(theme_resource)

	# 更新当前主题
	current_theme = theme_name

	# 发送信号
	theme_changed.emit(theme_name)

# 应用主题
func _apply_theme(theme_resource: Theme) -> void: # Renamed from theme to avoid conflict
	# 设置全局主题
	get_tree().root.theme = theme_resource

# 获取当前主题
func get_current_theme() -> String:
	return current_theme

# 获取当前主题类型
func get_current_theme_type() -> ThemeType:
	return current_theme_type

# 获取主题对象
func get_theme_object(theme_name: String = "") -> Theme:
	if theme_name.is_empty():
		theme_name = current_theme

	if theme_cache.has(theme_name):
		return theme_cache[theme_name]

	return null

# 获取颜色 (Renamed)
func get_theme_color(color_name: String) -> Color:
	var theme_key = "light" if current_theme_type == ThemeType.LIGHT else "dark"
	return theme_colors[theme_key].get(color_name, Color(1, 1, 1))

# 获取字体大小 (Renamed)
func get_theme_font_size(size_name: String) -> int:
	return theme_font_sizes.get(size_name, 16)

# 获取边距 (Renamed)
func get_theme_margin(margin_name: String) -> int:
	return theme_margins.get(margin_name, 10)

# 设置主题类型
func set_theme_type(p_theme_type: ThemeType) -> void: # Renamed parameter to avoid conflict
	current_theme_type = p_theme_type
	_apply_theme_type()

	# 发送信号
	theme_changed.emit(current_theme)

# 应用主题类型
func _apply_theme_type() -> void:
	# 创建主题
	var theme_resource = create_theme_from_type(current_theme_type) # Renamed from theme to avoid conflict

	# 应用主题
	_apply_theme(theme_resource)

# 根据主题类型创建主题
func create_theme_from_type(p_theme_type: ThemeType) -> Theme: # Renamed parameter
	var new_theme = Theme.new() # Renamed from theme

	# 获取主题颜色
	var colors = theme_colors["light"] if p_theme_type == ThemeType.LIGHT else theme_colors["dark"]

	# 设置默认字体
	new_theme.default_font_size = theme_font_sizes["body"]

	# 设置按钮样式
	var button_normal_style = StyleBoxFlat.new()
	button_normal_style.bg_color = colors["primary"]
	button_normal_style.border_width_left = 0
	button_normal_style.border_width_top = 0
	button_normal_style.border_width_right = 0
	button_normal_style.border_width_bottom = 0
	button_normal_style.corner_radius_top_left = 4
	button_normal_style.corner_radius_top_right = 4
	button_normal_style.corner_radius_bottom_left = 4
	button_normal_style.corner_radius_bottom_right = 4

	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = colors["primary"].lightened(0.1)
	# ... (rest of button_hover_style properties) ...
	button_hover_style.corner_radius_top_left = 4 # ensure all properties are copied
	button_hover_style.corner_radius_top_right = 4
	button_hover_style.corner_radius_bottom_left = 4
	button_hover_style.corner_radius_bottom_right = 4


	var button_pressed_style = StyleBoxFlat.new()
	button_pressed_style.bg_color = colors["primary"].darkened(0.1)
	# ... (rest of button_pressed_style properties) ...
	button_pressed_style.corner_radius_top_left = 4 # ensure all properties are copied
	button_pressed_style.corner_radius_top_right = 4
	button_pressed_style.corner_radius_bottom_left = 4
	button_pressed_style.corner_radius_bottom_right = 4

	new_theme.set_stylebox("normal", "Button", button_normal_style)
	new_theme.set_stylebox("hover", "Button", button_hover_style)
	new_theme.set_stylebox("pressed", "Button", button_pressed_style)
	new_theme.set_color("font_color", "Button", colors["text"])
	new_theme.set_color("font_hover_color", "Button", colors["text"])
	new_theme.set_color("font_pressed_color", "Button", colors["text"])

	# 设置面板样式
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = colors["panel"]
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = colors["secondary"]
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4

	new_theme.set_stylebox("panel", "Panel", panel_style)

	# 设置标签样式
	new_theme.set_color("font_color", "Label", colors["text"])

	# 设置滑动条样式
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = colors["secondary"]
	slider_style.corner_radius_top_left = 2
	slider_style.corner_radius_top_right = 2
	slider_style.corner_radius_bottom_left = 2
	slider_style.corner_radius_bottom_right = 2

	new_theme.set_stylebox("slider", "HSlider", slider_style)

	return new_theme

# 创建默认主题
func create_default_theme() -> Theme:
	return create_theme_from_type(ThemeType.LIGHT)

# 创建样式盒
func create_stylebox(color_name: String, corner_radius: int = 4, border_width: int = 0, border_color_name: String = "") -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	var theme_key = "light" if current_theme_type == ThemeType.LIGHT else "dark"
	var colors = theme_colors[theme_key]

	style.bg_color = colors.get(color_name, Color(1, 1, 1))

	# 设置圆角
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	# 设置边框
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width

		if border_color_name != "":
			style.border_color = colors.get(border_color_name, Color(0.5, 0.5, 0.5))

	return style

# 应用主题到控件
func apply_theme_to_control(control: Control) -> void:
	# 根据控件类型应用不同的主题
	if control is Button:
		_apply_theme_to_button(control)
	elif control is Label:
		_apply_theme_to_label(control)
	elif control is Panel:
		_apply_theme_to_panel(control)
	elif control is LineEdit:
		_apply_theme_to_line_edit(control)
	elif control is TextEdit:
		_apply_theme_to_text_edit(control)
	elif control is OptionButton:
		_apply_theme_to_option_button(control)
	elif control is CheckBox:
		_apply_theme_to_check_box(control)
	elif control is HSlider:
		_apply_theme_to_slider(control)

	# 递归应用主题到子控件
	for child in control.get_children():
		if child is Control:
			apply_theme_to_control(child)

# 应用主题到按钮
func _apply_theme_to_button(button: Button) -> void:
	button.add_theme_color_override("font_color", get_theme_color("text"))
	button.add_theme_color_override("font_hover_color", get_theme_color("text"))
	button.add_theme_stylebox_override("normal", create_stylebox("primary"))
	button.add_theme_stylebox_override("hover", create_stylebox("primary", 4, 0, "")) # Assuming hover uses same color or needs adjustment
	button.add_theme_stylebox_override("pressed", create_stylebox("primary", 4, 0, "")) # Assuming pressed uses same color or needs adjustment


# 应用主题到标签
func _apply_theme_to_label(label: Label) -> void:
	label.add_theme_color_override("font_color", get_theme_color("text"))

# 应用主题到面板
func _apply_theme_to_panel(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到行编辑
func _apply_theme_to_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_color_override("font_color", get_theme_color("text"))
	line_edit.add_theme_stylebox_override("normal", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到文本编辑
func _apply_theme_to_text_edit(text_edit: TextEdit) -> void:
	text_edit.add_theme_color_override("font_color", get_theme_color("text"))
	text_edit.add_theme_stylebox_override("normal", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到选项按钮
func _apply_theme_to_option_button(option_button: OptionButton) -> void:
	option_button.add_theme_color_override("font_color", get_theme_color("text"))
	option_button.add_theme_stylebox_override("normal", create_stylebox("panel", 4, 1, "secondary"))

# 应用主题到复选框
func _apply_theme_to_check_box(check_box: CheckBox) -> void:
	check_box.add_theme_color_override("font_color", get_theme_color("text"))

# 应用主题到滑动条
func _apply_theme_to_slider(slider: HSlider) -> void:
	slider.add_theme_stylebox_override("slider", create_stylebox("primary", 2))

# 保存主题
func save_theme(theme_name: String, theme_resource: Theme) -> void: # Renamed theme to theme_resource
	# 构建主题路径
	var theme_file_path = THEME_PATH + theme_name + ".tres" # Renamed theme_path

	# 保存主题
	var err = ResourceSaver.save(theme_resource, theme_file_path)
	if err != OK:
		GlobalEventBus.debug.dispatch_event(DebugEvents.DebugMessageEvent.new("无法保存主题: " + theme_file_path + ", 错误: " + str(err), 1))
		return

	# 缓存主题
	theme_cache[theme_name] = theme_resource

# End of ThemeManager Methods

# 重写清理方法 (Adding for UIManager, including ThemeManager cleanup)
func _do_cleanup() -> void:
	# Original UIManager cleanup (if any, add here - currently none specific beyond BaseManager)
	# Copied and adapted ThemeManager cleanup logic:
	# GlobalEventBus.ui.remove_listener("theme_changed", _on_theme_changed) # Not needed as UIManager manages themes directly

	# Clear theme cache
	theme_cache.clear()

	# Reset global theme
	if get_tree() and get_tree().root:
		get_tree().root.theme = null
	
	_log_info("UIManager (including Theme functionality) cleanup complete.")
	
	# Ensure other UIManager specific cleanup is also handled if it existed.
	# For now, focusing on adding the theme part.
	# UIManager's original dependencies and listeners are handled by BaseManager or if it had its own _do_cleanup.
	# Since UIManager didn't have _do_cleanup, we call super() if BaseManager has one.
	# BaseManager._do_cleanup is 'pass', so super() is not strictly needed unless for future-proofing.
	# However, UIManager does have listeners like:
	# GlobalEventBus.ui.add_class_listener(UIEvents.ShowToastEvent, _on_show_toast)
	# These should be removed.

	# UIAnimator cleanup
	anim_clear_animations()

	# NotificationSystem cleanup
	noti_clear_notifications()
	if is_instance_valid(global_notification_container):
		global_notification_container.queue_free()
		global_notification_container = null
	# Remove listeners for NotificationSystem events
	GlobalEventBus.ui.remove_class_listener(UIEvents.ShowNotificationEvent, _on_ui_show_notification_event)
	GlobalEventBus.ui.remove_class_listener(UIEvents.HideNotificationEvent, _on_ui_hide_notification_event)
	GlobalEventBus.ui.remove_class_listener(UIEvents.ClearNotificationsEvent, _on_ui_clear_notifications_event)

	# UIThrottleManager event listener cleanup
	GlobalEventBus.ui.remove_class_listener(UIEvents.RegisterUIThrottlerEvent, _throt_on_register_ui_throttler_event)
	GlobalEventBus.ui.remove_class_listener(UIEvents.UnregisterUIThrottlerEvent, _throt_on_unregister_ui_throttler_event)
	GlobalEventBus.ui.remove_class_listener(UIEvents.ForceUIUpdateEvent, _throt_on_force_ui_update_event)
	
	# TooltipSystem cleanup
	if get_viewport() and get_viewport().gui_focus_changed.is_connected(self._tip_on_gui_focus_changed):
		get_viewport().gui_focus_changed.disconnect(self._tip_on_gui_focus_changed)
	tip_hide_tooltip() # Hide any active tooltip
	if is_instance_valid(tip_delay_timer):
		tip_delay_timer.queue_free()
		tip_delay_timer = null
	
	# RelicUIManager cleanup
	if is_instance_valid(relic_ui_instance):
		relic_ui_instance.queue_free()
		relic_ui_instance = null

	GlobalEventBus.ui.remove_class_listener(UIEvents.ShowToastEvent, _on_show_toast)
	GlobalEventBus.ui.remove_class_listener(UIEvents.ShowPopupEvent, _on_show_popup)
	GlobalEventBus.ui.remove_class_listener(UIEvents.ClosePopupEvent, _on_close_popup)
	GlobalEventBus.ui.remove_class_listener(UIEvents.StartTransitionEvent, _on_start_transition)
	GlobalEventBus.game.remove_class_listener(GameEvents.GameStateChangedEvent, _on_game_state_changed)

	# Cleanup for UI containers and nodes
	if is_instance_valid(toast_node):
		toast_node.queue_free()
		toast_node = null
	if is_instance_valid(transition_node):
		transition_node.queue_free()
		transition_node = null
	if is_instance_valid(achievement_notification_container):
		achievement_notification_container.queue_free()
		achievement_notification_container = null
	
	for key in ui_containers:
		if is_instance_valid(ui_containers[key]):
			ui_containers[key].queue_free()
	ui_containers.clear()
	
	active_popups.clear()
	popup_stack.clear()
	popup_cache.clear()

	super() # Call BaseManager's _do_cleanup if any future logic is added there.

# UIAnimator Methods (Copied, adapted, and prefixed with anim_)
func _anim_create_animation_id(animation_name: String) -> String:
	var timestamp = Time.get_unix_time_from_system()
	var unique_id = "ui_anim_%s_%d" % [animation_name, timestamp] # Prefixed id
	return unique_id

func _anim_on_animation_finished(animation_id: String) -> void:
	if not active_animations.has(animation_id):
		return
	var animation_data = active_animations[animation_id]
	animation_data.state = AnimState.COMPLETED
	active_animations.erase(animation_id)
	anim_animation_completed.emit(animation_id)

func anim_cancel_animation(animation_id: String) -> bool:
	if not active_animations.has(animation_id):
		return false
	var animation_data = active_animations[animation_id]
	var target = animation_data.target
	var tween = animation_data.tween
	if tween and tween is Tween:
		tween.kill()
	if animation_data.has("original_position") and is_instance_valid(target):
		target.position = animation_data.original_position
	animation_data.state = AnimState.COMPLETED
	active_animations.erase(animation_id)
	anim_animation_cancelled.emit(animation_id)
	return true

func anim_has_active_animations() -> bool:
	return not active_animations.is_empty()

func anim_get_animation_state(animation_id: String) -> int: # AnimState
	if not active_animations.has(animation_id):
		return AnimState.IDLE
	return active_animations[animation_id].state

func anim_play_animation(ui_element, animation_name: String, params: Dictionary = {}) -> String:
	if not is_instance_valid(ui_element) or animation_name.is_empty():
		return ""
	var animation_id = _anim_create_animation_id(animation_name)
	var default_params = {
		"duration": ANIM_ANIMATION_DURATION,
		"direction": "right",
		"start_scale": Vector2(0.5, 0.5),
		"end_scale": Vector2(1.0, 1.0),
		"times": 3,
		"intensity": 10.0
	}
	for key in default_params:
		if not params.has(key):
			params[key] = default_params[key]
	var animation_data = {
		"id": animation_id,
		"target": ui_element,
		"animation_name": animation_name,
		"params": params,
		"state": AnimState.PLAYING
	}
	var tween = create_tween()
	animation_data.tween = tween
	match animation_name:
		"fade_in":
			ui_element.modulate.a = 0.0
			ui_element.visible = true
			tween.tween_property(ui_element, "modulate:a", 1.0, params.duration)
		"fade_out":
			tween.tween_property(ui_element, "modulate:a", 0.0, params.duration)
			tween.tween_callback(func(): ui_element.visible = false)
		"slide_in":
			var final_position = ui_element.position
			var start_position = final_position
			match params.direction:
				"left": start_position.x = -ui_element.size.x
				"right": start_position.x = get_viewport().size.x
				"top": start_position.y = -ui_element.size.y
				"bottom": start_position.y = get_viewport().size.y
			ui_element.position = start_position
			ui_element.visible = true
			tween.tween_property(ui_element, "position", final_position, params.duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		"slide_out":
			var start_position = ui_element.position
			var final_position = start_position
			match params.direction:
				"left": final_position.x = -ui_element.size.x
				"right": final_position.x = get_viewport().size.x
				"top": final_position.y = -ui_element.size.y
				"bottom": final_position.y = get_viewport().size.y
			tween.tween_property(ui_element, "position", final_position, params.duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			tween.tween_callback(func(): ui_element.visible = false)
		"scale":
			ui_element.scale = params.start_scale
			ui_element.visible = true
			tween.tween_property(ui_element, "scale", params.end_scale, params.duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		"pop_in":
			ui_element.scale = Vector2(0.5, 0.5)
			ui_element.visible = true
			tween.tween_property(ui_element, "scale", Vector2(1.0, 1.0), params.duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		"pop_out":
			tween.tween_property(ui_element, "scale", Vector2(0.5, 0.5), params.duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			tween.tween_callback(func(): ui_element.visible = false)
		"blink":
			for i in range(params.times):
				tween.tween_property(ui_element, "modulate:a", 0.0, params.duration / (params.times * 2))
				tween.tween_property(ui_element, "modulate:a", 1.0, params.duration / (params.times * 2))
		"shake":
			var original_position = ui_element.position
			animation_data.original_position = original_position
			for i in range(params.times):
				var offset_x = randf_range(-params.intensity, params.intensity)
				var offset_y = randf_range(-params.intensity, params.intensity)
				tween.tween_property(ui_element, "position", original_position + Vector2(offset_x, offset_y), params.duration / (params.times * 2))
				tween.tween_property(ui_element, "position", original_position, params.duration / (params.times * 2))
			tween.tween_callback(func(): ui_element.position = original_position)
		_:
			return ""
	active_animations[animation_id] = animation_data
	anim_animation_started.emit(animation_id)
	tween.finished.connect(func(): _anim_on_animation_finished(animation_id))
	return animation_id

func anim_pause_animation(animation_id: String) -> bool:
	if not active_animations.has(animation_id): return false
	var animation_data = active_animations[animation_id]
	var tween = animation_data.tween
	if tween and tween is Tween:
		tween.pause()
		animation_data.state = AnimState.PAUSED
		return true
	return false

func anim_resume_animation(animation_id: String) -> bool:
	if not active_animations.has(animation_id): return false
	var animation_data = active_animations[animation_id]
	if animation_data.state != AnimState.PAUSED: return false
	var tween = animation_data.tween
	if tween and tween is Tween:
		tween.play()
		animation_data.state = AnimState.PLAYING
		return true
	return false

func anim_set_animation_speed(animation_id: String, speed: float) -> bool:
	if not active_animations.has(animation_id): return false
	if speed <= 0: return false
	var animation_data = active_animations[animation_id]
	var tween = animation_data.tween
	if tween and tween is Tween:
		tween.set_speed_scale(speed)
		return true
	return false

func anim_clear_animations() -> void:
	var animations_to_clear = active_animations.keys()
	for animation_id in animations_to_clear:
		anim_cancel_animation(animation_id)
# End of UIAnimator Methods

# NotificationSystem Methods (Copied, adapted, and prefixed with noti_)
func _noti_create_notification_container() -> void:
	global_notification_container = Control.new()
	global_notification_container.name = "GlobalNotificationContainer" # Renamed
	global_notification_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	global_notification_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer" # This name might conflict if another VBoxContainer is a direct child
	vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vbox.position = Vector2(0, 50) # This might need adjustment based on UIManager's structure
	vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	vbox.add_theme_constant_override("separation", 10)
	
	global_notification_container.add_child(vbox)
	add_child(global_notification_container) # Add to UIManager node

func noti_show_notification(message: String, p_notification_type: NotiType = NotiType.INFO, duration: float = NOTI_NOTIFICATION_DURATION, notification_id: String = "") -> String:
	if notification_id.is_empty():
		notification_id = str(Time.get_unix_time_from_system()) + "_noti_" + str(randi() % 1000)
	
	var notification_data = {
		"id": notification_id,
		"message": message,
		"type": p_notification_type,
		"duration": duration,
		"created_at": Time.get_unix_time_from_system()
	}
	
	if noti_active_notifications.size() >= NOTI_MAX_NOTIFICATIONS:
		noti_notification_queue.append(notification_data)
		return notification_id
	
	var notification_instance = _noti_create_notification_instance(notification_data)
	
	var vbox = global_notification_container.get_node("VBoxContainer") # Assumes VBoxContainer is direct child
	vbox.add_child(notification_instance)
	
	noti_active_notifications[notification_id] = {
		"instance": notification_instance,
		"data": notification_data
	}
	
	anim_play_animation(notification_instance, "fade_in", {"duration": 0.3}) # Uses self.anim_play_animation
	noti_notification_shown.emit(notification_id, NotiType.keys()[p_notification_type])
	
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(func(): noti_hide_notification(notification_id))
	
	return notification_id

func noti_hide_notification(notification_id: String) -> void:
	if not noti_active_notifications.has(notification_id):
		return
	
	var notification_entry = noti_active_notifications[notification_id]
	var notification_instance = notification_entry.instance
	
	var anim_params = {"duration": 0.3}
	# Store animation id if needed for await, though direct await is tricky
	# var anim_id = anim_play_animation(notification_instance, "fade_out", anim_params)
	anim_play_animation(notification_instance, "fade_out", anim_params)


	# Simplified: Rely on fade_out to hide, then free after a delay.
	# A more robust solution would use signals from the animation system.
	var timer = get_tree().create_timer(0.4) # Slightly longer than animation
	await timer.timeout

	if is_instance_valid(notification_instance):
		notification_instance.queue_free()
	
	noti_active_notifications.erase(notification_id)
	noti_notification_hidden.emit(notification_id)
	
	_noti_process_notification_queue()

func noti_clear_notifications() -> void:
	for notification_id in noti_active_notifications.keys(): # Iterate over keys due to modification
		noti_hide_notification(notification_id)
	noti_notification_queue.clear()

func _noti_process_notification_queue() -> void:
	if noti_notification_queue.size() > 0 and noti_active_notifications.size() < NOTI_MAX_NOTIFICATIONS:
		var next_notification = noti_notification_queue.pop_front()
		noti_show_notification(
			next_notification.message,
			next_notification.type,
			next_notification.duration,
			next_notification.id
		)

func _noti_create_notification_instance(notification_data: Dictionary) -> Control:
	var notification_instance = Panel.new()
	notification_instance.name = "Notification_" + notification_data.id
	notification_instance.custom_minimum_size = Vector2(300, 80)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	
	match notification_data.type:
		NotiType.INFO:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.4, 0.4, 0.8, 1.0)
		NotiType.SUCCESS:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.4, 0.8, 0.4, 1.0)
		NotiType.WARNING:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.8, 0.8, 0.4, 1.0)
		NotiType.ERROR:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.8, 0.4, 0.4, 1.0)
		NotiType.SYSTEM:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.8, 0.4, 0.8, 1.0)
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	notification_instance.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	# Using theme margins for consistency
	hbox.set("theme_override_constants/margin_left", get_theme_margin("medium"))
	hbox.set("theme_override_constants/margin_top", get_theme_margin("medium"))
	hbox.set("theme_override_constants/margin_right", get_theme_margin("medium"))
	hbox.set("theme_override_constants/margin_bottom", get_theme_margin("medium"))

	var icon_texture = TextureRect.new()
	icon_texture.custom_minimum_size = Vector2(32, 32)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_path = ""
	match notification_data.type:
		NotiType.INFO: icon_path = "res://assets/icons/info.svg"
		NotiType.SUCCESS: icon_path = "res://assets/icons/success.svg"
		NotiType.WARNING: icon_path = "res://assets/icons/warning.svg"
		NotiType.ERROR: icon_path = "res://assets/icons/error.svg"
		NotiType.SYSTEM: icon_path = "res://assets/icons/system.svg"
	
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
	
	var message_label = Label.new()
	message_label.text = notification_data.message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(24, 24)
	close_button.pressed.connect(func(): noti_hide_notification(notification_data.id))
	
	hbox.add_child(icon_texture)
	hbox.add_child(message_label)
	hbox.add_child(close_button)
	notification_instance.add_child(hbox)
	return notification_instance

func noti_get_active_notification_count() -> int:
	return noti_active_notifications.size()

func noti_get_queued_notification_count() -> int:
	return noti_notification_queue.size()

func noti_has_notification(notification_id: String) -> bool:
	return noti_active_notifications.has(notification_id)

func noti_update_notification_message(notification_id: String, new_message: String) -> void:
	if not noti_active_notifications.has(notification_id):
		return
	var notification_entry = noti_active_notifications[notification_id]
	var notification_instance = notification_entry.instance
	var message_label = notification_instance.get_node("HBoxContainer/Label") # Path might need adjustment
	if message_label:
		message_label.text = new_message
	notification_entry.data.message = new_message

# Event handlers for UIEvents related to notifications
func _on_ui_show_notification_event(event: UIEvents.ShowNotificationEvent) -> void:
	# Assuming UIEvents.ShowNotificationEvent has properties: message, type, duration, id
	# And that event.type maps to NotiType enum values
	var type_val = NotiType.INFO # Default
	if event.has_method("get_notification_type_enum"): # Check if event provides enum
		type_val = event.get_notification_type_enum()
	elif typeof(event.type) == TYPE_INT and NotiType.has_value(event.type): # If it's already an int/enum
		type_val = event.type
	# Add more mapping if event.type is string or other
	
	noti_show_notification(event.message, type_val, event.duration, event.id)

func _on_ui_hide_notification_event(event: UIEvents.HideNotificationEvent) -> void:
	# Assuming UIEvents.HideNotificationEvent has property: id
	noti_hide_notification(event.id)

func _on_ui_clear_notifications_event(_event: UIEvents.ClearNotificationsEvent) -> void:
	noti_clear_notifications()

# End of NotificationSystem Methods

# TooltipSystem Methods (Copied, adapted, and prefixed with tip_)
func _input(event: InputEvent) -> void: # Added for TooltipSystem mouse tracking
	if event is InputEventMouseMotion:
		tip_mouse_position = event.position
		if tip_current_tooltip and is_instance_valid(tip_current_tooltip):
			_tip_update_tooltip_position()

func tip_register_control(control: Control, tooltip_text: String = "", tooltip_builder: Callable = Callable()) -> void:
	if not is_instance_valid(control):
		return
	control.set_meta("has_tooltip", true)
	if not tooltip_text.is_empty():
		control.set_meta("tooltip_text", tooltip_text)
	if tooltip_builder.is_valid():
		control.set_meta("tooltip_builder", tooltip_builder)
	
	# Ensure signals are not connected multiple times if called repeatedly on same control
	if not control.mouse_entered.is_connected(self._tip_on_control_mouse_entered):
		control.mouse_entered.connect(self._tip_on_control_mouse_entered.bind(control))
	if not control.mouse_exited.is_connected(self._tip_on_control_mouse_exited):
		control.mouse_exited.connect(self._tip_on_control_mouse_exited.bind(control))

func tip_unregister_control(control: Control) -> void:
	if not is_instance_valid(control):
		return
	if control.has_meta("has_tooltip"): control.remove_meta("has_tooltip")
	if control.has_meta("tooltip_text"): control.remove_meta("tooltip_text")
	if control.has_meta("tooltip_builder"): control.remove_meta("tooltip_builder")
	
	if control.mouse_entered.is_connected(self._tip_on_control_mouse_entered):
		control.mouse_entered.disconnect(self._tip_on_control_mouse_entered)
	if control.mouse_exited.is_connected(self._tip_on_control_mouse_exited):
		control.mouse_exited.disconnect(self._tip_on_control_mouse_exited)

func tip_update_tooltip_text(control: Control, tooltip_text: String) -> void:
	if not is_instance_valid(control): return
	control.set_meta("tooltip_text", tooltip_text)
	if tip_current_target == control and tip_current_tooltip and is_instance_valid(tip_current_tooltip):
		var label = tip_current_tooltip.get_node("MarginContainer/Label") # Path might need adjustment if default tooltip structure changes
		if label: label.text = tooltip_text

func tip_show_tooltip(control: Control) -> void:
	if not is_instance_valid(control): return
	tip_hide_tooltip() # Hide previous one
	tip_current_target = control
	if is_instance_valid(tip_delay_timer): # Ensure timer is valid
		tip_delay_timer.start(TIP_TOOLTIP_DELAY)

func tip_hide_tooltip() -> void:
	if is_instance_valid(tip_delay_timer): tip_delay_timer.stop()
	if tip_current_tooltip and is_instance_valid(tip_current_tooltip):
		tip_current_tooltip.queue_free()
		tip_current_tooltip = null
		if tip_current_target and is_instance_valid(tip_current_target):
			tip_tooltip_hidden.emit(tip_current_target)
	tip_current_target = null

func _tip_create_tooltip() -> void:
	if not tip_current_target or not is_instance_valid(tip_current_target): return
	
	if tip_current_target.has_meta("tooltip_builder"):
		var builder = tip_current_target.get_meta("tooltip_builder")
		if builder is Callable and builder.is_valid(): # Check if callable is valid
			tip_current_tooltip = builder.call()
			if tip_current_tooltip:
				_tip_setup_tooltip()
				return
	
	if tip_current_target.has_meta("tooltip_text"):
		var tooltip_text = tip_current_target.get_meta("tooltip_text")
		if tooltip_text is String and not tooltip_text.is_empty():
			tip_current_tooltip = _tip_create_default_tooltip(tooltip_text)
			_tip_setup_tooltip()
			return
	
	if tip_current_target.has_method("get_tooltip_text") and not tip_current_target.get_tooltip_text().is_empty(): # Godot's built-in tooltip_text
		tip_current_tooltip = _tip_create_default_tooltip(tip_current_target.get_tooltip_text())
		_tip_setup_tooltip()
	elif tip_current_target.has_property("tooltip_text") and not tip_current_target.tooltip_text.is_empty():
		tip_current_tooltip = _tip_create_default_tooltip(tip_current_target.tooltip_text)
		_tip_setup_tooltip()


func _tip_setup_tooltip() -> void:
	if not tip_current_tooltip or not is_instance_valid(tip_current_tooltip): return
	add_child(tip_current_tooltip) # Add to UIManager node
	_tip_update_tooltip_position()
	tip_tooltip_shown.emit(tip_current_target)

func _tip_update_tooltip_position() -> void:
	if not tip_current_tooltip or not is_instance_valid(tip_current_tooltip): return
	var position = tip_mouse_position + TIP_TOOLTIP_OFFSET
	var viewport_size = get_viewport().size
	var tooltip_size = tip_current_tooltip.size
	if position.x + tooltip_size.x > viewport_size.x: position.x = viewport_size.x - tooltip_size.x
	if position.y + tooltip_size.y > viewport_size.y: position.y = viewport_size.y - tooltip_size.y
	tip_current_tooltip.position = position

func _tip_create_default_tooltip(text: String) -> Control:
	var tooltip = Panel.new()
	tooltip.name = "DefaultTooltip" # Renamed for clarity
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	tooltip.add_theme_stylebox_override("panel", style)
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	var label = Label.new()
	label.name = "Label"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(label)
	tooltip.add_child(margin)
	return tooltip

func _tip_on_delay_timer_timeout() -> void:
	_tip_create_tooltip()

func _tip_on_control_mouse_entered(control: Control) -> void:
	tip_show_tooltip(control)

func _tip_on_control_mouse_exited(control: Control) -> void:
	if tip_current_target == control:
		tip_hide_tooltip()

func _tip_on_gui_focus_changed(control: Control) -> void:
	if tip_current_target and tip_current_target != control:
		tip_hide_tooltip()
# End of TooltipSystem Methods

# UIThrottleManager Methods (Copied, adapted, and prefixed with throt_)
func _process(delta: float) -> void: # Added for FPS updates
	# Call existing _input for tooltip mouse tracking if it was separate
	# _input(delta) # No, _input takes InputEvent, _process takes delta. They are different.
	
	# UIThrottleManager's _process logic
	throt_fps_timer += delta
	if throt_fps_timer >= 1.0:
		throt_fps_timer = 0.0
		_throt_update_fps()

func _throt_update_fps() -> void:
	throt_current_fps = Engine.get_frames_per_second()

func _throt_get_throttler(id: String) -> UIThrottler: # Renamed from get_throttler
	if not throt_throttlers.has(id):
		var throttler = UIThrottler.new(throt_global_config) # Use throt_global_config
		throt_throttlers[id] = throttler
	return throt_throttlers[id]

func _throt_should_update(ui_id: String, component_id: String, delta: float, custom_interval: float = -1) -> bool: # Renamed
	var throttler = _throt_get_throttler(ui_id)
	return throttler.should_update(component_id, delta, custom_interval)

func _throt_force_update(ui_id: String, component_id: String = "") -> void: # Renamed
	if throt_throttlers.has(ui_id):
		var throttler = throt_throttlers[ui_id]
		if component_id.is_empty():
			throttler.reset_all()
		else:
			throttler.force_update(component_id)

func _throt_on_register_ui_throttler_event(event: UIEvents.RegisterUIThrottlerEvent) -> void: # Renamed
	var config_to_use = throt_global_config if event.data == null or event.data.is_empty() else event.data
	var throttler = UIThrottler.new(config_to_use)
	throt_throttlers[event.type] = throttler # Assuming event.type is the ui_id

func _throt_on_unregister_ui_throttler_event(event: UIEvents.UnregisterUIThrottlerEvent) -> void: # Renamed
	if throt_throttlers.has(event.ui_id):
		throt_throttlers.erase(event.ui_id)

func _throt_on_force_ui_update_event(event: UIEvents.ForceUIUpdateEvent) -> void: # Renamed
	_throt_force_update(event.ui_id, event.component_id)

func throt_set_global_config(config: Dictionary) -> void: # Renamed
	for key in config:
		if throt_global_config.has(key):
			throt_global_config[key] = config[key]
	for throttler_instance in throt_throttlers.values(): # Renamed variable
		throttler_instance.set_config("enabled", throt_global_config.enabled)
		throttler_instance.set_config("adaptive", throt_global_config.adaptive)
		throttler_instance.set_config("default_interval", throt_global_config.default_interval)
		throttler_instance.set_config("high_fps_interval", throt_global_config.high_fps_interval)
		throttler_instance.set_config("low_fps_interval", throt_global_config.low_fps_interval)
		throttler_instance.set_config("fps_threshold", throt_global_config.fps_threshold)

func throt_set_throttling_enabled(enabled: bool) -> void: # Renamed
	throt_global_config.enabled = enabled
	for throttler_instance in throt_throttlers.values(): # Renamed variable
		throttler_instance.set_config("enabled", enabled)

func throt_get_current_fps() -> float: # Renamed, changed return to float
	return throt_current_fps
# End of UIThrottleManager Methods

# RelicUIManager Exposed Methods
func show_relic_panel() -> void:
	if relic_ui_instance and relic_ui_instance.has_method("show_relic_panel"):
		relic_ui_instance.show_relic_panel()
	else:
		push_warning("UIManager: relic_ui_instance is not valid or missing show_relic_panel method.")

func hide_relic_panel() -> void:
	if relic_ui_instance and relic_ui_instance.has_method("hide_relic_panel"):
		relic_ui_instance.hide_relic_panel()
	else:
		push_warning("UIManager: relic_ui_instance is not valid or missing hide_relic_panel method.")

func show_relic_tooltip(relic_data, position: Vector2) -> void:
	if relic_ui_instance and relic_ui_instance.has_method("show_relic_tooltip"):
		relic_ui_instance.show_relic_tooltip(relic_data, position)
	else:
		push_warning("UIManager: relic_ui_instance is not valid or missing show_relic_tooltip method.")

func hide_relic_tooltip() -> void:
	if relic_ui_instance and relic_ui_instance.has_method("hide_relic_tooltip"):
		relic_ui_instance.hide_relic_tooltip()
	else:
		push_warning("UIManager: relic_ui_instance is not valid or missing hide_relic_tooltip method.")
# End of RelicUIManager Exposed Methods
