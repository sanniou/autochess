extends BaseTest
## 棋子系统测试
## 测试新的组件化棋子系统的功能

# 测试数据
var test_chess_ids = ["warrior_1", "mage_1", "assassin_1", "tank_1", "ranger_1"]
var created_pieces = []

# 重写测试名称和描述
func _init() -> void:
	test_name = "棋子系统测试"
	test_description = "测试新的组件化棋子系统的功能"

# 测试前的准备
func _setup() -> void:
	# 创建UI
	_create_ui()
	
	# 连接信号
	GameManager.chess_manager.chess_created.connect(_on_chess_created)
	GameManager.chess_manager.chess_released.connect(_on_chess_released)
	GameManager.chess_manager.chess_merged.connect(_on_chess_merged)

# 运行测试
func _run() -> void:
	# 测试棋子创建
	await test_chess_creation()
	
	# 测试棋子属性
	await test_chess_attributes()
	
	# 测试棋子组件
	await test_chess_components()
	
	# 测试棋子升级
	await test_chess_upgrade()
	
	# 测试棋子合并
	await test_chess_merge()
	
	# 测试棋子效果
	await test_chess_effects()

# 测试后的清理
func _teardown() -> void:
	# 释放所有创建的棋子
	for piece in created_pieces:
		if is_instance_valid(piece):
			GameManager.chess_manager.release_chess(piece)
	
	created_pieces.clear()
	
	# 断开信号连接
	GameManager.chess_manager.chess_created.disconnect(_on_chess_created)
	GameManager.chess_manager.chess_released.disconnect(_on_chess_released)
	GameManager.chess_manager.chess_merged.disconnect(_on_chess_merged)

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
	title_label.text = "棋子系统测试"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	main_container.add_child(title_label)
	
	# 创建分隔线
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# 创建内容容器
	var content_container = HBoxContainer.new()
	content_container.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	main_container.add_child(content_container)
	
	# 创建左侧面板
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.3
	content_container.add_child(left_panel)
	
	# 创建棋子列表
	var chess_list_label = Label.new()
	chess_list_label.text = "棋子列表"
	chess_list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(chess_list_label)
	
	var chess_list = VBoxContainer.new()
	chess_list.name = "ChessList"
	chess_list.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	left_panel.add_child(chess_list)
	
	# 创建右侧面板
	var right_panel = VBoxContainer.new()
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

# 测试棋子创建
func test_chess_creation() -> void:
	_add_result("开始测试棋子创建...")
	
	# 测试创建不同类型的棋子
	for chess_id in test_chess_ids:
		var chess_piece = GameManager.chess_manager.create_chess_piece(chess_id)
		assert_not_null(chess_piece, "创建棋子 " + chess_id)
		
		if chess_piece:
			created_pieces.append(chess_piece)
			_add_result("成功创建棋子: " + chess_id)
			
			# 检查棋子ID
			assert_equal(chess_piece.id, chess_id, "棋子ID正确")
			
			# 检查棋子等级
			assert_equal(chess_piece.get_level(), 1, "棋子初始等级为1")
			
			# 检查棋子所属
			assert_true(chess_piece.is_player_piece(), "棋子默认属于玩家")
	
	_add_result("棋子创建测试完成")
	await wait(0.5)

# 测试棋子属性
func test_chess_attributes() -> void:
	_add_result("开始测试棋子属性...")
	
	# 确保有创建的棋子
	if created_pieces.is_empty():
		fail("没有可用的棋子进行测试")
		return
	
	# 测试第一个棋子的属性
	var chess_piece = created_pieces[0]
	
	# 获取属性组件
	var attribute_component = chess_piece.get_component("AttributeComponent")
	assert_not_null(attribute_component, "棋子有属性组件")
	
	if attribute_component:
		# 检查基本属性
		assert_greater_than(attribute_component.get_attribute("health"), 0, "棋子生命值大于0")
		assert_greater_than(attribute_component.get_attribute("attack"), 0, "棋子攻击力大于0")
		assert_greater_than(attribute_component.get_attribute("defense"), 0, "棋子防御力大于0")
		
		# 修改属性
		var original_health = attribute_component.get_attribute("health")
		attribute_component.set_attribute("health", original_health + 100)
		assert_equal(attribute_component.get_attribute("health"), original_health + 100, "修改棋子生命值成功")
		
		# 添加属性修饰符
		attribute_component.add_attribute_modifier("attack", "test_modifier", 50, "add")
		assert_greater_than(attribute_component.get_attribute("attack"), attribute_component.get_base_attribute("attack"), "属性修饰符生效")
		
		# 移除属性修饰符
		attribute_component.remove_attribute_modifier("attack", "test_modifier")
		assert_equal(attribute_component.get_attribute("attack"), attribute_component.get_base_attribute("attack"), "移除属性修饰符成功")
	
	_add_result("棋子属性测试完成")
	await wait(0.5)

# 测试棋子组件
func test_chess_components() -> void:
	_add_result("开始测试棋子组件...")
	
	# 确保有创建的棋子
	if created_pieces.is_empty():
		fail("没有可用的棋子进行测试")
		return
	
	# 测试第一个棋子的组件
	var chess_piece = created_pieces[0]
	
	# 检查必要组件
	assert_not_null(chess_piece.get_component("AttributeComponent"), "棋子有属性组件")
	assert_not_null(chess_piece.get_component("AbilityComponent"), "棋子有技能组件")
	assert_not_null(chess_piece.get_component("EffectComponent"), "棋子有效果组件")
	assert_not_null(chess_piece.get_component("EquipmentComponent"), "棋子有装备组件")
	
	# 测试添加自定义组件
	var test_component = Node.new()
	test_component.name = "TestComponent"
	chess_piece.add_component(test_component)
	assert_not_null(chess_piece.get_component("TestComponent"), "添加自定义组件成功")
	
	# 测试移除自定义组件
	chess_piece.remove_component("TestComponent")
	assert_null(chess_piece.get_component("TestComponent"), "移除自定义组件成功")
	
	_add_result("棋子组件测试完成")
	await wait(0.5)

# 测试棋子升级
func test_chess_upgrade() -> void:
	_add_result("开始测试棋子升级...")
	
	# 确保有创建的棋子
	if created_pieces.is_empty():
		fail("没有可用的棋子进行测试")
		return
	
	# 测试第一个棋子的升级
	var chess_piece = created_pieces[0]
	var original_level = chess_piece.get_level()
	
	# 升级棋子
	chess_piece.set_level(original_level + 1)
	assert_equal(chess_piece.get_level(), original_level + 1, "棋子升级成功")
	
	# 检查属性是否提升
	var attribute_component = chess_piece.get_component("AttributeComponent")
	if attribute_component:
		assert_greater_than(attribute_component.get_attribute("health"), 0, "升级后生命值大于0")
		assert_greater_than(attribute_component.get_attribute("attack"), 0, "升级后攻击力大于0")
		assert_greater_than(attribute_component.get_attribute("defense"), 0, "升级后防御力大于0")
	
	_add_result("棋子升级测试完成")
	await wait(0.5)

# 测试棋子合并
func test_chess_merge() -> void:
	_add_result("开始测试棋子合并...")
	
	# 创建3个相同的棋子
	var chess_id = test_chess_ids[0]
	var merge_pieces = []
	
	for i in range(3):
		var chess_piece = GameManager.chess_manager.create_chess_piece(chess_id)
		if chess_piece:
			merge_pieces.append(chess_piece)
	
	# 确保创建了3个棋子
	if merge_pieces.size() < 3:
		fail("没有创建足够的棋子进行合并测试")
		return
	
	# 合并棋子
	var merged_piece = GameManager.chess_manager.merge_chess_pieces(merge_pieces)
	assert_not_null(merged_piece, "棋子合并成功")
	
	if merged_piece:
		# 检查合并后的棋子等级
		assert_equal(merged_piece.get_level(), 2, "合并后棋子等级为2")
		
		# 添加到创建的棋子列表
		created_pieces.append(merged_piece)
	
	_add_result("棋子合并测试完成")
	await wait(0.5)

# 测试棋子效果
func test_chess_effects() -> void:
	_add_result("开始测试棋子效果...")
	
	# 确保有创建的棋子
	if created_pieces.is_empty():
		fail("没有可用的棋子进行测试")
		return
	
	# 测试第一个棋子的效果
	var chess_piece = created_pieces[0]
	
	# 获取效果组件
	var effect_component = chess_piece.get_component("EffectComponent")
	assert_not_null(effect_component, "棋子有效果组件")
	
	if effect_component:
		# 创建测试效果
		var test_effect = {
			"id": "test_effect",
			"name": "测试效果",
			"description": "这是一个测试效果",
			"duration": 3,
			"type": "buff",
			"attributes": {
				"attack": 50,
				"defense": 30
			}
		}
		
		# 添加效果
		chess_piece.add_effect(test_effect)
		assert_true(chess_piece.has_effect("test_effect"), "添加效果成功")
		
		# 检查效果是否影响属性
		var attribute_component = chess_piece.get_component("AttributeComponent")
		if attribute_component:
			var base_attack = attribute_component.get_base_attribute("attack")
			var current_attack = attribute_component.get_attribute("attack")
			assert_greater_than(current_attack, base_attack, "效果增加了攻击力")
		
		# 移除效果
		chess_piece.remove_effect("test_effect")
		assert_false(chess_piece.has_effect("test_effect"), "移除效果成功")
		
		# 检查属性是否恢复
		if attribute_component:
			var base_attack = attribute_component.get_base_attribute("attack")
			var current_attack = attribute_component.get_attribute("attack")
			assert_equal(current_attack, base_attack, "移除效果后攻击力恢复")
	
	_add_result("棋子效果测试完成")
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

# 棋子创建事件处理
func _on_chess_created(chess_piece) -> void:
	_add_result("棋子创建事件: " + chess_piece.id)

# 棋子释放事件处理
func _on_chess_released(chess_piece) -> void:
	_add_result("棋子释放事件: " + chess_piece.id)

# 棋子合并事件处理
func _on_chess_merged(source_pieces, merged_piece) -> void:
	_add_result("棋子合并事件: " + merged_piece.id + " (等级 " + str(merged_piece.get_level()) + ")")
