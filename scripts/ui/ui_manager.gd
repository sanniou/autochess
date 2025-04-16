extends Node
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

# 当前场景的HUD
var current_hud: Control = null

# 过渡动画节点
var transition_node: Control = null

# 提示节点
var toast_node: Control = null

# 成就通知容器
var achievement_notification_container: Control = null

# 引用
@onready var scene_manager = get_node("/root/GameManager").scene_manager
@onready var config_manager = get_node("/root/ConfigManager")

# 初始化
func _ready() -> void:
	# 连接信号
	EventBus.show_toast.connect(show_toast)
	EventBus.show_popup.connect(show_popup)
	EventBus.close_popup.connect(close_popup)
	EventBus.start_transition.connect(start_transition)
	EventBus.game_state_changed.connect(_on_game_state_changed)

	# 创建过渡动画节点
	_create_transition_node()

	# 创建提示节点
	_create_toast_node()

	# 创建成就通知容器
	_create_achievement_notification_container()

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
	# 设置提示文本
	var label = toast_node.get_node("Panel/Label")
	label.text = message

	# 显示提示
	toast_node.visible = true

	# 发送信号
	toast_shown.emit(message)

	# 创建定时器
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func(): toast_node.visible = false)

# 显示弹窗
func show_popup(popup_name: String, popup_data: Dictionary = {}) -> Control:
	# 加载弹窗场景
	var popup_path = UI_POPUP_PATH + popup_name + ".tscn"
	var popup_scene = load(popup_path)

	if popup_scene == null:
		EventBus.debug_message.emit("无法加载弹窗: " + popup_path, 1)
		return null

	# 实例化弹窗
	var popup_instance = popup_scene.instantiate()
	add_child(popup_instance)

	# 设置弹窗数据
	if popup_instance.has_method("set_popup_data"):
		popup_instance.set_popup_data(popup_data)

	# 显示弹窗
	popup_instance.popup_centered()

	# 更新UI状态
	current_state = UIState.POPUP
	active_popups.append(popup_instance)

	# 发送信号
	popup_opened.emit(popup_name)

	# 连接关闭信号
	if popup_instance.has_signal("popup_hide"):
		popup_instance.popup_hide.connect(func(): _on_popup_closed(popup_instance, popup_name))

	return popup_instance

# 关闭弹窗
func close_popup(popup_instance: Control = null) -> void:
	if popup_instance == null and active_popups.size() > 0:
		# 关闭最后一个弹窗
		popup_instance = active_popups.back()

	if popup_instance != null and popup_instance.has_method("hide"):
		popup_instance.hide()

		# 从活动弹窗列表中移除
		active_popups.erase(popup_instance)

		# 如果没有活动弹窗，恢复正常状态
		if active_popups.size() == 0:
			current_state = UIState.NORMAL

# 弹窗关闭处理
func _on_popup_closed(popup_instance: Control, popup_name: String) -> void:
	# 从活动弹窗列表中移除
	active_popups.erase(popup_instance)

	# 如果没有活动弹窗，恢复正常状态
	if active_popups.size() == 0:
		current_state = UIState.NORMAL

	# 发送信号
	popup_closed.emit(popup_name)

	# 延迟销毁弹窗
	popup_instance.queue_free()

# 开始过渡动画
func start_transition(transition_type: String = "fade", duration: float = TRANSITION_DURATION) -> void:
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
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration)
			tween.tween_callback(func(): _on_transition_finished(transition_type))
		"fade_out":
			# 淡出动画
			color_rect.color = Color(0, 0, 0, 1)
			var tween = create_tween()
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration)
			tween.tween_callback(func(): _on_transition_finished(transition_type))
		"fade":
			# 淡入淡出动画
			var tween = create_tween()
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration / 2)
			tween.tween_callback(func(): EventBus.transition_midpoint.emit())
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 0), duration / 2)
			tween.tween_callback(func(): _on_transition_finished(transition_type))
		_:
			# 默认淡入淡出
			var tween = create_tween()
			tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration / 2)
			tween.tween_callback(func(): EventBus.transition_midpoint.emit())
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

# 加载HUD
func load_hud(hud_name: String) -> Control:
	# 卸载当前HUD
	if current_hud != null:
		current_hud.queue_free()
		current_hud = null

	# 加载HUD场景
	var hud_path = UI_HUD_PATH + hud_name + ".tscn"
	var hud_scene = load(hud_path)

	if hud_scene == null:
		EventBus.debug_message.emit("无法加载HUD: " + hud_path, 1)
		return null

	# 实例化HUD
	current_hud = hud_scene.instantiate()
	add_child(current_hud)

	return current_hud

# 游戏状态变化处理
func _on_game_state_changed(old_state: int, new_state: int) -> void:
	# 根据游戏状态加载不同的HUD
	match new_state:
		GameManager.GameState.MAIN_MENU:
			load_hud("main_menu_hud")
		GameManager.GameState.MAP:
			load_hud("map_hud")
		GameManager.GameState.BATTLE:
			load_hud("battle_hud")
		GameManager.GameState.SHOP:
			load_hud("shop_hud")
		GameManager.GameState.EVENT:
			load_hud("event_hud")
		_:
			# 默认HUD
			load_hud("default_hud")

# 获取当前UI状态
func get_current_state() -> UIState:
	return current_state

# 是否有活动弹窗
func has_active_popup() -> bool:
	return active_popups.size() > 0

# 获取当前HUD
func get_current_hud() -> Control:
	return current_hud

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
		EventBus.debug_message.emit("无法加载成就通知: " + notification_path, 1)
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
