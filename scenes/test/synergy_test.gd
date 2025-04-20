extends BaseTest
## 羁绊系统测试
## 测试新的羁绊系统实现

# 测试数据
var test_chess_pieces = []
var test_synergies = ["warrior", "mage", "assassin", "elf", "human", "undead"]

# 重写测试名称和描述
func _init() -> void:
	test_name = "羁绊系统测试"
	test_description = "测试新的羁绊系统实现"

# 测试前的准备
func _setup() -> void:
	# 创建UI
	_create_ui()
	
	# 连接信号
	GameManager.synergy_manager.synergy_activated.connect(_on_synergy_activated)
	GameManager.synergy_manager.synergy_deactivated.connect(_on_synergy_deactivated)
	GameManager.synergy_manager.synergy_level_changed.connect(_on_synergy_level_changed)

# 运行测试
func _run() -> void:
	# 测试羁绊配置加载
	await test_synergy_config_loading()
	
	# 测试羁绊激活
	await test_synergy_activation()
	
	# 测试羁绊效果应用
	await test_synergy_effect_application()
	
	# 测试羁绊等级变化
	await test_synergy_level_change()
	
	# 测试羁绊停用
	await test_synergy_deactivation()

# 测试后的清理
func _teardown() -> void:
	# 释放所有创建的棋子
	for piece in test_chess_pieces:
		if is_instance_valid(piece):
			GameManager.chess_manager.release_chess(piece)
	
	test_chess_pieces.clear()
	
	# 断开信号连接
	GameManager.synergy_manager.synergy_activated.disconnect(_on_synergy_activated)
	GameManager.synergy_manager.synergy_deactivated.disconnect(_on_synergy_deactivated)
	GameManager.synergy_manager.synergy_level_changed.disconnect(_on_synergy_level_changed)
	
	# 重置羁绊管理器
	GameManager.synergy_manager.reset()

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
	title_label.text = "羁绊系统测试"
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
	
	# 创建羁绊列表
	var synergy_list_label = Label.new()
	synergy_list_label.text = "羁绊列表"
	synergy_list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(synergy_list_label)
	
	var synergy_list = VBoxContainer.new()
	synergy_list.name = "SynergyList"
	synergy_list.size_flags_vertical = Control.SIZE_FLAGS_EXPAND_FILL
	left_panel.add_child(synergy_list)
	
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

# 测试羁绊配置加载
func test_synergy_config_loading() -> void:
	_add_result("开始测试羁绊配置加载...")
	
	# 获取所有羁绊配置
	var synergy_configs = GameManager.synergy_manager.get_all_synergy_configs()
	
	# 检查是否加载了羁绊配置
	assert_greater_than(synergy_configs.size(), 0, "加载了羁绊配置")
	
	# 打印所有羁绊配置
	_add_result("加载了 " + str(synergy_configs.size()) + " 个羁绊配置:")
	
	for synergy_id in synergy_configs:
		var synergy_config = synergy_configs[synergy_id]
		_add_result("- " + synergy_id + ": " + synergy_config.get_name())
		
		# 检查羁绊阈值
		var thresholds = synergy_config.get_thresholds()
		assert_greater_than(thresholds.size(), 0, "羁绊有阈值")
		
		# 检查羁绊效果
		for threshold in thresholds:
			if threshold.has("effects"):
				var effects = threshold.effects
				assert_greater_than(effects.size(), 0, "阈值有效果")
	
	_add_result("羁绊配置加载测试完成")
	await wait(0.5)

# 测试羁绊激活
func test_synergy_activation() -> void:
	_add_result("开始测试羁绊激活...")
	
	# 创建测试棋子
	for i in range(3):
		var chess_piece = GameManager.chess_manager.create_chess_piece("warrior_1")
		if chess_piece:
			test_chess_pieces.append(chess_piece)
			_add_result("创建战士棋子: " + chess_piece.id)
	
	# 等待羁绊激活
	await wait(0.5)
	
	# 检查羁绊是否激活
	var active_synergies = GameManager.synergy_manager.get_active_synergies()
	assert_true(active_synergies.has("warrior"), "战士羁绊已激活")
	
	if active_synergies.has("warrior"):
		var level = active_synergies["warrior"]
		_add_result("战士羁绊已激活，等级: " + str(level))
	
	_add_result("羁绊激活测试完成")
	await wait(0.5)

# 测试羁绊效果应用
func test_synergy_effect_application() -> void:
	_add_result("开始测试羁绊效果应用...")
	
	# 获取第一个棋子
	var chess_piece = test_chess_pieces[0]
	
	# 获取属性组件
	var attribute_component = chess_piece.get_component("AttributeComponent")
	if attribute_component:
		# 获取基础属性
		var base_attack = attribute_component.get_base_attribute("attack")
		var current_attack = attribute_component.get_attribute("attack")
		
		# 检查属性是否增加
		assert_not_equal(current_attack, base_attack, "羁绊效果已应用到属性")
		
		_add_result("基础攻击力: " + str(base_attack))
		_add_result("当前攻击力: " + str(current_attack))
		_add_result("增加了: " + str(current_attack - base_attack))
	
	# 获取效果组件
	var effect_component = chess_piece.get_component("EffectComponent")
	if effect_component:
		# 获取所有效果
		var effects = effect_component.get_all_effects()
		
		# 检查是否有羁绊效果
		var has_synergy_effect = false
		for effect_id in effects:
			if effect_id.begins_with("synergy_warrior"):
				has_synergy_effect = true
				_add_result("发现羁绊效果: " + effect_id)
		
		assert_true(has_synergy_effect, "棋子有羁绊效果")
	
	_add_result("羁绊效果应用测试完成")
	await wait(0.5)

# 测试羁绊等级变化
func test_synergy_level_change() -> void:
	_add_result("开始测试羁绊等级变化...")
	
	# 获取当前羁绊等级
	var current_level = GameManager.synergy_manager.get_synergy_level("warrior")
	_add_result("当前战士羁绊等级: " + str(current_level))
	
	# 创建更多战士棋子
	for i in range(3):
		var chess_piece = GameManager.chess_manager.create_chess_piece("warrior_1")
		if chess_piece:
			test_chess_pieces.append(chess_piece)
			_add_result("创建额外战士棋子: " + chess_piece.id)
	
	# 等待羁绊等级变化
	await wait(0.5)
	
	# 检查羁绊等级是否变化
	var new_level = GameManager.synergy_manager.get_synergy_level("warrior")
	_add_result("新的战士羁绊等级: " + str(new_level))
	
	assert_greater_than(new_level, current_level, "羁绊等级已增加")
	
	# 检查第一个棋子的属性是否变化
	var chess_piece = test_chess_pieces[0]
	var attribute_component = chess_piece.get_component("AttributeComponent")
	
	if attribute_component:
		var base_attack = attribute_component.get_base_attribute("attack")
		var current_attack = attribute_component.get_attribute("attack")
		
		_add_result("基础攻击力: " + str(base_attack))
		_add_result("当前攻击力: " + str(current_attack))
		_add_result("增加了: " + str(current_attack - base_attack))
	
	_add_result("羁绊等级变化测试完成")
	await wait(0.5)

# 测试羁绊停用
func test_synergy_deactivation() -> void:
	_add_result("开始测试羁绊停用...")
	
	# 记录第一个棋子的当前属性
	var chess_piece = test_chess_pieces[0]
	var attribute_component = chess_piece.get_component("AttributeComponent")
	var current_attack = 0
	
	if attribute_component:
		current_attack = attribute_component.get_attribute("attack")
		_add_result("停用前攻击力: " + str(current_attack))
	
	# 移除所有棋子
	for piece in test_chess_pieces:
		if is_instance_valid(piece):
			GameManager.chess_manager.release_chess(piece)
	
	test_chess_pieces.clear()
	
	# 等待羁绊停用
	await wait(0.5)
	
	# 检查羁绊是否停用
	var active_synergies = GameManager.synergy_manager.get_active_synergies()
	assert_false(active_synergies.has("warrior"), "战士羁绊已停用")
	
	_add_result("羁绊停用测试完成")
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

# 羁绊激活事件处理
func _on_synergy_activated(synergy_id: String, level: int) -> void:
	_add_result("羁绊激活事件: " + synergy_id + " 等级 " + str(level))

# 羁绊停用事件处理
func _on_synergy_deactivated(synergy_id: String, level: int) -> void:
	_add_result("羁绊停用事件: " + synergy_id + " 等级 " + str(level))

# 羁绊等级变化事件处理
func _on_synergy_level_changed(synergy_id: String, old_level: int, new_level: int) -> void:
	_add_result("羁绊等级变化事件: " + synergy_id + " 从 " + str(old_level) + " 到 " + str(new_level))
