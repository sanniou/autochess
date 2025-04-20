extends Node
class_name TestRunner
## 测试运行器
## 用于自动运行测试

# 信号
signal tests_started()
signal tests_completed(results)
signal test_progress(current, total)

# 测试状态
enum TestStatus {
	PENDING,   # 等待运行
	RUNNING,   # 正在运行
	PASSED,    # 通过
	FAILED     # 失败
}

# 测试场景列表
var test_scenes: Array = []

# 测试结果
var test_results: Dictionary = {}

# 当前运行的测试索引
var current_test_index: int = -1

# 是否正在运行测试
var is_running: bool = false

# 初始化
func _ready() -> void:
	pass

# 添加测试场景
func add_test_scene(scene_path: String) -> void:
	if not test_scenes.has(scene_path):
		test_scenes.append(scene_path)

# 添加多个测试场景
func add_test_scenes(scene_paths: Array) -> void:
	for scene_path in scene_paths:
		add_test_scene(scene_path)

# 清空测试场景
func clear_test_scenes() -> void:
	test_scenes.clear()

# 运行所有测试
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
			"time": 0.0
		}
	
	# 设置当前测试索引
	current_test_index = -1
	
	# 发送测试开始信号
	tests_started.emit()
	
	# 运行下一个测试
	_run_next_test()

# 运行下一个测试
func _run_next_test() -> void:
	# 增加当前测试索引
	current_test_index += 1
	
	# 检查是否所有测试都已运行
	if current_test_index >= test_scenes.size():
		# 发送测试完成信号
		tests_completed.emit(test_results)
		
		# 重置状态
		is_running = false
		current_test_index = -1
		
		return
	
	# 发送测试进度信号
	test_progress.emit(current_test_index, test_scenes.size())
	
	# 获取当前测试场景路径
	var scene_path = test_scenes[current_test_index]
	
	# 更新测试状态
	test_results[scene_path].status = TestStatus.RUNNING
	
	# 记录开始时间
	var start_time = Time.get_ticks_msec()
	
	# 加载测试场景
	var scene = load(scene_path)
	if not scene:
		# 更新测试结果
		test_results[scene_path].status = TestStatus.FAILED
		test_results[scene_path].message = "无法加载场景"
		
		# 运行下一个测试
		_run_next_test()
		return
	
	# 实例化测试场景
	var test_instance = scene.instantiate()
	
	# 检查测试场景是否有run_test方法
	if not test_instance.has_method("run_test"):
		# 更新测试结果
		test_results[scene_path].status = TestStatus.FAILED
		test_results[scene_path].message = "场景没有run_test方法"
		
		# 释放测试实例
		test_instance.queue_free()
		
		# 运行下一个测试
		_run_next_test()
		return
	
	# 添加测试实例到场景树
	add_child(test_instance)
	
	# 运行测试
	var result = await test_instance.run_test()
	
	# 记录结束时间
	var end_time = Time.get_ticks_msec()
	
	# 更新测试结果
	if result is bool:
		test_results[scene_path].status = TestStatus.PASSED if result else TestStatus.FAILED
	elif result is Dictionary:
		test_results[scene_path].status = result.get("status", TestStatus.FAILED)
		test_results[scene_path].message = result.get("message", "")
	else:
		test_results[scene_path].status = TestStatus.FAILED
		test_results[scene_path].message = "无效的测试结果"
	
	# 更新测试时间
	test_results[scene_path].time = (end_time - start_time) / 1000.0
	
	# 释放测试实例
	test_instance.queue_free()
	
	# 运行下一个测试
	_run_next_test()

# 停止测试
func stop_tests() -> void:
	# 如果没有运行测试，忽略
	if not is_running:
		return
	
	# 设置状态
	is_running = false
	
	# 更新剩余测试的状态
	for i in range(current_test_index + 1, test_scenes.size()):
		var scene_path = test_scenes[i]
		test_results[scene_path].status = TestStatus.PENDING
	
	# 发送测试完成信号
	tests_completed.emit(test_results)
	
	# 重置当前测试索引
	current_test_index = -1
