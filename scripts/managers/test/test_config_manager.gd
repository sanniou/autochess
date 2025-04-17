extends "res://scripts/managers/core/base_manager.gd"
## 配置管理器测试脚本
## 用于测试配置管理器是否能正确加载配置文件

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "TestConfigManager"
	# 添加依赖
	add_dependency("ConfigManager")

	# 原 _ready 函数的内容
	# 获取配置管理器
	var config_manager = get_node("/root/ConfigManager")

	# 测试加载所有配置文件
	print("测试加载所有配置文件...")

	# 测试棋子配置
	var chess_pieces = config_manager.get_all_chess_pieces()
	print("棋子配置数量: ", chess_pieces.size())

	# 测试装备配置
	var equipment = config_manager.get_all_equipment()
	print("装备配置数量: ", equipment.size())

	# 测试遗物配置
	var relics = config_manager.get_all_relics()
	print("遗物配置数量: ", relics.size())

	# 测试事件配置
	var events = config_manager.get_all_events()
	print("事件配置数量: ", events.size())

	# 测试羁绊配置
	var synergies = config_manager.get_all_synergies()
	print("羁绊配置数量: ", synergies.size())

	# 测试难度配置
	var difficulty = config_manager.get_difficulty_config(1)
	print("难度配置: ", difficulty)

	# 测试成就配置
	var achievements = config_manager.get_all_achievements()
	print("成就配置数量: ", achievements.size())

	# 测试皮肤配置
	var skins = config_manager.get_all_skins()
	print("皮肤配置数量: ", skins.size())

	# 测试获取所有配置文件
	var all_configs = config_manager.get_all_config_files()
	print("所有配置文件: ", all_configs)

	# 测试加载任意配置文件
	var test_config = config_manager.load_json("res://config/chess_pieces.json")
	print("测试加载棋子配置: ", test_config.size())

	print("配置管理器测试完成!")
# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])
