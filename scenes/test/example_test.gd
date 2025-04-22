extends BaseTest
## 示例测试
## 展示如何使用测试框架

# 测试数据
var test_array = [1, 2, 3, 4, 5]
var test_dict = {"a": 1, "b": 2, "c": 3}
var test_node: Node = null

# 重写测试名称和描述
func _init() -> void:
	test_name = "示例测试"
	test_description = "展示如何使用测试框架的各种功能"

# 测试前的准备
func _setup() -> void:
	# 创建测试节点
	test_node = Node.new()
	test_node.name = "TestNode"
	add_child(test_node)
	
	# 添加自定义属性
	test_node.set_meta("test_value", 42)

# 运行测试
func _run() -> void:
	# 基本断言
	assert_equal(2 + 2, 4, "基本算术")
	assert_not_equal(2 + 2, 5, "基本算术")
	assert_true(true, "真值断言")
	assert_false(false, "假值断言")
	
	# 空值断言
	var null_value = null
	var non_null_value = "not null"
	assert_null(null_value, "空值断言")
	assert_not_null(non_null_value, "非空值断言")
	
	# 数值比较断言
	assert_greater_than(5, 3, "大于断言")
	assert_less_than(3, 5, "小于断言")
	assert_greater_than_or_equal(5, 5, "大于等于断言")
	assert_less_than_or_equal(3, 3, "小于等于断言")
	assert_almost_equal(0.1 + 0.2, 0.3, 0.0001, "浮点数近似相等断言")
	
	# 容器断言
	assert_contains(test_array, 3, "数组包含断言")
	assert_not_contains(test_array, 6, "数组不包含断言")
	assert_contains(test_dict, "b", "字典包含断言")
	assert_not_contains(test_dict, "d", "字典不包含断言")
	
	# 类型断言
	assert_type(test_array, "Array", "类型断言 - 数组")
	assert_type(test_dict, "Dictionary", "类型断言 - 字典")
	assert_type(test_node, "Node", "类型断言 - 节点")
	
	# 节点断言
	assert_not_null(get_node_or_null("TestNode"), "节点存在断言")
	assert_equal(test_node.get_meta("test_value"), 42, "节点元数据断言")
	
	# 异步测试
	await _run_async_tests()

# 异步测试
func _run_async_tests() -> void:
	# 等待时间
	print("等待 1 秒...")
	await wait(1.0)
	print("等待时间成功")
	
	# 等待信号
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.5
	add_child(timer)
	
	print("等待计时器信号...")
	timer.start()
	var signal_result = await wait_for_signal(timer, "timeout")
	assert_true(signal_result, "等待信号成功")
	
	# 等待条件
	var counter = 0
	var condition = func(): 
		counter += 1
		return counter >= 10
	
	print("等待条件满足...")
	var condition_result = await wait_for_condition(condition, 1.0)
	assert_true(condition_result, "等待条件成功")
	assert_greater_than_or_equal(counter, 10, "条件计数器值正确")
	
	# 清理
	timer.queue_free()

# 测试后的清理
func _teardown() -> void:
	# 移除测试节点
	if test_node and is_instance_valid(test_node):
		test_node.queue_free()
		test_node = null
