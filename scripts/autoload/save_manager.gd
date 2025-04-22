extends "res://scripts/managers/core/base_manager.gd"
## 存档管理器
## 负责游戏数据的持久化和加载

# 存档文件夹路径
const SAVE_DIR = "user://saves/"
# 存档文件扩展名
const SAVE_EXTENSION = ".save"
# 自动存档文件名
const AUTOSAVE_NAME = "autosave"
# 自动存档最大数量
const MAX_AUTOSAVES = 1
# 最大存档槽数
const MAX_SAVE_SLOTS = 5
# 存档版本
const SAVE_VERSION = "1.0.0"

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

# 初始化
func _ready() -> void:
	# 初始化管理器
	initialize()

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "SaveManager"
	# 添加依赖
	add_dependency("ConfigManager")
	# 添加依赖
	add_dependency("SettingsManager")

	# 原 _ready 函数的内容
	# 确保存档目录存在
	_ensure_save_directory()

	# 加载存档元数据
	load_save_metadata()

	# 连接信号
	EventBus.save.connect_event("autosave_triggered", _on_autosave_triggered)
	EventBus.game.connect_event("game_state_changed", _on_game_state_changed)

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
			EventBus.debug.emit_event("debug_message", ["游戏已自动存档", 0])

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
	var metadata = ConfigManager.load_json(metadata_path)
	if metadata.is_empty():
		EventBus.debug.emit_event("debug_message", ["无法加载存档元数据", 2])
		return

	save_metadata = metadata

	# 版本兼容性检查
	if not save_metadata.has("version") or save_metadata.version != SAVE_VERSION:
		EventBus.debug.emit_event("debug_message", ["存档版本不兼容，可能需要迁移", 1])

## 保存元数据
func _save_metadata() -> void:
	var metadata_path = SAVE_DIR + "metadata.json"

	# 使用 ConfigManager 保存元数据
	var result = GameManager.config_manager.save_json(metadata_path, save_metadata)
	if not result:
		EventBus.debug.emit_event("debug_message", ["无法写入存档元数据文件", 2])

## 保存游戏
func save_game(slot_name: String = "") -> bool:
	# 如果没有指定存档槽，使用当前槽
	if slot_name == "":
		slot_name = current_save_slot
		if slot_name == "":
			EventBus.debug.emit_event("debug_message", ["未指定存档槽", 2])
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
		"tutorials": _get_tutorials_save_data(),
		"settings": _get_settings_save_data()
	}

	# 保存到文件
	var save_path = SAVE_DIR + slot_name + SAVE_EXTENSION

	# 使用 ConfigManager 保存存档文件
	var result = GameManager.config_manager.save_json(save_path, save_data)
	if not result:
		EventBus.debug.emit_event("debug_message", ["无法写入存档文件: " + save_path, 2])
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
	EventBus.save.emit_event("game_saved", [slot_name])

	return true

## 加载游戏
func load_game(slot_name: String) -> bool:
	var save_path = SAVE_DIR + slot_name + SAVE_EXTENSION
	if not FileAccess.file_exists(save_path):
		EventBus.debug.emit_event("debug_message", ["存档文件不存在: " + save_path, 2])
		return false

	# 使用 ConfigManager 加载存档文件
	var save_data = GameManager.config_manager.load_json(save_path)
	if save_data.is_empty():
		EventBus.debug.emit_event("debug_message", ["无法加载存档文件: " + save_path, 2])
		return false

	# 版本兼容性检查
	if not save_data.has("version") or save_data.version != SAVE_VERSION:
		EventBus.debug.emit_event("debug_message", ["存档版本不兼容，可能无法正确加载", 1])

	# 应用存档数据
	_apply_player_save_data(save_data.player)
	_apply_map_save_data(save_data.map)
	_apply_chess_pieces_save_data(save_data.chess_pieces)
	_apply_equipment_save_data(save_data.equipment)
	_apply_relics_save_data(save_data.relics)
	_apply_achievements_save_data(save_data.achievements)
	if save_data.has("tutorials"):
		_apply_tutorials_save_data(save_data.tutorials)
	_apply_settings_save_data(save_data.settings)

	# 设置当前存档槽
	current_save_slot = slot_name

	# 发送加载信号
	EventBus.save.emit_event("game_loaded", [slot_name])

	return true

## 获取存档列表
func get_save_list() -> Array:
	var saves = []
	for save_name in save_metadata.saves.keys():
		saves.append(save_metadata.saves[save_name])

	# 按时间戳排序，最新的在前
	saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)

	return saves

## 获取存档信息
func get_save_info(slot_name: String) -> Dictionary:
	if save_metadata.saves.has(slot_name):
		return save_metadata.saves[slot_name]
	return {}

## 删除存档
func delete_save(slot_name: String) -> bool:
	var save_path = SAVE_DIR + slot_name + SAVE_EXTENSION
	if not FileAccess.file_exists(save_path):
		EventBus.debug.emit_event("debug_message", ["存档文件不存在: " + save_path, 2])
		return false

	var dir = DirAccess.open(SAVE_DIR)
	if dir.remove(slot_name + SAVE_EXTENSION) != OK:
		EventBus.debug.emit_event("debug_message", ["无法删除存档文件: " + save_path, 2])
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
	# 从玩家管理器获取数据
	var player_manager = get_node_or_null("/root/GameManager/PlayerManager")
	if player_manager:
		var current_player = player_manager.get_current_player()
		if current_player:
			return current_player.get_save_data()

	# 如果无法获取玩家数据，返回默认数据
	return {
		"name": "Player",
		"health": 100,
		"max_health": 100,
		"level": 1,
		"gold": 0,
		"exp": 0,
		"win_streak": 0,
		"lose_streak": 0,
		"total_wins": 0,
		"total_losses": 0,
		"chess_pieces": [],
		"bench_pieces": [],
		"equipments": [],
		"relics": [],
		"difficulty": GameManager.difficulty_level
	}

## 获取地图存档数据
func _get_map_save_data() -> Dictionary:
	# 从地图管理器获取数据
	var map_manager = get_node_or_null("/root/GameManager/MapManager")
	if map_manager:
		var map_data = map_manager.get_current_map()
		if map_data:
			var nodes_data = []

			# 遍历所有节点
			for node in map_data.nodes:
				# 获取节点数据
				if node is MapNode:
					nodes_data.append({
						"id": node.id,
						"type": node.type,
						"layer": node.layer,
						"position": node.position,
						"visited": node.visited,
						"properties": node.properties.duplicate(),
						"rewards": node.rewards.duplicate()
					})

			# 获取连接数据
			var connections_data = []
			for connection in map_data.connections:
				if connection is MapConnection:
					connections_data.append({
						"id": connection.id,
						"from_node_id": connection.from_node_id,
						"to_node_id": connection.to_node_id,
						"traversable": connection.traversable,
						"properties": connection.properties.duplicate()
					})

			# 获取当前节点和已访问节点
			var current_node_id = ""
			if map_manager.current_node:
				current_node_id = map_manager.current_node.id

			return {
				"seed": map_data.seed_value,
				"nodes": nodes_data,
				"connections": connections_data,
				"current_node": current_node_id,
				"visited_nodes": map_manager.visited_nodes.keys(),
				"template_id": map_data.template_id,
				"layers": map_data.layers,
				"difficulty": map_data.difficulty
			}

	# 如果无法获取地图数据，返回默认数据
	return {
		"seed": 0,
		"nodes": [],
		"current_node": "",
		"visited_nodes": [],
		"progress": 0,
		"template_id": "standard"
	}

## 获取棋子存档数据
func _get_chess_pieces_save_data() -> Array:
	# 从棋子管理器获取数据
	var chess_manager = get_node_or_null("/root/GameManager/ChessManager")
	if chess_manager:
		var chess_pieces = chess_manager.get_all_chess_pieces()
		var chess_data = []

		for piece in chess_pieces:
			var piece_data = {
				"id": piece.id,
				"star_level": piece.star_level,
				"position": {"x": piece.board_position.x, "y": piece.board_position.y} if piece.is_on_board else null,
				"is_on_board": piece.is_on_board,
				"is_on_bench": piece.is_on_bench,
				"bench_index": piece.bench_index if piece.is_on_bench else -1,
				"health": piece.current_health,
				"mana": piece.current_mana,
				"equipments": []
			}

			# 获取棋子装备数据
			for equipment in piece.equipments:
				piece_data.equipments.append(equipment.id)

			chess_data.append(piece_data)

		return chess_data

	# 如果无法获取棋子数据，返回空数组
	return []

## 获取装备存档数据
func _get_equipment_save_data() -> Array:
	# 从装备管理器获取数据
	var equipment_manager = get_node_or_null("/root/GameManager/EquipmentManager")
	if equipment_manager:
		var equipments = equipment_manager.get_all_equipments()
		var equipment_data = []

		for equip in equipments:
			var equip_data = {
				"id": equip.id,
				"base_id": equip.base_id,
				"quality": equip.quality,
				"durability": equip.durability,
				"max_durability": equip.max_durability,
				"is_equipped": equip.is_equipped,
				"equipped_to": equip.equipped_to,
				"attack_bonus": equip.attack_bonus,
				"defense_bonus": equip.defense_bonus,
				"health_bonus": equip.health_bonus,
				"mana_bonus": equip.mana_bonus,
				"enchantments": equip.enchantments.duplicate()
			}

			equipment_data.append(equip_data)

		return equipment_data

	# 如果无法获取装备数据，返回空数组
	return []

## 获取遗物存档数据
func _get_relics_save_data() -> Array:
	# 从遗物管理器获取数据
	var relic_manager = get_node_or_null("/root/GameManager/RelicManager")
	if relic_manager:
		var relics = relic_manager.get_all_relics()
		var relic_data = []

		for relic in relics:
			var relic_info = {
				"id": relic.id,
				"base_id": relic.base_id,
				"rarity": relic.rarity,
				"is_active": relic.is_active,
				"stacks": relic.stacks,
				"effects": relic.effects.duplicate()
			}

			relic_data.append(relic_info)

		return relic_data

	# 如果无法获取遗物数据，返回空数组
	return []

## 获取成就存档数据
func _get_achievements_save_data() -> Dictionary:
	# 从成就管理器获取数据
	var achievement_manager = get_node_or_null("/root/GameManager/AchievementManager")
	if achievement_manager:
		var achievements = achievement_manager.get_all_achievements()
		var achievement_data = {}

		for achievement_id in achievements.keys():
			var achievement = achievements[achievement_id]
			achievement_data[achievement_id] = {
				"unlocked": achievement.unlocked,
				"progress": achievement.progress,
				"unlock_date": achievement.unlock_date,
				"viewed": achievement.viewed
			}

		return achievement_data

	# 如果无法获取成就数据，返回空字典
	return {}

## 获取教程存档数据
func _get_tutorials_save_data() -> Dictionary:
	# 这里将从教程管理器获取数据
	var tutorial_manager = get_node_or_null("/root/GameManager/TutorialManager")
	if tutorial_manager:
		return {
			"completed_tutorials": tutorial_manager.get_completed_tutorials(),
			"skipped_tutorials": tutorial_manager.get_skipped_tutorials()
		}
	return {}

## 获取设置存档数据
func _get_settings_save_data() -> Dictionary:
	# 从设置管理器获取数据
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		return {
			"audio": {
				"master_volume": settings_manager.get_master_volume(),
				"music_volume": settings_manager.get_music_volume(),
				"sfx_volume": settings_manager.get_sfx_volume()
			},
			"graphics": {
				"fullscreen": settings_manager.is_fullscreen(),
				"vsync": settings_manager.is_vsync_enabled()
			},
			"gameplay": {
				"language": settings_manager.get_language(),
				"show_tooltips": settings_manager.get_show_tooltips()
			}
		}

	# 如果无法获取设置数据，返回默认设置
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
	# 应用数据到玩家管理器
	var player_manager = get_node_or_null("/root/GameManager/PlayerManager")
	if player_manager and not data.is_empty():
		# 设置玩家数据
		player_manager.load_player_data(data)
		EventBus.debug.emit_event("debug_message", ["应用玩家存档数据成功", 0])
	else:
		EventBus.debug.emit_event("debug_message", ["无法应用玩家存档数据", 1])

## 应用地图存档数据
func _apply_map_save_data(data: Dictionary) -> void:
	# 应用数据到地图管理器
	var map_manager = get_node_or_null("/root/GameManager/MapManager")
	if map_manager and not data.is_empty():
		# 设置地图数据
		# 首先创建一个MapData对象
		var map_data = MapData.new()

		# 设置基本信息
		map_data.id = data.get("id", "")
		map_data.name = data.get("name", "")
		map_data.description = data.get("description", "")
		map_data.difficulty = data.get("difficulty", 1)
		map_data.seed_value = data.get("seed", 0)
		map_data.template_id = data.get("template_id", "standard")
		map_data.layers = data.get("layers", 0)

		# 创建节点
		for node_data in data.get("nodes", []):
			var node = MapNode.new()
			node.initialize(
				node_data.get("id", ""),
				node_data.get("type", ""),
				node_data.get("layer", 0),
				node_data.get("position", 0)
			)
			node.visited = node_data.get("visited", false)
			node.properties = node_data.get("properties", {}).duplicate()
			node.rewards = node_data.get("rewards", {}).duplicate()
			map_data.add_node(node)

		# 创建连接
		for connection_data in data.get("connections", []):
			var connection = MapConnection.new()
			connection.initialize(
				connection_data.get("id", ""),
				connection_data.get("from_node_id", ""),
				connection_data.get("to_node_id", "")
			)
			connection.traversable = connection_data.get("traversable", true)
			connection.properties = connection_data.get("properties", {}).duplicate()
			map_data.add_connection(connection)

		# 加载地图
		map_manager.load_map(map_data)
		EventBus.debug.emit_event("debug_message", ["应用地图存档数据成功", 0])
	else:
		EventBus.debug.emit_event("debug_message", ["无法应用地图存档数据", 1])

## 应用棋子存档数据
func _apply_chess_pieces_save_data(data: Array) -> void:
	# 应用数据到棋子管理器
	var chess_manager = get_node_or_null("/root/GameManager/ChessManager")
	if chess_manager and data.size() > 0:
		# 设置棋子数据
		chess_manager.load_chess_pieces_data(data)
		EventBus.debug.emit_event("debug_message", ["应用棋子存档数据成功", 0])
	else:
		EventBus.debug.emit_event("debug_message", ["无法应用棋子存档数据", 1])

## 应用装备存档数据
func _apply_equipment_save_data(data: Array) -> void:
	# 应用数据到装备管理器
	var equipment_manager = get_node_or_null("/root/GameManager/EquipmentManager")
	if equipment_manager and data.size() > 0:
		# 设置装备数据
		equipment_manager.load_equipment_data(data)
		EventBus.debug.emit_event("debug_message", ["应用装备存档数据成功", 0])
	else:
		EventBus.debug.emit_event("debug_message", ["无法应用装备存档数据", 1])

## 应用遗物存档数据
func _apply_relics_save_data(data: Array) -> void:
	# 应用数据到遗物管理器
	var relic_manager = get_node_or_null("/root/GameManager/RelicManager")
	if relic_manager and data.size() > 0:
		# 设置遗物数据
		relic_manager.load_relics_data(data)
		EventBus.debug.emit_event("debug_message", ["应用遗物存档数据成功", 0])
	else:
		EventBus.debug.emit_event("debug_message", ["无法应用遗物存档数据", 1])

## 应用成就存档数据
func _apply_achievements_save_data(data: Dictionary) -> void:
	# 这里将应用数据到成就管理器
	var achievement_manager = get_node_or_null("/root/GameManager/AchievementManager")
	if achievement_manager and not data.is_empty():
		achievement_manager.load_achievement_data(data)
	EventBus.debug.emit_event("debug_message", ["应用成就存档数据", 0])

## 应用教程存档数据
func _apply_tutorials_save_data(data: Dictionary) -> void:
	# 这里将应用数据到教程管理器
	var tutorial_manager = get_node_or_null("/root/GameManager/TutorialManager")
	if tutorial_manager and not data.is_empty():
		# 加载已完成的教程
		if data.has("completed_tutorials"):
			for tutorial_id in data.completed_tutorials:
				tutorial_manager.mark_tutorial_completed(tutorial_id)

		# 加载已跳过的教程
		if data.has("skipped_tutorials"):
			for tutorial_id in data.skipped_tutorials:
				tutorial_manager.mark_tutorial_skipped(tutorial_id)
	EventBus.debug.emit_event("debug_message", ["应用教程存档数据", 0])

## 应用设置存档数据
func _apply_settings_save_data(data: Dictionary) -> void:
	# 应用数据到设置管理器
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager and not data.is_empty():
		# 应用音频设置
		if data.has("audio"):
			var audio_settings = data.audio
			if audio_settings.has("master_volume"):
				settings_manager.set_master_volume(audio_settings.master_volume)
			if audio_settings.has("music_volume"):
				settings_manager.set_music_volume(audio_settings.music_volume)
			if audio_settings.has("sfx_volume"):
				settings_manager.set_sfx_volume(audio_settings.sfx_volume)

		# 应用图形设置
		if data.has("graphics"):
			var graphics_settings = data.graphics
			if graphics_settings.has("fullscreen"):
				settings_manager.set_fullscreen(graphics_settings.fullscreen)
			if graphics_settings.has("vsync"):
				settings_manager.set_vsync(graphics_settings.vsync)

		# 应用游戏设置
		if data.has("gameplay"):
			var gameplay_settings = data.gameplay
			if gameplay_settings.has("language"):
				settings_manager.set_language(gameplay_settings.language)
			if gameplay_settings.has("show_tooltips"):
				settings_manager.set_show_tooltips(gameplay_settings.show_tooltips)

		# 保存设置
		settings_manager.save_settings()
		EventBus.debug.emit_event("debug_message", ["应用设置存档数据成功", 0])
	else:
		EventBus.debug.emit_event("debug_message", ["无法应用设置存档数据", 1])

## 保存成就数据
func save_achievement_data(data: Dictionary) -> bool:
	# 如果没有当前存档槽，使用全局成就数据文件
	var save_path = ""
	if current_save_slot != "":
		# 使用当前存档槽
		save_path = SAVE_DIR + current_save_slot + "_achievements.json"
	else:
		# 使用全局成就数据文件
		save_path = SAVE_DIR + "global_achievements.json"

	# 使用 ConfigManager 保存成就数据
	var result = GameManager.config_manager.save_json(save_path, data)
	if not result:
		EventBus.debug.emit_event("debug_message", ["无法写入成就数据文件: " + save_path, 2])
		return false

	return true

## 加载成就数据
func load_achievement_data() -> Dictionary:
	# 如果没有当前存档槽，使用全局成就数据文件
	var save_path = ""
	if current_save_slot != "":
		# 使用当前存档槽
		save_path = SAVE_DIR + current_save_slot + "_achievements.json"

		# 如果文件不存在，尝试使用全局成就数据文件
		if not FileAccess.file_exists(save_path):
			save_path = SAVE_DIR + "global_achievements.json"
	else:
		# 使用全局成就数据文件
		save_path = SAVE_DIR + "global_achievements.json"

	# 如果文件不存在，返回空字典
	if not FileAccess.file_exists(save_path):
		return {}

	# 使用 ConfigManager 加载成就数据
	var data = GameManager.config_manager.load_json(save_path)
	if data.is_empty():
		EventBus.debug.emit_event("debug_message", ["无法加载成就数据文件: " + save_path, 2])
		return {}

	return data

## 保存教程数据
func save_tutorial_data(data: Dictionary) -> bool:
	# 如果没有当前存档槽，使用全局教程数据文件
	var save_path = ""
	if current_save_slot != "":
		# 使用当前存档槽
		save_path = SAVE_DIR + current_save_slot + "_tutorials.json"
	else:
		# 使用全局教程数据文件
		save_path = SAVE_DIR + "global_tutorials.json"

	# 使用 ConfigManager 保存教程数据
	var result = GameManager.config_manager.save_json(save_path, data)
	if not result:
		EventBus.debug.emit_event("debug_message", ["无法写入教程数据文件: " + save_path, 2])
		return false

	return true

## 加载教程数据
func load_tutorial_data() -> Dictionary:
	# 如果没有当前存档槽，使用全局教程数据文件
	var save_path = ""
	if current_save_slot != "":
		# 使用当前存档槽
		save_path = SAVE_DIR + current_save_slot + "_tutorials.json"

		# 如果文件不存在，尝试使用全局教程数据文件
		if not FileAccess.file_exists(save_path):
			save_path = SAVE_DIR + "global_tutorials.json"
	else:
		# 使用全局教程数据文件
		save_path = SAVE_DIR + "global_tutorials.json"

	# 如果文件不存在，返回空字典
	if not FileAccess.file_exists(save_path):
		return {}

	# 使用 ConfigManager 加载教程数据
	var data = GameManager.config_manager.load_json(save_path)
	if data.is_empty():
		EventBus.debug.emit_event("debug_message", ["无法加载教程数据文件: " + save_path, 2])
		return {}

	return data

## 自动存档触发处理
func _on_autosave_triggered() -> void:
	if autosave_enabled and current_save_slot != "":
		save_game(AUTOSAVE_NAME)

## 触发自动存档
func trigger_autosave() -> bool:
	if autosave_enabled and GameManager.current_state != GameManager.GameState.NONE and GameManager.current_state != GameManager.GameState.MAIN_MENU:
		return save_game(AUTOSAVE_NAME)
	return false

## 游戏状态变更处理
func _on_game_state_changed(old_state, new_state) -> void:
	# 在某些状态转换时触发自动存档
	if old_state == GameManager.GameState.BATTLE and new_state != GameManager.GameState.GAME_OVER:
		if autosave_enabled and current_save_slot != "":
			save_game(AUTOSAVE_NAME)
			EventBus.debug.emit_event("debug_message", ["战斗结束后自动存档", 0])
