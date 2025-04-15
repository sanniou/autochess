extends Node
## 存档管理器
## 负责游戏数据的持久化和加载

# 存档文件夹路径
const SAVE_DIR = "user://saves/"
# 存档文件扩展名
const SAVE_EXTENSION = ".save"
# 自动存档文件名
const AUTOSAVE_NAME = "autosave"
# 最大存档槽数
const MAX_SAVE_SLOTS = 5
# 存档版本
const SAVE_VERSION = "1.0.0"

# 引用
@onready var config_manager = get_node("/root/ConfigManager")

# 当前加载的存档槽
var current_save_slot = ""
# 是否启用自动存档
var autosave_enabled = true
# 自动存档间隔（秒）
var autosave_interval = 300
# 自动存档计时器
var _autosave_timer = 0

# 存档元数据
var save_metadata = {}

func _ready():
	# 确保存档目录存在
	_ensure_save_directory()

	# 加载存档元数据
	load_save_metadata()

	# 连接信号
	EventBus.autosave_triggered.connect(_on_autosave_triggered)
	EventBus.game_state_changed.connect(_on_game_state_changed)

	# 设置自动存档计时器
	if autosave_enabled:
		_autosave_timer = autosave_interval

func _process(delta):
	# 处理自动存档计时
	if autosave_enabled and current_save_slot != "" and GameManager.current_state != GameManager.GameState.NONE and GameManager.current_state != GameManager.GameState.MAIN_MENU:
		_autosave_timer -= delta
		if _autosave_timer <= 0:
			_autosave_timer = autosave_interval
			save_game(AUTOSAVE_NAME)
			EventBus.debug_message.emit("游戏已自动存档", 0)

## 确保存档目录存在
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_DIR.trim_suffix("/")):
		dir.make_dir(SAVE_DIR.trim_suffix("/"))

## 加载存档元数据
func load_save_metadata() -> void:
	var metadata_path = SAVE_DIR + "metadata.json"
	if not FileAccess.file_exists(metadata_path):
		save_metadata = {
			"saves": {},
			"last_save": "",
			"version": SAVE_VERSION
		}
		_save_metadata()
		return

	# 使用 ConfigManager 加载元数据
	var metadata = config_manager.load_json(metadata_path)
	if metadata.is_empty():
		EventBus.debug_message.emit("无法加载存档元数据", 2)
		return

	save_metadata = metadata

	# 版本兼容性检查
	if not save_metadata.has("version") or save_metadata.version != SAVE_VERSION:
		EventBus.debug_message.emit("存档版本不兼容，可能需要迁移", 1)

## 保存元数据
func _save_metadata() -> void:
	var metadata_path = SAVE_DIR + "metadata.json"

	# 使用 ConfigManager 保存元数据
	var result = config_manager.save_json(metadata_path, save_metadata)
	if not result:
		EventBus.debug_message.emit("无法写入存档元数据文件", 2)

## 保存游戏
func save_game(slot_name: String = "") -> bool:
	# 如果没有指定存档槽，使用当前槽
	if slot_name == "":
		slot_name = current_save_slot
		if slot_name == "":
			EventBus.debug_message.emit("未指定存档槽", 2)
			return false

	# 准备存档数据
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": _get_player_save_data(),
		"map": _get_map_save_data(),
		"chess_pieces": _get_chess_pieces_save_data(),
		"equipment": _get_equipment_save_data(),
		"relics": _get_relics_save_data(),
		"achievements": _get_achievements_save_data(),
		"settings": _get_settings_save_data()
	}

	# 保存到文件
	var save_path = SAVE_DIR + slot_name + SAVE_EXTENSION

	# 使用 ConfigManager 保存存档文件
	var result = config_manager.save_json(save_path, save_data)
	if not result:
		EventBus.debug_message.emit("无法写入存档文件: " + save_path, 2)
		return false

	# 更新元数据
	save_metadata.saves[slot_name] = {
		"name": slot_name,
		"timestamp": save_data.timestamp,
		"player_level": save_data.player.level,
		"map_progress": save_data.map.progress,
		"difficulty": save_data.player.difficulty
	}
	save_metadata.last_save = slot_name
	_save_metadata()

	# 设置当前存档槽
	current_save_slot = slot_name

	# 发送存档信号
	EventBus.game_saved.emit(slot_name)

	return true

## 加载游戏
func load_game(slot_name: String) -> bool:
	var save_path = SAVE_DIR + slot_name + SAVE_EXTENSION
	if not FileAccess.file_exists(save_path):
		EventBus.debug_message.emit("存档文件不存在: " + save_path, 2)
		return false

	# 使用 ConfigManager 加载存档文件
	var save_data = config_manager.load_json(save_path)
	if save_data.is_empty():
		EventBus.debug_message.emit("无法加载存档文件: " + save_path, 2)
		return false

	# 版本兼容性检查
	if not save_data.has("version") or save_data.version != SAVE_VERSION:
		EventBus.debug_message.emit("存档版本不兼容，可能无法正确加载", 1)

	# 应用存档数据
	_apply_player_save_data(save_data.player)
	_apply_map_save_data(save_data.map)
	_apply_chess_pieces_save_data(save_data.chess_pieces)
	_apply_equipment_save_data(save_data.equipment)
	_apply_relics_save_data(save_data.relics)
	_apply_achievements_save_data(save_data.achievements)
	_apply_settings_save_data(save_data.settings)

	# 设置当前存档槽
	current_save_slot = slot_name

	# 发送加载信号
	EventBus.game_loaded.emit(slot_name)

	return true

## 获取存档列表
func get_save_list() -> Array:
	var saves = []
	for save_name in save_metadata.saves.keys():
		saves.append(save_metadata.saves[save_name])

	# 按时间戳排序，最新的在前
	saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	return saves

## 删除存档
func delete_save(slot_name: String) -> bool:
	var save_path = SAVE_DIR + slot_name + SAVE_EXTENSION
	if not FileAccess.file_exists(save_path):
		EventBus.debug_message.emit("存档文件不存在: " + save_path, 2)
		return false

	var dir = DirAccess.open(SAVE_DIR)
	if dir.remove(slot_name + SAVE_EXTENSION) != OK:
		EventBus.debug_message.emit("无法删除存档文件: " + save_path, 2)
		return false

	# 更新元数据
	save_metadata.saves.erase(slot_name)
	if save_metadata.last_save == slot_name:
		save_metadata.last_save = ""
	_save_metadata()

	return true

## 创建新存档槽
func create_new_save_slot() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var slot_name = "save_" + str(timestamp)

	# 如果存档数量超过最大值，删除最旧的存档
	var saves = get_save_list()
	if saves.size() >= MAX_SAVE_SLOTS:
		var oldest_save = saves[saves.size() - 1].name
		delete_save(oldest_save)

	return slot_name

## 获取玩家存档数据
func _get_player_save_data() -> Dictionary:
	# 这里将从玩家管理器获取数据
	# 暂时返回示例数据
	return {
		"health": 100,
		"max_health": 100,
		"level": 1,
		"gold": 0,
		"experience": 0,
		"difficulty": GameManager.difficulty_level
	}

## 获取地图存档数据
func _get_map_save_data() -> Dictionary:
	# 这里将从地图管理器获取数据
	# 暂时返回示例数据
	return {
		"seed": 0,
		"nodes": [],
		"current_node": "",
		"visited_nodes": [],
		"progress": 0
	}

## 获取棋子存档数据
func _get_chess_pieces_save_data() -> Array:
	# 这里将从棋子管理器获取数据
	# 暂时返回示例数据
	return []

## 获取装备存档数据
func _get_equipment_save_data() -> Array:
	# 这里将从装备管理器获取数据
	# 暂时返回示例数据
	return []

## 获取遗物存档数据
func _get_relics_save_data() -> Array:
	# 这里将从遗物管理器获取数据
	# 暂时返回示例数据
	return []

## 获取成就存档数据
func _get_achievements_save_data() -> Dictionary:
	# 这里将从成就管理器获取数据
	# 暂时返回示例数据
	return {}

## 获取设置存档数据
func _get_settings_save_data() -> Dictionary:
	# 这里将从设置管理器获取数据
	# 暂时返回示例数据
	return {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 1.0,
			"sfx_volume": 1.0
		},
		"graphics": {
			"fullscreen": false,
			"vsync": true
		},
		"gameplay": {
			"language": "zh_CN",
			"show_tooltips": true
		}
	}

## 应用玩家存档数据
func _apply_player_save_data(data: Dictionary) -> void:
	# 这里将应用数据到玩家管理器
	# 暂时只打印日志
	EventBus.debug_message.emit("应用玩家存档数据", 0)

## 应用地图存档数据
func _apply_map_save_data(data: Dictionary) -> void:
	# 这里将应用数据到地图管理器
	# 暂时只打印日志
	EventBus.debug_message.emit("应用地图存档数据", 0)

## 应用棋子存档数据
func _apply_chess_pieces_save_data(data: Array) -> void:
	# 这里将应用数据到棋子管理器
	# 暂时只打印日志
	EventBus.debug_message.emit("应用棋子存档数据", 0)

## 应用装备存档数据
func _apply_equipment_save_data(data: Array) -> void:
	# 这里将应用数据到装备管理器
	# 暂时只打印日志
	EventBus.debug_message.emit("应用装备存档数据", 0)

## 应用遗物存档数据
func _apply_relics_save_data(data: Array) -> void:
	# 这里将应用数据到遗物管理器
	# 暂时只打印日志
	EventBus.debug_message.emit("应用遗物存档数据", 0)

## 应用成就存档数据
func _apply_achievements_save_data(data: Dictionary) -> void:
	# 这里将应用数据到成就管理器
	# 暂时只打印日志
	EventBus.debug_message.emit("应用成就存档数据", 0)

## 应用设置存档数据
func _apply_settings_save_data(data: Dictionary) -> void:
	# 这里将应用数据到设置管理器
	# 暂时只打印日志
	EventBus.debug_message.emit("应用设置存档数据", 0)

## 自动存档触发处理
func _on_autosave_triggered() -> void:
	if autosave_enabled and current_save_slot != "":
		save_game(AUTOSAVE_NAME)

## 游戏状态变更处理
func _on_game_state_changed(old_state, new_state) -> void:
	# 在某些状态转换时触发自动存档
	if old_state == GameManager.GameState.BATTLE and new_state != GameManager.GameState.GAME_OVER:
		if autosave_enabled and current_save_slot != "":
			save_game(AUTOSAVE_NAME)
			EventBus.debug_message.emit("战斗结束后自动存档", 0)
