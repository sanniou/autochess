extends Node
class_name SkinSystem
## 皮肤系统
## 负责管理游戏中的皮肤，包括棋子皮肤、棋盘皮肤和UI皮肤

# 信号
signal skin_changed(skin_type: String, skin_id: String)
signal skin_unlocked(skin_type: String, skin_id: String)

# 常量
const SKIN_CONFIG_PATH = "res://config/skins.json"

# 皮肤类型
enum SkinType {
	CHESS,  # 棋子皮肤
	BOARD,  # 棋盘皮肤
	UI      # UI皮肤
}

# 皮肤配置
var skin_config: Dictionary = {}

# 当前皮肤
var current_skins: Dictionary = {
	SkinType.CHESS: "default",
	SkinType.BOARD: "default",
	SkinType.UI: "default"
}

# 已解锁的皮肤
var unlocked_skins: Dictionary = {
	SkinType.CHESS: ["default"],
	SkinType.BOARD: ["default"],
	SkinType.UI: ["default"]
}

# 引用
@onready var config_manager = get_node("/root/ConfigManager")
@onready var save_manager = get_node("/root/SaveManager")

# 初始化
func _ready() -> void:
	# 加载皮肤配置
	_load_skin_config()

	# 加载已解锁的皮肤
	_load_unlocked_skins()

	# 连接信号
	EventBus.skin_changed.connect(_on_skin_changed)
	EventBus.skin_unlocked.connect(_on_skin_unlocked)

# 加载皮肤配置
func _load_skin_config() -> void:
	# 使用标准的ConfigManager方法获取皮肤配置
	skin_config = config_manager.get_all_skins()

	if skin_config.is_empty():
		# 创建默认配置
		skin_config = {
			"chess": {
				"default": {
					"id": "default",
					"name": "默认棋子皮肤",
					"description": "默认的棋子外观",
					"preview_path": "res://assets/skins/chess/default/preview.png",
					"path": "res://assets/skins/chess/default/"
				}
			},
			"board": {
				"default": {
					"id": "default",
					"name": "默认棋盘皮肤",
					"description": "默认的棋盘外观",
					"preview_path": "res://assets/skins/board/default/preview.png",
					"path": "res://assets/skins/board/default/"
				}
			},
			"ui": {
				"default": {
					"id": "default",
					"name": "默认UI皮肤",
					"description": "默认的UI外观",
					"preview_path": "res://assets/skins/ui/default/preview.png",
					"path": "res://assets/skins/ui/default/"
				}
			}
		}

		# 保存默认配置
		config_manager.save_json(SKIN_CONFIG_PATH, skin_config)

# 加载已解锁的皮肤
func _load_unlocked_skins() -> void:
	var save_data = save_manager.get_save_data()

	if save_data.has("unlocked_skins"):
		unlocked_skins = save_data.unlocked_skins
	else:
		# 确保至少有默认皮肤
		unlocked_skins = {
			SkinType.CHESS: ["default"],
			SkinType.BOARD: ["default"],
			SkinType.UI: ["default"]
		}

		# 保存到存档
		save_data["unlocked_skins"] = unlocked_skins
		save_manager.save_game()

	# 加载当前皮肤
	if save_data.has("current_skins"):
		current_skins = save_data.current_skins
	else:
		current_skins = {
			SkinType.CHESS: "default",
			SkinType.BOARD: "default",
			SkinType.UI: "default"
		}

		# 保存到存档
		save_data["current_skins"] = current_skins
		save_manager.save_game()

	# 应用当前皮肤
	for skin_type in current_skins.keys():
		apply_skin(skin_type, current_skins[skin_type])

# 应用皮肤
func apply_skin(skin_type: SkinType, skin_id: String) -> bool:
	# 检查皮肤是否存在
	if not _skin_exists(skin_type, skin_id):
		EventBus.debug_message.emit("皮肤不存在: " + SkinType.keys()[skin_type] + " - " + skin_id, 1)
		return false

	# 检查皮肤是否已解锁
	if not _skin_unlocked(skin_type, skin_id):
		EventBus.debug_message.emit("皮肤未解锁: " + SkinType.keys()[skin_type] + " - " + skin_id, 1)
		return false

	# 更新当前皮肤
	current_skins[skin_type] = skin_id

	# 保存到存档
	var save_data = save_manager.get_save_data()
	save_data["current_skins"] = current_skins
	save_manager.save_game()

	# 根据皮肤类型应用不同的处理
	match skin_type:
		SkinType.CHESS:
			_apply_chess_skin(skin_id)
		SkinType.BOARD:
			_apply_board_skin(skin_id)
		SkinType.UI:
			_apply_ui_skin(skin_id)

	# 发送信号
	skin_changed.emit(SkinType.keys()[skin_type], skin_id)

	return true

# 解锁皮肤
func unlock_skin(skin_type: SkinType, skin_id: String) -> bool:
	# 检查皮肤是否存在
	if not _skin_exists(skin_type, skin_id):
		EventBus.debug_message.emit("皮肤不存在: " + SkinType.keys()[skin_type] + " - " + skin_id, 1)
		return false

	# 检查皮肤是否已解锁
	if _skin_unlocked(skin_type, skin_id):
		EventBus.debug_message.emit("皮肤已解锁: " + SkinType.keys()[skin_type] + " - " + skin_id, 0)
		return true

	# 解锁皮肤
	unlocked_skins[skin_type].append(skin_id)

	# 保存到存档
	var save_data = save_manager.get_save_data()
	save_data["unlocked_skins"] = unlocked_skins
	save_manager.save_game()

	# 发送信号
	skin_unlocked.emit(SkinType.keys()[skin_type], skin_id)

	return true

# 获取皮肤列表
func get_skin_list(skin_type: SkinType) -> Array:
	var skin_list = []

	match skin_type:
		SkinType.CHESS:
			if skin_config.has("chess"):
				skin_list = skin_config.chess.keys()
		SkinType.BOARD:
			if skin_config.has("board"):
				skin_list = skin_config.board.keys()
		SkinType.UI:
			if skin_config.has("ui"):
				skin_list = skin_config.ui.keys()

	return skin_list

# 获取已解锁的皮肤列表
func get_unlocked_skin_list(skin_type: SkinType) -> Array:
	return unlocked_skins[skin_type]

# 获取当前皮肤
func get_current_skin(skin_type: SkinType) -> String:
	return current_skins[skin_type]

# 获取皮肤信息
func get_skin_info(skin_type: SkinType, skin_id: String) -> Dictionary:
	var skin_info = {}

	match skin_type:
		SkinType.CHESS:
			if skin_config.has("chess") and skin_config.chess.has(skin_id):
				skin_info = skin_config.chess[skin_id]
		SkinType.BOARD:
			if skin_config.has("board") and skin_config.board.has(skin_id):
				skin_info = skin_config.board[skin_id]
		SkinType.UI:
			if skin_config.has("ui") and skin_config.ui.has(skin_id):
				skin_info = skin_config.ui[skin_id]

	return skin_info

# 获取皮肤路径
func get_skin_path(skin_type: SkinType, skin_id: String) -> String:
	var skin_info = get_skin_info(skin_type, skin_id)

	if skin_info.has("path"):
		return skin_info.path

	return ""

# 获取皮肤资源
func get_skin_resource(skin_type: SkinType, skin_id: String, resource_name: String) -> Resource:
	var skin_path = get_skin_path(skin_type, skin_id)

	if skin_path.is_empty():
		return null

	var resource_path = skin_path + resource_name

	if ResourceLoader.exists(resource_path):
		return ResourceLoader.load(resource_path)

	return null

# 检查皮肤是否存在
func _skin_exists(skin_type: SkinType, skin_id: String) -> bool:
	match skin_type:
		SkinType.CHESS:
			return skin_config.has("chess") and skin_config.chess.has(skin_id)
		SkinType.BOARD:
			return skin_config.has("board") and skin_config.board.has(skin_id)
		SkinType.UI:
			return skin_config.has("ui") and skin_config.ui.has(skin_id)

	return false

# 检查皮肤是否已解锁
func _skin_unlocked(skin_type: SkinType, skin_id: String) -> bool:
	return unlocked_skins[skin_type].has(skin_id)

# 应用棋子皮肤
func _apply_chess_skin(skin_id: String) -> void:
	# 通知棋子工厂更新皮肤
	EventBus.chess_skin_changed.emit(skin_id)

# 应用棋盘皮肤
func _apply_board_skin(skin_id: String) -> void:
	# 通知棋盘管理器更新皮肤
	EventBus.board_skin_changed.emit(skin_id)

# 应用UI皮肤
func _apply_ui_skin(skin_id: String) -> void:
	# 通知UI管理器更新皮肤
	EventBus.ui_skin_changed.emit(skin_id)

# 皮肤变化处理
func _on_skin_changed(skin_type_str: String, skin_id: String) -> void:
	# 查找皮肤类型枚举值
	var skin_type = SkinType.get(skin_type_str)
	if skin_type != null:
		apply_skin(skin_type, skin_id)

# 皮肤解锁处理
func _on_skin_unlocked(skin_type_str: String, skin_id: String) -> void:
	# 查找皮肤类型枚举值
	var skin_type = SkinType.get(skin_type_str)
	if skin_type != null:
		unlock_skin(skin_type, skin_id)
