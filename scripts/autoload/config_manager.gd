extends Node
## 配置管理器
## 负责加载和管理游戏配置数据

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

# 配置文件路径
const CONFIG_PATH = {
	"chess_pieces": "res://config/chess_pieces.json",
	"equipment": "res://config/equipment.json",
	"map_nodes": "res://config/map_nodes.json",
	"relics": "res://config/relics.json",
	"synergies": "res://config/synergies.json",
	"events": "res://config/events.json",
	"difficulty": "res://config/difficulty.json",
	"achievements": "res://config/achievements.json",
	"skins": "res://config/skins.json"
}

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
	
	EventBus.debug_message.emit("所有配置加载完成", 0)

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

## 获取棋子配置
func get_chess_piece_config(piece_id: String) -> Dictionary:
	if chess_pieces_config.has(piece_id):
		return chess_pieces_config[piece_id]
	return {}

## 获取所有棋子配置
func get_all_chess_pieces() -> Dictionary:
	return chess_pieces_config

## 获取装备配置
func get_equipment_config(equipment_id: String) -> Dictionary:
	if equipment_config.has(equipment_id):
		return equipment_config[equipment_id]
	return {}

## 获取所有装备配置
func get_all_equipment() -> Dictionary:
	return equipment_config

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

## 调试命令处理
func _on_debug_command_executed(command: String, _result) -> void:
	if command == "reload_configs":
		reload_configs()
