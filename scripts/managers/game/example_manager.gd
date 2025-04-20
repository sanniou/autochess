extends "res://scripts/managers/core/base_manager.gd"
class_name ExampleManager
## 示例管理器
## 展示新的管理器系统的使用方式

# 示例数据
var example_data: Dictionary = {}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ExampleManager"

	# 添加依赖
	add_dependency("ConfigManager")
	add_dependency("PlayerManager")

	# 连接事件
	EventBus.game.connect_event("game_started", _on_game_started)
	EventBus.game.connect_event("game_ended", _on_game_ended)

	# 初始化数据
	_initialize_data()

	# 输出初始化完成信息
	_log_info("ExampleManager 初始化完成")

# 初始化数据
func _initialize_data() -> void:
	# 加载配置数据
	example_data = {
		"initialized": true,
		"timestamp": Time.get_unix_time_from_system()
	}

	# 输出数据初始化信息
	_log_info("示例数据初始化完成")

# 重写重置方法
func _do_reset() -> void:
	# 清空数据
	example_data.clear()

	# 重新初始化数据
	_initialize_data()

	# 输出重置完成信息
	_log_info("ExampleManager 重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.game.disconnect_event("game_started", _on_game_started)
	EventBus.game.disconnect_event("game_ended", _on_game_ended)

	# 清空数据
	example_data.clear()

	# 输出清理完成信息
	_log_info("ExampleManager 清理完成")

# 游戏开始事件处理
func _on_game_started() -> void:
	_log_info("游戏开始，更新示例数据")

	# 更新数据
	example_data["game_started"] = true
	example_data["start_time"] = Time.get_unix_time_from_system()

# 游戏结束事件处理
func _on_game_ended(win: bool) -> void:
	_log_info("游戏结束，更新示例数据")

	# 更新数据
	example_data["game_ended"] = true
	example_data["end_time"] = Time.get_unix_time_from_system()
	example_data["win"] = win

	# 计算游戏时长
	if example_data.has("start_time"):
		var duration = example_data["end_time"] - example_data["start_time"]
		example_data["duration"] = duration
		_log_info("游戏时长: " + str(duration) + " 秒")

# 获取示例数据
func get_example_data() -> Dictionary:
	return example_data

# 设置示例数据
func set_example_data(key: String, value) -> void:
	example_data[key] = value
	_log_info("设置示例数据: " + key + " = " + str(value))

# 清除示例数据
func clear_example_data() -> void:
	example_data.clear()
	_log_info("清除示例数据")

# 获取玩家管理器（示例依赖获取）
func get_player_manager():
	return get_manager("PlayerManager")
