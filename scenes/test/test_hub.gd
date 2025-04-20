extends Control
## 测试中心
## 统一的测试入口，用于管理和运行所有测试

# 测试管理器引用
var test_manager: TestManager = null

# 当前选中的测试
var selected_module: String = ""
var selected_test: String = ""

# 测试树引用
@onready var test_tree: Tree = $MainContainer/LeftPanel/VBoxContainer/TestTree
@onready var search_edit: LineEdit = $MainContainer/LeftPanel/VBoxContainer/SearchContainer/SearchEdit

# 测试信息引用
@onready var test_name_label: Label = $MainContainer/RightPanel/VBoxContainer/TestInfoPanel/VBoxContainer/TestNameLabel
@onready var test_description_label: Label = $MainContainer/RightPanel/VBoxContainer/TestInfoPanel/VBoxContainer/TestDescriptionLabel
@onready var test_scene_path_label: Label = $MainContainer/RightPanel/VBoxContainer/TestInfoPanel/VBoxContainer/TestScenePathLabel
@onready var run_test_button: Button = $MainContainer/RightPanel/VBoxContainer/TestInfoPanel/VBoxContainer/TestControlsContainer/RunTestButton

# 测试内容引用
@onready var test_content: SubViewportContainer = $MainContainer/RightPanel/VBoxContainer/TestContentContainer/TestContent
@onready var test_viewport: SubViewport = $MainContainer/RightPanel/VBoxContainer/TestContentContainer/TestContent/SubViewport

# 状态引用
@onready var status_label: Label = $BottomPanel/HBoxContainer/StatusLabel
@onready var progress_bar: ProgressBar = $BottomPanel/HBoxContainer/ProgressBar

# 初始化
func _ready() -> void:
	# 获取测试管理器
	test_manager = GameManager.get_manager("TestManager")
	if not test_manager:
		status_label.text = "错误: 无法获取测试管理器"
		return
	
	# 连接信号
	test_manager.test_started.connect(_on_test_started)
	test_manager.test_completed.connect(_on_test_completed)
	test_manager.test_progress.connect(_on_test_progress)
	test_manager.all_tests_completed.connect(_on_all_tests_completed)
	
	# 初始化测试树
	_initialize_test_tree()
	
	# 初始化测试内容
	_initialize_test_content()
	
	# 更新状态
	status_label.text = "就绪"
	progress_bar.value = 1.0

# 初始化测试树
func _initialize_test_tree() -> void:
	# 清空测试树
	test_tree.clear()
	
	# 创建根节点
	var root = test_tree.create_item()
	root.set_text(0, "所有测试")
	
	# 获取所有测试模块
	var modules = test_manager.get_all_test_modules()
	
	# 添加测试模块
	for module_id in modules:
		var module = modules[module_id]
		
		# 创建模块节点
		var module_item = test_tree.create_item(root)
		module_item.set_text(0, module.name)
		module_item.set_metadata(0, {"type": "module", "id": module_id})
		
		# 添加测试
		var tests = module.tests
		for test_id in tests:
			var test = tests[test_id]
			
			# 创建测试节点
			var test_item = test_tree.create_item(module_item)
			test_item.set_text(0, test.name)
			test_item.set_metadata(0, {"type": "test", "module_id": module_id, "id": test_id})
	
	# 展开根节点
	root.set_collapsed(false)

# 初始化测试内容
func _initialize_test_content() -> void:
	# 设置测试视口大小
	test_viewport.size = test_content.size

# 更新测试信息
func _update_test_info() -> void:
	# 检查是否有选中的测试
	if selected_module.is_empty() or selected_test.is_empty():
		# 清空测试信息
		test_name_label.text = "选择一个测试"
		test_description_label.text = "请从左侧选择一个测试项目"
		test_scene_path_label.text = "场景路径: "
		run_test_button.disabled = true
		return
	
	# 获取测试信息
	var test = test_manager.get_test(selected_module, selected_test)
	if test.is_empty():
		# 清空测试信息
		test_name_label.text = "测试不存在"
		test_description_label.text = "所选测试不存在或已被移除"
		test_scene_path_label.text = "场景路径: "
		run_test_button.disabled = true
		return
	
	# 更新测试信息
	test_name_label.text = test.name
	test_description_label.text = test.description
	test_scene_path_label.text = "场景路径: " + test.scene_path
	run_test_button.disabled = false

# 运行测试
func _run_test() -> void:
	# 检查是否有选中的测试
	if selected_module.is_empty() or selected_test.is_empty():
		return
	
	# 更新状态
	status_label.text = "正在运行测试: " + selected_module + "." + selected_test
	progress_bar.value = 0.0
	
	# 运行测试
	test_manager.run_test(selected_module, selected_test)

# 运行模块测试
func _run_module_tests() -> void:
	# 检查是否有选中的模块
	if selected_module.is_empty():
		return
	
	# 更新状态
	status_label.text = "正在运行模块测试: " + selected_module
	progress_bar.value = 0.0
	
	# 运行模块测试
	test_manager.run_module_tests(selected_module)

# 运行所有测试
func _run_all_tests() -> void:
	# 更新状态
	status_label.text = "正在运行所有测试"
	progress_bar.value = 0.0
	
	# 运行所有测试
	test_manager.run_all_tests()

# 搜索测试
func _search_tests(search_text: String) -> void:
	# 如果搜索文本为空，显示所有测试
	if search_text.is_empty():
		_initialize_test_tree()
		return
	
	# 清空测试树
	test_tree.clear()
	
	# 创建根节点
	var root = test_tree.create_item()
	root.set_text(0, "搜索结果")
	
	# 获取所有测试模块
	var modules = test_manager.get_all_test_modules()
	
	# 搜索测试
	var found = false
	for module_id in modules:
		var module = modules[module_id]
		var module_item = null
		
		# 搜索模块名称
		if search_text.to_lower() in module.name.to_lower():
			# 创建模块节点
			module_item = test_tree.create_item(root)
			module_item.set_text(0, module.name)
			module_item.set_metadata(0, {"type": "module", "id": module_id})
			found = true
		
		# 搜索测试
		var tests = module.tests
		for test_id in tests:
			var test = tests[test_id]
			
			# 搜索测试名称和描述
			if search_text.to_lower() in test.name.to_lower() or search_text.to_lower() in test.description.to_lower():
				# 如果模块节点不存在，创建模块节点
				if not module_item:
					module_item = test_tree.create_item(root)
					module_item.set_text(0, module.name)
					module_item.set_metadata(0, {"type": "module", "id": module_id})
				
				# 创建测试节点
				var test_item = test_tree.create_item(module_item)
				test_item.set_text(0, test.name)
				test_item.set_metadata(0, {"type": "test", "module_id": module_id, "id": test_id})
				found = true
	
	# 展开根节点
	root.set_collapsed(false)
	
	# 如果没有找到任何测试，显示提示
	if not found:
		var no_result_item = test_tree.create_item(root)
		no_result_item.set_text(0, "没有找到匹配的测试")
		no_result_item.set_selectable(0, false)

# 测试树项目选择事件处理
func _on_test_tree_item_selected() -> void:
	# 获取选中的项目
	var selected_item = test_tree.get_selected()
	if not selected_item:
		return
	
	# 获取项目元数据
	var metadata = selected_item.get_metadata(0)
	if not metadata:
		return
	
	# 检查项目类型
	var item_type = metadata.get("type", "")
	
	if item_type == "module":
		# 选中模块
		selected_module = metadata.get("id", "")
		selected_test = ""
	elif item_type == "test":
		# 选中测试
		selected_module = metadata.get("module_id", "")
		selected_test = metadata.get("id", "")
	
	# 更新测试信息
	_update_test_info()

# 搜索编辑框文本变化事件处理
func _on_search_edit_text_changed(new_text: String) -> void:
	# 搜索测试
	_search_tests(new_text)

# 运行测试按钮点击事件处理
func _on_run_test_button_pressed() -> void:
	# 运行测试
	_run_test()

# 运行模块测试按钮点击事件处理
func _on_run_module_button_pressed() -> void:
	# 运行模块测试
	_run_module_tests()

# 运行所有测试按钮点击事件处理
func _on_run_all_button_pressed() -> void:
	# 运行所有测试
	_run_all_tests()

# 返回按钮点击事件处理
func _on_back_button_pressed() -> void:
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# 测试开始事件处理
func _on_test_started(test_id: String) -> void:
	# 更新状态
	status_label.text = "正在运行测试: " + test_id
	progress_bar.value = 0.0

# 测试完成事件处理
func _on_test_completed(test_id: String, success: bool) -> void:
	# 更新状态
	if success:
		status_label.text = "测试完成: " + test_id
	else:
		status_label.text = "测试失败: " + test_id
	
	progress_bar.value = 1.0

# 测试进度事件处理
func _on_test_progress(current: int, total: int) -> void:
	# 更新进度条
	progress_bar.max_value = total
	progress_bar.value = current
	
	# 更新状态
	status_label.text = "正在运行测试: " + str(current) + "/" + str(total)

# 所有测试完成事件处理
func _on_all_tests_completed(results: Dictionary) -> void:
	# 计算成功和失败的测试数量
	var success_count = 0
	var fail_count = 0
	
	for test_id in results:
		var result = results[test_id]
		if result.status == 2:  # PASSED
			success_count += 1
		elif result.status == 3:  # FAILED
			fail_count += 1
	
	# 更新状态
	status_label.text = "测试完成: " + str(success_count) + " 成功, " + str(fail_count) + " 失败"
	progress_bar.value = progress_bar.max_value
