extends BaseTest
## 商店系统测试
## 测试商店系统的功能

# 测试数据
var test_player = null
var shop_inventory = []

# 重写测试名称和描述
func _init() -> void:
	test_name = "商店系统测试"
	test_description = "测试商店系统的功能"

# 测试前的准备
func _setup() -> void:
	# 创建UI
	_create_ui()
	
	# 初始化测试玩家
	_initialize_test_player()
	
	# 连接信号
	GameManager.shop_manager.shop_refreshed.connect(_on_shop_refreshed)
	GameManager.shop_manager.item_purchased.connect(_on_item_purchased)

# 运行测试
func _run() -> void:
	# 测试商店刷新
	await test_shop_refresh()
	
	# 测试商店购买
	await test_shop_purchase()
	
	# 测试商店锁定
	await test_shop_lock()
	
	# 测试特殊商店
	await test_special_shops()
	
	# 测试商店概率
	await test_shop_probabilities()

# 测试后的清理
func _teardown() -> void:
	# 清理测试玩家
	if test_player:
		GameManager.player_manager.remove_player(test_player.id)
		test_player = null
	
	# 重置商店
	GameManager.shop_manager.reset()
	
	# 断开信号连接
	GameManager.shop_manager.shop_refreshed.disconnect(_on_shop_refreshed)
	GameManager.shop_manager.item_purchased.disconnect(_on_item_purchased)

# 创建UI
func _create_ui() -> void:
	# 创建主容器
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	add_child(main_container)
	
	# 创建标题
	var title_label = Label.new()
	title_label.text = "商店系统测试"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	main_container.add_child(title_label)
	
	# 创建分隔线
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# 创建内容容器
	var content_container = HBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	main_container.add_child(content_container)
	
	# 创建左侧面板
	var left_panel = VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.3
	content_container.add_child(left_panel)
	
	# 创建商店信息面板
	var shop_info_label = Label.new()
	shop_info_label.text = "商店信息"
	shop_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(shop_info_label)
	
	var shop_info_container = VBoxContainer.new()
	shop_info_container.name = "ShopInfoContainer"
	shop_info_container.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	left_panel.add_child(shop_info_container)
	
	# 创建右侧面板
	var right_panel = VBoxContainer.new()
	right_panel.name = "RightPanel"
	right_panel.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 0.7
	content_container.add_child(right_panel)
	
	# 创建测试结果面板
	var result_panel = VBoxContainer.new()
	result_panel.name = "ResultPanel"
	result_panel.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	right_panel.add_child(result_panel)
	
	var result_label = Label.new()
	result_label.text = "测试结果"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_panel.add_child(result_label)
	
	var result_scroll = ScrollContainer.new()
	result_scroll.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	result_panel.add_child(result_scroll)
	
	var result_container = VBoxContainer.new()
	result_container.name = "ResultContainer"
	result_container.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
	result_container.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	result_scroll.add_child(result_container)
	
	# 创建底部控制面板
	var control_panel = HBoxContainer.new()
	control_panel.name = "ControlPanel"
	main_container.add_child(control_panel)
	
	var run_button = Button.new()
	run_button.text = "运行测试"
	run_button.pressed.connect(run_test)
	control_panel.add_child(run_button)
	
	var clear_button = Button.new()
	clear_button.text = "清除结果"
	clear_button.pressed.connect(_clear_results)
	control_panel.add_child(clear_button)
	
	var back_button = Button.new()
	back_button.text = "返回"
	back_button.pressed.connect(_on_back_button_pressed)
	control_panel.add_child(back_button)

# 初始化测试玩家
func _initialize_test_player() -> void:
	# 创建测试玩家
	GameManager.player_manager.initialize_player("ShopTest")
	test_player = GameManager.player_manager.get_current_player()
	
	# 设置初始金币和等级
	if test_player:
		test_player.gold = 100
		test_player.level = 5
		test_player.current_health = 100
		test_player.max_health = 100
		
		_add_result("测试玩家初始化完成")
		_add_result("玩家金币: " + str(test_player.gold))
		_add_result("玩家等级: " + str(test_player.level))

# 测试商店刷新
func test_shop_refresh() -> void:
	_add_result("开始测试商店刷新...")
	
	# 确保有测试玩家
	if not test_player:
		fail("没有可用的测试玩家")
		return
	
	# 刷新商店
	GameManager.shop_manager.refresh_shop()
	
	# 获取商店库存
	shop_inventory = GameManager.shop_manager.get_shop_inventory()
	
	# 检查商店库存
	assert_not_null(shop_inventory, "商店库存不为空")
	assert_greater_than(shop_inventory.size(), 0, "商店库存有商品")
	
	# 打印商店库存
	_add_result("商店库存数量: " + str(shop_inventory.size()))
	for i in range(shop_inventory.size()):
		var item = shop_inventory[i]
		if item:
			_add_result("商品 " + str(i+1) + ": " + item.name + " (价格: " + str(item.price) + ")")
	
	_add_result("商店刷新测试完成")
	await wait(0.5)

# 测试商店购买
func test_shop_purchase() -> void:
	_add_result("开始测试商店购买...")
	
	# 确保有测试玩家和商店库存
	if not test_player or shop_inventory.is_empty():
		fail("没有可用的测试玩家或商店库存")
		return
	
	# 记录初始金币
	var initial_gold = test_player.gold
	
	# 购买第一个商品
	var item_index = 0
	var item = shop_inventory[item_index]
	
	if item:
		# 检查是否有足够的金币
		if test_player.gold >= item.price:
			# 购买商品
			var success = GameManager.shop_manager.purchase_item(item_index)
			assert_true(success, "购买商品成功")
			
			# 检查金币是否减少
			assert_equal(test_player.gold, initial_gold - item.price, "购买后金币减少")
			
			# 检查商品是否从库存中移除
			var new_inventory = GameManager.shop_manager.get_shop_inventory()
			assert_not_equal(new_inventory[item_index], item, "商品已从库存中移除")
			
			_add_result("成功购买商品: " + item.name)
			_add_result("剩余金币: " + str(test_player.gold))
		else:
			_add_result("金币不足，无法购买商品")
	
	_add_result("商店购买测试完成")
	await wait(0.5)

# 测试商店锁定
func test_shop_lock() -> void:
	_add_result("开始测试商店锁定...")
	
	# 确保有测试玩家
	if not test_player:
		fail("没有可用的测试玩家")
		return
	
	# 锁定商店
	GameManager.shop_manager.lock_shop(true)
	assert_true(GameManager.shop_manager.is_shop_locked(), "商店锁定成功")
	
	# 尝试刷新商店
	var old_inventory = GameManager.shop_manager.get_shop_inventory()
	GameManager.shop_manager.refresh_shop()
	var new_inventory = GameManager.shop_manager.get_shop_inventory()
	
	# 检查库存是否相同
	var inventory_changed = false
	for i in range(min(old_inventory.size(), new_inventory.size())):
		if old_inventory[i] != new_inventory[i]:
			inventory_changed = true
			break
	
	assert_false(inventory_changed, "锁定后商店库存未变化")
	
	# 解锁商店
	GameManager.shop_manager.lock_shop(false)
	assert_false(GameManager.shop_manager.is_shop_locked(), "商店解锁成功")
	
	# 刷新商店
	GameManager.shop_manager.refresh_shop()
	new_inventory = GameManager.shop_manager.get_shop_inventory()
	
	# 更新商店库存
	shop_inventory = new_inventory
	
	_add_result("商店锁定测试完成")
	await wait(0.5)

# 测试特殊商店
func test_special_shops() -> void:
	_add_result("开始测试特殊商店...")
	
	# 确保有测试玩家
	if not test_player:
		fail("没有可用的测试玩家")
		return
	
	# 测试装备商店
	GameManager.shop_manager.set_shop_type("equipment")
	GameManager.shop_manager.refresh_shop()
	
	# 获取商店库存
	var equipment_inventory = GameManager.shop_manager.get_shop_inventory()
	
	# 检查商店库存
	assert_not_null(equipment_inventory, "装备商店库存不为空")
	assert_greater_than(equipment_inventory.size(), 0, "装备商店库存有商品")
	
	# 检查是否都是装备
	var all_equipment = true
	for item in equipment_inventory:
		if item and not item is Equipment:
			all_equipment = false
			break
	
	assert_true(all_equipment, "装备商店只有装备")
	
	# 测试遗物商店
	GameManager.shop_manager.set_shop_type("relic")
	GameManager.shop_manager.refresh_shop()
	
	# 获取商店库存
	var relic_inventory = GameManager.shop_manager.get_shop_inventory()
	
	# 检查商店库存
	assert_not_null(relic_inventory, "遗物商店库存不为空")
	assert_greater_than(relic_inventory.size(), 0, "遗物商店库存有商品")
	
	# 检查是否都是遗物
	var all_relics = true
	for item in relic_inventory:
		if item and not item is Relic:
			all_relics = false
			break
	
	assert_true(all_relics, "遗物商店只有遗物")
	
	# 恢复普通商店
	GameManager.shop_manager.set_shop_type("normal")
	GameManager.shop_manager.refresh_shop()
	
	# 更新商店库存
	shop_inventory = GameManager.shop_manager.get_shop_inventory()
	
	_add_result("特殊商店测试完成")
	await wait(0.5)

# 测试商店概率
func test_shop_probabilities() -> void:
	_add_result("开始测试商店概率...")
	
	# 确保有测试玩家
	if not test_player:
		fail("没有可用的测试玩家")
		return
	
	# 获取商店概率
	var probabilities = GameManager.shop_manager.get_shop_probabilities(test_player.level)
	
	# 检查概率
	assert_not_null(probabilities, "商店概率不为空")
	assert_greater_than(probabilities.size(), 0, "商店概率有数据")
	
	# 打印概率
	_add_result("玩家等级 " + str(test_player.level) + " 的商店概率:")
	for tier in probabilities:
		_add_result("等级 " + str(tier) + " 棋子概率: " + str(probabilities[tier]) + "%")
	
	# 检查概率总和是否为100%
	var total_probability = 0
	for tier in probabilities:
		total_probability += probabilities[tier]
	
	assert_almost_equal(total_probability, 100.0, 0.1, "概率总和为100%")
	
	# 测试不同等级的概率
	for level in range(1, 10):
		var level_probabilities = GameManager.shop_manager.get_shop_probabilities(level)
		assert_not_null(level_probabilities, "等级 " + str(level) + " 的商店概率不为空")
		
		# 检查概率总和是否为100%
		var level_total = 0
		for tier in level_probabilities:
			level_total += level_probabilities[tier]
		
		assert_almost_equal(level_total, 100.0, 0.1, "等级 " + str(level) + " 的概率总和为100%")
	
	_add_result("商店概率测试完成")
	await wait(0.5)

# 添加测试结果
func _add_result(text: String) -> void:
	var result_container = get_node_or_null("MainContainer/ContentContainer/RightPanel/ResultPanel/ResultContainer")
	if result_container:
		var result_label = Label.new()
		result_label.text = text
		result_container.add_child(result_label)
		print(text)

# 清除测试结果
func _clear_results() -> void:
	var result_container = get_node_or_null("MainContainer/ContentContainer/RightPanel/ResultPanel/ResultContainer")
	if result_container:
		for child in result_container.get_children():
			child.queue_free()

# 返回按钮处理
func _on_back_button_pressed() -> void:
	# 返回测试中心
	GameManager.test_manager.open_test_hub()

# 商店刷新事件处理
func _on_shop_refreshed() -> void:
	_add_result("商店刷新事件")

# 商品购买事件处理
func _on_item_purchased(item_index: int, item) -> void:
	_add_result("商品购买事件: 索引 " + str(item_index) + ", 商品 " + item.name)
