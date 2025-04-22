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

# 配置变更信号
signal config_loaded(config_type: String)
signal config_reloaded(config_type: String)
signal config_validated(config_type: String, is_valid: bool, errors: Array)
signal all_configs_loaded()
signal all_configs_reloaded()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ConfigManager"

	# 设置调试模式
	debug_mode = OS.is_debug_build()

	# 注册默认配置类型
	_register_default_config_types()

	# 加载所有配置
	load_all_configs()

	# 输出初始化完成信息
	_log_info("ConfigManager 初始化完成")

## 注册默认配置类型
func _register_default_config_types() -> void:
	# 注册棋子配置
	register_config_type(
		"chess_pieces",
		"res://config/chess_pieces.json",
		"res://scripts/config/models/chess_piece_config.gd"
	)

	# 注册装备配置
	register_config_type(
		"equipment",
		"res://config/equipment.json",
		"res://scripts/config/models/equipment_config.gd"
	)

	# 注册地图配置
	register_config_type(
		"map_config",
		"res://config/map_config.json",
		"res://scripts/config/models/map_config.gd"
	)

	# 注册遗物配置
	register_config_type(
		"relics",
		"res://config/relics/relics.json",
		"res://scripts/config/models/relic_config.gd"
	)

	# 注册羁绊配置
	register_config_type(
		"synergies",
		"res://config/synergies.json",
		"res://scripts/config/models/synergy_config.gd"
	)

	# 注册事件配置
	register_config_type(
		"events",
		"res://config/events/events.json",
		"res://scripts/config/models/event_config.gd"
	)

	# 注册难度配置
	register_config_type(
		"difficulty",
		"res://config/difficulty.json",
		"res://scripts/config/models/difficulty_config.gd"
	)

	# 注册成就配置
	register_config_type(
		"achievements",
		"res://config/achievements.json",
		"res://scripts/config/models/achievement_config.gd"
	)

	# 注册皮肤配置
	register_config_type(
		"skins",
		"res://config/skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

	# 注册教程配置
	register_config_type(
		"tutorials",
		"res://config/tutorials.json",
		"res://scripts/config/models/tutorial_config.gd"
	)

	# 注册动画配置
	register_config_type(
		"animation_config",
		"res://config/animations/animation_config.json",
		"res://scripts/config/models/animation_config.gd"
	)

	# 注册环境效果配置
	register_config_type(
		"environment_effects",
		"res://config/effects/environment_effects.json",
		"res://scripts/config/models/effect_config.gd"
	)

	# 注册技能效果配置
	register_config_type(
		"skill_effects",
		"res://config/effects/skill_effects.json",
		"res://scripts/config/models/effect_config.gd"
	)

	# 注册棋盘皮肤配置
	register_config_type(
		"board_skins",
		"res://config/skins/board_skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

	# 注册棋子皮肤配置
	register_config_type(
		"chess_skins",
		"res://config/skins/chess_skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

	# 注册UI皮肤配置
	register_config_type(
		"ui_skins",
		"res://config/skins/ui_skins.json",
		"res://scripts/config/models/skin_config.gd"
	)

## 注册配置类型
## 注册一个新的配置类型，指定其文件路径和模型类
func register_config_type(config_type: String, file_path: String, model_class_path: String = "") -> void:
	# 注册配置路径
	_config_paths[config_type] = file_path

	# 注册配置模型类
	if not model_class_path.is_empty():
		_config_model_classes[config_type] = model_class_path

	_log_info("注册配置类型: " + config_type + " -> " + file_path)

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
func load_all_configs() -> void:
	# 加载配置模型类
	_load_config_model_classes()

	# 加载所有配置文件
	for config_type in _config_paths:
		load_config(config_type)

	# 验证所有配置文件
	if debug_mode:
		validate_all_configs()

	_log_info("所有配置加载完成")
	all_configs_loaded.emit()

## 加载配置模型类
func _load_config_model_classes() -> void:
	# 加载基础配置模型类
	var base_model = load("res://scripts/config/config_model.gd")

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
				_log_warning("配置模型类不存在: " + model_path + "，使用基础模型类")

## 验证所有配置文件
func validate_all_configs() -> bool:
	var all_valid = true
	var all_errors = []

	for config_type in _config_cache:
		var result = validate_config(config_type)
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

## 验证配置文件
func validate_config(config_type: String) -> Dictionary:
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
static func _load_json_file(file_path: String) -> Dictionary:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		_log_warning("加载JSON文件失败: 文件不存在 - " + file_path)
		return {}

	# 打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		_log_warning("加载JSON文件失败: 无法打开文件 - " + file_path)
		return {}

	# 读取文件内容
	var json_text = file.get_as_text()
	file.close()

	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		_log_warning("加载JSON文件失败: JSON解析错误 - " + file_path + " - " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}

	# 获取解析结果
	var result = json.get_data()
	if not result is Dictionary:
		_log_warning("加载JSON文件失败: JSON根节点不是字典 - " + file_path)
		return {}

	return result

## 获取配置项
func get_config_item(config_type: String, config_id: String) -> Dictionary:
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

## 获取配置模型
func get_config_model(config_type: String, config_id: String) -> ConfigModel:
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

## 获取所有配置项
func get_all_config_items(config_type: String) -> Dictionary:
	# 检查配置类型是否有效
	if not _config_cache.has(config_type):
		_log_warning("获取所有配置项失败: 配置类型不存在 - " + config_type)
		return {}

	return _config_cache[config_type].duplicate(true)

## 获取所有配置模型
func get_all_config_models(config_type: String) -> Dictionary:
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
func reload_all_configs() -> void:
	# 清除所有缓存
	_config_cache.clear()

	# 加载所有配置
	load_all_configs()

	_log_info("所有配置已重新加载")
	all_configs_reloaded.emit()

## 保存配置
func save_config(config_type: String) -> bool:
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
func save_json(file_path: String, data: Variant) -> bool:
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		_log_warning("无法打开配置文件进行写入: " + file_path)
		return false

	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()
	_log_info("配置文件已保存: " + file_path)
	return true

## 加载指定配置
static func load_json(file_path: String) -> Variant:
	return _load_json_file(file_path)

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

	return true

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

	_log_info("ConfigManager 已清理")

# 以下是为了向后兼容的方法

## 获取棋子配置
func get_chess_piece_config(piece_id: String):
	return get_config_model("chess_pieces", piece_id)

## 获取所有棋子配置
func get_all_chess_pieces() -> Dictionary:
	return get_all_config_models("chess_pieces")

## 获取装备配置
func get_equipment_config(equipment_id: String):
	return get_config_model("equipment", equipment_id)

## 获取所有装备配置
func get_all_equipment() -> Dictionary:
	return get_all_config_models("equipment")

## 获取地图配置
func get_map_config():
	return get_config_model("map_config", "map_config")

## 获取地图配置数据
func get_map_config_data() -> Dictionary:
	return get_all_config_items("map_config")

## 获取遗物配置
func get_relic_config(relic_id: String):
	return get_config_model("relics", relic_id)

## 获取所有遗物配置
func get_all_relics() -> Dictionary:
	return get_all_config_models("relics")

## 获取羁绊配置
func get_synergy_config(synergy_id: String):
	return get_config_model("synergies", synergy_id)

## 获取所有羁绊配置
func get_all_synergies() -> Dictionary:
	return get_all_config_models("synergies")

## 获取事件配置
func get_event_config(event_id: String):
	return get_config_model("events", event_id)

## 获取所有事件配置
func get_all_events() -> Dictionary:
	return get_all_config_models("events")

## 获取难度配置
func get_difficulty_config(difficulty_level: int):
	var difficulty_key = str(difficulty_level)
	return get_config_model("difficulty", difficulty_key)

## 获取所有难度配置
func get_all_difficulty() -> Dictionary:
	return get_all_config_models("difficulty")

## 获取成就配置
func get_achievement_config(achievement_id: String):
	return get_config_model("achievements", achievement_id)

## 获取所有成就配置
func get_all_achievements() -> Dictionary:
	return get_all_config_models("achievements")

## 获取皮肤配置
func get_skin_config(skin_id: String):
	return get_config_model("skins", skin_id)

## 获取所有皮肤配置
func get_all_skins() -> Dictionary:
	return get_all_config_models("skins")

## 获取教程配置
func get_tutorial_config(tutorial_id: String):
	return get_config_model("tutorials", tutorial_id)

## 获取所有教程配置
func get_all_tutorials() -> Dictionary:
	return get_all_config_models("tutorials")

## 获取棋子配置（按羁绊）
func get_chess_pieces_by_synergy(synergy_id: String) -> Array:
	var result = []
	var all_pieces = get_all_chess_pieces()

	for piece_id in all_pieces:
		var piece = all_pieces[piece_id]
		if piece.get_synergies().has(synergy_id):
			result.append(piece)

	return result

## 获取棋子配置（按费用）
func get_chess_pieces_by_cost(costs: Array) -> Array:
	var result = []
	var all_pieces = get_all_chess_pieces()

	for piece_id in all_pieces:
		var piece = all_pieces[piece_id]
		if costs.has(piece.get_cost()):
			result.append(piece)

	return result

## 获取配置
func get_config(config_type: String) -> Dictionary:
	return get_all_config_items(config_type)
