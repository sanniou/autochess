extends Control
## 事件测试场景
## 用于测试各种事件的效果

# 事件管理器
var event_manager: EventManager

# 配置管理器
var config_manager: ConfigManager

# 选中的事件
var selected_event: Event = null

# 初始化
func _ready():
	# 获取管理器
	event_manager = get_node("/root/GameManager/EventManager")
	config_manager = get_node("/root/GameManager/ConfigManager")
	
	# 连接信号
	EventBus.connect("event_option_selected", _on_event_option_selected)
	
	# 加载事件列表
	_load_event_list()
	
	# 清空事件显示
	_clear_event_display()

# 加载事件列表
func _load_event_list() -> void:
	# 获取事件列表容器
	var container = $EventList/VBoxContainer
	
	# 清空现有内容
	for child in container.get_children():
		if child.name != "EventListTitle":
			child.queue_free()
	
	# 获取所有事件配置
	var event_configs = event_manager.get_all_event_configs()
	
	# 添加事件到列表
	for id in event_configs:
		var config = event_configs[id]
		
		# 创建事件项
		var item = _create_event_item(id, config)
		container.add_child(item)

# 创建事件项
func _create_event_item(id: String, config: Dictionary) -> Control:
	# 创建容器
	var item = HBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 创建事件名称标签
	var name_label = Label.new()
	name_label.text = config.title
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(name_label)
	
	# 创建事件类型标签
	var type_label = Label.new()
	type_label.text = config.type
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(type_label)
	
	# 创建选择按钮
	var select_button = Button.new()
	select_button.text = "选择"
	select_button.pressed.connect(_on_event_selected.bind(id))
	item.add_child(select_button)
	
	return item

# 清空事件显示
func _clear_event_display() -> void:
	# 清空事件内容
	$EventDisplay/EventContent.text = "选择一个事件查看详情..."
	
	# 清空事件标题
	$EventDisplay/EventTitle.text = "事件详情"
	
	# 清空选项容器
	for child in $EventDisplay/OptionContainer.get_children():
		child.queue_free()

# 事件选择处理
func _on_event_selected(id: String) -> void:
	# 创建事件
	selected_event = event_manager.create_event(id)
	
	# 显示事件
	_display_event(selected_event)

# 显示事件
func _display_event(event: Event) -> void:
	# 设置事件标题
	$EventDisplay/EventTitle.text = event.title
	
	# 设置事件内容
	$EventDisplay/EventContent.text = event.description
	
	# 清空选项容器
	for child in $EventDisplay/OptionContainer.get_children():
		child.queue_free()
	
	# 添加选项
	for option in event.options:
		var option_button = Button.new()
		option_button.text = option.text
		option_button.pressed.connect(_on_option_button_pressed.bind(option))
		$EventDisplay/OptionContainer.add_child(option_button)

# 选项按钮处理
func _on_option_button_pressed(option: Dictionary) -> void:
	# 触发选项选择信号
	EventBus.event_option_selected.emit(selected_event, option)

# 事件选项选择处理
func _on_event_option_selected(event: Event, option: Dictionary) -> void:
	# 显示选项结果
	var result_text = "选择了选项: " + option.text + "\n\n"
	
	# 添加结果描述
	if option.has("result_description"):
		result_text += option.result_description + "\n\n"
	
	# 添加效果描述
	if option.has("effects"):
		result_text += "效果:\n"
		for effect in option.effects:
			result_text += "- " + _get_effect_description(effect) + "\n"
	
	# 更新事件内容
	$EventDisplay/EventContent.text = result_text
	
	# 清空选项容器
	for child in $EventDisplay/OptionContainer.get_children():
		child.queue_free()
	
	# 添加继续按钮
	var continue_button = Button.new()
	continue_button.text = "继续"
	continue_button.pressed.connect(_on_continue_button_pressed)
	$EventDisplay/OptionContainer.add_child(continue_button)

# 继续按钮处理
func _on_continue_button_pressed() -> void:
	# 清空事件显示
	_clear_event_display()
	
	# 清空选中事件
	selected_event = null

# 获取效果描述
func _get_effect_description(effect: Dictionary) -> String:
	var description = ""
	
	match effect.type:
		"gold":
			var amount = effect.amount
			if amount > 0:
				description = "获得 " + str(amount) + " 金币"
			else:
				description = "失去 " + str(abs(amount)) + " 金币"
		"health":
			var amount = effect.amount
			if amount > 0:
				description = "恢复 " + str(amount) + " 生命值"
			else:
				description = "失去 " + str(abs(amount)) + " 生命值"
		"equipment":
			description = "获得装备: " + effect.equipment_id
		"chess_piece":
			description = "获得棋子: " + effect.chess_id
		"relic":
			description = "获得遗物: " + effect.relic_id
		"buff":
			description = "获得增益: " + effect.buff_id
		"debuff":
			description = "获得减益: " + effect.debuff_id
		"shop_discount":
			var discount = int(effect.discount * 100)
			description = "商店折扣: " + str(discount) + "%"
		"max_health":
			var amount = effect.amount
			if amount > 0:
				description = "增加 " + str(amount) + " 最大生命值"
			else:
				description = "减少 " + str(abs(amount)) + " 最大生命值"
		"random":
			description = "随机效果"
		_:
			description = "未知效果: " + effect.type
	
	return description

# 测试事件按钮处理
func _on_test_event_button_pressed() -> void:
	if selected_event:
		# 显示事件
		_display_event(selected_event)

# 随机事件按钮处理
func _on_random_event_button_pressed() -> void:
	# 创建随机事件
	var random_event = event_manager.create_random_event()
	
	# 设置选中事件
	selected_event = random_event
	
	# 显示事件
	_display_event(random_event)

# 重置按钮处理
func _on_reset_button_pressed() -> void:
	# 清空事件显示
	_clear_event_display()
	
	# 清空选中事件
	selected_event = null

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
