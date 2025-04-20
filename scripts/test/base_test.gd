extends Node
class_name BaseTest
## 测试基类
## 所有测试场景都应该继承这个基类

# 测试框架
var test_framework: TestFramework = null

# 测试名称
var test_name: String = ""

# 测试描述
var test_description: String = ""

# 初始化
func _ready() -> void:
	# 创建测试框架
	test_framework = TestFramework.new()
	add_child(test_framework)
	
	# 设置测试名称
	if test_name.is_empty():
		test_name = get_script().resource_path.get_file().get_basename()
	
	# 设置测试描述
	if test_description.is_empty():
		test_description = "测试 " + test_name

# 运行测试
func run_test() -> Dictionary:
	# 开始测试
	test_framework.start_test(test_name)
	
	# 运行测试前的准备
	_setup()
	
	# 运行测试
	await _run()
	
	# 运行测试后的清理
	_teardown()
	
	# 结束测试
	return test_framework.end_test()

# 测试前的准备
func _setup() -> void:
	pass

# 运行测试
func _run() -> void:
	# 子类应该重写这个方法
	test_framework.fail("测试未实现")

# 测试后的清理
func _teardown() -> void:
	pass

# 断言相等
func assert_equal(actual, expected, message: String = "") -> bool:
	return test_framework.assert_equal(actual, expected, message)

# 断言不相等
func assert_not_equal(actual, expected, message: String = "") -> bool:
	return test_framework.assert_not_equal(actual, expected, message)

# 断言为真
func assert_true(condition, message: String = "") -> bool:
	return test_framework.assert_true(condition, message)

# 断言为假
func assert_false(condition, message: String = "") -> bool:
	return test_framework.assert_false(condition, message)

# 断言为空
func assert_null(value, message: String = "") -> bool:
	return test_framework.assert_null(value, message)

# 断言不为空
func assert_not_null(value, message: String = "") -> bool:
	return test_framework.assert_not_null(value, message)

# 断言大于
func assert_greater_than(actual, expected, message: String = "") -> bool:
	return test_framework.assert_greater_than(actual, expected, message)

# 断言小于
func assert_less_than(actual, expected, message: String = "") -> bool:
	return test_framework.assert_less_than(actual, expected, message)

# 断言大于等于
func assert_greater_than_or_equal(actual, expected, message: String = "") -> bool:
	return test_framework.assert_greater_than_or_equal(actual, expected, message)

# 断言小于等于
func assert_less_than_or_equal(actual, expected, message: String = "") -> bool:
	return test_framework.assert_less_than_or_equal(actual, expected, message)

# 断言近似相等（浮点数比较）
func assert_almost_equal(actual, expected, epsilon: float = 0.0001, message: String = "") -> bool:
	return test_framework.assert_almost_equal(actual, expected, epsilon, message)

# 断言包含
func assert_contains(container, value, message: String = "") -> bool:
	return test_framework.assert_contains(container, value, message)

# 断言不包含
func assert_not_contains(container, value, message: String = "") -> bool:
	return test_framework.assert_not_contains(container, value, message)

# 断言类型
func assert_type(value, type_name: String, message: String = "") -> bool:
	return test_framework.assert_type(value, type_name, message)

# 断言失败
func fail(message: String = "测试失败") -> bool:
	return test_framework.fail(message)

# 断言通过
func pass(message: String = "测试通过") -> bool:
	return test_framework.pass(message)

# 等待时间
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# 等待信号
func wait_for_signal(object: Object, signal_name: String, timeout: float = 5.0) -> bool:
	var timer = get_tree().create_timer(timeout)
	var signal_received = false
	
	# 连接信号
	var callable = func(): signal_received = true
	object.connect(signal_name, callable, CONNECT_ONE_SHOT)
	
	# 等待信号或超时
	await timer.timeout
	
	# 检查是否收到信号
	if not signal_received:
		# 断开信号连接
		if object.is_connected(signal_name, callable):
			object.disconnect(signal_name, callable)
		
		# 测试失败
		fail("等待信号超时: " + signal_name)
		return false
	
	return true

# 等待节点添加到场景树
func wait_for_node_added(parent: Node, node_name: String, timeout: float = 5.0) -> Node:
	var timer = get_tree().create_timer(timeout)
	var node = null
	
	# 等待节点添加或超时
	while not timer.is_stopped():
		node = parent.get_node_or_null(node_name)
		if node:
			return node
		await get_tree().process_frame
	
	# 测试失败
	fail("等待节点添加超时: " + node_name)
	return null

# 等待节点从场景树移除
func wait_for_node_removed(parent: Node, node_name: String, timeout: float = 5.0) -> bool:
	var timer = get_tree().create_timer(timeout)
	var node = parent.get_node_or_null(node_name)
	
	# 如果节点不存在，直接返回成功
	if not node:
		return true
	
	# 等待节点移除或超时
	while not timer.is_stopped():
		node = parent.get_node_or_null(node_name)
		if not node:
			return true
		await get_tree().process_frame
	
	# 测试失败
	fail("等待节点移除超时: " + node_name)
	return false

# 等待条件满足
func wait_for_condition(condition_callable: Callable, timeout: float = 5.0) -> bool:
	var timer = get_tree().create_timer(timeout)
	
	# 等待条件满足或超时
	while not timer.is_stopped():
		if condition_callable.call():
			return true
		await get_tree().process_frame
	
	# 测试失败
	fail("等待条件满足超时")
	return false
