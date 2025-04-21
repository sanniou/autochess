extends Node
class_name UnifiedTestRunner
## 统一测试运行器
## 用于运行和管理测试

# 信号
signal tests_started
signal tests_completed(results)
signal test_progress(current, total)

# 测试状态
enum TestStatus {
	PENDING,   # 等待运行
	RUNNING,   # 正在运行
	PASSED,    # 通过
	FAILED     # 失败
}

# 测试框架
var test_framework: UnifiedTestFramework = null

# 测试场景
var test_scenes: Array = []

# 测试结果
var test_results: Dictionary = {}

# 当前测试场景索引
var _current_scene_index: int = -1

# 是否正在运行测试
var is_running: bool = false

# 初始化
func _ready() -> void:
	# 创建测试框架
	test_framework = UnifiedTestFramework.new()
	add_child(test_framework)
	
	# 连接信号
	test_framework.all_tests_completed.connect(_on_all_tests_completed)
	test_framework.test_started.connect(_on_test_started)
	test_framework.test_completed.connect(_on_test_completed)
	test_framework.test_failed.connect(_on_test_failed)

## 添加测试场景
func add_test_scene(scene_path: String) -> void:
	if not scene_path in test_scenes:
		test_scenes.append(scene_path)

## 添加测试场景列表
func add_test_scenes(scene_paths: Array) -> void:
	for path in scene_paths:
		add_test_scene(path)

## 清除测试场景
func clear_test_scenes() -> void:
	test_scenes.clear()

## 运行所有测试
func run_all_tests() -> void:
	# 如果正在运行测试，忽略
	if is_running:
		return
	
	# 如果没有测试场景，忽略
	if test_scenes.is_empty():
		return
	
	# 设置状态
	is_running = true
	
	# 清空测试结果
	test_results.clear()
	
	# 初始化测试结果
	for scene_path in test_scenes:
		test_results[scene_path] = {
			"status": TestStatus.PENDING,
			"message": "",
			"time": 0.0,
			"tests": {}
		}
	
	# 设置当前测试索引
	_current_scene_index = -1
	
	# 发送测试开始信号
	tests_started.emit()
	
	# 运行下一个测试
	_run_next_test_scene()

## 运行指定测试场景
func run_test_scene(scene_path: String) -> void:
	# 加载测试场景
	var scene = load(scene_path)
	if scene == null:
		print("无法加载测试场景: " + scene_path)
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
		
		# 重置状态
		is_running = false
		_current_scene_index = -1
		
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
	# 如果当前没有测试场景，忽略
	if _current_scene_index < 0 or _current_scene_index >= test_scenes.size():
		return
	
	# 获取当前测试场景路径
	var scene_path = test_scenes[_current_scene_index]
	
	# 更新测试结果
	if not test_results[scene_path].tests.has(test_name):
		test_results[scene_path].tests[test_name] = {
			"status": TestStatus.RUNNING,
			"message": "",
			"time": 0.0
		}

## 测试完成事件处理
func _on_test_completed(test_name: String, result: Dictionary) -> void:
	# 如果当前没有测试场景，忽略
	if _current_scene_index < 0 or _current_scene_index >= test_scenes.size():
		return
	
	# 获取当前测试场景路径
	var scene_path = test_scenes[_current_scene_index]
	
	# 更新测试结果
	test_results[scene_path].tests[test_name] = {
		"status": result.status,
		"message": result.message,
		"time": result.duration,
		"assertions": result.assertions,
		"failures": result.failures
	}
	
	# 更新场景测试状态
	if result.status == UnifiedTestFramework.TestStatus.FAILED:
		test_results[scene_path].status = TestStatus.FAILED
		if test_results[scene_path].message.is_empty():
			test_results[scene_path].message = "测试失败: " + test_name
		else:
			test_results[scene_path].message += "\n测试失败: " + test_name

## 测试失败事件处理
func _on_test_failed(test_name: String, error_message: String) -> void:
	# 如果当前没有测试场景，忽略
	if _current_scene_index < 0 or _current_scene_index >= test_scenes.size():
		return
	
	# 获取当前测试场景路径
	var scene_path = test_scenes[_current_scene_index]
	
	# 更新测试结果
	if test_results[scene_path].tests.has(test_name):
		test_results[scene_path].tests[test_name].status = TestStatus.FAILED
		test_results[scene_path].tests[test_name].message = error_message
	
	# 更新场景测试状态
	test_results[scene_path].status = TestStatus.FAILED
	if test_results[scene_path].message.is_empty():
		test_results[scene_path].message = error_message
	else:
		test_results[scene_path].message += "\n" + error_message

## 所有测试完成事件处理
func _on_all_tests_completed(results: Dictionary) -> void:
	# 如果当前没有测试场景，忽略
	if _current_scene_index < 0 or _current_scene_index >= test_scenes.size():
		return
	
	# 获取当前测试场景路径
	var scene_path = test_scenes[_current_scene_index]
	
	# 更新测试结果
	if test_results[scene_path].status != TestStatus.FAILED:
		test_results[scene_path].status = TestStatus.PASSED
