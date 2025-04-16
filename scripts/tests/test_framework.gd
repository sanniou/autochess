extends Node
class_name TestFramework
## 单元测试框架
## 用于测试游戏的各个组件

# 信号
signal test_started(test_name)
signal test_completed(test_name, success)
signal test_failed(test_name, error_message)
signal all_tests_completed(results)

# 测试状态
enum TestStatus {
	PENDING,
	RUNNING,
	PASSED,
	FAILED
}

# 测试结果
var test_results = {}

# 当前运行的测试
var current_test = ""

# 测试超时时间（秒）
var test_timeout = 10.0

# 测试计时器
var _test_timer = 0.0

# 测试列表
var _tests = []

# 初始化
func _ready() -> void:
	# 设置进程模式
	process_mode = Node.PROCESS_MODE_ALWAYS

# 进程
func _process(delta: float) -> void:
	# 如果有测试正在运行，更新计时器
	if current_test != "":
		_test_timer += delta
		
		# 检查是否超时
		if _test_timer >= test_timeout:
			_fail_test(current_test, "测试超时")

## 注册测试
func register_test(test_name: String, test_method: Callable) -> void:
	_tests.append({
		"name": test_name,
		"method": test_method,
		"status": TestStatus.PENDING
	})
	
	test_results[test_name] = {
		"status": TestStatus.PENDING,
		"error": "",
		"duration": 0.0
	}

## 运行所有测试
func run_all_tests() -> void:
	# 重置测试结果
	test_results.clear()
	
	# 初始化测试结果
	for test in _tests:
		test_results[test.name] = {
			"status": TestStatus.PENDING,
			"error": "",
			"duration": 0.0
		}
	
	# 运行测试
	for test in _tests:
		run_test(test.name)

## 运行指定测试
func run_test(test_name: String) -> void:
	# 查找测试
	var test = null
	for t in _tests:
		if t.name == test_name:
			test = t
			break
	
	if test == null:
		EventBus.debug_message.emit("测试不存在: " + test_name, 2)
		return
	
	# 设置当前测试
	current_test = test_name
	
	# 重置计时器
	_test_timer = 0.0
	
	# 更新测试状态
	test.status = TestStatus.RUNNING
	test_results[test_name].status = TestStatus.RUNNING
	
	# 发送测试开始信号
	test_started.emit(test_name)
	
	# 运行测试
	var start_time = Time.get_ticks_msec()
	
	try:
		test.method.call()
		
		# 计算测试时间
		var end_time = Time.get_ticks_msec()
		var duration = (end_time - start_time) / 1000.0
		
		# 更新测试结果
		_pass_test(test_name, duration)
	except e:
		# 测试失败
		_fail_test(test_name, str(e))

## 断言相等
func assert_equal(actual, expected, message: String = "") -> void:
	if actual != expected:
		var error = "断言失败: 期望 %s，实际 %s" % [str(expected), str(actual)]
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言不相等
func assert_not_equal(actual, expected, message: String = "") -> void:
	if actual == expected:
		var error = "断言失败: 期望不等于 %s" % str(expected)
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言为真
func assert_true(condition, message: String = "") -> void:
	if not condition:
		var error = "断言失败: 期望为真"
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言为假
func assert_false(condition, message: String = "") -> void:
	if condition:
		var error = "断言失败: 期望为假"
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言为空
func assert_null(value, message: String = "") -> void:
	if value != null:
		var error = "断言失败: 期望为空，实际为 %s" % str(value)
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言不为空
func assert_not_null(value, message: String = "") -> void:
	if value == null:
		var error = "断言失败: 期望不为空"
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言在范围内
func assert_in_range(value, min_value, max_value, message: String = "") -> void:
	if value < min_value or value > max_value:
		var error = "断言失败: 期望在范围 [%s, %s] 内，实际为 %s" % [str(min_value), str(max_value), str(value)]
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言包含
func assert_contains(container, value, message: String = "") -> void:
	if not container.has(value):
		var error = "断言失败: 期望包含 %s" % str(value)
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言不包含
func assert_not_contains(container, value, message: String = "") -> void:
	if container.has(value):
		var error = "断言失败: 期望不包含 %s" % str(value)
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言大小
func assert_size(container, expected_size, message: String = "") -> void:
	if container.size() != expected_size:
		var error = "断言失败: 期望大小为 %s，实际为 %s" % [str(expected_size), str(container.size())]
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 断言类型
func assert_type(value, type, message: String = "") -> void:
	if not is_instance_of(value, type):
		var error = "断言失败: 期望类型为 %s，实际为 %s" % [str(type), str(typeof(value))]
		if message != "":
			error += " - " + message
		
		_fail_current_test(error)

## 测试通过
func _pass_test(test_name: String, duration: float) -> void:
	# 更新测试状态
	for test in _tests:
		if test.name == test_name:
			test.status = TestStatus.PASSED
			break
	
	# 更新测试结果
	test_results[test_name].status = TestStatus.PASSED
	test_results[test_name].duration = duration
	
	# 清除当前测试
	current_test = ""
	
	# 发送测试完成信号
	test_completed.emit(test_name, true)
	
	# 检查是否所有测试都已完成
	_check_all_tests_completed()

## 测试失败
func _fail_test(test_name: String, error_message: String) -> void:
	# 更新测试状态
	for test in _tests:
		if test.name == test_name:
			test.status = TestStatus.FAILED
			break
	
	# 更新测试结果
	test_results[test_name].status = TestStatus.FAILED
	test_results[test_name].error = error_message
	
	# 清除当前测试
	current_test = ""
	
	# 发送测试失败信号
	test_failed.emit(test_name, error_message)
	
	# 检查是否所有测试都已完成
	_check_all_tests_completed()

## 当前测试失败
func _fail_current_test(error_message: String) -> void:
	if current_test != "":
		_fail_test(current_test, error_message)

## 检查是否所有测试都已完成
func _check_all_tests_completed() -> void:
	var all_completed = true
	
	for test in _tests:
		if test.status == TestStatus.PENDING or test.status == TestStatus.RUNNING:
			all_completed = false
			break
	
	if all_completed:
		all_tests_completed.emit(test_results)

## 获取测试结果
func get_test_results() -> Dictionary:
	return test_results

## 获取测试统计
func get_test_stats() -> Dictionary:
	var total = _tests.size()
	var passed = 0
	var failed = 0
	var pending = 0
	
	for test in _tests:
		match test.status:
			TestStatus.PASSED:
				passed += 1
			TestStatus.FAILED:
				failed += 1
			_:
				pending += 1
	
	return {
		"total": total,
		"passed": passed,
		"failed": failed,
		"pending": pending,
		"success_rate": float(passed) / total if total > 0 else 0.0
	}

## 设置测试超时时间
func set_test_timeout(timeout: float) -> void:
	test_timeout = max(1.0, timeout)

## 清除所有测试
func clear_tests() -> void:
	_tests.clear()
	test_results.clear()
	current_test = ""
