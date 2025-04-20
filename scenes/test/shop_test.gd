extends Control
## 商店测试场景
## 用于测试商店系统的功能

# 当前玩家
var current_player:Player = null

# 初始化
func _ready():
	# 初始化测试玩家
	_initialize_test_player()

	# 加载商店场景
	var shop_scene = load("res://scenes/shop/shop_scene.tscn").instantiate()
	$ShopContainer.add_child(shop_scene)

	# 连接测试按钮信号
	$TestPanel/AddGoldButton.pressed.connect(_on_add_gold_button_pressed)
	$TestPanel/UpgradeLevelButton.pressed.connect(_on_upgrade_level_button_pressed)
	$TestPanel/UpgradeShopButton.pressed.connect(_on_upgrade_shop_button_pressed)
	$TestPanel/ApplyDiscountButton.pressed.connect(_on_apply_discount_button_pressed)
	$TestPanel/TriggerBlackMarketButton.pressed.connect(_on_trigger_black_market_button_pressed)
	$TestPanel/TriggerMysteryShopButton.pressed.connect(_on_trigger_mystery_shop_button_pressed)
	$TestPanel/TriggerEquipmentShopButton.pressed.connect(_on_trigger_equipment_shop_button_pressed)
	$TestPanel/AddRelicButton.pressed.connect(_on_add_relic_button_pressed)
	$TestPanel/ToggleTestPanelButton.pressed.connect(_on_toggle_test_panel_button_pressed)
	$TestPanel/CloseButton.pressed.connect(_on_close_button_pressed)
	$ToggleButtonContainer/ToggleButton.pressed.connect(_on_toggle_button_pressed)

	# 默认隐藏测试面板
	$TestPanel.visible = false

	# 更新测试数据显示
	_update_test_data_display()

	# 连接事件
	EventBus.economy.connect_event("item_purchased", _on_item_purchased)
	EventBus.economy.connect_event("shop_refreshed", _on_shop_refreshed)

	# 设置快捷键
	set_process_input(true)

# 初始化测试玩家
func _initialize_test_player() -> void:
	# 创建测试玩家
	GameManager.player_manager.initialize_player("ShopTest")
	current_player = GameManager.player_manager.get_current_player()

	# 设置初始金币和等级
	if current_player:
		current_player.gold = 100
		current_player.level = 1
		current_player.current_health = 100
		current_player.max_health = 100

# 更新测试数据显示
func _update_test_data_display() -> void:
	if current_player:
		$TestDataPanel/PlayerInfoContainer/PlayerLevelLabel.text = "玩家等级: " + str(current_player.level)
		$TestDataPanel/PlayerInfoContainer/PlayerGoldLabel.text = "玩家金币: " + str(current_player.gold)
		$TestDataPanel/PlayerInfoContainer/PlayerHealthLabel.text = "玩家生命: " + str(current_player.current_health) + "/" + str(current_player.max_health)

	var shop_params = GameManager.shop_manager.get_shop_params()
	$TestDataPanel/ShopInfoContainer/ShopDiscountLabel.text = "商店折扣: " + str(int(shop_params.discount_rate * 100)) + "%"

	var shop_type = "普通商店"
	if shop_params.is_black_market:
		shop_type = "黑市商人"
	elif shop_params.is_mystery_shop:
		shop_type = "神秘商店"
	elif shop_params.is_equipment_shop:
		shop_type = "装备商店"

	$TestDataPanel/ShopInfoContainer/ShopTypeLabel.text = "商店类型: " + shop_type

	# 更新已购买物品列表
	_update_purchased_items_list()

# 更新已购买物品列表
func _update_purchased_items_list() -> void:
	$TestDataPanel/PurchasedItemsContainer/PurchasedItemsList.clear()

	if current_player:
		# 添加棋子
		for piece in current_player.chess_pieces:
			$TestDataPanel/PurchasedItemsContainer/PurchasedItemsList.add_item("棋子: " + piece.id)

		# 添加装备
		for equipment in current_player.equipments:
			$TestDataPanel/PurchasedItemsContainer/PurchasedItemsList.add_item("装备: " + equipment.id)

		# 添加遗物
		for relic in GameManager.relic_manager.get_player_relics():
			$TestDataPanel/PurchasedItemsContainer/PurchasedItemsList.add_item("遗物: " + relic.id)

# 输入处理
func _input(event: InputEvent) -> void:
	# 快捷键处理
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_G:  # 增加金币
				if event.shift_pressed:
					_on_add_gold_button_pressed()
			KEY_L:  # 提升等级
				if event.shift_pressed:
					_on_upgrade_level_button_pressed()
			KEY_R:  # 刷新商店
				if event.shift_pressed:
					GameManager.shop_manager.refresh_shop(true)
			KEY_T:  # 切换测试面板
				if event.shift_pressed:
					_toggle_panels()

# 测试按钮处理
func _on_add_gold_button_pressed() -> void:
	if current_player:
		current_player.add_gold(50)
		_update_test_data_display()

func _on_upgrade_level_button_pressed() -> void:
	if current_player:
		current_player.add_exp(current_player.get_exp_required_for_next_level())
		_update_test_data_display()

func _on_upgrade_shop_button_pressed() -> void:
	var shop_params = GameManager.shop_manager.get_shop_params()

	# 修改商店参数
	shop_params.max_chess_items = min(shop_params.max_chess_items + 1, 8)
	shop_params.max_equipment_items = min(shop_params.max_equipment_items + 1, 6)

	# 设置商店参数
	GameManager.shop_manager.set_shop_params(shop_params)

	# 刷新商店
	GameManager.shop_manager.refresh_shop(true)

	# 更新测试数据显示
	_update_test_data_display()

	# 显示提示
	EventBus.debug.emit_event("debug_message", ["商店升级成功", 0])

func _on_apply_discount_button_pressed() -> void:
	var shop_params = GameManager.shop_manager.get_shop_params()

	# 切换折扣状态
	if shop_params.discount_rate == 1.0:
		GameManager.shop_manager.apply_discount(0.8)
	else:
		GameManager.shop_manager.apply_discount(1.0)

	# 刷新商店
	GameManager.shop_manager.refresh_shop(true)

	# 更新测试数据显示
	_update_test_data_display()

	# 显示提示
	var discount_text = "折扣已" + ("启用" if shop_params.discount_rate != 1.0 else "禁用")
	EventBus.debug.emit_event("debug_message", [discount_text, 0])

func _on_trigger_black_market_button_pressed() -> void:
	# 触发黑市商人
	GameManager.shop_manager._trigger_black_market()

	# 刷新商店
	GameManager.shop_manager.refresh_shop(true)

	# 更新测试数据显示
	_update_test_data_display()

	# 显示提示
	EventBus.debug.emit_event("debug_message", ["黑市商人已触发", 0])

func _on_trigger_mystery_shop_button_pressed() -> void:
	# 触发神秘商店
	GameManager.shop_manager._trigger_mystery_shop()

	# 刷新商店
	GameManager.shop_manager.refresh_shop(true)

	# 更新测试数据显示
	_update_test_data_display()

	# 显示提示
	EventBus.debug.emit_event("debug_message", ["神秘商店已触发", 0])

func _on_trigger_equipment_shop_button_pressed() -> void:
	# 触发装备商店
	GameManager.shop_manager._trigger_equipment_shop()

	# 刷新商店
	GameManager.shop_manager.refresh_shop(true)

	# 更新测试数据显示
	_update_test_data_display()

	# 显示提示
	EventBus.debug.emit_event("debug_message", ["装备商店已触发", 0])

func _on_add_relic_button_pressed() -> void:
	# 获取随机遗物
	var relic_id = GameManager.relic_manager.get_random_relic()

	if relic_id != "":
		# 获取遗物
		var relic = GameManager.relic_manager.acquire_relic(relic_id, current_player)

		if relic:
			# 更新测试数据显示
			_update_test_data_display()

			# 显示提示
			EventBus.debug.emit_event("debug_message", ["已添加遗物: " + relic.display_name, 0])
	else:
		# 显示提示
		EventBus.debug.emit_event("debug_message", ["没有可用的遗物", 1])

func _on_toggle_test_panel_button_pressed() -> void:
	# 切换测试面板显示状态
	_toggle_panels()

# 切换测试面板和数据面板的显示状态
func _toggle_panels() -> void:
	# 切换测试面板显示状态
	var show_panels = !$TestPanel.visible
	$TestPanel.visible = show_panels
	$TestDataPanel.visible = show_panels

	# 更新按钮文本
	if show_panels:
		$TestPanel/ToggleTestPanelButton.text = "隐藏测试面板"
	else:
		$TestPanel/ToggleTestPanelButton.text = "显示测试面板"

# 关闭按钮点击事件
func _on_close_button_pressed() -> void:
	# 隐藏测试面板
	$TestPanel.visible = false
	$TestDataPanel.visible = false

# 切换按钮点击事件
func _on_toggle_button_pressed() -> void:
	# 切换测试面板显示状态
	_toggle_panels()

# 事件处理
func _on_item_purchased(item_data: Dictionary) -> void:
	# 更新测试数据显示
	_update_test_data_display()

func _on_shop_refreshed() -> void:
	# 更新测试数据显示
	_update_test_data_display()
