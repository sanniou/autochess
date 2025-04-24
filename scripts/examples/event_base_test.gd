extends Node
## 事件基类改进测试

# 简单事件类，不需要实现 get_type() 和 clone()
class SimpleEvent extends BusEvent:
	var data: String
	
	func _init(p_data: String = ""):
		data = p_data

# 测试函数
func test_event_base_improvements() -> void:
	print("测试事件基类改进...")
	
	# 测试简单事件
	var simple_event = SimpleEvent.new("test data")
	print("事件类型: " + simple_event.get_type())  # 应该自动推断为 "event.simple"
	print("事件字符串: " + str(simple_event))  # 应该显示所有属性
	
	# 测试克隆
	var cloned_event = simple_event.clone()
	print("克隆事件类型: " + cloned_event.get_type())
	print("克隆事件字符串: " + str(cloned_event))
	print("克隆事件数据: " + cloned_event.data)
	
	print("测试完成!")

# 初始化
func _ready() -> void:
	test_event_base_improvements()
