extends "res://scripts/managers/core/base_manager.gd"
class_name StandardManagerTemplate
## 标准管理器模板
## 所有管理器应参考此模板实现

# 信号
signal example_signal(param)

# 管理器数据
var example_data: Dictionary = {}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "StandardManagerTemplate"
	
	# 添加依赖
	add_dependency("ConfigManager")
	
	# 连接事件
	EventBus.game.connect_event("game_started", _on_game_started)
	
	# 初始化数据
	_initialize_data()
	
	_log_info("管理器初始化完成")

# 初始化数据
func _initialize_data() -> void:
	# 初始化数据
	example_data = {
		"initialized": true,
		"timestamp": Time.get_unix_time_from_system()
	}

# 重写重置方法
func _do_reset() -> void:
	# 清空数据
	example_data.clear()
	
	# 重新初始化数据
	_initialize_data()
	
	_log_info("管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.game.disconnect_event("game_started", _on_game_started)
	
	# 清空数据
	example_data.clear()
	
	_log_info("管理器清理完成")

# 事件处理方法
func _on_game_started() -> void:
	_log_info("游戏开始事件处理")

