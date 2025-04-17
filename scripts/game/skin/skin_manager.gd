extends "res://scripts/core/base_manager.gd"
class_name SkinManager
## 皮肤管理器
## 负责管理游戏皮肤的加载、应用和解锁

# 信号
signal skin_applied(skin_id, skin_type)
signal skin_unlocked(skin_id, skin_type)

# 皮肤类型
enum SkinType {
	CHESS,  # 棋子皮肤
	BOARD,  # 棋盘皮肤
	UI      # UI皮肤
}

# 皮肤配置文件路径
const SKIN_CONFIG_PATH = "res://config/skins.json"

# 皮肤数据
var chess_skins = {}
var board_skins = {}
var ui_skins = {}

# 已解锁的皮肤
var unlocked_skins = {
	"chess": [],
	"board": [],
	"ui": []
}

# 当前选中的皮肤
var selected_skins = {
	"chess": "default",
	"board": "default",
	"ui": "default"
}

# 引用
@onready var config_manager = get_node("/root/ConfigManager")
@onready var save_manager = get_node("/root/SaveManager")

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "SkinManager"
	# 添加依赖
	add_dependency("ConfigManager")
	# 添加依赖
	add_dependency("SaveManager")
	
	# 原 _ready 函数的内容
	# 加载皮肤配置
		_load_skin_configs()
	
		# 加载已解锁的皮肤
		_load_unlocked_skins()
	
		# 加载选中的皮肤
		_load_selected_skins()
	
		# 连接事件总线信号
		_connect_signals()
	
	# 连接信号
func _connect_signals() -> void:
	# 皮肤相关信号
	EventBus.skin.skin_changed.connect(_on_skin_changed)
	EventBus.skin.skin_unlocked.connect(_on_skin_unlocked)

	# 游戏状态信号
	EventBus.save.game_loaded.connect(_on_game_loaded)

# 皮肤变化处理
func _on_skin_changed(skin_type: String, skin_id: String) -> void:
	# 检查皮肤类型是否有效
	if not selected_skins.has(skin_type):
		EventBus.debug.debug_message.emit("无效的皮肤类型: " + skin_type, 1)
		return

	# 检查皮肤是否已解锁
	if not is_skin_unlocked(skin_id, skin_type):
		EventBus.debug.debug_message.emit("皮肤未解锁: " + skin_id, 1)
		return

	# 更新选中的皮肤
	var skins = {skin_type: skin_id}
	apply_skins(skins)

# 皮肤解锁处理
func _on_skin_unlocked(skin_type: String, skin_id: String) -> void:
	# 解锁皮肤
	unlock_skin(skin_id, skin_type)

# 游戏加载处理
func _on_game_loaded(slot_name: String) -> void:
	# 重新加载皮肤数据
	_load_unlocked_skins()
	_load_selected_skins()

	# 应用皮肤效果
	_apply_skin_effects()

# 加载皮肤配置
func _load_skin_configs() -> void:
	# 使用ConfigManager加载皮肤配置
	var skins_config = config_manager.get_all_skins()

	if skins_config.is_empty():
		EventBus.debug.debug_message.emit("皮肤配置为空", 1)
		return

	# 处理配置数据，分类存储
	for skin_id in skins_config.keys():
		var skin_data = skins_config[skin_id]

		# 根据皮肤类型分类
		if skin_data.has("chess_pieces"):
			chess_skins[skin_id] = skin_data

		if skin_data.has("board"):
			board_skins[skin_id] = skin_data

		if skin_data.has("ui"):
			ui_skins[skin_id] = skin_data

	EventBus.debug.debug_message.emit("皮肤配置加载完成: 棋子皮肤" + str(chess_skins.size()) + ", 棋盘皮肤" + str(board_skins.size()) + ", UI皮肤" + str(ui_skins.size()), 0)

# 加载已解锁的皮肤
func _load_unlocked_skins() -> void:
	# 从存档中加载已解锁的皮肤
	var save_data = save_manager.get_save_data()

	if save_data.has("unlocked_skins"):
		unlocked_skins = save_data.unlocked_skins
	else:
		# 默认解锁基础皮肤
		unlocked_skins = {
			"chess": ["default"],
			"board": ["default"],
			"ui": ["default"]
		}

		# 保存到存档
		save_data.unlocked_skins = unlocked_skins
		save_manager.save_game()

# 加载选中的皮肤
func _load_selected_skins() -> void:
	# 从存档中加载选中的皮肤
	var save_data = save_manager.get_save_data()

	if save_data.has("selected_skins"):
		selected_skins = save_data.selected_skins
	else:
		# 默认选择基础皮肤
		selected_skins = {
			"chess": "default",
			"board": "default",
			"ui": "default"
		}

		# 保存到存档
		save_data.selected_skins = selected_skins
		save_manager.save_game()

# 获取所有皮肤
func get_all_skins(skin_type: String) -> Dictionary:
	match skin_type:
		"chess":
			return chess_skins
		"board":
			return board_skins
		"ui":
			return ui_skins
		_:
			return {}

# 获取皮肤数据
func get_skin_data(skin_id: String, skin_type: String) -> Dictionary:
	var skins = get_all_skins(skin_type)

	if skins.has(skin_id):
		return skins[skin_id]

	return {}

# 获取已解锁的皮肤
func get_unlocked_skins(skin_type: String) -> Array:
	if unlocked_skins.has(skin_type):
		return unlocked_skins[skin_type]

	return []

# 获取选中的皮肤
func get_selected_skins() -> Dictionary:
	return selected_skins.duplicate()

# 获取选中的皮肤ID
func get_selected_skin_id(skin_type: String) -> String:
	if selected_skins.has(skin_type):
		return selected_skins[skin_type]

	return "default"

# 检查皮肤是否已解锁
func is_skin_unlocked(skin_id: String, skin_type: String) -> bool:
	if unlocked_skins.has(skin_type):
		return unlocked_skins[skin_type].has(skin_id)

	return false

# 解锁皮肤
func unlock_skin(skin_id: String, skin_type: String) -> bool:
	# 检查皮肤是否存在
	var skins = get_all_skins(skin_type)
	if not skins.has(skin_id):
		return false

	# 检查皮肤是否已解锁
	if is_skin_unlocked(skin_id, skin_type):
		return true

	# 获取皮肤数据
	var skin_data = skins[skin_id]

	# 检查是否有解锁条件
	if skin_data.has("unlock_condition"):
		var condition = skin_data.unlock_condition

		# 检查金币条件
		if condition.has("gold"):
			var required_gold = condition.gold
			var player_gold = save_manager.get_save_data().gold

			if player_gold < required_gold:
				return false

			# 扣除金币
			save_manager.get_save_data().gold -= required_gold

		# 检查成就条件
		if condition.has("achievement"):
			var required_achievement = condition.achievement
			var player_achievements = save_manager.get_save_data().achievements

			if not player_achievements.has(required_achievement):
				return false

	# 解锁皮肤
	unlocked_skins[skin_type].append(skin_id)

	# 保存到存档
	save_manager.get_save_data().unlocked_skins = unlocked_skins
	save_manager.save_game()

	# 发送解锁信号
	skin_unlocked.emit(skin_id, skin_type)

	return true

# 应用皮肤
func apply_skins(skins: Dictionary) -> void:
	# 检查皮肤是否已解锁
	for skin_type in skins:
		var skin_id = skins[skin_type]

		if not is_skin_unlocked(skin_id, skin_type):
			EventBus.debug.debug_message.emit("皮肤未解锁: " + skin_id, 1)
			continue

		# 应用皮肤
		selected_skins[skin_type] = skin_id

		# 发送应用信号
		skin_applied.emit(skin_id, skin_type)

	# 保存到存档
	save_manager.get_save_data().selected_skins = selected_skins
	save_manager.save_game()

	# 应用皮肤效果
	_apply_skin_effects()

# 应用皮肤效果
func _apply_skin_effects() -> void:
	# 应用棋子皮肤
	_apply_chess_skin()

	# 应用棋盘皮肤
	_apply_board_skin()

	# 应用UI皮肤
	_apply_ui_skin()

# 应用棋子皮肤
func _apply_chess_skin() -> void:
	var skin_id = selected_skins.chess
	var skin_data = get_skin_data(skin_id, "chess")

	if skin_data.is_empty():
		return

	# 通过事件总线发送皮肤变化信号
	EventBus.skin.chess_skin_changed.emit(skin_id)

	EventBus.debug.debug_message.emit("应用棋子皮肤: " + skin_id, 0)

# 应用棋盘皮肤
func _apply_board_skin() -> void:
	var skin_id = selected_skins.board
	var skin_data = get_skin_data(skin_id, "board")

	if skin_data.is_empty():
		return

	# 通过事件总线发送皮肤变化信号
	EventBus.skin.board_skin_changed.emit(skin_id)

	EventBus.debug.debug_message.emit("应用棋盘皮肤: " + skin_id, 0)

# 应用UI皮肤
func _apply_ui_skin() -> void:
	var skin_id = selected_skins.ui
	var skin_data = get_skin_data(skin_id, "ui")

	if skin_data.is_empty():
		return

	# 通过事件总线发送皮肤变化信号
	EventBus.skin.ui_skin_changed.emit(skin_id)

	EventBus.debug.debug_message.emit("应用UI皮肤: " + skin_id, 0)

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
