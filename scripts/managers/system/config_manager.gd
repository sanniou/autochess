extends "res://scripts/managers/core/base_manager.gd"

class_name ConfigManager
## 配置管理器
## 负责加载、验证和管理游戏配置数据

# 配置数据模型
var _config_models: Dictionary = {}

# 配置数据缓存
var _config_cache: Dictionary = {}

# 配置文件路径
var _config_paths: Dictionary = {}

# 配置模型类映射
var _config_model_classes: Dictionary = {}

# 配置目录
var _config_dir: String = "res://config/"

# 是否处于调试模式
var debug_mode: bool = false

# 是否启用热重载
var hot_reload_enabled: bool = false

# 配置文件监视器
var _file_watcher: Timer = null

# 文件修改时间缓存
var _file_modified_times: Dictionary = {}

# 配置类型映射（枚举值到字符串）
var _config_type_map: Dictionary = {}

# 配置变更信号
signal config_loaded(config_type: String)
signal config_reloaded(config_type: String)
signal config_validated(config_type: String, is_valid: bool, errors: Array)
signal config_changed(config_type: String, config_id: String)
signal all_configs_loaded()
signal all_configs_reloaded()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ConfigManager"

	# 设置调试模式
	debug_mode = OS.is_debug_build()

	# 初始化配置类型映射
	_initialize_config_type_map()

	# 注册默认配置类型
	_register_default_config_types()

	# 加载所有配置
	load_all_configs()

	# 初始化文件监视器
	_initialize_file_watcher()

	# 输出初始化完成信息
	_log_info("ConfigManager 初始化完成")

## 自动发现和注册配置
func _discover_and_register_configs() -> void:
	# 使用配置发现工具扫描配置目录
	var discovered_configs = ConfigDiscovery.discover_configs(_config_dir)

	# 记录发现的配置数量
	var discovered_count = 0

	# 注册发现的配置
	for config_type in discovered_configs:
		# 检查是否已经注册
		if not _config_paths.has(config_type):
			var file_path = discovered_configs[config_type]
			var model_class_path = ConfigDiscovery.get_model_class_path(config_type)

			# 检查模型类是否存在
			if ResourceLoader.exists(model_class_path):
				register_config_type(config_type, file_path, model_class_path)
			else:
				# 使用默认模型类
				register_config_type(config_type, file_path)

			discovered_count += 1

	_log_info("自动发现并注册了 " + str(discovered_count) + " 个配置类型")

## 初始化配置类型映射
func _initialize_config_type_map() -> void:
	# 遍历所有配置类型枚举值
	for type_value in ConfigTypes.Type.values():
		# 将枚举值映射到字符串
		_config_type_map[type_value] = ConfigTypes.int_to_string(type_value)

## 初始化文件监视器
func _initialize_file_watcher() -> void:
	# 如果已经创建了监视器，则返回
	if _file_watcher != null:
		return

	# 创建定时器
	_file_watcher = Timer.new()
	_file_watcher.name = "ConfigFileWatcher"
	_file_watcher.wait_time = 2.0  # 每2秒检查一次
	_file_watcher.autostart = false
	_file_watcher.one_shot = false
	add_child(_file_watcher)

	# 连接定时器超时信号
	_file_watcher.timeout.connect(_check_config_files)

	# 缓存所有配置文件的修改时间
	_cache_file_modified_times()

	# 如果在调试模式下，默认启用热重载
	if debug_mode:
		enable_hot_reload(true)

## 缓存所有配置文件的修改时间
func _cache_file_modified_times() -> void:
	_file_modified_times.clear()

	# 遍历所有配置文件路径
	for config_type in _config_paths:
		var file_path = _config_paths[config_type]

		# 检查文件是否存在
		if FileAccess.file_exists(file_path):
			# 获取文件修改时间
			var modified_time = FileAccess.get_modified_time(file_path)
			_file_modified_times[file_path] = modified_time

## 检查配置文件是否发生变化
func _check_config_files() -> void:
	# 如果没有启用热重载，则返回
	if not hot_reload_enabled:
		return

	# 遍历所有配置文件路径
	for config_type in _config_paths:
		var file_path = _config_paths[config_type]

		# 检查文件是否存在
		if FileAccess.file_exists(file_path):
			# 获取文件当前修改时间
			var current_modified_time = FileAccess.get_modified_time(file_path)

			# 获取缓存的修改时间
			var cached_modified_time = _file_modified_times.get(file_path, 0)

			# 如果文件已经被修改
			if current_modified_time > cached_modified_time:
				_log_info("检测到配置文件变化: " + file_path)

				# 重新加载配置
				reload_config(config_type)

				# 更新缓存的修改时间
				_file_modified_times[file_path] = current_modified_time

## 启用或禁用热重载
func enable_hot_reload(enabled: bool = true) -> void:
	hot_reload_enabled = enabled

	if hot_reload_enabled:
		# 启动文件监视器
		if _file_watcher:
			_file_watcher.start()
			_log_info("配置热重载已启用")
	else:
		# 停止文件监视器
		if _file_watcher:
			_file_watcher.stop()
			_log_info("配置热重载已禁用")

## 注册默认配置类型
func _register_default_config_types() -> void:
	# 注册棋子配置
	register_config_type_enum(
		ConfigTypes.Type.CHESS_PIECES,
		"res://config/chess_pieces.json",
		"res://scripts/config/models/chess_piece_config.gd"
	)

	# 注册装备配置
	register_config_type_enum(
		ConfigTypes.Type.EQUIPMENT,
		"res://config/equipment.json",
		"res://scripts/config/models/equipment_config.gd"
	)

	# 注册地图配置
	register_config_type_enum(
		ConfigTypes.Type.MAP_CONFIG,
		"res://config/map_config.json",
		"res://scripts/config/models/map_config.gd"
	)

	# 注册遗物配置
	register_config_type_enum(
		ConfigTypes.Type.RELICS,
		"res://config/relics/relics.json",
		"res://scripts/config/models/relic_config.gd"
	)

	# 注册羁绊配置
	register_config_type_enum(
		ConfigTypes.Type.SYNERGIES,
		"res://config/synergies.json",
		"res://scripts/config/models/synergy_config.gd"
	)

	# 注册事件配置
	register_config_type_enum(
		ConfigTypes.Type.EVENTS,
		"res://config/events/events.json",
		"res://scripts/config/models/event_config.gd"
	)

	# 注册难度配置
	register_config_type_enum(
		ConfigTypes.Type.DIFFICULTY,
		"res://config/difficulty.json",
		"res://scripts/config/models/difficulty_config.gd"
	)

	# 注册成就配置
	register_config_type_enum(
		ConfigTypes.Type.ACHIEVEMENTS,
		"res://config/achievements.json",
		"res://scripts/config/models/achievement_config.gd"
	)

	# 注册皮肤配置
	register_config_type_enum(
		ConfigTypes.Type.SKINS,
		"res://config/skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

	# 注册教程配置
	register_config_type_enum(
		ConfigTypes.Type.TUTORIALS,
		"res://config/tutorials.json",
		"res://scripts/config/models/tutorial_config.gd"
	)

	# 注册动画配置
	register_config_type_enum(
		ConfigTypes.Type.ANIMATION_CONFIG,
		"res://config/animations/animation_config.json",
		"res://scripts/config/models/animation_config.gd"
	)

	# 注册环境效果配置
	register_config_type_enum(
		ConfigTypes.Type.ENVIRONMENT_EFFECTS,
		"res://config/effects/environment_effects.json",
		"res://scripts/config/models/effect_config.gd"
	)

	# 注册技能效果配置
	register_config_type_enum(
		ConfigTypes.Type.SKILL_EFFECTS,
		"res://config/effects/skill_effects.json",
		"res://scripts/config/models/effect_config.gd"
	)

	# 注册棋盘皮肤配置
	register_config_type_enum(
		ConfigTypes.Type.BOARD_SKINS,
		"res://config/skins/board_skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

	# 注册棋子皮肤配置
	register_config_type_enum(
		ConfigTypes.Type.CHESS_SKINS,
		"res://config/skins/chess_skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

	# 注册UI皮肤配置
	register_config_type_enum(
		ConfigTypes.Type.UI_SKINS,
		"res://config/skins/ui_skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

## 注册配置类型（使用枚举）
## 注册一个新的配置类型，指定其文件路径和模型类
## @param config_type 配置类型枚举
## @param file_path 配置文件路径
## @param model_class_path 配置模型类路径
func register_config_type_enum(config_type: int, file_path: String, model_class_path: String = "") -> void:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return

	# 检查文件路径是否有效
	if file_path.is_empty():
		push_error("致命错误: 配置文件路径为空 - " + str(config_type))
		assert(false, "配置文件路径为空")
		return

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 注册配置路径
	_config_paths[type_str] = file_path

	# 注册配置模型类
	if not model_class_path.is_empty():
		_config_model_classes[type_str] = model_class_path

	_log_info("注册配置类型: " + type_str + " -> " + file_path)

## 注册配置类型
## 注册一个新的配置类型，指定其文件路径和模型类
func register_config_type(config_type: String, file_path: String, model_class_path: String = "") -> void:
	# 注册配置路径
	_config_paths[config_type] = file_path

	# 注册配置模型类
	if not model_class_path.is_empty():
		_config_model_classes[config_type] = model_class_path

	_log_info("注册配置类型: " + config_type + " -> " + file_path)

## 取消注册配置类型（使用枚举）
## 取消注册指定类型的配置
## @param config_type 配置类型枚举
func unregister_config_type_enum(config_type: int) -> void:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 检查配置类型是否已注册
	if not _config_paths.has(type_str):
		push_warning("取消注册配置类型失败: 配置类型未注册 - " + type_str)
		return

	# 移除配置路径
	_config_paths.erase(type_str)

	# 移除配置模型类
	if _config_model_classes.has(type_str):
		_config_model_classes.erase(type_str)

	# 清除缓存
	if _config_cache.has(type_str):
		_config_cache.erase(type_str)

	# 清除模型
	if _config_models.has(type_str):
		_config_models.erase(type_str)

	_log_info("取消注册配置类型: " + type_str)

## 取消注册配置类型
func unregister_config_type(config_type: String) -> void:
	# 检查配置类型是否存在
	if not _config_paths.has(config_type):
		_log_warning("取消注册配置类型失败: 配置类型不存在 - " + config_type)
		return

	# 移除配置路径
	_config_paths.erase(config_type)

	# 移除配置模型类
	if _config_model_classes.has(config_type):
		_config_model_classes.erase(config_type)

	# 清除缓存
	if _config_cache.has(config_type):
		_config_cache.erase(config_type)

	# 清除模型
	if _config_models.has(config_type):
		_config_models.erase(config_type)

	_log_info("取消注册配置类型: " + config_type)

## 加载所有配置文件
## 加载所有已注册的配置文件
func load_all_configs() -> void:
	# 加载配置模型类
	_load_config_model_classes()

	# 加载所有配置文件
	for config_type in _config_type_map:
		var type_str = _config_type_map[config_type]

		# 检查配置类型是否已注册
		if _config_paths.has(type_str):
			load_config_enum(config_type)

	# 验证所有配置文件
	if debug_mode:
		validate_all_configs()

	_log_info("所有配置加载完成")
	all_configs_loaded.emit()

## 加载配置模型类
## 加载所有已注册的配置模型类
func _load_config_model_classes() -> void:
	# 加载基础配置模型类
	var base_model_path = "res://scripts/config/config_model.gd"
	if not ResourceLoader.exists(base_model_path):
		push_error("致命错误: 基础配置模型类不存在 - " + base_model_path)
		assert(false, "基础配置模型类不存在")
		return

	var base_model = load(base_model_path)

	# 加载所有配置模型类
	for config_type in _config_model_classes:
		var model_path = _config_model_classes[config_type]

		# 检查文件是否存在
		if ResourceLoader.exists(model_path):
			var model_class = load(model_path)
			_config_models[config_type] = model_class
		else:
			# 如果模型类不存在，使用基础模型类
			_config_models[config_type] = base_model

			if debug_mode:
				push_warning("配置模型类不存在: " + model_path + "，使用基础模型类")

## 验证所有配置文件
## 验证所有已加载的配置数据是否符合要求
## @return 是否所有配置都验证通过
func validate_all_configs() -> bool:
	var all_valid = true
	var all_errors = []

	# 遍历所有配置类型枚举
	for config_type in _config_type_map:
		var type_str = _config_type_map[config_type]

		# 检查配置是否已加载
		if not _config_cache.has(type_str):
			continue

		# 验证配置
		var result = validate_config_enum(config_type)
		if not result.valid:
			all_valid = false
			all_errors.append_array(result.errors)

	if not all_valid:
		_log_warning("配置验证失败: " + str(all_errors.size()) + " 个错误")
		for error in all_errors:
			_log_warning(error)
	else:
		_log_info("所有配置验证通过")

	return all_valid

## 验证配置文件（使用枚举）
## 验证指定类型的配置数据是否符合要求
## @param config_type 配置类型枚举
## @return 验证结果，包含是否成功和错误信息
func validate_config_enum(config_type: int) -> Dictionary:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		var error = "验证配置失败: 无效的配置类型枚举 - " + str(config_type)
		push_error("致命错误: " + error)
		assert(false, "配置类型不存在")
		return {
			"valid": false,
			"errors": [error]
		}

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 获取配置数据
	if not _config_cache.has(type_str):
		var error = "验证配置失败: 配置类型未加载 - " + type_str
		push_error("致命错误: " + error)
		assert(false, "配置类型未加载")
		return {
			"valid": false,
			"errors": [error]
		}

	var config_data = _config_cache[type_str]

	# 获取配置模型类
	var model_class = _config_models.get(type_str)
	if not model_class:
		var error = "验证配置失败: 配置模型类不存在 - " + type_str
		push_error("致命错误: " + error)
		assert(false, "配置模型类不存在")
		return {
			"valid": false,
			"errors": [error]
		}

	# 验证配置数据
	var errors = []
	var all_valid = true

	for config_id in config_data:
		var model = model_class.new(config_id, config_data[config_id])
		if not model.validation_errors.is_empty():
			all_valid = false
			for error in model.validation_errors:
				errors.append(type_str + "." + config_id + ": " + error)

	# 发送验证结果信号
	config_validated.emit(type_str, all_valid, errors)

	if not all_valid:
		_log_warning("配置验证失败: " + type_str + " - " + str(errors.size()) + " 个错误")
		for error in errors:
			_log_warning(error)
	else:
		_log_info("配置验证通过: " + type_str)

	return {
		"valid": all_valid,
		"errors": errors
	}

# 以下方法已弃用，请使用 validate_config_enum 代替
func validate_config(config_type: String) -> Dictionary:
	push_warning("弃用警告: validate_config 已弃用，请使用 validate_config_enum 代替")

	# 尝试将字符串转换为枚举
	var enum_type = ConfigTypes.from_string(config_type)
	if enum_type != -1:
		return validate_config_enum(enum_type)

	# 如果无法转换，使用旧的实现
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		var error = "验证配置失败: 配置类型不存在 - " + config_type
		_log_warning(error)
		return {
			"valid": false,
			"errors": [error]
		}

	# 获取配置数据
	var config_data = _config_cache[config_type]

	# 获取配置模型类
	var model_class = _config_models.get(config_type)
	if not model_class:
		var error = "验证配置失败: 配置模型类不存在 - " + config_type
		_log_warning(error)
		return {
			"valid": false,
			"errors": [error]
		}

	# 验证配置数据
	var errors = []
	var all_valid = true

	for config_id in config_data:
		var model = model_class.new(config_id, config_data[config_id])
		if not model.validation_errors.is_empty():
			all_valid = false
			for error in model.validation_errors:
				errors.append(config_type + "." + config_id + ": " + error)

	# 发送验证结果信号
	config_validated.emit(config_type, all_valid, errors)

	if not all_valid:
		_log_warning("配置验证失败: " + config_type + " - " + str(errors.size()) + " 个错误")
		for error in errors:
			_log_warning(error)
	else:
		_log_info("配置验证通过: " + config_type)

	return {
		"valid": all_valid,
		"errors": errors
	}

## 加载配置文件（使用枚举）
## 加载指定类型的配置文件
## @param config_type 配置类型枚举
## @return 是否加载成功
func load_config_enum(config_type: int) -> bool:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return false

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 检查配置类型是否已注册
	if not _config_paths.has(type_str):
		push_error("致命错误: 配置类型未注册 - " + type_str)
		assert(false, "配置类型未注册")
		return false

	# 获取配置文件路径
	var file_path = _config_paths[type_str]

	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("致命错误: 配置文件不存在 - " + file_path)
		assert(false, "配置文件不存在")
		return false

	# 加载配置文件
	var config_data = _load_json_file(file_path)
	if config_data.is_empty():
		push_error("致命错误: 配置文件为空 - " + file_path)
		assert(false, "配置文件为空")
		return false

	# 缓存配置数据
	_config_cache[type_str] = config_data

	_log_info(type_str + " 配置加载完成")
	config_loaded.emit(type_str)
	return true

## 加载配置文件
func load_config(config_type: String) -> bool:
	# 检查配置类型是否有效
	if not _config_paths.has(config_type):
		_log_warning("加载配置失败: 无效的配置类型 - " + config_type)
		return false

	# 获取配置文件路径
	var file_path = _config_paths[config_type]

	# 加载配置文件
	var config_data = _load_json_file(file_path)
	if config_data.is_empty():
		_log_warning("加载配置失败: 配置文件为空 - " + file_path)
		return false

	# 缓存配置数据
	_config_cache[config_type] = config_data

	_log_info(config_type + " 配置加载完成")
	config_loaded.emit(config_type)
	return true

## 加载JSON文件
## 加载并解析JSON文件
## @param file_path JSON文件路径
## @return JSON数据字典
static func _load_json_file(file_path: String) -> Dictionary:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("致命错误: JSON文件不存在 - " + file_path)
		assert(false, "JSON文件不存在")
		return {}

	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("致命错误: 无法打开JSON文件 - " + file_path + ", 错误码: " + str(FileAccess.get_open_error()))
		assert(false, "无法打开JSON文件")
		return {}

	# 读取文件内容
	var json_text = file.get_as_text()
	file.close()

	# 检查文件内容是否为空
	if json_text.is_empty():
		push_error("致命错误: JSON文件为空 - " + file_path)
		assert(false, "JSON文件为空")
		return {}

	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("致命错误: JSON解析错误 - " + file_path + " - " + json.get_error_message() + " at line " + str(json.get_error_line()))
		assert(false, "JSON解析错误")
		return {}

	# 获取解析结果
	var result = json.get_data()
	if not result is Dictionary:
		push_error("致命错误: JSON根节点不是字典 - " + file_path)
		assert(false, "JSON根节点不是字典")
		return {}

	return result

## 获取配置项（使用枚举）
## 根据配置类型枚举和ID获取配置项
## @param config_type 配置类型枚举
## @param config_id 配置ID
## @return 配置项数据
func get_config_item_enum(config_type: int, config_id: String) -> Dictionary:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return {}

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 获取配置数据
	if not _config_cache.has(type_str):
		push_error("致命错误: 配置类型未加载 - " + type_str)
		assert(false, "配置类型未加载")
		return {}

	var config_data = _config_cache[type_str]

	# 检查配置ID是否存在
	if not config_data.has(config_id):
		push_error("致命错误: 配置ID不存在 - " + type_str + "." + config_id)
		assert(false, "配置ID不存在")
		return {}

	return config_data[config_id].duplicate(true)

# 以下方法已弃用，请使用 get_config_item_enum 代替
func get_config_item(config_type: String, config_id: String) -> Dictionary:
	push_warning("弃用警告: get_config_item 已弃用，请使用 get_config_item_enum 代替")

	# 尝试将字符串转换为枚举
	var enum_type = ConfigTypes.from_string(config_type)
	if enum_type != -1:
		return get_config_item_enum(enum_type, config_id)

	# 如果无法转换，使用旧的实现
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		_log_warning("获取配置项失败: 配置类型不存在 - " + config_type)
		return {}

	# 获取配置数据
	var config_data = _config_cache[config_type]

	# 检查配置ID是否存在
	if not config_data.has(config_id):
		_log_warning("获取配置项失败: 配置ID不存在 - " + config_type + "." + config_id)
		return {}

	return config_data[config_id].duplicate(true)

## 获取配置模型（使用枚举）
## 根据配置类型枚举和ID获取配置模型对象
## @param config_type 配置类型枚举
## @param config_id 配置ID
## @return 配置模型对象
func get_config_model_enum(config_type: int, config_id: String) -> ConfigModel:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return null

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 获取配置数据
	if not _config_cache.has(type_str):
		push_error("致命错误: 配置类型未加载 - " + type_str)
		assert(false, "配置类型未加载")
		return null

	var config_data = _config_cache[type_str]

	# 检查配置ID是否存在
	if not config_data.has(config_id):
		push_error("致命错误: 配置ID不存在 - " + type_str + "." + config_id)
		assert(false, "配置ID不存在")
		return null

	# 获取配置模型类
	var model_class = _config_models.get(type_str)
	if not model_class:
		push_error("致命错误: 配置模型类不存在 - " + type_str)
		assert(false, "配置模型类不存在")
		return null

	# 创建配置模型
	return model_class.new(config_id, config_data[config_id])

# 以下方法已弃用，请使用 get_config_model_enum 代替
func get_config_model(config_type: String, config_id: String) -> ConfigModel:
	push_warning("弃用警告: get_config_model 已弃用，请使用 get_config_model_enum 代替")

	# 尝试将字符串转换为枚举
	var enum_type = ConfigTypes.from_string(config_type)
	if enum_type != -1:
		return get_config_model_enum(enum_type, config_id)

	# 如果无法转换，使用旧的实现
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		_log_warning("获取配置模型失败: 配置类型不存在 - " + config_type)
		return null

	# 获取配置模型类
	var model_class = _config_models.get(config_type)
	if not model_class:
		_log_warning("获取配置模型失败: 配置模型类不存在 - " + config_type)
		return null

	# 获取配置数据
	var config_data = _config_cache[config_type]

	# 检查配置ID是否存在
	if not config_data.has(config_id):
		_log_warning("获取配置模型失败: 配置ID不存在 - " + config_type + "." + config_id)
		return null

	# 创建配置模型
	return model_class.new(config_id, config_data[config_id])

## 获取所有配置项（使用枚举）
## 根据配置类型枚举获取所有配置项
## @param config_type 配置类型枚举
## @return 配置项字典，键为配置ID，值为配置数据
func get_all_config_items_enum(config_type: int) -> Dictionary:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return {}

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 获取配置数据
	if not _config_cache.has(type_str):
		push_error("致命错误: 配置类型未加载 - " + type_str)
		assert(false, "配置类型未加载")
		return {}

	return _config_cache[type_str].duplicate(true)

# 以下方法已弃用，请使用 get_all_config_items_enum 代替
func get_all_config_items(config_type: String) -> Dictionary:
	push_warning("弃用警告: get_all_config_items 已弃用，请使用 get_all_config_items_enum 代替")

	# 尝试将字符串转换为枚举
	var enum_type = ConfigTypes.from_string(config_type)
	if enum_type != -1:
		return get_all_config_items_enum(enum_type)

	# 如果无法转换，使用旧的实现
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		_log_warning("获取所有配置项失败: 配置类型不存在 - " + config_type)
		return {}

	return _config_cache[config_type].duplicate(true)

## 获取所有配置模型（使用枚举）
## 根据配置类型枚举获取所有配置模型对象
## @param config_type 配置类型枚举
## @return 配置模型对象字典，键为配置ID，值为配置模型对象
func get_all_config_models_enum(config_type: int) -> Dictionary:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return {}

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 获取配置数据
	if not _config_cache.has(type_str):
		push_error("致命错误: 配置类型未加载 - " + type_str)
		assert(false, "配置类型未加载")
		return {}

	var config_data = _config_cache[type_str]

	# 获取配置模型类
	var model_class = _config_models.get(type_str)
	if not model_class:
		push_error("致命错误: 配置模型类不存在 - " + type_str)
		assert(false, "配置模型类不存在")
		return {}

	# 创建配置模型
	var models = {}
	for config_id in config_data:
		models[config_id] = model_class.new(config_id, config_data[config_id])

	return models

# 以下方法已弃用，请使用 get_all_config_models_enum 代替
func get_all_config_models(config_type: String) -> Dictionary:
	push_warning("弃用警告: get_all_config_models 已弃用，请使用 get_all_config_models_enum 代替")

	# 尝试将字符串转换为枚举
	var enum_type = ConfigTypes.from_string(config_type)
	if enum_type != -1:
		return get_all_config_models_enum(enum_type)

	# 如果无法转换，使用旧的实现
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		_log_warning("获取所有配置模型失败: 配置类型不存在 - " + config_type)
		return {}

	# 获取配置数据
	var config_data = _config_cache[config_type]

	# 获取配置模型类
	var model_class = _config_models.get(config_type)
	if not model_class:
		_log_warning("获取所有配置模型失败: 配置模型类不存在 - " + config_type)
		return {}

	# 创建配置模型
	var models = {}
	for config_id in config_data:
		models[config_id] = model_class.new(config_id, config_data[config_id])

	return models

## 获取所有配置类型
func get_all_config_types() -> Array:
	return _config_paths.keys()

## 获取所有配置文件路径
func get_all_config_paths() -> Dictionary:
	return _config_paths.duplicate()

## 重新加载配置（使用枚举）
## 重新加载指定类型的配置
## @param config_type 配置类型枚举
## @return 是否重新加载成功
func reload_config_enum(config_type: int) -> bool:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return false

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 检查配置类型是否已注册
	if not _config_paths.has(type_str):
		push_error("致命错误: 配置类型未注册 - " + type_str)
		assert(false, "配置类型未注册")
		return false

	# 清除缓存
	if _config_cache.has(type_str):
		_config_cache.erase(type_str)

	# 加载配置
	var result = load_config_enum(config_type)
	if result:
		config_reloaded.emit(type_str)

	return result

## 重新加载配置
func reload_config(config_type: String) -> bool:
	# 检查配置类型是否有效
	if not _config_paths.has(config_type):
		_log_warning("重新加载配置失败: 无效的配置类型 - " + config_type)
		return false

	# 清除缓存
	if _config_cache.has(config_type):
		_config_cache.erase(config_type)

	# 加载配置
	var result = load_config(config_type)
	if result:
		config_reloaded.emit(config_type)
	return result

## 重新加载所有配置
## 重新加载所有已注册的配置
func reload_all_configs() -> void:
	# 清除所有缓存
	_config_cache.clear()

	# 加载所有配置
	load_all_configs()

	_log_info("所有配置已重新加载")
	all_configs_reloaded.emit()

## 保存配置（使用枚举）
## 保存指定类型的配置到文件
## @param config_type 配置类型枚举
## @return 是否保存成功
func save_config_enum(config_type: int) -> bool:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return false

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 检查配置类型是否已注册
	if not _config_paths.has(type_str):
		push_error("致命错误: 配置类型未注册 - " + type_str)
		assert(false, "配置类型未注册")
		return false

	# 检查配置是否已加载
	if not _config_cache.has(type_str):
		push_error("致命错误: 配置未加载 - " + type_str)
		assert(false, "配置未加载")
		return false

	# 获取配置文件路径
	var file_path = _config_paths[type_str]

	# 获取配置数据
	var config_data = _config_cache[type_str]

	# 保存配置文件
	var result = save_json(file_path, config_data)
	if result:
		_log_info("配置已保存: " + type_str)

	return result

## 保存配置
## 保存指定类型的配置到文件
## @param config_type 配置类型字符串
## @return 是否保存成功
func save_config(config_type: String) -> bool:
	# 尝试将字符串转换为枚举
	var enum_type = ConfigTypes.from_string(config_type)
	if enum_type != -1:
		return save_config_enum(enum_type)

	# 如果无法转换，使用旧的实现
	# 检查配置类型是否有效
	if not _config_paths.has(config_type):
		_log_warning("保存配置失败: 无效的配置类型 - " + config_type)
		return false

	# 检查配置是否已加载
	if not _config_cache.has(config_type):
		_log_warning("保存配置失败: 配置未加载 - " + config_type)
		return false

	# 获取配置文件路径
	var file_path = _config_paths[config_type]

	# 获取配置数据
	var config_data = _config_cache[config_type]

	# 保存配置文件
	return save_json(file_path, config_data)

## 保存JSON文件
## 将数据保存为JSON文件
## @param file_path 文件路径
## @param data 要保存的数据
## @return 是否保存成功
func save_json(file_path: String, data: Variant) -> bool:
	# 检查文件路径是否有效
	if file_path.is_empty():
		push_error("致命错误: 文件路径为空")
		assert(false, "文件路径为空")
		return false

	# 创建目录
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		var err = dir.make_dir_recursive(dir_path)
		if err != OK:
			push_error("致命错误: 无法创建目录 - " + dir_path + ", 错误码: " + str(err))
			assert(false, "无法创建目录")
			return false

	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("致命错误: 无法打开文件进行写入 - " + file_path + ", 错误码: " + str(FileAccess.get_open_error()))
		assert(false, "无法打开文件进行写入")
		return false

	# 序列化数据
	var json_text = JSON.stringify(data, "\t")
	if json_text.is_empty():
		push_error("致命错误: JSON序列化失败 - " + file_path)
		assert(false, "JSON序列化失败")
		file.close()
		return false

	# 写入文件
	file.store_string(json_text)
	file.close()

	return true

## 加载指定配置
static func load_json(file_path: String) -> Variant:
	return _load_json_file(file_path)

## 设置配置项（使用枚举）
## 设置指定类型和ID的配置项数据
## @param config_type 配置类型枚举
## @param config_id 配置ID
## @param config_data 配置数据
## @return 是否设置成功
func set_config_item_enum(config_type: int, config_id: String, config_data: Dictionary) -> bool:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return false

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 检查配置ID是否有效
	if config_id.is_empty():
		push_error("致命错误: 配置ID为空 - " + type_str)
		assert(false, "配置ID为空")
		return false

	# 检查配置数据是否有效
	if config_data.is_empty():
		push_error("致命错误: 配置数据为空 - " + type_str + "." + config_id)
		assert(false, "配置数据为空")
		return false

	# 检查配置类型是否已加载
	if not _config_cache.has(type_str):
		push_error("致命错误: 配置类型未加载 - " + type_str)
		assert(false, "配置类型未加载")
		return false

	# 获取配置模型类
	var model_class = _config_models.get(type_str)
	if not model_class:
		push_error("致命错误: 配置模型类不存在 - " + type_str)
		assert(false, "配置模型类不存在")
		return false

	# 验证配置数据
	var model = model_class.new(config_id, config_data)
	if not model.validation_errors.is_empty():
		push_error("致命错误: 配置数据验证失败 - " + type_str + "." + config_id)
		for error in model.validation_errors:
			push_error("- " + error)
		assert(false, "配置数据验证失败")
		return false

	# 更新配置数据
	_config_cache[type_str][config_id] = config_data.duplicate(true)

	# 发送配置变更信号
	config_changed.emit(type_str, config_id)

	return true

## 设置配置项
func set_config_item(config_type: String, config_id: String, config_data: Dictionary) -> bool:
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		_log_warning("设置配置项失败: 配置类型不存在 - " + config_type)
		return false

	# 获取配置模型类
	var model_class = _config_models.get(config_type)
	if not model_class:
		_log_warning("设置配置项失败: 配置模型类不存在 - " + config_type)
		return false

	# 验证配置数据
	var model = model_class.new(config_id, config_data)
	if not model.validation_errors.is_empty():
		_log_warning("设置配置项失败: 配置数据验证失败 - " + config_type + "." + config_id)
		for error in model.validation_errors:
			_log_warning(error)
		return false

	# 更新配置数据
	_config_cache[config_type][config_id] = config_data.duplicate(true)

	# 发送配置变更信号
	config_changed.emit(config_type, config_id)

	return true

## 删除配置项（使用枚举）
## 删除指定类型和ID的配置项
## @param config_type 配置类型枚举
## @param config_id 配置ID
## @return 是否删除成功
func delete_config_item_enum(config_type: int, config_id: String) -> bool:
	# 检查配置类型是否有效
	if not _config_type_map.has(config_type):
		push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
		assert(false, "配置类型不存在")
		return false

	# 获取配置类型字符串
	var type_str = _config_type_map[config_type]

	# 检查配置ID是否有效
	if config_id.is_empty():
		push_error("致命错误: 配置ID为空 - " + type_str)
		assert(false, "配置ID为空")
		return false

	# 检查配置类型是否已加载
	if not _config_cache.has(type_str):
		push_error("致命错误: 配置类型未加载 - " + type_str)
		assert(false, "配置类型未加载")
		return false

	# 检查配置ID是否存在
	if not _config_cache[type_str].has(config_id):
		push_error("致命错误: 配置ID不存在 - " + type_str + "." + config_id)
		assert(false, "配置ID不存在")
		return false

	# 删除配置项
	_config_cache[type_str].erase(config_id)

	# 发送配置变更信号
	config_changed.emit(type_str, config_id)

	return true

## 删除配置项
func delete_config_item(config_type: String, config_id: String) -> bool:
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		_log_warning("删除配置项失败: 配置类型不存在 - " + config_type)
		return false

	# 检查配置ID是否存在
	if not _config_cache[config_type].has(config_id):
		_log_warning("删除配置项失败: 配置ID不存在 - " + config_type + "." + config_id)
		return false

	# 删除配置项
	_config_cache[config_type].erase(config_id)

	# 发送配置变更信号
	config_changed.emit(config_type, config_id)

	return true

## 清除配置缓存（使用枚举）
## 清除指定类型或所有类型的配置缓存
## @param config_type 配置类型枚举，-1表示清除所有缓存
func clear_config_cache_enum(config_type: int = -1) -> void:
	if config_type == -1:
		# 清除所有缓存
		_config_cache.clear()
		_log_info("所有配置缓存已清除")
	else:
		# 检查配置类型是否有效
		if not _config_type_map.has(config_type):
			push_error("致命错误: 无效的配置类型枚举 - " + str(config_type))
			assert(false, "配置类型不存在")
			return

		# 获取配置类型字符串
		var type_str = _config_type_map[config_type]

		# 清除指定配置缓存
		if _config_cache.has(type_str):
			_config_cache.erase(type_str)
			_log_info("配置缓存已清除: " + type_str)
		else:
			push_warning("清除配置缓存: 配置类型未加载 - " + type_str)

## 清除配置缓存
func clear_config_cache(config_type: String = "") -> void:
	if config_type.is_empty():
		# 清除所有缓存
		_config_cache.clear()
		_log_info("所有配置缓存已清除")
	else:
		# 清除指定配置缓存
		if _config_cache.has(config_type):
			_config_cache.erase(config_type)
			_log_info("配置缓存已清除: " + config_type)
		else:
			_log_warning("清除配置缓存失败: 配置类型不存在 - " + config_type)

## 设置配置目录
func set_config_dir(dir_path: String) -> void:
	_config_dir = dir_path
	_log_info("配置目录已设置为: " + dir_path)

## 获取配置目录
func get_config_dir() -> String:
	return _config_dir

## 重写重置方法
func _do_reset() -> void:
	# 清除所有缓存
	_config_cache.clear()

	# 重新加载所有配置
	load_all_configs()

	_log_info("ConfigManager 已重置")

## 重写清理方法
func _do_cleanup() -> void:
	# 清除所有缓存
	_config_cache.clear()

	# 清除所有模型
	_config_models.clear()

	# 清理文件监视器
	if _file_watcher:
		_file_watcher.stop()
		_file_watcher.queue_free()
		_file_watcher = null

	# 清理文件修改时间缓存
	_file_modified_times.clear()

	_log_info("ConfigManager 已清理")

# 以下是为了向后兼容的方法

## 获取棋子配置
func get_chess_piece_config(piece_id: String):
	return get_config_model_enum(ConfigTypes.Type.CHESS_PIECES, piece_id)

## 获取所有棋子配置
func get_all_chess_pieces() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.CHESS_PIECES)

## 获取装备配置
func get_equipment_config(equipment_id: String):
	return get_config_model_enum(ConfigTypes.Type.EQUIPMENT, equipment_id)

## 获取所有装备配置
func get_all_equipment() -> Dictionary[String, EquipmentConfig]:
	var raw_dict = get_all_config_models_enum(ConfigTypes.Type.EQUIPMENT)
	# 转换为目标类型
	var equipment_dict: Dictionary[String, EquipmentConfig] = {}
	for key in raw_dict:
		equipment_dict[key] = raw_dict[key]
	return equipment_dict

## 获取地图配置
func get_map_config():
	return get_config_model_enum(ConfigTypes.Type.MAP_CONFIG, "map_config")

## 获取地图配置数据
func get_map_config_data() -> Dictionary:
	return get_all_config_items_enum(ConfigTypes.Type.MAP_CONFIG)

## 获取遗物配置
func get_relic_config(relic_id: String):
	return get_config_model_enum(ConfigTypes.Type.RELICS, relic_id)

## 获取所有遗物配置
func get_all_relics() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.RELICS)

## 获取羁绊配置
func get_synergy_config(synergy_id: String):
	return get_config_model_enum(ConfigTypes.Type.SYNERGIES, synergy_id)

## 获取所有羁绊配置
func get_all_synergies() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.SYNERGIES)

## 获取事件配置
func get_event_config(event_id: String):
	return get_config_model_enum(ConfigTypes.Type.EVENTS, event_id)

## 获取所有事件配置
func get_all_events() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.EVENTS)

## 获取难度配置
func get_difficulty_config(difficulty_level: int):
	var difficulty_key = str(difficulty_level)
	return get_config_model_enum(ConfigTypes.Type.DIFFICULTY, difficulty_key)

## 获取所有难度配置
func get_all_difficulty() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.DIFFICULTY)

## 获取成就配置
func get_achievement_config(achievement_id: String):
	return get_config_model_enum(ConfigTypes.Type.ACHIEVEMENTS, achievement_id)

## 获取所有成就配置
func get_all_achievements() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.ACHIEVEMENTS)

## 获取皮肤配置
func get_skin_config(skin_id: String):
	return get_config_model_enum(ConfigTypes.Type.SKINS, skin_id)

## 获取所有皮肤配置
func get_all_skins() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.SKINS)

## 获取教程配置
func get_tutorial_config(tutorial_id: String):
	return get_config_model_enum(ConfigTypes.Type.TUTORIALS, tutorial_id)

## 获取所有教程配置
func get_all_tutorials() -> Dictionary:
	return get_all_config_models_enum(ConfigTypes.Type.TUTORIALS)

## 获取棋子配置（按羁绊）
func get_chess_pieces_by_synergy(synergy_id: String) -> Array:
	var result = []
	var all_pieces = get_all_config_models_enum(ConfigTypes.Type.CHESS_PIECES)

	for piece_id in all_pieces:
		var piece = all_pieces[piece_id]
		if piece.get_synergies().has(synergy_id):
			result.append(piece)

	return result

## 获取棋子配置（按费用）
func get_chess_pieces_by_cost(costs: Array) -> Array:
	var result = []
	var all_pieces = get_all_config_models_enum(ConfigTypes.Type.CHESS_PIECES)

	for piece_id in all_pieces:
		var piece = all_pieces[piece_id]
		if costs.has(piece.get_cost()):
			result.append(piece)

	return result

## 获取配置
func get_config(config_type: String) -> Dictionary:
	return get_all_config_items(config_type)

## 获取配置（使用枚举）
func get_config_enum(config_type: int) -> Dictionary:
	return get_all_config_items_enum(config_type)

## 创建查询构建器
## 提供链式调用API，简化配置查询
## @param config_type 配置类型枚举
## @return 配置查询构建器
func create_query(config_type: int) -> ConfigQuery:
	return ConfigQuery.new(self, config_type)

## 查询配置
## 根据条件查询配置项
## @param config_type 配置类型（枚举）
## @param query 查询条件，例如 {"rarity": "rare"}
## @param as_model 是否返回模型对象
## @return 符合条件的配置项字典
func query(config_type: int, query: Dictionary = {}, as_model: bool = true) -> Dictionary:
	# 获取所有配置项
	var all_items: Dictionary

	# 使用枚举版本
	if as_model:
		all_items = get_all_config_models_enum(config_type)
	else:
		all_items = get_all_config_items_enum(config_type)

	# 如果没有查询条件，返回所有项
	if query.is_empty():
		return all_items

	# 根据条件过滤
	var result = {}
	for item_id in all_items:
		var item = all_items[item_id]
		var match_all = true

		# 检查每个查询条件
		for key in query:
			var value = query[key]

			# 如果是模型对象
			if item is ConfigModel:
				# 使用 get_value 方法
				if item.get_value(key, null) != value:
					match_all = false
					break
			# 如果是字典
			elif item is Dictionary:
				# 直接检查键值
				if not item.has(key) or item[key] != value:
					match_all = false
					break
			else:
				# 不支持的类型
				match_all = false
				break

		# 如果所有条件都匹配，添加到结果中
		if match_all:
			result[item_id] = item

	return result

## 查询配置并返回数组
## 根据条件查询配置项，返回数组形式
## @param config_type 配置类型（枚举）
## @param query 查询条件，例如 {"rarity": "rare"}
## @param as_model 是否返回模型对象
## @return 符合条件的配置项数组
func query_array(config_type: int, query: Dictionary = {}, as_model: bool = true) -> Array:
	# 使用查询方法获取结果字典
	var result_dict = query(config_type, query, as_model)

	# 转换为数组
	var result_array = []
	for item_id in result_dict:
		result_array.append(result_dict[item_id])

	return result_array
