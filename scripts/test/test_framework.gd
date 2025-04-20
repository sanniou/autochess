extends Node
class_name TestFramework
## 测试框架
## 提供测试API和工具

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

# 初始化
func _init() -> void:
	pass

# 开始测试
func start_test(test_name: String) -> void:
	# 设置当前测试
	current_test = test_name
	
	# 初始化测试结果
	test_results[test_name] = {
		"status": TestStatus.RUNNING,
		"message": "",
		"assertions": 0,
		"failures": 0
	}
	
	# 打印测试开始信息
	print("开始测试: " + test_name)

# 结束测试
func end_test() -> Dictionary:
	# 检查当前测试
	if current_test.is_empty():
		return {
			"status": TestStatus.FAILED,
			"message": "没有正在运行的测试"
		}
	
	# 获取测试结果
	var result = test_results[current_test]
	
	# 设置测试状态
	if result.failures == 0:
		result.status = TestStatus.PASSED
	else:
		result.status = TestStatus.FAILED
	
	# 打印测试结束信息
	if result.status == TestStatus.PASSED:
		print("测试通过: " + current_test + " (" + str(result.assertions) + " 个断言)")
	else:
		print("测试失败: " + current_test + " (" + str(result.failures) + " 个失败, " + str(result.assertions) + " 个断言)")
	
	# 清除当前测试
	current_test = ""
	
	return result

# 断言相等
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

# 断言不相等
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

# 断言为真
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

# 断言为假
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

# 断言为空
func assert_null(value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查值
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

# 断言不为空
func assert_not_null(value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查值
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

# 断言大于
func assert_greater_than(actual, expected, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查大于
	if actual > expected:
		return true
	
	# 增加失败计数
	test_results[current_test].failures += 1
	
	# 构建错误消息
	var error_message = "断言失败: 期望大于 " + str(expected) + ", 实际 " + str(actual)
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

# 断言小于
func assert_less_than(actual, expected, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查小于
	if actual < expected:
		return true
	
	# 增加失败计数
	test_results[current_test].failures += 1
	
	# 构建错误消息
	var error_message = "断言失败: 期望小于 " + str(expected) + ", 实际 " + str(actual)
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

# 断言大于等于
func assert_greater_than_or_equal(actual, expected, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查大于等于
	if actual >= expected:
		return true
	
	# 增加失败计数
	test_results[current_test].failures += 1
	
	# 构建错误消息
	var error_message = "断言失败: 期望大于等于 " + str(expected) + ", 实际 " + str(actual)
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

# 断言小于等于
func assert_less_than_or_equal(actual, expected, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查小于等于
	if actual <= expected:
		return true
	
	# 增加失败计数
	test_results[current_test].failures += 1
	
	# 构建错误消息
	var error_message = "断言失败: 期望小于等于 " + str(expected) + ", 实际 " + str(actual)
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

# 断言近似相等（浮点数比较）
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
	var error_message = "断言失败: 期望近似等于 " + str(expected) + " (±" + str(epsilon) + "), 实际 " + str(actual)
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

# 断言包含
func assert_contains(container, value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查包含
	if container is Array or container is Dictionary or container is String:
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

# 断言不包含
func assert_not_contains(container, value, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查不包含
	if container is Array or container is Dictionary or container is String:
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

# 断言类型
func assert_type(value, type_name: String, message: String = "") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 检查类型
	var is_correct_type = false
	
	match type_name:
		"int":
			is_correct_type = value is int
		"float":
			is_correct_type = value is float
		"bool":
			is_correct_type = value is bool
		"String":
			is_correct_type = value is String
		"Array":
			is_correct_type = value is Array
		"Dictionary":
			is_correct_type = value is Dictionary
		"Vector2":
			is_correct_type = value is Vector2
		"Vector3":
			is_correct_type = value is Vector3
		"Color":
			is_correct_type = value is Color
		"Rect2":
			is_correct_type = value is Rect2
		"Transform2D":
			is_correct_type = value is Transform2D
		"Transform3D":
			is_correct_type = value is Transform3D
		"Basis":
			is_correct_type = value is Basis
		"Quaternion":
			is_correct_type = value is Quaternion
		"Plane":
			is_correct_type = value is Plane
		"AABB":
			is_correct_type = value is AABB
		"NodePath":
			is_correct_type = value is NodePath
		"RID":
			is_correct_type = value is RID
		"Object":
			is_correct_type = value is Object
		_:
			# 尝试检查自定义类型
			if value is Object and value.get_class() == type_name:
				is_correct_type = true
			elif value is Object and type_name in ClassDB.get_inheriters_from_class(value.get_class()):
				is_correct_type = true
	
	if is_correct_type:
		return true
	
	# 增加失败计数
	test_results[current_test].failures += 1
	
	# 构建错误消息
	var error_message = "断言失败: 期望类型 " + type_name + ", 实际类型 " + (value.get_class() if value is Object else typeof(value) as String)
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

# 断言失败
func fail(message: String = "测试失败") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return false
	
	# 增加断言计数和失败计数
	test_results[current_test].assertions += 1
	test_results[current_test].failures += 1
	
	# 打印错误消息
	print("断言失败: " + message)
	
	# 更新测试结果消息
	if test_results[current_test].message.is_empty():
		test_results[current_test].message = message
	else:
		test_results[current_test].message += "\n" + message
	
	return false

# 断言通过
func pass(message: String = "测试通过") -> bool:
	# 检查当前测试
	if current_test.is_empty():
		print("错误: 没有正在运行的测试")
		return true
	
	# 增加断言计数
	test_results[current_test].assertions += 1
	
	# 打印消息
	print("断言通过: " + message)
	
	return true
