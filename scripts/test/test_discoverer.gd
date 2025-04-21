extends Node
class_name TestDiscoverer
## 测试发现器
## 用于自动发现和注册测试

# 测试配置管理器
var test_config_manager: UnifiedTestConfigManager = null

# 测试场景目录
var test_scene_dir: String = "res://scenes/test"

# 测试脚本目录
var test_script_dir: String = "res://scripts/test"

# 测试场景后缀
var test_scene_suffix: String = "_test.tscn"

# 测试脚本后缀
var test_script_suffix: String = "_test.gd"

# 测试模块
var test_modules: Dictionary = {}

# 初始化
func _init() -> void:
	# 获取测试配置管理器
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		if game_manager.has_manager("UnifiedTestConfigManager"):
			test_config_manager = game_manager.get_manager("UnifiedTestConfigManager")

	# 如果有测试配置管理器，使用其配置
	if test_config_manager:
		test_scene_dir = test_config_manager.get_test_scene_dir()
		test_script_dir = test_config_manager.get_test_script_dir()
		test_scene_suffix = test_config_manager.get_test_scene_suffix()
		test_script_suffix = test_config_manager.get_test_script_suffix()

## 发现所有测试
func discover_all_tests() -> Dictionary:
	# 清空测试模块
	test_modules.clear()

	# 创建默认测试模块
	_create_default_modules()

	# 发现测试场景
	_discover_test_scenes()

	# 发现测试脚本
	_discover_test_scripts()

	return test_modules

## 创建默认测试模块
func _create_default_modules() -> void:
	# 如果有测试配置管理器，使用其模块配置
	if test_config_manager:
		var module_configs = test_config_manager.get_all_module_configs()
		for module_id in module_configs:
			var module_config = module_configs[module_id]
			if module_config.get("enabled", true):
				test_modules[module_id] = {
					"id": module_id,
					"name": module_config.get("name", module_id),
					"description": module_config.get("description", "测试" + module_id),
					"tests": {}
				}
	else:
		# 创建核心系统测试模块
		test_modules["core"] = {
			"id": "core",
			"name": "核心系统",
			"description": "测试游戏的核心系统",
			"tests": {}
		}

		# 创建游戏系统测试模块
		test_modules["game"] = {
			"id": "game",
			"name": "游戏系统",
			"description": "测试游戏的核心玩法系统",
			"tests": {}
		}

		# 创建UI测试模块
		test_modules["ui"] = {
			"id": "ui",
			"name": "UI系统",
			"description": "测试游戏的UI系统",
			"tests": {}
		}

		# 创建性能测试模块
		test_modules["performance"] = {
			"id": "performance",
			"name": "性能测试",
			"description": "测试游戏的性能",
			"tests": {}
		}

## 发现测试场景
func _discover_test_scenes() -> void:
	# 获取测试场景目录
	var dir = DirAccess.open(test_scene_dir)
	if not dir:
		print("无法打开测试场景目录: " + test_scene_dir)
		return

	# 遍历目录
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# 检查是否是测试场景
		if file_name.ends_with(test_scene_suffix):
			# 获取测试ID
			var test_id = file_name.substr(0, file_name.length() - test_scene_suffix.length())

			# 获取测试名称
			var test_name = test_id.replace("_", " ").capitalize()

			# 获取测试描述
			var test_description = "测试 " + test_name

			# 获取测试场景路径
			var scene_path = test_scene_dir + "/" + file_name

			# 确定测试模块
			var module_id = _determine_module_for_test(test_id)

			# 添加测试
			test_modules[module_id].tests[test_id] = {
				"id": test_id,
				"name": test_name,
				"description": test_description,
				"scene_path": scene_path
			}

		# 获取下一个文件
		file_name = dir.get_next()

	# 结束遍历
	dir.list_dir_end()

## 发现测试脚本
func _discover_test_scripts() -> void:
	# 获取测试脚本目录
	var dir = DirAccess.open(test_script_dir)
	if not dir:
		print("无法打开测试脚本目录: " + test_script_dir)
		return

	# 遍历目录
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# 检查是否是测试脚本
		if file_name.ends_with(test_script_suffix):
			# 获取测试ID
			var test_id = file_name.substr(0, file_name.length() - test_script_suffix.length())

			# 获取测试名称
			var test_name = test_id.replace("_", " ").capitalize()

			# 获取测试描述
			var test_description = "测试 " + test_name

			# 获取测试脚本路径
			var script_path = test_script_dir + "/" + file_name

			# 确定测试模块
			var module_id = _determine_module_for_test(test_id)

			# 检查是否已经添加了这个测试
			if not test_modules[module_id].tests.has(test_id):
				# 添加测试
				test_modules[module_id].tests[test_id] = {
					"id": test_id,
					"name": test_name,
					"description": test_description,
					"script_path": script_path
				}
			else:
				# 更新测试
				test_modules[module_id].tests[test_id].script_path = script_path

		# 获取下一个文件
		file_name = dir.get_next()

	# 结束遍历
	dir.list_dir_end()

## 确定测试所属的模块
func _determine_module_for_test(test_id: String) -> String:
	# 根据测试ID确定模块
	if test_id.begins_with("core_") or test_id.begins_with("event_") or test_id.begins_with("save_") or test_id.begins_with("config_") or test_id.begins_with("manager_") or test_id.begins_with("resource_") or test_id.begins_with("object_pool_") or test_id.begins_with("example_"):
		return "core"
	elif test_id.begins_with("game_") or test_id.begins_with("board_") or test_id.begins_with("battle_") or test_id.begins_with("chess_") or test_id.begins_with("ability_") or test_id.begins_with("equipment_") or test_id.begins_with("map_") or test_id.begins_with("event_") or test_id.begins_with("shop_") or test_id.begins_with("relic_") or test_id.begins_with("synergy_") or test_id.begins_with("curse_") or test_id.begins_with("story_"):
		return "game"
	elif test_id.begins_with("ui_") or test_id.begins_with("animation_") or test_id.begins_with("environment_") or test_id.begins_with("hud_") or test_id.begins_with("menu_") or test_id.begins_with("dialog_") or test_id.begins_with("notification_") or test_id.begins_with("tooltip_"):
		return "ui"
	elif test_id.begins_with("performance_") or test_id.begins_with("benchmark_") or test_id.begins_with("stress_"):
		return "performance"
	else:
		# 默认为游戏系统测试
		return "game"
