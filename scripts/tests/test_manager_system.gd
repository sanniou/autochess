extends Node
## 管理器系统测试脚本
## 用于测试管理器系统的功能

# 测试结果
var test_results = {}

# 初始化
func _ready() -> void:
	# 连接信号
	EventBus.debug.connect_event("debug_message", _on_debug_message)
	
	# 运行测试
	run_tests()

# 运行所有测试
func run_tests() -> void:
	print("开始测试管理器系统...")
	
	# 测试 ManagerRegistry
	test_manager_registry()
	
	# 测试 BaseManager
	test_base_manager()
	
	# 测试 GameManager
	test_game_manager()
	
	# 输出测试结果
	print_test_results()

# 测试 ManagerRegistry
func test_manager_registry() -> void:
	print("测试 ManagerRegistry...")
	
	# 创建 ManagerRegistry
	var registry = load("res://scripts/core/manager_registry.gd").new()
	
	# 测试注册管理器
	var test_manager = Node.new()
	test_manager.name = "TestManager"
	
	var result = registry.register("TestManager", test_manager)
	test_results["registry_register"] = result
	
	# 测试获取管理器
	var manager = registry.get_manager("TestManager")
	test_results["registry_get_manager"] = manager != null
	
	# 测试检查管理器是否存在
	var has_manager = registry.has_manager("TestManager")
	test_results["registry_has_manager"] = has_manager
	
	# 测试获取不存在的管理器
	var non_existent_manager = registry.get_manager("NonExistentManager")
	test_results["registry_get_non_existent_manager"] = non_existent_manager == null
	
	# 测试添加依赖
	var test_manager2 = Node.new()
	test_manager2.name = "TestManager2"
	registry.register("TestManager2", test_manager2)
	
	var add_dependency_result = registry.add_dependency("TestManager", "TestManager2")
	test_results["registry_add_dependency"] = add_dependency_result
	
	# 测试获取依赖
	var dependencies = registry.get_dependencies("TestManager")
	test_results["registry_get_dependencies"] = dependencies.size() == 1 and dependencies[0] == "TestManager2"
	
	# 测试移除依赖
	var remove_dependency_result = registry.remove_dependency("TestManager", "TestManager2")
	test_results["registry_remove_dependency"] = remove_dependency_result
	
	# 测试获取所有管理器名称
	var manager_names = registry.get_all_manager_names()
	test_results["registry_get_all_manager_names"] = manager_names.size() == 2
	
	# 测试获取已初始化的管理器名称
	var initialized_manager_names = registry.get_initialized_manager_names()
	test_results["registry_get_initialized_manager_names"] = initialized_manager_names.size() == 0
	
	# 测试初始化管理器
	var initialize_result = registry.initialize("TestManager")
	test_results["registry_initialize"] = initialize_result
	
	# 测试重置管理器
	var reset_result = registry.reset_manager("TestManager")
	test_results["registry_reset_manager"] = reset_result
	
	# 测试清理管理器
	var cleanup_result = registry.cleanup_manager("TestManager")
	test_results["registry_cleanup_manager"] = cleanup_result
	
	# 测试获取错误信息
	var error = registry.get_error("TestManager")
	test_results["registry_get_error"] = error != null
	
	# 测试获取所有错误信息
	var all_errors = registry.get_all_errors()
	test_results["registry_get_all_errors"] = all_errors != null
	
	# 测试获取有错误的管理器
	var managers_with_errors = registry.get_managers_with_errors()
	test_results["registry_get_managers_with_errors"] = managers_with_errors != null

# 测试 BaseManager
func test_base_manager() -> void:
	print("测试 BaseManager...")
	
	# 创建 BaseManager
	var manager = load("res://scripts/core/base_manager.gd").new()
	
	# 测试设置管理器名称
	manager.set_manager_name("TestBaseManager")
	test_results["base_manager_set_name"] = manager.manager_name == "TestBaseManager"
	
	# 测试添加依赖
	manager.add_dependency("TestDependency")
	test_results["base_manager_add_dependency"] = manager._dependencies.size() == 1
	
	# 测试获取依赖
	var dependencies = manager.get_dependencies()
	test_results["base_manager_get_dependencies"] = dependencies.size() == 1
	
	# 测试移除依赖
	manager.remove_dependency("TestDependency")
	test_results["base_manager_remove_dependency"] = manager._dependencies.size() == 0
	
	# 测试初始化
	var initialize_result = manager.initialize()
	test_results["base_manager_initialize"] = initialize_result
	
	# 测试检查是否已初始化
	var is_initialized = manager.is_initialized()
	test_results["base_manager_is_initialized"] = is_initialized
	
	# 测试重置
	var reset_result = manager.reset()
	test_results["base_manager_reset"] = reset_result
	
	# 测试清理
	var cleanup_result = manager.cleanup()
	test_results["base_manager_cleanup"] = cleanup_result
	
	# 测试获取错误信息
	var error = manager.get_error()
	test_results["base_manager_get_error"] = error != null
	
	# 测试检查是否有错误
	var has_error = manager.has_error()
	test_results["base_manager_has_error"] = has_error == false
	
	# 测试清空错误信息
	manager.clear_error()
	test_results["base_manager_clear_error"] = manager.get_error() == ""
	
	# 测试获取管理器状态
	var status = manager.get_status()
	test_results["base_manager_get_status"] = status != null

# 测试 GameManager
func test_game_manager() -> void:
	print("测试 GameManager...")
	
	# 测试获取管理器
	var scene_manager = GameManager.get_manager("SceneManager")
	test_results["game_manager_get_manager"] = scene_manager != null
	
	# 测试检查管理器是否存在
	var has_manager = GameManager.has_manager("SceneManager")
	test_results["game_manager_has_manager"] = has_manager
	
	# 测试获取管理器注册表
	var registry = GameManager.manager_registry
	test_results["game_manager_get_registry"] = registry != null
	
	# 测试获取游戏状态
	var game_state = GameManager.current_state
	test_results["game_manager_get_state"] = game_state != null
	
	# 测试暂停游戏
	GameManager.pause_game()
	test_results["game_manager_pause_game"] = GameManager.is_paused
	
	# 测试恢复游戏
	GameManager.resume_game()
	test_results["game_manager_resume_game"] = not GameManager.is_paused

# 输出测试结果
func print_test_results() -> void:
	print("测试结果:")
	
	var success_count = 0
	var failure_count = 0
	
	for test_name in test_results.keys():
		var result = test_results[test_name]
		if result:
			success_count += 1
			print("  ✓ " + test_name)
		else:
			failure_count += 1
			print("  ✗ " + test_name)
	
	print("总计: " + str(success_count + failure_count) + " 测试, " + str(success_count) + " 成功, " + str(failure_count) + " 失败")

# 调试消息处理
func _on_debug_message(message: String, level: int) -> void:
	var level_str = ""
	match level:
		0: level_str = "[INFO] "
		1: level_str = "[WARN] "
		2: level_str = "[ERROR] "
		3: level_str = "[FATAL] "
	
	print(level_str + message)
