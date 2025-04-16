extends Node
## 配置管理器
## 负责加载和管理游戏配置数据
##
## 配置文件结构标准请参考 config/README.md
## 所有配置文件应使用统一的结构和命名约定

# 配置数据
var chess_pieces_config = {}
var equipment_config = {}
var map_nodes_config = {}
var relics_config = {}
var synergies_config = {}
var events_config = {}
var difficulty_config = {}
var achievements_config = {}
var skins_config = {}
var tutorials_config = {}

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

# 是否处于调试模式
var debug_mode = false

func _ready():
	# 加载所有配置
	load_all_configs()

	# 连接调试相关信号
	if OS.is_debug_build():
		debug_mode = true
		EventBus.debug_command_executed.connect(_on_debug_command_executed)

## 加载所有配置文件
func load_all_configs() -> void:
	load_chess_pieces_config()
	load_equipment_config()
	load_map_nodes_config()
	load_relics_config()
	load_synergies_config()
	load_events_config()
	load_difficulty_config()
	load_achievements_config()
	load_skins_config()
	load_tutorials_config()

	# 验证所有配置文件
	if debug_mode:
		validate_all_configs()

	EventBus.debug_message.emit("所有配置加载完成", 0)

## 验证所有配置文件
func validate_all_configs() -> void:
	validate_chess_pieces_config()
	validate_equipment_config()
	validate_map_nodes_config()
	validate_relics_config()
	validate_synergies_config()
	validate_events_config()
	validate_difficulty_config()
	validate_achievements_config()
	validate_skins_config()
	validate_tutorials_config()

## 加载棋子配置
func load_chess_pieces_config() -> void:
	var config = _load_json_file(CONFIG_PATH.chess_pieces)
	if config:
		chess_pieces_config = config
		EventBus.debug_message.emit("棋子配置加载完成", 0)

## 加载装备配置
func load_equipment_config() -> void:
	var config = _load_json_file(CONFIG_PATH.equipment)
	if config:
		equipment_config = config
		EventBus.debug_message.emit("装备配置加载完成", 0)

## 加载地图节点配置
func load_map_nodes_config() -> void:
	var config = _load_json_file(CONFIG_PATH.map_nodes)
	if config:
		map_nodes_config = config
		EventBus.debug_message.emit("地图节点配置加载完成", 0)

## 加载遗物配置
func load_relics_config() -> void:
	var config = _load_json_file(CONFIG_PATH.relics)
	if config:
		relics_config = config
		EventBus.debug_message.emit("遗物配置加载完成", 0)

## 加载羁绊配置
func load_synergies_config() -> void:
	var config = _load_json_file(CONFIG_PATH.synergies)
	if config:
		synergies_config = config
		EventBus.debug_message.emit("羁绊配置加载完成", 0)

## 加载事件配置
func load_events_config() -> void:
	var config = _load_json_file(CONFIG_PATH.events)
	if config:
		events_config = config
		EventBus.debug_message.emit("事件配置加载完成", 0)

## 加载难度配置
func load_difficulty_config() -> void:
	var config = _load_json_file(CONFIG_PATH.difficulty)
	if config:
		difficulty_config = config
		EventBus.debug_message.emit("难度配置加载完成", 0)

## 加载成就配置
func load_achievements_config() -> void:
	var config = _load_json_file(CONFIG_PATH.achievements)
	if config:
		achievements_config = config
		EventBus.debug_message.emit("成就配置加载完成", 0)

## 加载皮肤配置
func load_skins_config() -> void:
	var config = _load_json_file(CONFIG_PATH.skins)
	if config:
		skins_config = config
		EventBus.debug_message.emit("皮肤配置加载完成", 0)

## 加载教程配置
func load_tutorials_config() -> void:
	var config = _load_json_file(CONFIG_PATH.tutorials)
	if config:
		tutorials_config = config
		EventBus.debug_message.emit("教程配置加载完成", 0)

## 获取棋子配置
func get_chess_piece_config(piece_id: String) -> Dictionary:
	if chess_pieces_config.has(piece_id):
		return chess_pieces_config[piece_id]
	return {}

## 获取所有棋子配置
func get_all_chess_pieces() -> Dictionary:
	return chess_pieces_config

## 获取棋子
func get_chess_piece(piece_id: String) -> Dictionary:
	return get_chess_piece_config(piece_id)

## 根据羁绊获取棋子
func get_chess_pieces_by_synergy(synergy_id: String) -> Array:
	var result = []

	for piece_id in chess_pieces_config:
		var piece = chess_pieces_config[piece_id]
		if piece.has("synergies") and piece.synergies.has(synergy_id):
			result.append(piece)

	return result

## 根据费用获取棋子
func get_chess_pieces_by_cost(costs: Array) -> Array:
	var result = []

	for piece_id in chess_pieces_config:
		var piece = chess_pieces_config[piece_id]
		if piece.has("cost") and costs.has(piece.cost):
			result.append(piece)

	return result

## 获取装备配置
func get_equipment_config(equipment_id: String) -> Dictionary:
	if equipment_config.has(equipment_id):
		return equipment_config[equipment_id]
	return {}

## 获取所有装备配置
func get_all_equipment() -> Dictionary:
	return equipment_config

## 获取装备
func get_equipment(equipment_id: String) -> Dictionary:
	return get_equipment_config(equipment_id)

## 根据稀有度获取装备
func get_equipments_by_rarity(rarities: Array) -> Array:
	var result = []

	for equip_id in equipment_config:
		var equip = equipment_config[equip_id]
		if equip.has("rarity") and rarities.has(equip.rarity):
			result.append(equip_id)

	return result

## 获取遗物配置
func get_relic_config(relic_id: String) -> Dictionary:
	if relics_config.has(relic_id):
		return relics_config[relic_id]
	return {}

## 获取所有遗物配置
func get_all_relics() -> Dictionary:
	return relics_config

## 获取羁绊配置
func get_synergy_config(synergy_id: String) -> Dictionary:
	if synergies_config.has(synergy_id):
		return synergies_config[synergy_id]
	return {}

## 获取所有羁绊配置
func get_all_synergies() -> Dictionary:
	return synergies_config

## 获取事件配置
func get_event_config(event_id: String) -> Dictionary:
	if events_config.has(event_id):
		return events_config[event_id]
	return {}

## 获取所有事件配置
func get_all_events() -> Dictionary:
	return events_config

## 获取难度配置
func get_difficulty_config(difficulty_level: int) -> Dictionary:
	var difficulty_key = str(difficulty_level)
	if difficulty_config.has(difficulty_key):
		return difficulty_config[difficulty_key]
	return {}

## 获取成就配置
func get_achievement_config(achievement_id: String) -> Dictionary:
	if achievements_config.has(achievement_id):
		return achievements_config[achievement_id]
	return {}

## 获取所有成就配置
func get_all_achievements() -> Dictionary:
	return achievements_config

## 获取皮肤配置
func get_skin_config(skin_id: String) -> Dictionary:
	if skins_config.has(skin_id):
		return skins_config[skin_id]
	return {}

## 获取所有皮肤配置
func get_all_skins() -> Dictionary:
	return skins_config

## 获取教程配置
func get_tutorial_config(tutorial_id: String) -> Dictionary:
	if tutorials_config.has(tutorial_id):
		return tutorials_config[tutorial_id]
	return {}

## 获取所有教程配置
func get_all_tutorials() -> Dictionary:
	return tutorials_config

## 重新加载配置（用于热重载）
func reload_configs() -> void:
	load_all_configs()
	EventBus.debug_message.emit("配置已重新加载", 0)

## 从JSON文件加载配置
func _load_json_file(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		# 如果文件不存在，创建一个空的配置文件
		if debug_mode:
			_create_empty_config_file(file_path)
		EventBus.debug_message.emit("配置文件不存在: " + file_path, 2)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		EventBus.debug_message.emit("无法打开配置文件: " + file_path, 2)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		EventBus.debug_message.emit("解析配置文件失败: " + file_path + ", 行 " + str(json.get_error_line()) + ": " + json.get_error_message(), 2)
		return {}

	return json.get_data()

## 创建空的配置文件（仅在调试模式下）
func _create_empty_config_file(file_path: String) -> void:
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		EventBus.debug_message.emit("无法创建配置文件: " + file_path, 2)
		return

	file.store_string("{}")
	file.close()
	EventBus.debug_message.emit("创建了空配置文件: " + file_path, 1)

## 验证棋子配置
func validate_chess_pieces_config() -> void:
	for piece_id in chess_pieces_config:
		var piece = chess_pieces_config[piece_id]
		var required_fields = ["id", "name", "description", "cost", "health", "attack_damage", "attack_speed", "armor", "magic_resist", "attack_range", "move_speed", "ability", "synergies"]

		for field in required_fields:
			if not piece.has(field):
				EventBus.debug_message.emit("棋子配置验证失败: " + piece_id + " 缺少必要字段 " + field, 2)

## 验证装备配置
func validate_equipment_config() -> void:
	for equip_id in equipment_config:
		var equip = equipment_config[equip_id]
		var required_fields = ["id", "name", "description"]

		for field in required_fields:
			if not equip.has(field):
				EventBus.debug_message.emit("装备配置验证失败: " + equip_id + " 缺少必要字段 " + field, 2)

## 验证地图节点配置
func validate_map_nodes_config() -> void:
	if not map_nodes_config.has("map_templates") or not map_nodes_config.has("node_types"):
		EventBus.debug_message.emit("地图节点配置验证失败: 缺少 map_templates 或 node_types", 2)
		return

	for template_id in map_nodes_config.map_templates:
		var template = map_nodes_config.map_templates[template_id]
		var required_fields = ["name", "description", "node_weights", "layers"]

		for field in required_fields:
			if not template.has(field):
				EventBus.debug_message.emit("地图模板配置验证失败: " + template_id + " 缺少必要字段 " + field, 2)

## 验证遗物配置
func validate_relics_config() -> void:
	for relic_id in relics_config:
		var relic = relics_config[relic_id]
		var required_fields = ["id", "name", "description", "rarity", "is_passive", "effects"]

		for field in required_fields:
			if not relic.has(field):
				EventBus.debug_message.emit("遗物配置验证失败: " + relic_id + " 缺少必要字段 " + field, 2)

## 验证羁绑配置
func validate_synergies_config() -> void:
	for synergy_id in synergies_config:
		var synergy = synergies_config[synergy_id]
		var required_fields = ["id", "name", "description"]

		for field in required_fields:
			if not synergy.has(field):
				EventBus.debug_message.emit("羁绑配置验证失败: " + synergy_id + " 缺少必要字段 " + field, 2)

		# 验证羁绊阈值字段
		if not synergy.has("thresholds") and not synergy.has("tiers"):
			EventBus.debug_message.emit("羁绑配置验证失败: " + synergy_id + " 缺少必要字段 thresholds 或 tiers", 2)

## 验证事件配置
func validate_events_config() -> void:
	for event_id in events_config:
		var event = events_config[event_id]
		var required_fields = ["id", "title", "description", "choices"]

		for field in required_fields:
			if not event.has(field):
				EventBus.debug_message.emit("事件配置验证失败: " + event_id + " 缺少必要字段 " + field, 2)

## 验证难度配置
func validate_difficulty_config() -> void:
	for diff_id in difficulty_config:
		var diff = difficulty_config[diff_id]
		var required_fields = ["name", "description"]

		for field in required_fields:
			if not diff.has(field):
				EventBus.debug_message.emit("难度配置验证失败: " + diff_id + " 缺少必要字段 " + field, 2)

## 验证成就配置
func validate_achievements_config() -> void:
	for achievement_id in achievements_config:
		var achievement = achievements_config[achievement_id]
		var required_fields = ["id", "name", "description", "requirements"]

		for field in required_fields:
			if not achievement.has(field):
				EventBus.debug_message.emit("成就配置验证失败: " + achievement_id + " 缺少必要字段 " + field, 2)

## 验证皮肤配置
func validate_skins_config() -> void:
	for skin_id in skins_config:
		var skin = skins_config[skin_id]
		var required_fields = ["id", "name", "description"]

		for field in required_fields:
			if not skin.has(field):
				EventBus.debug_message.emit("皮肤配置验证失败: " + skin_id + " 缺少必要字段 " + field, 2)

## 验证教程配置
func validate_tutorials_config() -> void:
	for tutorial_id in tutorials_config:
		var tutorial = tutorials_config[tutorial_id]
		var required_fields = ["id", "title", "description", "steps"]

		for field in required_fields:
			if not tutorial.has(field):
				EventBus.debug_message.emit("教程配置验证失败: " + tutorial_id + " 缺少必要字段 " + field, 2)

		# 验证步骤
		if tutorial.has("steps") and tutorial.steps is Array:
			for i in range(tutorial.steps.size()):
				var step = tutorial.steps[i]
				var step_required_fields = ["content"]

				for field in step_required_fields:
					if not step.has(field):
						EventBus.debug_message.emit("教程步骤配置验证失败: " + tutorial_id + " 步骤 " + str(i) + " 缺少必要字段 " + field, 2)

## 验证配置文件结构
func validate_config_structure(config: Dictionary, schema: Dictionary, config_name: String, config_id: String) -> bool:
	var valid = true

	# 验证必要字段
	for field in schema.required_fields:
		if not config.has(field):
			EventBus.debug_message.emit(config_name + " 配置验证失败: " + config_id + " 缺少必要字段 " + field, 2)
			valid = false

	# 验证字段类型
	for field in schema.field_types:
		if config.has(field) and typeof(config[field]) != schema.field_types[field]:
			EventBus.debug_message.emit(config_name + " 配置验证失败: " + config_id + " 字段 " + field + " 类型错误", 2)
			valid = false

	# 验证嵌套字段
	for field in schema.nested_fields:
		if config.has(field) and schema.nested_fields[field].has("required_fields"):
			for nested_field in schema.nested_fields[field].required_fields:
				if not config[field].has(nested_field):
					EventBus.debug_message.emit(config_name + " 配置验证失败: " + config_id + " 字段 " + field + " 缺少必要字段 " + nested_field, 2)
					valid = false

	return valid

## 调试命令处理
func _on_debug_command_executed(command: String, _result) -> void:
	if command == "reload_configs":
		reload_configs()
	elif command == "validate_configs":
		validate_all_configs()

## 保存JSON文件
## 用于将配置数据保存到文件
func save_json(file_path: String, data: Variant) -> bool:
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path):
		dir.make_dir_recursive(dir_path)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		EventBus.debug_message.emit("无法打开配置文件进行写入: " + file_path, 2)
		return false

	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()
	EventBus.debug_message.emit("配置文件已保存: " + file_path, 0)
	return true

## 加载指定配置
## 用于加载任意配置文件
func load_json(file_path: String) -> Variant:
	return _load_json_file(file_path)

## 获取指定配置
## 用于获取任意配置数据
func get_config(config_name: String) -> Variant:
	if config_name == "chess_pieces":
		return chess_pieces_config
	elif config_name == "equipment":
		return equipment_config
	elif config_name == "map_nodes":
		return map_nodes_config
	elif config_name == "relics":
		return relics_config
	elif config_name == "synergies":
		return synergies_config
	elif config_name == "events":
		return events_config
	elif config_name == "difficulty":
		return difficulty_config
	elif config_name == "achievements":
		return achievements_config
	elif config_name == "skins":
		return skins_config
	elif config_name == "tutorials":
		return tutorials_config
	else:
		return {}

## 获取配置目录下的所有JSON文件
## 用于扫描配置目录下的所有JSON文件
func get_all_config_files() -> Dictionary:
	var result = {}
	var dir = DirAccess.open(CONFIG_DIR)
	if dir == null:
		EventBus.debug_message.emit("无法打开配置目录: " + CONFIG_DIR, 2)
		return result

	# 扫描根目录
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = CONFIG_DIR + file_name
			result[file_name.get_basename()] = file_path
		elif dir.current_is_dir() and file_name != "." and file_name != "..":
			# 扫描子目录
			var subdir_path = CONFIG_DIR + file_name + "/"
			var subdir = DirAccess.open(subdir_path)
			if subdir != null:
				subdir.list_dir_begin()
				var subfile_name = subdir.get_next()
				while subfile_name != "":
					if not subdir.current_is_dir() and subfile_name.ends_with(".json"):
						var subfile_path = subdir_path + subfile_name
						result[file_name + "/" + subfile_name.get_basename()] = subfile_path
					subfile_name = subdir.get_next()
				subdir.list_dir_end()
		file_name = dir.get_next()
	dir.list_dir_end()

	return result
