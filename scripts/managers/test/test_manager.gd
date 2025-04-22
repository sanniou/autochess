extends "res://scripts/managers/core/base_manager.gd"
class_name TestManager
## 测试管理器
## 负责管理和运行所有测试

# 信号
signal test_started(test_id)
signal test_completed(test_id, success)
signal test_progress(current, total)
signal all_tests_completed(results)

# 测试模块结构
var test_modules: Dictionary = {}

# 测试场景缓存
var test_scene_cache: Dictionary = {}

# 测试结果
var test_results: Dictionary = {}

# 当前运行的测试
var current_test: String = ""

# 测试运行器
var test_runner: UnifiedTestRunner = null

# 测试发现器
var test_discoverer: TestDiscoverer = null

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "TestManager"

	# 创建测试运行器
	test_runner = UnifiedTestRunner.new()
	add_child(test_runner)

	# 连接信号
	test_runner.tests_started.connect(_on_tests_started)
	test_runner.tests_completed.connect(_on_tests_completed)
	test_runner.test_progress.connect(_on_test_progress)

	# 创建测试发现器
	test_discoverer = TestDiscoverer.new()
	add_child(test_discoverer)

	# 发现测试
	test_modules = test_discoverer.discover_all_tests()

	_log_info("测试管理器初始化完成")

# 重写重置方法
func _do_reset() -> void:
	# 清空测试结果
	test_results.clear()

	# 清空测试场景缓存
	for scene in test_scene_cache.values():
		if scene is PackedScene:
			# 无需释放 PackedScene，它们会在场景树中自动释放
			pass

	test_scene_cache.clear()

	# 重置当前测试
	current_test = ""

	_log_info("测试管理器已重置")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开信号连接
	if test_runner:
		test_runner.tests_started.disconnect(_on_tests_started)
		test_runner.tests_completed.disconnect(_on_tests_completed)
		test_runner.test_progress.disconnect(_on_test_progress)

	# 释放测试运行器
	if test_runner:
		test_runner.queue_free()
		test_runner = null

	# 释放测试发现器
	if test_discoverer:
		test_discoverer.queue_free()
		test_discoverer = null

	_log_info("测试管理器已清理")

## 注册测试模块
func _register_test_modules() -> void:
	# 注册核心系统测试
	_register_core_tests()

	# 注册游戏系统测试
	_register_game_tests()

	# 注册UI测试
	_register_ui_tests()

	# 注册性能测试
	_register_performance_tests()

## 注册核心系统测试
func _register_core_tests() -> void:
	# 创建核心系统测试模块
	var core_module = {
		"id": "core",
		"name": "核心系统",
		"description": "测试游戏的核心系统",
		"tests": {}
	}

	# 添加事件总线测试
	core_module.tests["event_bus"] = {
		"id": "event_bus",
		"name": "事件总线",
		"description": "测试事件总线系统",
		"scene_path": "res://scenes/test/event_bus_test.tscn"
	}

	# 添加存档系统测试
	core_module.tests["save_system"] = {
		"id": "save_system",
		"name": "存档系统",
		"description": "测试存档系统",
		"scene_path": "res://scenes/test/save_system_test.tscn"
	}

	# 添加本地化测试
	core_module.tests["localization"] = {
		"id": "localization",
		"name": "本地化",
		"description": "测试本地化系统",
		"scene_path": "res://scenes/test/localization_test.tscn"
	}

	# 添加管理器系统测试
	core_module.tests["manager_system"] = {
		"id": "manager_system",
		"name": "管理器系统",
		"description": "测试管理器系统",
		"scene_path": "res://scenes/test/manager_system_test.tscn"
	}

	# 添加资源管理器测试
	core_module.tests["resource_manager"] = {
		"id": "resource_manager",
		"name": "资源管理器",
		"description": "测试资源管理器",
		"scene_path": "res://scenes/test/resource_manager_test.tscn"
	}

	# 添加对象池测试
	core_module.tests["object_pool"] = {
		"id": "object_pool",
		"name": "对象池",
		"description": "测试对象池系统",
		"scene_path": "res://scenes/test/object_pool_test.tscn"
	}

	# 添加示例测试
	core_module.tests["example"] = {
		"id": "example",
		"name": "示例测试",
		"description": "测试框架示例",
		"scene_path": "res://scenes/test/example_test.tscn"
	}

	# 注册核心系统测试模块
	test_modules["core"] = core_module

## 注册游戏系统测试
func _register_game_tests() -> void:
	# 创建游戏系统测试模块
	var game_module = {
		"id": "game",
		"name": "游戏系统",
		"description": "测试游戏的核心玩法系统",
		"tests": {}
	}

	# 添加棋盘测试
	game_module.tests["board"] = {
		"id": "board",
		"name": "棋盘系统",
		"description": "测试棋盘系统",
		"scene_path": "res://scenes/test/board_test.tscn"
	}

	# 添加战斗系统测试
	game_module.tests["battle"] = {
		"id": "battle",
		"name": "战斗系统",
		"description": "测试战斗系统",
		"scene_path": "res://scenes/test/battle_system_test.tscn"
	}

	# 添加战斗模拟测试
	game_module.tests["battle_simulation"] = {
		"id": "battle_simulation",
		"name": "战斗模拟",
		"description": "测试完整的战斗模拟",
		"scene_path": "res://scenes/test/battle_simulation_test.tscn"
	}

	# 添加棋子系统测试
	game_module.tests["chess"] = {
		"id": "chess",
		"name": "棋子系统",
		"description": "测试棋子系统",
		"scene_path": "res://scenes/test/chess_system_test.tscn"
	}

	# 添加棋子测试
	game_module.tests["chess_test"] = {
		"id": "chess_test",
		"name": "棋子测试",
		"description": "测试棋子功能",
		"scene_path": "res://scenes/test/chess_test.tscn"
	}

	# 添加新的棋子系统测试
	game_module.tests["chess_system_test_new"] = {
		"id": "chess_system_test_new",
		"name": "新棋子系统测试",
		"description": "测试新的组件化棋子系统的功能",
		"scene_path": "res://scenes/test/chess_system_test_new.tscn"
	}

	# 添加技能测试
	game_module.tests["ability"] = {
		"id": "ability",
		"name": "技能系统",
		"description": "测试技能系统",
		"scene_path": "res://scenes/test/ability_test.tscn"
	}

	# 添加装备测试
	game_module.tests["equipment"] = {
		"id": "equipment",
		"name": "装备系统",
		"description": "测试装备系统",
		"scene_path": "res://scenes/test/equipment_test.tscn"
	}

	# 添加新的装备测试
	game_module.tests["equipment_test_new"] = {
		"id": "equipment_test_new",
		"name": "新装备测试",
		"description": "测试装备系统的功能",
		"scene_path": "res://scenes/test/equipment_test_new.tscn"
	}

	# 添加地图测试
	game_module.tests["map"] = {
		"id": "map",
		"name": "地图系统",
		"description": "测试地图系统",
		"scene_path": "res://scenes/test/map_test.tscn"
	}

	# 添加新地图测试
	game_module.tests["new_map"] = {
		"id": "new_map",
		"name": "新地图系统",
		"description": "测试新的地图系统",
		"scene_path": "res://scenes/test/new_map_test.tscn"
	}

	# 添加事件测试
	game_module.tests["event"] = {
		"id": "event",
		"name": "事件系统",
		"description": "测试事件系统",
		"scene_path": "res://scenes/test/event_test.tscn"
	}

	# 添加商店测试
	game_module.tests["shop"] = {
		"id": "shop",
		"name": "商店系统",
		"description": "测试商店系统",
		"scene_path": "res://scenes/test/shop_test.tscn"
	}

	# 添加现代化商店测试
	game_module.tests["modern_shop"] = {
		"id": "modern_shop",
		"name": "现代化商店",
		"description": "测试现代化商店界面",
		"scene_path": "res://scenes/test/modern_shop_test.tscn"
	}

	# 添加新的商店测试
	game_module.tests["shop_test_new"] = {
		"id": "shop_test_new",
		"name": "新商店测试",
		"description": "测试商店系统的功能",
		"scene_path": "res://scenes/test/shop_test_new.tscn"
	}

	# 添加羞结测试
	game_module.tests["synergy_test"] = {
		"id": "synergy_test",
		"name": "羞结测试",
		"description": "测试羞结系统实现",
		"scene_path": "res://scenes/test/synergy_test.tscn"
	}

	# 添加效果系统测试
	game_module.tests["effect_test"] = {
		"id": "effect_test",
		"name": "效果系统",
		"description": "测试游戏效果和视觉效果系统",
		"scene_path": "res://scenes/test/effect_test.tscn"
	}

	# 注册游戏系统测试模块
	test_modules["game"] = game_module

## 注册UI测试
func _register_ui_tests() -> void:
	# 创建UI测试模块
	var ui_module = {
		"id": "ui",
		"name": "UI系统",
		"description": "测试游戏的UI系统",
		"tests": {}
	}

	# 添加UI测试
	ui_module.tests["ui"] = {
		"id": "ui",
		"name": "UI系统",
		"description": "测试UI系统",
		"scene_path": "res://scenes/test/ui_test.tscn"
	}

	# 添加UI组件测试
	ui_module.tests["ui_components"] = {
		"id": "ui_components",
		"name": "UI组件",
		"description": "测试UI组件",
		"scene_path": "res://scenes/test/ui_components_test.tscn"
	}

	# 添加动画测试
	ui_module.tests["animation"] = {
		"id": "animation",
		"name": "动画系统",
		"description": "测试动画系统",
		"scene_path": "res://scenes/test/animation_test.tscn"
	}

	# 添加环境特效测试
	ui_module.tests["environment"] = {
		"id": "environment",
		"name": "环境特效",
		"description": "测试环境特效",
		"scene_path": "res://scenes/test/environment_test.tscn"
	}

	# 注册UI测试模块
	test_modules["ui"] = ui_module

## 注册性能测试
func _register_performance_tests() -> void:
	# 创建性能测试模块
	var performance_module = {
		"id": "performance",
		"name": "性能测试",
		"description": "测试游戏的性能",
		"tests": {}
	}

	# 添加性能测试
	performance_module.tests["performance"] = {
		"id": "performance",
		"name": "性能测试",
		"description": "测试游戏性能",
		"scene_path": "res://scenes/test/performance_test.tscn"
	}

	# 注册性能测试模块
	test_modules["performance"] = performance_module

## 获取所有测试模块
func get_all_test_modules() -> Dictionary:
	return test_modules

## 获取测试模块
func get_test_module(module_id: String) -> Dictionary:
	if test_modules.has(module_id):
		return test_modules[module_id]
	return {}

## 获取测试
func get_test(module_id: String, test_id: String) -> Dictionary:
	if test_modules.has(module_id) and test_modules[module_id].tests.has(test_id):
		return test_modules[module_id].tests[test_id]
	return {}

## 运行测试
func run_test(module_id: String, test_id: String) -> void:
	# 获取测试信息
	var test = get_test(module_id, test_id)
	if test.is_empty():
		_log_warning("测试不存在: " + module_id + "." + test_id)
		return

	# 设置当前测试
	current_test = module_id + "." + test_id

	# 发送测试开始信号
	test_started.emit(current_test)

	# 加载测试场景
	var scene_path = test.scene_path

	# 检查场景是否已缓存
	if test_scene_cache.has(scene_path):
		# 使用缓存的场景
		_run_test_scene(test_scene_cache[scene_path])
	else:
		# 加载场景
		var scene = load(scene_path)
		if scene:
			# 缓存场景
			test_scene_cache[scene_path] = scene

			# 运行测试场景
			_run_test_scene(scene)
		else:
			_log_warning("无法加载测试场景: " + scene_path)

			# 发送测试完成信号（失败）
			test_completed.emit(current_test, false)

			# 清除当前测试
			current_test = ""

## 运行测试场景
func _run_test_scene(scene: PackedScene) -> void:
	# 获取当前场景
	var current_scene = get_tree().current_scene

	# 保存当前场景路径
	var current_scene_path = current_scene.scene_file_path

	# 切换到测试场景
	get_tree().change_scene_to_packed(scene)

	# 等待场景加载完成
	await get_tree().process_frame

	# 发送测试完成信号（成功）
	test_completed.emit(current_test, true)

	# 清除当前测试
	current_test = ""

## 运行模块中的所有测试
func run_module_tests(module_id: String) -> void:
	# 获取模块信息
	var module = get_test_module(module_id)
	if module.is_empty():
		_log_warning("测试模块不存在: " + module_id)
		return

	# 获取模块中的所有测试
	var tests = module.tests

	# 创建测试场景列表
	var test_scenes = []
	for test_id in tests:
		var test = tests[test_id]
		test_scenes.append(test.scene_path)

	# 设置测试运行器
	test_runner.add_test_scenes(test_scenes)

	# 运行所有测试
	test_runner.run_all_tests()

## 运行所有测试
func run_all_tests() -> void:
	# 创建测试场景列表
	var test_scenes = []

	# 收集所有测试场景
	for module_id in test_modules:
		var module = test_modules[module_id]
		var tests = module.tests

		for test_id in tests:
			var test = tests[test_id]
			test_scenes.append(test.scene_path)

	# 设置测试运行器
	test_runner.add_test_scenes(test_scenes)

	# 运行所有测试
	test_runner.run_all_tests()

## 打开测试入口
func open_test_hub() -> void:
	# 加载测试入口场景
	get_tree().change_scene_to_file("res://scenes/test/test_hub.tscn")

## 测试开始事件处理
func _on_tests_started() -> void:
	# 转发信号
	test_started.emit("all_tests")

## 测试完成事件处理
func _on_tests_completed(results: Dictionary) -> void:
	# 保存测试结果
	test_results = results

	# 转发信号
	all_tests_completed.emit(results)

## 测试进度事件处理
func _on_test_progress(current: int, total: int) -> void:
	# 转发信号
	test_progress.emit(current, total)

## 重新发现测试
func rediscover_tests() -> void:
	# 发现测试
	if test_discoverer:
		test_modules = test_discoverer.discover_all_tests()
