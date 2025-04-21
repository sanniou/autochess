extends Node
class_name UnifiedTestFramework
## 统一测试框架
## 提供测试API和工具

# 信号
signal test_started(test_name)
signal test_completed(test_name, result)
signal test_failed(test_name, error_message)
signal all_tests_completed(results)

# 测试状态
enum TestStatus {
	PENDING,   # 等待运行
	RUNNING,   # 正在运行
	PASSED,    # 通过
	FAILED     # 失败
}

# 测试结果
var test_results: Dictionary = {}

# 当前测试
var current_test: String = ""

# 测试超时时间（秒）
var test_timeout: float = 10.0

# 测试计时器
var _test_timer: float = 0.0

# 测试列表
var _tests: Array = []

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
		"duration": 0.0,
		"assertions": 0,
		"failures": 0,
		"message": ""
	}

## 清除所有测试
func clear_tests() -> void:
	_tests.clear()
	test_results.clear()
	current_test = ""
	_test_timer = 0.0

## 运行所有测试
func run_all_tests() -> void:
	# 重置测试结果
	for test in _tests:
		test_results[test.name] = {
			"status": TestStatus.PENDING,
			"error": "",
			"duration": 0.0,
			"assertions": 0,
			"failures": 0,
			"message": ""
		}

	# 运行测试
	for test in _tests:
		await run_test(test.name)

	# 发送所有测试完成信号
	all_tests_completed.emit(test_results)

## 运行指定测试
func run_test(test_name: String) -> void:
	# 查找测试
	var test = null
	for t in _tests:
		if t.name == test_name:
			test = t
			break

	if test == null:
		print("测试不存在: " + test_name)
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

	await test.method.call()

	# 计算测试时间
	var end_time = Time.get_ticks_msec()
	var duration = (end_time - start_time) / 1000.0

	# 检查是否有失败的断言
	if test_results[test_name].failures > 0:
		# 测试失败
		_fail_test(test_name, test_results[test_name].message, duration)
	else:
		# 测试通过
		_pass_test(test_name, duration)


## 测试通过
func _pass_test(test_name: String, duration: float = 0.0) -> void:
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
	test_completed.emit(test_name, test_results[test_name])

## 测试失败
func _fail_test(test_name: String, error_message: String, duration: float = 0.0) -> void:
	# 更新测试状态
	for test in _tests:
		if test.name == test_name:
			test.status = TestStatus.FAILED
			break

	# 更新测试结果
	test_results[test_name].status = TestStatus.FAILED
	test_results[test_name].error = error_message
	test_results[test_name].duration = duration

	# 清除当前测试
	current_test = ""

	# 发送测试失败信号
	test_failed.emit(test_name, error_message)

	# 发送测试完成信号
	test_completed.emit(test_name, test_results[test_name])

## 开始测试
func start_test(test_name: String) -> void:
	# 设置当前测试
	current_test = test_name

	# 初始化测试结果
	test_results[test_name] = {
		"status": TestStatus.RUNNING,
		"error": "",
		"duration": 0.0,
		"assertions": 0,
		"failures": 0,
		"message": ""
	}

	# 发送测试开始信号
	test_started.emit(test_name)

## 结束测试
func end_test() -> Dictionary:
	# 检查当前测试
	if current_test.is_empty():
		return {}

	# 获取测试结果
	var result = test_results[current_test]

	# 更新测试状态
	if result.failures > 0:
		result.status = TestStatus.FAILED
	else:
		result.status = TestStatus.PASSED

	# 清除当前测试
	var test_name = current_test
	current_test = ""

	# 发送测试完成信号
	test_completed.emit(test_name, result)

	return result

## 断言相等
func assert_equal(actual, expected, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查相等
	if actual == expected:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望 " + str(expected) + ", 实际 " + str(actual)
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言不相等
func assert_not_equal(actual, expected, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查不相等
	if actual != expected:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望不等于 " + str(expected) + ", 实际 " + str(actual)
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言为真
func assert_true(condition, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查条件
	if condition:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望为真, 实际为假"
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言为假
func assert_false(condition, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查条件
	if not condition:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望为假, 实际为真"
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言为空
func assert_null(value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查为空
	if value == null:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望为空, 实际为 " + str(value)
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言不为空
func assert_not_null(value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查不为空
	if value != null:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望不为空, 实际为空"
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言近似相等（浮点数比较）
func assert_almost_equal(actual, expected, epsilon: float = 0.0001, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查近似相等
	if abs(actual - expected) <= epsilon:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望近似等于 " + str(expected) + ", 实际 " + str(actual) + ", 误差 " + str(abs(actual - expected)) + " > " + str(epsilon)
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言包含
func assert_contains(container, value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查包含
	if value in container:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望包含 " + str(value) + ", 实际不包含"
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言不包含
func assert_not_contains(container, value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查不包含
	if not value in container:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var error_message = "断言失败: 期望不包含 " + str(value) + ", 实际包含"
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言类型
func assert_type(value, type_name: String, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 检查类型
	var type_matches = false
	match type_name:
		"int", "integer":
			type_matches = value is int
		"float", "real":
			type_matches = value is float
		"bool", "boolean":
			type_matches = value is bool
		"String", "string":
			type_matches = value is String
		"Array", "array":
			type_matches = value is Array
		"Dictionary", "dict":
			type_matches = value is Dictionary
		"Object", "object":
			type_matches = value is Object
		"Node":
			type_matches = value is Node
		"Resource":
			type_matches = value is Resource
		_:
			# 尝试使用类名检查
			if value != null:
				# 使用is_class方法检查类型
				if value is Object and value.has_method("is_class"):
					type_matches = value.is_class(type_name)
				else:
					# 尝试使用脚本类名检查
					type_matches = value.get_class() == type_name if value is Object else false
			else:
				type_matches = false

	if type_matches:
		return true

	# 增加失败计数
	test_results[current_test].failures += 1

	# 构建错误消息
	var actual_type = "null" if value == null else value.get_class() if value is Object else typeof(value)
	var error_message = "断言失败: 期望类型 " + type_name + ", 实际类型 " + str(actual_type)
	if not message.is_empty():
		error_message += " - " + message

	# 打印错误消息
	print(error_message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = error_message
	else:
		test_results[current_test].message += "\n" + error_message

	return false

## 断言失败
func fail(message: String = "测试失败") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false

	# 增加断言计数和失败计数
	test_results[current_test].assertions += 1
	test_results[current_test].failures += 1

	# 打印错误消息
	print(message)

	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = message
	else:
		test_results[current_test].message += "\n" + message

	return false

## 断言通过
func _pass(message: String = "测试通过") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return true

	# 增加断言计数
	test_results[current_test].assertions += 1

	# 打印消息
	print(message)

	return true
