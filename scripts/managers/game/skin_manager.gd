extends "res://scripts/managers/core/base_manager.gd"
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
	EventBus.skin.connect_event("skin_changed", _on_skin_changed)
	EventBus.skin.connect_event("skin_unlocked", _on_skin_unlocked)

	# 游戏状态信号
	EventBus.save.connect_event("game_loaded", _on_game_loaded)

# 皮肤变化处理
func _on_skin_changed(skin_type: String, skin_id: String) -> void:
	# 检查皮肤类型是否有效
	if not selected_skins.has(skin_type):
		EventBus.debug.emit_event("debug_message", ["无效的皮肤类型: " + skin_type, 1])
		return

	# 检查皮肤是否已解锁
	if not is_skin_unlocked(skin_id, skin_type):
		EventBus.debug.emit_event("debug_message", ["皮肤未解锁: " + skin_id, 1])
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
	# 清空现有皮肤数据
	chess_skins.clear()
	board_skins.clear()
	ui_skins.clear()

	# 使用 ConfigManager 加载皮肤配置
	var skins_config = ConfigManager.get_all_config_models("skins")

	if skins_config.is_empty():
		_log_warning("皮肤配置为空")
		return

	# 处理配置数据
	for skin_id in skins_config:
		var skin_model = skins_config[skin_id] as SkinConfig

		if skin_model == null:
			_log_warning("无法加载皮肤模型: " + skin_id)
			continue

		# 根据皮肤类型分类
		var skin_type = skin_model.get_skin_type()

		match skin_type:
			"theme":
				# 主题皮肤同时包含棋子、棋盘和UI皮肤
				chess_skins[skin_id] = skin_model
				board_skins[skin_id] = skin_model
				ui_skins[skin_id] = skin_model
				_log_info("加载主题皮肤: " + skin_id)
			"chess":
				chess_skins[skin_id] = skin_model
				_log_info("加载棋子皮肤: " + skin_id)
			"board":
				board_skins[skin_id] = skin_model
				_log_info("加载棋盘皮肤: " + skin_id)
			"ui":
				ui_skins[skin_id] = skin_model
				_log_info("加载界面皮肤: " + skin_id)
			_:
				_log_warning("未知的皮肤类型: " + skin_type + " for " + skin_id)

	_log_info("皮肤配置加载完成: 棋子皮肤" + str(chess_skins.size()) +
			  ", 棋盘皮肤" + str(board_skins.size()) +
			  ", UI皮肤" + str(ui_skins.size()))

# 加载已解锁的皮肤
func _load_unlocked_skins() -> void:
	# 从存档中加载已解锁的皮肤
	var save_data = SaveManager._get_player_save_data()

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
		SaveManager.save_game()

# 加载选中的皮肤
func _load_selected_skins() -> void:
	# 从存档中加载选中的皮肤
	var save_data = SaveManager._get_player_save_data()

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
		SaveManager.save_game()

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
			_log_warning("无效的皮肤类型: " + skin_type)
			return {}

# 获取皮肤数据
func get_skin_data(skin_id: String, skin_type: String) -> SkinConfig:
	var skins = get_all_skins(skin_type)

	if skins.has(skin_id):
		return skins[skin_id] as SkinConfig

	return null

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
		_log_warning("皮肤不存在: " + skin_id + " (类型: " + skin_type + ")")
		return false

	# 检查皮肤是否已解锁
	if is_skin_unlocked(skin_id, skin_type):
		_log_info("皮肤已解锁: " + skin_id)
		return true

	# 获取皮肤数据
	var skin_model = skins[skin_id] as SkinConfig
	if skin_model == null:
		_log_warning("无法加载皮肤模型: " + skin_id)
		return false

	# 检查是否有解锁条件
	var unlock_condition = skin_model.get_unlock_condition()
	if not unlock_condition.is_empty():
		# 检查是否有类型和值
		if not unlock_condition.has("type") or not unlock_condition.has("value"):
			_log_warning("无效的解锁条件: " + str(unlock_condition))
			return false

		var condition_type = unlock_condition.type
		var condition_value = unlock_condition.value

		match condition_type:
			"gold":
				# 检查金币条件
				var player_gold = SaveManager.get_save_data().gold
				if player_gold < condition_value:
					_log_warning("金币不足，需要 " + str(condition_value) + " 金币")
					return false

				# 扣除金币
				SaveManager.get_save_data().gold -= condition_value
				_log_info("扣除 " + str(condition_value) + " 金币")

			"achievement":
				# 检查成就条件
				var player_achievements = SaveManager.get_save_data().achievements
				if not player_achievements.has(condition_value) or not player_achievements[condition_value]:
					_log_warning("成就未解锁: " + condition_value)
					return false

			"level":
				# 检查等级条件
				var player_level = SaveManager.get_save_data().level
				if player_level < condition_value:
					_log_warning("等级不足，需要等级 " + str(condition_value))
					return false

			"win_count":
				# 检查胜利次数条件
				var player_win_count = SaveManager.get_save_data().win_count
				if player_win_count < condition_value:
					_log_warning("胜利次数不足，需要 " + str(condition_value) + " 次胜利")
					return false

			_:
				_log_warning("未知的解锁条件类型: " + condition_type)
				return false

	# 解锁皮肤
	if not unlocked_skins.has(skin_type):
		unlocked_skins[skin_type] = []

	unlocked_skins[skin_type].append(skin_id)
	_log_info("解锁皮肤: " + skin_id + " (类型: " + skin_type + ")")

	# 保存到存档
	SaveManager.get_save_data().unlocked_skins = unlocked_skins
	SaveManager.save_game()

	# 发送解锁信号
	skin_unlocked.emit(skin_id, skin_type)

	return true

# 应用皮肤
func apply_skins(skins: Dictionary) -> void:
	# 检查皮肤是否已解锁
	for skin_type in skins:
		var skin_id = skins[skin_type]

		if not is_skin_unlocked(skin_id, skin_type):
			EventBus.debug.emit_event("debug_message", ["皮肤未解锁: " + skin_id, 1])
			continue

		# 应用皮肤
		selected_skins[skin_type] = skin_id

		# 发送应用信号
		skin_applied.emit(skin_id, skin_type)

	# 保存到存档
	SaveManager.get_save_data().selected_skins = selected_skins
	SaveManager.save_game()

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
	var skin_model = get_skin_data(skin_id, "chess")

	if skin_model == null:
		_log_warning("无法加载棋子皮肤: " + skin_id)
		return

	# 检查皮肤是否有棋子资源
	if not skin_model.has_asset_type("chess"):
		_log_warning("皮肤没有棋子资源: " + skin_id)
		return

	# 通过事件总线发送皮肤变化信号
	EventBus.skin.emit_event("chess_skin_changed", [skin_id])

	_log_info("应用棋子皮肤: " + skin_id)

# 应用棋盘皮肤
func _apply_board_skin() -> void:
	var skin_id = selected_skins.board
	var skin_model = get_skin_data(skin_id, "board")

	if skin_model == null:
		_log_warning("无法加载棋盘皮肤: " + skin_id)
		return

	# 检查皮肤是否有棋盘资源
	if not skin_model.has_asset_type("board"):
		_log_warning("皮肤没有棋盘资源: " + skin_id)
		return

	# 通过事件总线发送皮肤变化信号
	EventBus.skin.emit_event("board_skin_changed", [skin_id])

	_log_info("应用棋盘皮肤: " + skin_id)

# 应用UI皮肤
func _apply_ui_skin() -> void:
	var skin_id = selected_skins.ui
	var skin_model = get_skin_data(skin_id, "ui")

	if skin_model == null:
		_log_warning("无法加载UI皮肤: " + skin_id)
		return

	# 检查皮肤是否有UI资源
	if not skin_model.has_asset_type("ui"):
		_log_warning("皮肤没有UI资源: " + skin_id)
		return

	# 通过事件总线发送皮肤变化信号
	EventBus.skin.emit_event("ui_skin_changed", [skin_id])

	_log_info("应用UI皮肤: " + skin_id)

# 记录错误信息
func _log_error(error_message: String) -> void:
	_error = error_message
	EventBus.debug.emit_event("debug_message", [error_message, 2])
	error_occurred.emit(error_message)

# 记录警告信息
func _log_warning(warning_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [warning_message, 1])

# 记录信息
func _log_info(info_message: String) -> void:
	EventBus.debug.emit_event("debug_message", [info_message, 0])

# 重写重置方法
func _do_reset() -> void:
	# 重新加载皮肤配置
	_load_skin_configs()

	# 重新加载已解锁的皮肤
	_load_unlocked_skins()

	# 重新加载选中的皮肤
	_load_selected_skins()

	_log_info("皮肤管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.skin.disconnect_event("skin_changed", _on_skin_changed)
	EventBus.skin.disconnect_event("skin_unlocked", _on_skin_unlocked)
	EventBus.save.disconnect_event("game_loaded", _on_game_loaded)

	# 清空皮肤数据
	chess_skins.clear()
	board_skins.clear()
	ui_skins.clear()

	_log_info("皮肤管理器清理完成")