extends Control
## 商店测试场景
## 用于测试商店系统的各项功能

# 商店管理器
var shop_manager = null

# 玩家管理器
var player_manager = null

# 当前商店类型
var current_shop_type = 0  # 0: 棋子商店, 1: 装备商店, 2: 遗物商店

# 初始化
func _ready():
	# 获取管理器引用
	shop_manager = GameManager.shop_manager
	player_manager = GameManager.player_manager
	
	# 初始化UI
	_initialize_ui()
	
	# 初始化商店
	_initialize_shop()
	
	# 更新玩家信息
	_update_player_info()

# 初始化UI
func _initialize_ui() -> void:
	# 设置商店类型选择器
	if has_node("ControlPanel/ShopTypeSelector/ShopTypeDropdown"):
		var dropdown = $ControlPanel/ShopTypeSelector/ShopTypeDropdown
		
		dropdown.clear()
		dropdown.add_item("棋子商店", 0)
		dropdown.add_item("装备商店", 1)
		dropdown.add_item("遗物商店", 2)
		dropdown.add_item("黑市商店", 3)
		dropdown.add_item("神秘商店", 4)
		
		dropdown.selected = 0
		current_shop_type = 0

# 初始化商店
func _initialize_shop() -> void:
	# 刷新商店
	if shop_manager:
		shop_manager.refresh_shop(true)
		
		# 更新商店物品
		_update_shop_items()

# 更新玩家信息
func _update_player_info() -> void:
	if player_manager and has_node("PlayerPanel/PlayerInfo"):
		var player = player_manager.get_current_player()
		if player:
			var info_text = "玩家信息：\n"
			info_text += "金币：" + str(player.gold) + "\n"
			info_text += "等级：" + str(player.level) + "\n"
			info_text += "经验：" + str(player.exp) + "/" + str(player.exp_to_level_up) + "\n"
			info_text += "生命值：" + str(player.health) + "/" + str(player.max_health) + "\n"
			
			$PlayerPanel/PlayerInfo.text = info_text

# 更新商店物品
func _update_shop_items() -> void:
	if shop_manager and has_node("ShopPanel/ItemContainer"):
		var container = $ShopPanel/ItemContainer
		
		# 清除现有物品
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
		
		# 获取商店物品
		var shop_items = shop_manager.get_shop_items()
		var items = []
		
		# 根据当前商店类型获取物品
		match current_shop_type:
			0:  # 棋子商店
				items = shop_items.get("chess", [])
			1:  # 装备商店
				items = shop_items.get("equipment", [])
			2:  # 遗物商店
				items = shop_items.get("relic", [])
			3:  # 黑市商店
				items = []
				items.append_array(shop_items.get("chess", []))
				items.append_array(shop_items.get("equipment", []))
				items.append_array(shop_items.get("relic", []))
			4:  # 神秘商店
				items = []
				items.append_array(shop_items.get("chess", []))
				items.append_array(shop_items.get("equipment", []))
				items.append_array(shop_items.get("relic", []))
		
		# 创建物品按钮
		for i in range(items.size()):
			var item = items[i]
			
			# 创建物品面板
			var item_panel = Panel.new()
			item_panel.custom_minimum_size = Vector2(120, 150)
			item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			# 创建物品容器
			var vbox = VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.offset_left = 5
			vbox.offset_top = 5
			vbox.offset_right = -5
			vbox.offset_bottom = -5
			item_panel.add_child(vbox)
			
			# 创建物品名称标签
			var name_label = Label.new()
			name_label.text = item.get("name", "未知物品")
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(name_label)
			
			# 创建物品图标
			var icon = TextureRect.new()
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(80, 80)
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(icon)
			
			# 创建物品价格标签
			var price_label = Label.new()
			price_label.text = str(item.get("price", 0)) + " 金币"
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(price_label)
			
			# 创建购买按钮
			var buy_button = Button.new()
			buy_button.text = "购买"
			buy_button.pressed.connect(_on_buy_item_button_pressed.bind(i))
			vbox.add_child(buy_button)
			
			# 添加到容器
			container.add_child(item_panel)
		
		# 更新商店标题
		if has_node("ShopPanel/ShopTitle"):
			var title_text = ""
			match current_shop_type:
				0:
					title_text = "棋子商店"
				1:
					title_text = "装备商店"
				2:
					title_text = "遗物商店"
				3:
					title_text = "黑市商店"
				4:
					title_text = "神秘商店"
			
			$ShopPanel/ShopTitle.text = title_text

# 购买物品
func _buy_item(item_index: int) -> void:
	if shop_manager:
		var result = false
		
		# 根据当前商店类型购买物品
		match current_shop_type:
			0:  # 棋子商店
				result = shop_manager.purchase_chess(item_index)
			1:  # 装备商店
				result = shop_manager.purchase_equipment(item_index)
			2:  # 遗物商店
				result = shop_manager.purchase_relic(item_index)
			3, 4:  # 黑市商店和神秘商店
				# 需要确定物品类型
				var shop_items = shop_manager.get_shop_items()
				var all_items = []
				all_items.append_array(shop_items.get("chess", []))
				all_items.append_array(shop_items.get("equipment", []))
				all_items.append_array(shop_items.get("relic", []))
				
				if item_index < all_items.size():
					var item = all_items[item_index]
					var item_type = item.get("type", "")
					
					match item_type:
						"chess_piece":
							result = shop_manager.purchase_chess(item_index)
						"weapon", "armor", "accessory":
							result = shop_manager.purchase_equipment(item_index)
						"relic":
							result = shop_manager.purchase_relic(item_index)
		
		# 更新UI
		if result:
			# 更新商店物品
			_update_shop_items()
			
			# 更新玩家信息
			_update_player_info()
			
			# 显示消息
			if has_node("MessageLabel"):
				$MessageLabel.text = "购买成功"
				$MessageLabel.visible = true
				
				# 3秒后隐藏消息
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func(): $MessageLabel.visible = false)
		else:
			# 显示错误消息
			if has_node("MessageLabel"):
				$MessageLabel.text = "购买失败：金币不足或库存已满"
				$MessageLabel.visible = true
				
				# 3秒后隐藏消息
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func(): $MessageLabel.visible = false)

# 刷新商店
func _refresh_shop() -> void:
	if shop_manager:
		var result = shop_manager.manual_refresh_shop()
		
		if result:
			# 更新商店物品
			_update_shop_items()
			
			# 更新玩家信息
			_update_player_info()
			
			# 显示消息
			if has_node("MessageLabel"):
				$MessageLabel.text = "商店已刷新"
				$MessageLabel.visible = true
				
				# 3秒后隐藏消息
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func(): $MessageLabel.visible = false)
		else:
			# 显示错误消息
			if has_node("MessageLabel"):
				$MessageLabel.text = "刷新失败：金币不足或商店已锁定"
				$MessageLabel.visible = true
				
				# 3秒后隐藏消息
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func(): $MessageLabel.visible = false)

# 锁定商店
func _toggle_shop_lock() -> void:
	if shop_manager:
		var is_locked = shop_manager.toggle_shop_lock()
		
		# 更新锁定按钮文本
		if has_node("ShopPanel/ButtonContainer/LockButton"):
			$ShopPanel/ButtonContainer/LockButton.text = "解锁商店" if is_locked else "锁定商店"
		
		# 显示消息
		if has_node("MessageLabel"):
			$MessageLabel.text = "商店已" + ("锁定" if is_locked else "解锁")
			$MessageLabel.visible = true
			
			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)

# 修改金币
func _modify_gold(amount: int) -> void:
	if player_manager:
		var player = player_manager.get_current_player()
		if player:
			player.add_gold(amount)
			
			# 更新玩家信息
			_update_player_info()
			
			# 显示消息
			if has_node("MessageLabel"):
				var action = "增加" if amount > 0 else "减少"
				$MessageLabel.text = "金币" + action + "了 " + str(abs(amount))
				$MessageLabel.visible = true
				
				# 3秒后隐藏消息
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func(): $MessageLabel.visible = false)

# 修改等级
func _modify_level(amount: int) -> void:
	if player_manager:
		var player = player_manager.get_current_player()
		if player:
			if amount > 0:
				for i in range(amount):
					player.level_up()
			else:
				player.level = max(1, player.level + amount)
			
			# 更新玩家信息
			_update_player_info()
			
			# 显示消息
			if has_node("MessageLabel"):
				var action = "提升" if amount > 0 else "降低"
				$MessageLabel.text = "等级" + action + "了 " + str(abs(amount))
				$MessageLabel.visible = true
				
				# 3秒后隐藏消息
				var timer = get_tree().create_timer(3.0)
				timer.timeout.connect(func(): $MessageLabel.visible = false)

# 触发特殊商店
func _trigger_special_shop() -> void:
	if shop_manager:
		match current_shop_type:
			3:  # 黑市商店
				shop_manager.trigger_black_market()
			4:  # 神秘商店
				shop_manager.trigger_mystery_shop()
		
		# 更新商店物品
		_update_shop_items()
		
		# 显示消息
		if has_node("MessageLabel"):
			var shop_type = "黑市" if current_shop_type == 3 else "神秘"
			$MessageLabel.text = shop_type + "商店已触发"
			$MessageLabel.visible = true
			
			# 3秒后隐藏消息
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): $MessageLabel.visible = false)

# 商店类型下拉菜单变化处理
func _on_shop_type_dropdown_item_selected(index: int) -> void:
	# 更新当前商店类型
	current_shop_type = index
	
	# 更新商店物品
	_update_shop_items()
	
	# 更新特殊商店按钮状态
	if has_node("ControlPanel/SpecialShopButton"):
		$ControlPanel/SpecialShopButton.visible = index == 3 or index == 4
		
		if index == 3:
			$ControlPanel/SpecialShopButton.text = "触发黑市商店"
		elif index == 4:
			$ControlPanel/SpecialShopButton.text = "触发神秘商店"

# 购买物品按钮处理
func _on_buy_item_button_pressed(item_index: int) -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 购买物品
	_buy_item(item_index)

# 刷新按钮处理
func _on_refresh_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 刷新商店
	_refresh_shop()

# 锁定按钮处理
func _on_lock_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 锁定商店
	_toggle_shop_lock()

# 增加金币按钮处理
func _on_add_gold_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 增加金币
	_modify_gold(10)

# 减少金币按钮处理
func _on_remove_gold_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 减少金币
	_modify_gold(-10)

# 增加等级按钮处理
func _on_level_up_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 增加等级
	_modify_level(1)

# 减少等级按钮处理
func _on_level_down_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 减少等级
	_modify_level(-1)

# 特殊商店按钮处理
func _on_special_shop_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 触发特殊商店
	_trigger_special_shop()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 播放按钮音效
	AudioManager.play_ui_sound("button_click.ogg")
	
	# 返回测试中心
	get_tree().change_scene_to_file("res://scenes/test/test_hub.tscn")
