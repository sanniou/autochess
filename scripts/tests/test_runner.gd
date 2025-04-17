extends Node
class_name TestRunner
## 测试运行器
## 用于运行和管理测试

# 信号
signal tests_started
signal tests_completed(results)
signal test_progress(current, total)

# 测试框架
var test_framework = null

# 测试场景
var test_scenes = []

# 测试结果
var test_results = {}

# 当前测试场景索引
var _current_scene_index = -1

# 初始化
func _ready() -> void:
	# 创建测试框架
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# 连接信号
	test_framework.all_tests_completed.connect(_on_all_tests_completed)
	test_framework.test_started.connect(_on_test_started)
	test_framework.test_completed.connect(_on_test_completed)
	test_framework.test_failed.connect(_on_test_failed)

## 添加测试场景
func add_test_scene(scene_path: String) -> void:
	test_scenes.append(scene_path)

## 添加测试场景列表
func add_test_scenes(scene_paths: Array) -> void:
	for path in scene_paths:
		add_test_scene(path)

## 运行所有测试
func run_all_tests() -> void:
	# 清除测试结果
	test_results.clear()
	
	# 发送测试开始信号
	tests_started.emit()
	
	# 开始运行测试场景
	_current_scene_index = -1
	_run_next_test_scene()

## 运行指定测试场景
func run_test_scene(scene_path: String) -> void:
	# 加载测试场景
	var scene = load(scene_path)
	if scene == null:
		EventBus.debug.debug_message.emit("无法加载测试场景: " + scene_path, 2)
		return
	
	# 实例化测试场景
	var instance = scene.instantiate()
	add_child(instance)
	
	# 收集测试
	_collect_tests(instance)
	
	# 运行测试
	test_framework.run_all_tests()
	
	# 等待测试完成
	await test_framework.all_tests_completed
	
	# 移除测试场景
	remove_child(instance)
	instance.queue_free()

## 运行下一个测试场景
func _run_next_test_scene() -> void:
	_current_scene_index += 1
	
	# 检查是否所有测试场景都已运行
	if _current_scene_index >= test_scenes.size():
		# 所有测试场景都已运行完成
		tests_completed.emit(test_results)
		return
	
	# 获取当前测试场景
	var scene_path = test_scenes[_current_scene_index]
	
	# 发送进度信号
	test_progress.emit(_current_scene_index + 1, test_scenes.size())
	
	# 运行测试场景
	await run_test_scene(scene_path)
	
	# 运行下一个测试场景
	_run_next_test_scene()

## 收集测试
func _collect_tests(node: Node) -> void:
	# 清除现有测试
	test_framework.clear_tests()
	
	# 查找所有测试方法
	for method in node.get_method_list():
		var method_name = method.name
		
		# 检查是否是测试方法
		if method_name.begins_with("test_"):
			# 注册测试
			test_framework.register_test(method_name, Callable(node, method_name))

## 测试开始事件处理
func _on_test_started(test_name: String) -> void:
	EventBus.debug.debug_message.emit("开始测试: " + test_name, 0)

## 测试完成事件处理
func _on_test_completed(test_name: String, success: bool) -> void:
	if success:
		EventBus.debug.debug_message.emit("测试通过: " + test_name, 0)
	else:
		EventBus.debug.debug_message.emit("测试失败: " + test_name, 2)

## 测试失败事件处理
func _on_test_failed(test_name: String, error_message: String) -> void:
	EventBus.debug.debug_message.emit("测试失败: " + test_name + " - " + error_message, 2)

## 所有测试完成事件处理
func _on_all_tests_completed(results: Dictionary) -> void:
	# 合并测试结果
	for test_name in results:
		test_results[test_name] = results[test_name]
	
	# 输出测试统计
	var stats = test_framework.get_test_stats()
	EventBus.debug.debug_message.emit("测试完成: 总计 %d, 通过 %d, 失败 %d, 成功率 %.1f%%" % [
		stats.total, stats.passed, stats.failed, stats.success_rate * 100
	], 0)

## 获取测试结果
func get_test_results() -> Dictionary:
	return test_results

## 获取测试统计
func get_test_stats() -> Dictionary:
	var total_tests = 0
	var passed_tests = 0
	var failed_tests = 0
	
	for test_name in test_results:
		total_tests += 1
		if test_results[test_name].status == TestFramework.TestStatus.PASSED:
			passed_tests += 1
		elif test_results[test_name].status == TestFramework.TestStatus.FAILED:
			failed_tests += 1
	
	return {
		"total": total_tests,
		"passed": passed_tests,
		"failed": failed_tests,
		"success_rate": float(passed_tests) / total_tests if total_tests > 0 else 0.0
	}

## 设置测试超时时间
func set_test_timeout(timeout: float) -> void:
	test_framework.set_test_timeout(timeout)

## 清除所有测试
func clear_tests() -> void:
	test_framework.clear_tests()
	test_results.clear()
	test_scenes.clear()
	_current_scene_index = -1
