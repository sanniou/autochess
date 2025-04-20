extends Control
## 事件场景
## 显示事件和选项

# 当前事件
var current_event = null

# 初始化
func _ready():
	# 获取当前事件
	if GameManager.event_manager.current_event:
		current_event = GameManager.event_manager.current_event
		
		# 显示事件
		_display_event()
	else:
		# 如果没有事件，返回地图
		_return_to_map()

# 显示事件
func _display_event():
	if not current_event:
		return
	
	# 设置标题
	$MarginContainer/VBoxContainer/HeaderPanel/TitleLabel.text = current_event.title
	
	# 设置描述
	$MarginContainer/VBoxContainer/ContentPanel/VBoxContainer/DescriptionLabel.text = current_event.description
	
	# 设置图片
	var image_path = current_event.image_path
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		$MarginContainer/VBoxContainer/ContentPanel/VBoxContainer/EventImage.texture = load(image_path)
	
	# 创建选项按钮
	_create_choice_buttons()

# 创建选项按钮
func _create_choice_buttons():
	# 清空选项容器
	var container = $MarginContainer/VBoxContainer/ContentPanel/VBoxContainer/ChoicesContainer
	for child in container.get_children():
		child.queue_free()
	
	# 添加选项按钮
	for i in range(current_event.choices.size()):
		var choice = current_event.choices[i]
		
		# 创建按钮
		var button = Button.new()
		button.text = choice.text
		button.custom_minimum_size = Vector2(0, 50)
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		
		# 检查是否满足选项要求
		if choice.has("requirements"):
			var can_choose = _check_choice_requirements(choice.requirements)
			button.disabled = not can_choose
			
			# 如果不满足要求，添加提示
			if not can_choose:
				button.text += " (不满足要求)"
		
		container.add_child(button)

# 检查选项要求
func _check_choice_requirements(requirements: Dictionary) -> bool:
	var player = GameManager.player_manager.get_current_player()
	if not player:
		return false
	
	for req_type in requirements:
		var req_value = requirements[req_type]
		
		match req_type:
			"gold":
				# 检查金币
				if player.gold < req_value:
					return false
			
			"health":
				# 检查生命值
				if player.current_health < req_value:
					return false
			
			"level":
				# 检查等级
				if player.level < req_value:
					return false
			
			"chess_piece":
				# 检查棋子
				var has_piece = false
				for piece in player.chess_pieces:
					if piece.id == req_value:
						has_piece = true
						break
				if not has_piece:
					return false
			
			"equipment":
				# 检查装备
				var has_equipment = false
				for equipment in player.equipments:
					if equipment.id == req_value:
						has_equipment = true
						break
				if not has_equipment:
					return false
			
			"relic":
				# 检查遗物
				var has_relic = false
				for relic in player.relics:
					if relic.id == req_value:
						has_relic = true
						break
				if not has_relic:
					return false
	
	return true

# 选项按钮点击处理
func _on_choice_button_pressed(choice_index: int):
	if not current_event:
		return
	
	# 选择选项
	current_event.make_choice(choice_index)
	
	# 返回地图
	_return_to_map()

# 跳过按钮点击处理
func _on_skip_button_pressed():
	# 返回地图
	_return_to_map()

# 返回地图
func _return_to_map():
	GameManager.change_state(GameManager.GameState.MAP)
