extends BaseTest
## 装备系统测试
## 测试装备系统的功能

# 测试数据
var test_equipment_ids = ["sword_1", "armor_1", "helmet_1", "boots_1", "amulet_1"]
var created_equipment = []
var test_chess_piece = null

# 重写测试名称和描述
func _init() -> void:
	test_name = "装备系统测试"
	test_description = "测试装备系统的功能"

# 测试前的准备
func _setup() -> void:
	# 创建UI
	_create_ui()

	# 连接信号
	GameManager.equipment_manager.equipment_created.connect(_on_equipment_created)
	GameManager.equipment_manager.equipment_released.connect(_on_equipment_released)

	# 创建测试棋子
	test_chess_piece = GameManager.chess_manager.create_chess_piece("warrior_1")
	if test_chess_piece:
		_add_result("创建测试棋子成功")

# 运行测试
func _run() -> void:
	# 测试装备创建
	await test_equipment_creation()

	# 测试装备属性
	await test_equipment_attributes()

	# 测试装备效果
	await test_equipment_effects()

	# 测试装备穿戴
	await test_equipment_equipping()

	# 测试装备升级
	await test_equipment_upgrade()

	# 测试装备生成
	await test_equipment_generation()

# 测试后的清理
func _teardown() -> void:
	# 释放所有创建的装备
	for equipment in created_equipment:
		if is_instance_valid(equipment):
			GameManager.equipment_manager.release_equipment(equipment)

	created_equipment.clear()

	# 释放测试棋子
	if test_chess_piece and is_instance_valid(test_chess_piece):
		GameManager.chess_manager.release_chess(test_chess_piece)
		test_chess_piece = null

	# 断开信号连接
	GameManager.equipment_manager.equipment_created.disconnect(_on_equipment_created)
	GameManager.equipment_manager.equipment_released.disconnect(_on_equipment_released)

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
	title_label.text = "装备系统测试"
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

	# 创建装备列表
	var equipment_list_label = Label.new()
	equipment_list_label.text = "装备列表"
	equipment_list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(equipment_list_label)

	var equipment_list = VBoxContainer.new()
	equipment_list.name = "EquipmentList"
	equipment_list.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	left_panel.add_child(equipment_list)

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

# 测试装备创建
func test_equipment_creation() -> void:
	_add_result("开始测试装备创建...")

	# 测试创建不同类型的装备
	for equipment_id in test_equipment_ids:
		var equipment = GameManager.equipment_manager.create_equipment(equipment_id)
		assert_not_null(equipment, "创建装备 " + equipment_id)

		if equipment:
			created_equipment.append(equipment)
			_add_result("成功创建装备: " + equipment_id)

			# 检查装备ID
			assert_equal(equipment.id, equipment_id, "装备ID正确")

			# 检查装备等级
			assert_equal(equipment.level, 1, "装备初始等级为1")

			# 检查装备稀有度
			assert_greater_than_or_equal(equipment.rarity, 0, "装备稀有度大于等于0")

	_add_result("装备创建测试完成")
	await wait(0.5)

# 测试装备属性
func test_equipment_attributes() -> void:
	_add_result("开始测试装备属性...")

	# 确保有创建的装备
	if created_equipment.is_empty():
		fail("没有可用的装备进行测试")
		return

	# 测试第一个装备的属性
	var equipment = created_equipment[0]

	# 检查基本属性
	assert_not_null(equipment.name, "装备有名称")
	assert_not_null(equipment.description, "装备有描述")
	assert_not_null(equipment.slot, "装备有槽位")

	# 检查属性加成
	assert_not_null(equipment.attributes, "装备有属性加成")

	if equipment.attributes:
		# 检查是否有至少一个属性加成
		assert_greater_than(equipment.attributes.size(), 0, "装备有至少一个属性加成")

		# 打印属性加成
		for attribute in equipment.attributes:
			_add_result("属性加成: " + attribute + " = " + str(equipment.attributes[attribute]))

	_add_result("装备属性测试完成")
	await wait(0.5)

# 测试装备效果
func test_equipment_effects() -> void:
	_add_result("开始测试装备效果...")

	# 确保有创建的装备
	if created_equipment.is_empty():
		fail("没有可用的装备进行测试")
		return

	# 测试第一个装备的效果
	var equipment = created_equipment[0]

	# 检查效果
	assert_not_null(equipment.effects, "装备有效果")

	if equipment.effects:
		# 检查是否有效果
		_add_result("装备效果数量: " + str(equipment.effects.size()))

		# 打印效果
		for effect in equipment.effects:
			_add_result("效果: " + effect.id + " - " + effect.description)

			# 检查效果类型
			assert_not_null(effect.type, "效果有类型")

			# 检查效果触发条件
			assert_not_null(effect.trigger, "效果有触发条件")

	_add_result("装备效果测试完成")
	await wait(0.5)

# 测试装备穿戴
func test_equipment_equipping() -> void:
	_add_result("开始测试装备穿戴...")

	# 确保有创建的装备和测试棋子
	if created_equipment.is_empty() or not test_chess_piece:
		fail("没有可用的装备或棋子进行测试")
		return

	# 获取棋子的装备组件
	var equipment_component = test_chess_piece.get_component("EquipmentComponent")
	assert_not_null(equipment_component, "棋子有装备组件")

	if equipment_component:
		# 测试穿戴装备
		var equipment = created_equipment[0]
		var slot = equipment.slot

		# 穿戴装备
		var success = equipment_component.equip_item(equipment, slot)
		assert_true(success, "穿戴装备成功")

		# 检查装备是否已穿戴
		var equipped_item = equipment_component.get_equipped_item(slot)
		assert_equal(equipped_item, equipment, "装备已穿戴在正确的槽位")

		# 检查属性是否增加
		var attribute_component = test_chess_piece.get_component("AttributeComponent")
		if attribute_component and equipment.attributes:
			for attribute in equipment.attributes:
				var base_value = attribute_component.get_base_attribute(attribute)
				var current_value = attribute_component.get_attribute(attribute)
				assert_greater_than_or_equal(current_value, base_value, "装备增加了属性 " + attribute)

		# 卸下装备
		success = equipment_component.unequip_item(slot)
		assert_true(success, "卸下装备成功")

		# 检查装备是否已卸下
		equipped_item = equipment_component.get_equipped_item(slot)
		assert_null(equipped_item, "装备已卸下")

		# 检查属性是否恢复
		if attribute_component and equipment.attributes:
			for attribute in equipment.attributes:
				var base_value = attribute_component.get_base_attribute(attribute)
				var current_value = attribute_component.get_attribute(attribute)
				assert_equal(current_value, base_value, "卸下装备后属性恢复")

	_add_result("装备穿戴测试完成")
	await wait(0.5)

# 测试装备升级
func test_equipment_upgrade() -> void:
	_add_result("开始测试装备升级...")

	# 确保有创建的装备
	if created_equipment.is_empty():
		fail("没有可用的装备进行测试")
		return

	# 测试第一个装备的升级
	var equipment = created_equipment[0]
	var original_level = equipment.level
	var original_attributes = equipment.attributes.duplicate()

	# 升级装备
	equipment.level += 1
	equipment.update_attributes()

	# 检查等级是否增加
	assert_equal(equipment.level, original_level + 1, "装备等级增加")

	# 检查属性是否增加
	for attribute in equipment.attributes:
		if original_attributes.has(attribute):
			assert_greater_than(equipment.attributes[attribute], original_attributes[attribute], "升级后属性增加: " + attribute)

	_add_result("装备升级测试完成")
	await wait(0.5)

# 测试装备生成
func test_equipment_generation() -> void:
	_add_result("开始测试装备生成...")

	# 测试随机生成装备
	var random_equipment = GameManager.equipment_manager.generate_random_equipment(2)
	assert_not_null(random_equipment, "随机生成装备成功")

	if random_equipment:
		created_equipment.append(random_equipment)
		_add_result("成功生成随机装备: " + random_equipment.id)

		# 检查装备等级
		assert_equal(random_equipment.level, 1, "随机装备初始等级为1")

		# 检查装备稀有度
		assert_greater_than_or_equal(random_equipment.rarity, 0, "随机装备稀有度大于等于0")

		# 检查装备属性
		assert_not_null(random_equipment.attributes, "随机装备有属性加成")

		# 检查装备效果
		assert_not_null(random_equipment.effects, "随机装备有效果")

	# 测试指定稀有度生成装备
	var rare_equipment = GameManager.equipment_manager.generate_equipment_with_rarity(3)
	assert_not_null(rare_equipment, "指定稀有度生成装备成功")

	if rare_equipment:
		created_equipment.append(rare_equipment)
		_add_result("成功生成稀有装备: " + rare_equipment.id)

		# 检查装备稀有度
		assert_equal(rare_equipment.rarity, 3, "稀有装备稀有度正确")

	_add_result("装备生成测试完成")
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

# 装备创建事件处理
func _on_equipment_created(equipment) -> void:
	_add_result("装备创建事件: " + equipment.id)

# 装备释放事件处理
func _on_equipment_released(equipment) -> void:
	_add_result("装备释放事件: " + equipment.id)
