extends "res://scripts/managers/core/base_manager.gd"
class_name ConfigManager
## 配置管理器
## 负责加载和管理游戏配置数据
##
## 配置文件结构标准请参考 config/README.md
## 所有配置文件应使用统一的结构和命名约定

# 配置数据模型
var config_models = {}

# 配置数据缓存
var config_cache = {}

# 配置文件路径
const CONFIG_PATH = {
	"chess_pieces": "res://config/chess_pieces.json",
	"equipment": "res://config/equipment.json",
	"map_nodes": "res://config/map_nodes.json",
	"relics": "res://config/relics/relics.json",
	"synergies": "res://config/synergies.json",
	"events": "res://config/events/events.json",
	"difficulty": "res://config/difficulty.json",
	"achievements": "res://config/achievements.json",
	"skins": "res://config/skins.json",
	"tutorials": "res://config/tutorials.json"
}

# 配置目录
const CONFIG_DIR = "res://config/"

# 配置模型类映射
const CONFIG_MODEL_CLASSES = {
	"chess_pieces": "res://scripts/config/models/chess_piece_config.gd",
	"equipment": "res://scripts/config/models/equipment_config.gd",
	"map_nodes": "res://scripts/config/models/map_node_config.gd",
	"relics": "res://scripts/config/models/relic_config.gd",
	"synergies": "res://scripts/config/models/synergy_config.gd",
	"events": "res://scripts/config/models/event_config.gd",
	"difficulty": "res://scripts/config/models/difficulty_config.gd",
	"achievements": "res://scripts/config/models/achievement_config.gd",
	"skins": "res://scripts/config/models/skin_config.gd",
	"tutorials": "res://scripts/config/models/tutorial_config.gd"
}

# 是否处于调试模式
var debug_mode = false

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "ConfigManager"

	# 设置调试模式
	debug_mode = OS.is_debug_build()

	# 加载所有配置
	load_all_configs()

	# 连接调试相关信号
	if debug_mode:
		EventBus.debug.debug_command_executed.connect(_on_debug_command_executed)

## 加载所有配置文件
func load_all_configs() -> void:
	# 加载配置模型类
	_load_config_model_classes()
	
	# 加载所有配置文件
	for config_type in CONFIG_PATH:
		load_config(config_type)
	
	# 验证所有配置文件
	if debug_mode:
		validate_all_configs()
	
	EventBus.debug.debug_message.emit("所有配置加载完成", 0)

## 加载配置模型类
func _load_config_model_classes() -> void:
	# 加载基础配置模型类
	var base_model = load("res://scripts/config/config_model.gd")
	
	# 加载所有配置模型类
	for config_type in CONFIG_MODEL_CLASSES:
		var model_path = CONFIG_MODEL_CLASSES[config_type]
		
		# 检查文件是否存在
		if ResourceLoader.exists(model_path):
			var model_class = load(model_path)
			config_models[config_type] = model_class
		else:
			# 如果模型类不存在，使用基础模型类
			config_models[config_type] = base_model
			
			if debug_mode:
				EventBus.debug.debug_message.emit("配置模型类不存在: " + model_path + "，使用基础模型类", 1)

## 验证所有配置文件
func validate_all_configs() -> bool:
	var all_valid = true
	
	for config_type in config_cache:
		if not validate_config(config_type):
			all_valid = false
	
	return all_valid

## 验证配置文件
func validate_config(config_type: String) -> bool:
	if not config_cache.has(config_type):
		EventBus.debug.debug_message.emit("验证配置失败: 配置类型不存在 - " + config_type, 2)
		return false
	
	var config_data = config_cache[config_type]
	var all_valid = true
	
	# 获取配置模型类
	var model_class = config_models.get(config_type)
	if not model_class:
		EventBus.debug.debug_message.emit("验证配置失败: 配置模型类不存在 - " + config_type, 2)
		return false
	
	# 验证每个配置项
	for config_id in config_data:
		var model = model_class.new(config_id, config_data[config_id])
		
		if not model.validate(config_data[config_id]):
			EventBus.debug.debug_message.emit("配置验证失败: " + config_type + "." + config_id, 2)
			
			# 输出验证错误
			for error in model.get_validation_errors():
				EventBus.debug.debug_message.emit("  - " + error, 2)
			
			all_valid = false
	
	if all_valid:
		EventBus.debug.debug_message.emit("配置验证成功: " + config_type, 0)
	
	return all_valid

## 加载配置文件
func load_config(config_type: String) -> bool:
	# 检查配置类型是否有效
	if not CONFIG_PATH.has(config_type):
		EventBus.debug.debug_message.emit("加载配置失败: 无效的配置类型 - " + config_type, 2)
		return false
	
	# 获取配置文件路径
	var file_path = CONFIG_PATH[config_type]
	
	# 加载配置文件
	var config_data = _load_json_file(file_path)
	if config_data.is_empty():
		EventBus.debug.debug_message.emit("加载配置失败: 配置文件为空 - " + file_path, 2)
		return false
	
	# 缓存配置数据
	config_cache[config_type] = config_data
	
	EventBus.debug.debug_message.emit(config_type + " 配置加载完成", 0)
	return true

## 获取配置项
func get_config_item(config_type: String, config_id: String) -> Dictionary:
	# 检查配置类型是否有效
	if not config_cache.has(config_type):
		EventBus.debug.debug_message.emit("获取配置项失败: 配置类型不存在 - " + config_type, 2)
		return {}
	
	# 获取配置数据
	var config_data = config_cache[config_type]
	
	# 检查配置ID是否存在
	if not config_data.has(config_id):
		EventBus.debug.debug_message.emit("获取配置项失败: 配置ID不存在 - " + config_type + "." + config_id, 2)
		return {}
	
	return config_data[config_id].duplicate(true)

## 获取配置模型
func get_config_model(config_type: String, config_id: String) -> ConfigModel:
	# 检查配置类型是否有效
	if not config_cache.has(config_type):
		EventBus.debug.debug_message.emit("获取配置模型失败: 配置类型不存在 - " + config_type, 2)
		return null
	
	# 获取配置数据
	var config_data = config_cache[config_type]
	
	# 检查配置ID是否存在
	if not config_data.has(config_id):
		EventBus.debug.debug_message.emit("获取配置模型失败: 配置ID不存在 - " + config_type + "." + config_id, 2)
		return null
	
	# 获取配置模型类
	var model_class = config_models.get(config_type)
	if not model_class:
		EventBus.debug.debug_message.emit("获取配置模型失败: 配置模型类不存在 - " + config_type, 2)
		return null
	
	# 创建配置模型
	return model_class.new(config_id, config_data[config_id])

## 获取所有配置项
func get_all_config_items(config_type: String) -> Dictionary:
	# 检查配置类型是否有效
	if not config_cache.has(config_type):
		EventBus.debug.debug_message.emit("获取所有配置项失败: 配置类型不存在 - " + config_type, 2)
		return {}
	
	return config_cache[config_type].duplicate(true)

## 获取所有配置模型
func get_all_config_models(config_type: String) -> Dictionary:
	# 检查配置类型是否有效
	if not config_cache.has(config_type):
		EventBus.debug.debug_message.emit("获取所有配置模型失败: 配置类型不存在 - " + config_type, 2)
		return {}
	
	# 获取配置数据
	var config_data = config_cache[config_type]
	
	# 获取配置模型类
	var model_class = config_models.get(config_type)
	if not model_class:
		EventBus.debug.debug_message.emit("获取所有配置模型失败: 配置模型类不存在 - " + config_type, 2)
		return {}
	
	# 创建配置模型
	var models = {}
	for config_id in config_data:
		models[config_id] = model_class.new(config_id, config_data[config_id])
	
	return models

## 获取所有配置类型
func get_all_config_types() -> Array:
	return config_cache.keys()

## 获取所有配置文件
func get_all_config_files() -> Dictionary:
	return CONFIG_PATH.duplicate()

## 重新加载配置
func reload_config(config_type: String) -> bool:
	# 检查配置类型是否有效
	if not CONFIG_PATH.has(config_type):
		EventBus.debug.debug_message.emit("重新加载配置失败: 无效的配置类型 - " + config_type, 2)
		return false
	
	# 清除缓存
	if config_cache.has(config_type):
		config_cache.erase(config_type)
	
	# 加载配置
	return load_config(config_type)

## 重新加载所有配置
func reload_all_configs() -> void:
	# 清除所有缓存
	config_cache.clear()
	
	# 加载所有配置
	load_all_configs()
	
	EventBus.debug.debug_message.emit("所有配置已重新加载", 0)

## 从JSON文件加载配置
func _load_json_file(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		# 如果文件不存在，创建一个空的配置文件
		if debug_mode:
			_create_empty_config_file(file_path)
		EventBus.debug.debug_message.emit("配置文件不存在: " + file_path, 2)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		EventBus.debug.debug_message.emit("无法打开配置文件: " + file_path, 2)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		EventBus.debug.debug_message.emit("解析配置文件失败: " + file_path + ", 行 " + str(json.get_error_line()) + ": " + json.get_error_message(), 2)
		return {}

	return json.get_data()

## 创建空的配置文件
func _create_empty_config_file(file_path: String) -> bool:
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		EventBus.debug.debug_message.emit("无法创建配置文件: " + file_path, 2)
		return false

	file.store_string("{}")
	file.close()
	EventBus.debug.debug_message.emit("创建空配置文件: " + file_path, 0)
	return true

## 保存JSON文件
func save_json(file_path: String, data: Variant) -> bool:
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		EventBus.debug.debug_message.emit("无法打开配置文件进行写入: " + file_path, 2)
		return false

	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()
	EventBus.debug.debug_message.emit("配置文件已保存: " + file_path, 0)
	return true

## 加载指定配置
func load_json(file_path: String) -> Variant:
	return _load_json_file(file_path)

## 调试命令处理
func _on_debug_command_executed(command: String, args: Array) -> void:
	match command:
		"reload_config":
			if args.size() > 0:
				reload_config(args[0])
			else:
				reload_all_configs()
		"validate_config":
			if args.size() > 0:
				validate_config(args[0])
			else:
				validate_all_configs()

# 以下是为了向后兼容的方法

## 获取棋子配置
func get_chess_piece_config(piece_id: String) -> Dictionary:
	return get_config_item("chess_pieces", piece_id)

## 获取所有棋子配置
func get_all_chess_pieces() -> Dictionary:
	return get_all_config_items("chess_pieces")

## 获取装备配置
func get_equipment_config(equipment_id: String) -> Dictionary:
	return get_config_item("equipment", equipment_id)

## 获取所有装备配置
func get_all_equipment() -> Dictionary:
	return get_all_config_items("equipment")

## 获取地图节点配置
func get_map_node_config(node_id: String) -> Dictionary:
	return get_config_item("map_nodes", node_id)

## 获取所有地图节点配置
func get_all_map_nodes() -> Dictionary:
	return get_all_config_items("map_nodes")

## 获取遗物配置
func get_relic_config(relic_id: String) -> Dictionary:
	return get_config_item("relics", relic_id)

## 获取所有遗物配置
func get_all_relics() -> Dictionary:
	return get_all_config_items("relics")

## 获取羁绊配置
func get_synergy_config(synergy_id: String) -> Dictionary:
	return get_config_item("synergies", synergy_id)

## 获取所有羁绊配置
func get_all_synergies() -> Dictionary:
	return get_all_config_items("synergies")

## 获取事件配置
func get_event_config(event_id: String) -> Dictionary:
	return get_config_item("events", event_id)

## 获取所有事件配置
func get_all_events() -> Dictionary:
	return get_all_config_items("events")

## 获取难度配置
func get_difficulty_config(difficulty_level: int) -> Dictionary:
	var difficulty_key = str(difficulty_level)
	return get_config_item("difficulty", difficulty_key)

## 获取所有难度配置
func get_all_difficulty() -> Dictionary:
	return get_all_config_items("difficulty")

## 获取成就配置
func get_achievement_config(achievement_id: String) -> Dictionary:
	return get_config_item("achievements", achievement_id)

## 获取所有成就配置
func get_all_achievements() -> Dictionary:
	return get_all_config_items("achievements")

## 获取皮肤配置
func get_skin_config(skin_id: String) -> Dictionary:
	return get_config_item("skins", skin_id)

## 获取所有皮肤配置
func get_all_skins() -> Dictionary:
	return get_all_config_items("skins")

## 获取教程配置
func get_tutorial_config(tutorial_id: String) -> Dictionary:
	return get_config_item("tutorials", tutorial_id)

## 获取所有教程配置
func get_all_tutorials() -> Dictionary:
	return get_all_config_items("tutorials")

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.debug_message.emit(error_message, 2)
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.debug_message.emit(warning_message, 1)

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.debug_message.emit(info_message, 0)
