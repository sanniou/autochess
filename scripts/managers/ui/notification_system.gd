extends Node
class_name NotificationSystem
## 通知系统
## 负责管理游戏中的通知和提示

# 信号
signal notification_shown(notification_id: String, notification_type: String)
signal notification_hidden(notification_id: String)

# 常量
const NOTIFICATION_DURATION = 3.0  # 默认通知显示时间
const MAX_NOTIFICATIONS = 5  # 最大同时显示的通知数量

# 通知类型
enum NotificationType {
	INFO,    # 信息通知
	SUCCESS, # 成功通知
	WARNING, # 警告通知
	ERROR,   # 错误通知
	SYSTEM   # 系统通知
}

# 通知容器
var notification_container: Control = null

# 活动通知
var active_notifications: Dictionary = {}

# 通知队列
var notification_queue: Array = []

# 初始化
func _ready() -> void:
	# 创建通知容器
	_create_notification_container()
	
	# 连接信号
	EventBus.ui.connect_event("show_notification", show_notification)
	EventBus.ui.connect_event("hide_notification", hide_notification)
	EventBus.ui.connect_event("clear_notifications", clear_notifications)

# 创建通知容器
func _create_notification_container() -> void:
	notification_container = Control.new()
	notification_container.name = "NotificationContainer"
	notification_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	notification_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vbox.position = Vector2(0, 50)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	vbox.add_theme_constant_override("separation", 10)
	
	notification_container.add_child(vbox)
	add_child(notification_container)

# 显示通知
func show_notification(message: String, notification_type: NotificationType = NotificationType.INFO, duration: float = NOTIFICATION_DURATION, notification_id: String = "") -> String:
	# 生成通知ID
	if notification_id.is_empty():
		notification_id = str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)
	
	# 创建通知数据
	var notification_data = {
		"id": notification_id,
		"message": message,
		"type": notification_type,
		"duration": duration,
		"created_at": Time.get_unix_time_from_system()
	}
	
	# 检查是否已达到最大通知数量
	if active_notifications.size() >= MAX_NOTIFICATIONS:
		# 将通知添加到队列
		notification_queue.append(notification_data)
		return notification_id
	
	# 创建通知实例
	var notification_instance = _create_notification_instance(notification_data)
	
	# 添加到容器
	var vbox = notification_container.get_node("VBoxContainer")
	vbox.add_child(notification_instance)
	
	# 记录活动通知
	active_notifications[notification_id] = {
		"instance": notification_instance,
		"data": notification_data
	}
	
	# 播放显示动画
	GameManager.ui_animator.fade_in(notification_instance, 0.3)
	# 发送信号
	notification_shown.emit(notification_id, NotificationType.keys()[notification_type])
	
	# 如果有持续时间，设置自动隐藏
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(func(): hide_notification(notification_id))
	
	return notification_id

# 隐藏通知
func hide_notification(notification_id: String) -> void:
	if not active_notifications.has(notification_id):
		return
	
	var notification = active_notifications[notification_id]
	var notification_instance = notification.instance
	
	# 播放隐藏动画
	GameManager.ui_animator.fade_out(notification_instance, 0.3)
	await get_tree().create_timer(0.3).timeout
	
	# 移除通知实例
	notification_instance.queue_free()
	
	# 移除活动通知记录
	active_notifications.erase(notification_id)
	
	# 发送信号
	notification_hidden.emit(notification_id)
	
	# 检查队列中是否有等待的通知
	_process_notification_queue()

# 清除所有通知
func clear_notifications() -> void:
	# 清除所有活动通知
	for notification_id in active_notifications.keys():
		hide_notification(notification_id)
	
	# 清空通知队列
	notification_queue.clear()

# 处理通知队列
func _process_notification_queue() -> void:
	if notification_queue.size() > 0 and active_notifications.size() < MAX_NOTIFICATIONS:
		var next_notification = notification_queue.pop_front()
		show_notification(
			next_notification.message,
			next_notification.type,
			next_notification.duration,
			next_notification.id
		)

# 创建通知实例
func _create_notification_instance(notification_data: Dictionary) -> Control:
	var notification_instance = Panel.new()
	notification_instance.name = "Notification_" + notification_data.id
	notification_instance.custom_minimum_size = Vector2(300, 80)
	
	# 设置样式
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	
	# 根据通知类型设置颜色
	match notification_data.type:
		NotificationType.INFO:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.4, 0.4, 0.8, 1.0)
		NotificationType.SUCCESS:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.4, 0.8, 0.4, 1.0)
		NotificationType.WARNING:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.8, 0.8, 0.4, 1.0)
		NotificationType.ERROR:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.8, 0.4, 0.4, 1.0)
		NotificationType.SYSTEM:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
			style.border_color = Color(0.8, 0.4, 0.8, 1.0)
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	notification_instance.add_theme_stylebox_override("panel", style)
	
	# 创建内容容器
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	hbox.set_margin(SIDE_LEFT, 10)
	hbox.set_margin(SIDE_TOP, 10)
	hbox.set_margin(SIDE_RIGHT, 10)
	hbox.set_margin(SIDE_BOTTOM, 10)
	
	# 创建图标
	var icon_texture = TextureRect.new()
	icon_texture.custom_minimum_size = Vector2(32, 32)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 根据通知类型设置图标
	var icon_path = ""
	match notification_data.type:
		NotificationType.INFO:
			icon_path = "res://assets/icons/info.svg"
		NotificationType.SUCCESS:
			icon_path = "res://assets/icons/success.svg"
		NotificationType.WARNING:
			icon_path = "res://assets/icons/warning.svg"
		NotificationType.ERROR:
			icon_path = "res://assets/icons/error.svg"
		NotificationType.SYSTEM:
			icon_path = "res://assets/icons/system.svg"
	
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
	
	# 创建消息标签
	var message_label = Label.new()
	message_label.text = notification_data.message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 创建关闭按钮
	var close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(24, 24)
	close_button.pressed.connect(func(): hide_notification(notification_data.id))
	
	# 添加到容器
	hbox.add_child(icon_texture)
	hbox.add_child(message_label)
	hbox.add_child(close_button)
	
	notification_instance.add_child(hbox)
	
	return notification_instance

# 获取活动通知数量
func get_active_notification_count() -> int:
	return active_notifications.size()

# 获取队列中的通知数量
func get_queued_notification_count() -> int:
	return notification_queue.size()

# 检查通知是否存在
func has_notification(notification_id: String) -> bool:
	return active_notifications.has(notification_id)

# 更新通知消息
func update_notification_message(notification_id: String, new_message: String) -> void:
	if not active_notifications.has(notification_id):
		return
	
	var notification = active_notifications[notification_id]
	var notification_instance = notification.instance
	var message_label = notification_instance.get_node("HBoxContainer/Label")
	
	if message_label:
		message_label.text = new_message
		
	# 更新数据
	notification.data.message = new_message
