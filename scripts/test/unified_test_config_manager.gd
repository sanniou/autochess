extends "res://scripts/managers/core/base_manager.gd"
class_name UnifiedTestConfigManager
## 统一测试配置管理器
## 用于管理测试配置

# 测试配置
var test_config: Dictionary = {}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "UnifiedTestConfigManager"
	
	# 添加依赖
	add_dependency("ConfigManager")
	
	# 加载测试配置
	_load_test_config()
	
	_log_info("测试配置管理器初始化完成")

# 重写重置方法
func _do_reset() -> void:
	# 清空测试配置
	test_config.clear()
	
	_log_info("测试配置管理器已重置")

# 重写清理方法
func _do_cleanup() -> void:
	# 清空测试配置
	test_config.clear()
	
	_log_info("测试配置管理器已清理")

## 加载测试配置
func _load_test_config() -> void:
	# 获取配置管理器
	var config_manager = get_manager("ConfigManager")
	if not config_manager:
		_log_error("无法获取配置管理器")
		return
	
	# 加载测试配置
	var test_config_path = "res://config/test_config.json"
	if FileAccess.file_exists(test_config_path):
		test_config = config_manager.load_json(test_config_path)
	else:
		# 创建默认测试配置
		test_config = {
			"test_timeout": 10.0,
			"auto_discover": true,
			"test_scene_dir": "res://scenes/test",
			"test_script_dir": "res://scripts/test",
			"test_scene_suffix": "_test.tscn",
			"test_script_suffix": "_test.gd",
			"modules": {
				"core": {
					"enabled": true,
					"name": "核心系统",
					"description": "测试游戏的核心系统"
				},
				"game": {
					"enabled": true,
					"name": "游戏系统",
					"description": "测试游戏的核心玩法系统"
				},
				"ui": {
					"enabled": true,
					"name": "UI系统",
					"description": "测试游戏的UI系统"
				},
				"performance": {
					"enabled": true,
					"name": "性能测试",
					"description": "测试游戏的性能"
				}
			}
		}
		
		# 保存默认测试配置
		_save_test_config()

## 保存测试配置
func _save_test_config() -> void:
	# 获取配置管理器
	var config_manager = get_manager("ConfigManager")
	if not config_manager:
		_log_error("无法获取配置管理器")
		return
	
	# 保存测试配置
	var test_config_path = "res://config/test_config.json"
	config_manager.save_json(test_config_path, test_config)

## 获取测试超时时间
func get_test_timeout() -> float:
	return test_config.get("test_timeout", 10.0)

## 设置测试超时时间
func set_test_timeout(timeout: float) -> void:
	test_config["test_timeout"] = timeout
	_save_test_config()

## 获取是否自动发现测试
func get_auto_discover() -> bool:
	return test_config.get("auto_discover", true)

## 设置是否自动发现测试
func set_auto_discover(auto_discover: bool) -> void:
	test_config["auto_discover"] = auto_discover
	_save_test_config()

## 获取测试场景目录
func get_test_scene_dir() -> String:
	return test_config.get("test_scene_dir", "res://scenes/test")

## 设置测试场景目录
func set_test_scene_dir(dir: String) -> void:
	test_config["test_scene_dir"] = dir
	_save_test_config()

## 获取测试脚本目录
func get_test_script_dir() -> String:
	return test_config.get("test_script_dir", "res://scripts/test")

## 设置测试脚本目录
func set_test_script_dir(dir: String) -> void:
	test_config["test_script_dir"] = dir
	_save_test_config()

## 获取测试场景后缀
func get_test_scene_suffix() -> String:
	return test_config.get("test_scene_suffix", "_test.tscn")

## 设置测试场景后缀
func set_test_scene_suffix(suffix: String) -> void:
	test_config["test_scene_suffix"] = suffix
	_save_test_config()

## 获取测试脚本后缀
func get_test_script_suffix() -> String:
	return test_config.get("test_script_suffix", "_test.gd")

## 设置测试脚本后缀
func set_test_script_suffix(suffix: String) -> void:
	test_config["test_script_suffix"] = suffix
	_save_test_config()

## 获取测试模块配置
func get_module_config(module_id: String) -> Dictionary:
	if test_config.has("modules") and test_config.modules.has(module_id):
		return test_config.modules[module_id]
	return {}

## 设置测试模块配置
func set_module_config(module_id: String, config: Dictionary) -> void:
	if not test_config.has("modules"):
		test_config["modules"] = {}
	
	test_config.modules[module_id] = config
	_save_test_config()

## 获取所有测试模块配置
func get_all_module_configs() -> Dictionary:
	return test_config.get("modules", {})

## 获取测试配置
func get_test_config() -> Dictionary:
	return test_config
