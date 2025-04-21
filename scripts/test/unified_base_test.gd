extends Node
class_name UnifiedBaseTest
## 统一测试基类
## 所有测试场景都应该继承这个基类

# 测试框架
var test_framework: UnifiedTestFramework = null

# 测试名称
var test_name: String = ""

# 测试描述
var test_description: String = ""

# 初始化
func _ready() -> void:
	# 创建测试框架
	test_framework = UnifiedTestFramework.new()
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

# 模拟输入
func simulate_input(action: String, pressed: bool = true) -> void:
	var event = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

# 模拟按键
func simulate_key(key: int, pressed: bool = true) -> void:
	var event = InputEventKey.new()
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

# 模拟鼠标点击
func simulate_mouse_click(position: Vector2, button_index: int = MOUSE_BUTTON_LEFT, pressed: bool = true) -> void:
	var event = InputEventMouseButton.new()
	event.position = position
	event.button_index = button_index
	event.pressed = pressed
	Input.parse_input_event(event)

# 模拟鼠标移动
func simulate_mouse_motion(position: Vector2, relative: Vector2 = Vector2.ZERO) -> void:
	var event = InputEventMouseMotion.new()
	event.position = position
	event.relative = relative
	Input.parse_input_event(event)

# 获取节点
func get_node_or_null(path: NodePath) -> Node:
	return get_node_or_null(path)

# 获取场景树
func get_tree() -> SceneTree:
	return get_tree()

# 获取当前场景
func get_current_scene() -> Node:
	return get_tree().current_scene

# 获取游戏管理器
func get_game_manager() -> Node:
	return Engine.get_singleton("GameManager")

# 获取管理器
func get_manager(manager_name: String) -> Node:
	var game_manager = get_game_manager()
	if game_manager:
		return game_manager.get_manager(manager_name)
	return null
