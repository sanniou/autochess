extends BaseHUD
class_name EventHUD
## 事件HUD
## 显示事件相关信息，如事件描述、选项等

# 事件管理器引用
var event_manager = null

# 当前事件
var current_event = null

# 初始化
func _initialize() -> void:
	# 获取事件管理器
	event_manager = game_manager.event_manager
	
	if event_manager == null:
		EventBus.debug.emit_event("debug_message", ["无法获取事件管理器", 1])
		return
	
	# 连接事件信号
	EventBus.event.connect_event("event_started", _on_event_started)
	EventBus.event.connect_event("event_option_selected", _on_event_option_selected)
	EventBus.event.connect_event("event_completed", _on_event_completed)
	
	# 更新显示
	update_hud()
	
	# 调用父类方法
	super._initialize()

# 更新HUD
func update_hud() -> void:
	if event_manager == null:
		return
	
	# 获取当前事件
	current_event = event_manager.get_current_event()
	
	if current_event == null:
		return
	
	# 更新事件标题
	if has_node("TitleLabel"):
		var title_label = get_node("TitleLabel")
		title_label.text = current_event.get_title()
	
	# 更新事件描述
	if has_node("DescriptionLabel"):
		var desc_label = get_node("DescriptionLabel")
		desc_label.text = current_event.get_description()
	
	# 更新事件图片
	if has_node("EventImage"):
		var event_image = get_node("EventImage")
		var image_path = current_event.get_image_path()
		if image_path:
			event_image.texture = load(image_path)
		else:
			event_image.texture = null
	
	# 更新事件选项
	_update_event_options()
	
	# 调用父类方法
	super.update_hud()

# 更新事件选项
func _update_event_options() -> void:
	# 获取选项容器
	var options_container = get_node_or_null("OptionsContainer")
	if options_container == null or current_event == null:
		return
	
	# 清空容器
	for child in options_container.get_children():
		child.queue_free()
	
	# 获取事件选项
	var options = current_event.get_options()
	
	# 添加选项按钮
	for i in range(options.size()):
		var option = options[i]
		
		# 创建选项按钮
		var option_button = Button.new()
		option_button.name = "Option_" + str(i)
		option_button.text = option.text
		option_button.custom_minimum_size = Vector2(400, 50)
		
		# 检查选项是否可用
		if option.has("available") and not option.available:
			option_button.disabled = true
			option_button.text += " " + tr("ui.event.unavailable")
		
		# 添加点击事件
		option_button.pressed.connect(_on_option_button_pressed.bind(i))
		
		# 添加到容器
		options_container.add_child(option_button)

# 事件开始处理
func _on_event_started(event) -> void:
	# 更新当前事件
	current_event = event
	
	# 更新显示
	update_hud()
	
	# 播放事件音效
	AudioManager.play_sfx("event_start.ogg")

# 事件选项选择处理
func _on_event_option_selected(option_index: int, result: Dictionary) -> void:
	# 更新显示
	update_hud()
	
	# 播放选项音效
	AudioManager.play_sfx("option_selected.ogg")
	
	# 显示结果
	_show_option_result(result)

# 事件完成处理
func _on_event_completed(event, result: Dictionary) -> void:
	# 清除当前事件
	current_event = null
	
	# 播放完成音效
	AudioManager.play_sfx("event_completed.ogg")
	
	# 延迟返回地图
	await get_tree().create_timer(2.0).timeout
	
	# 返回地图
	game_manager.change_state(GameManager.GameState.MAP)

# 选项按钮点击处理
func _on_option_button_pressed(option_index: int) -> void:
	# 选择选项
	if current_event:
		event_manager.select_option(option_index)

# 显示选项结果
func _show_option_result(result: Dictionary) -> void:
	# 创建结果弹窗
	var popup_data = {
		"title": result.get("title", tr("ui.event.result")),
		"description": result.get("description", ""),
		"rewards": result.get("rewards", {})
	}
	
	game_manager.ui_manager.show_popup("event_result", popup_data)
