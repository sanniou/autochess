extends "res://scripts/managers/core/base_manager.gd"
class_name SkinManager
## 皮肤管理器
## 负责管理游戏皮肤的加载、应用和解锁

# 信号
signal skin_applied(skin_id, skin_type)
signal skin_unlocked(skin_id, skin_type)
signal skin_preview_requested(skin_id, skin_type)

# 皮肤类型常量
const CHESS_SKIN_TYPE = "chess"
const BOARD_SKIN_TYPE = "board"
const UI_SKIN_TYPE = "ui"

# 皮肤数据
var chess_skins = {}
var board_skins = {}
var ui_skins = {}

# 已解锁的皮肤
var unlocked_skins = {
	CHESS_SKIN_TYPE: [],
	BOARD_SKIN_TYPE: [],
	UI_SKIN_TYPE: []
}

# 当前选中的皮肤
var selected_skins = {
	CHESS_SKIN_TYPE: "default",
	BOARD_SKIN_TYPE: "default",
	UI_SKIN_TYPE: "default"
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

	# 加载皮肤配置
	_load_skin_configs()

	# 加载已解锁的皮肤
	_load_unlocked_skins()

	# 加载选中的皮肤
	_load_selected_skins()

	# 连接事件总线信号
	_connect_signals()

	_log_info("皮肤管理器初始化完成")

# 连接信号
func _connect_signals() -> void:
	# 皮肤相关事件
	GlobalEventBus.skin.add_class_listener(SkinEvents.ChangeSkinEvent, _on_change_skin_event)
	GlobalEventBus.skin.add_class_listener(SkinEvents.UnlockSkinEvent, _on_unlock_skin_event)
	GlobalEventBus.skin.add_class_listener(SkinEvents.PreviewSkinEvent, _on_preview_skin_event)

	# 游戏状态信号
	GlobalEventBus.save.add_class_listener(SaveEvents.GameLoadedEvent, _on_game_loaded_event)

# 皮肤变更事件处理
func _on_change_skin_event(event: SkinEvents.ChangeSkinEvent) -> void:
	var skin_type = event.skin_type
	var skin_id = event.skin_id

	# 检查皮肤类型是否有效
	if not selected_skins.has(skin_type):
		_log_warning("无效的皮肤类型: " + skin_type)
		return

	# 检查皮肤是否已解锁
	if not is_skin_unlocked(skin_id, skin_type):
		_log_warning("皮肤未解锁: " + skin_id)
		return

	# 更新选中的皮肤
	var skins = {skin_type: skin_id}
	apply_skins(skins)

# 皮肤解锁事件处理
func _on_unlock_skin_event(event: SkinEvents.UnlockSkinEvent) -> void:
	var skin_type = event.skin_type
	var skin_id = event.skin_id

	# 解锁皮肤
	unlock_skin(skin_id, skin_type)

# 皮肤预览事件处理
func _on_preview_skin_event(event: SkinEvents.PreviewSkinEvent) -> void:
	var skin_type = event.skin_type
	var skin_id = event.skin_id

	# 发送皮肤预览信号
	skin_preview_requested.emit(skin_id, skin_type)

	# 临时应用皮肤进行预览
	_preview_skin(skin_id, skin_type)

# 游戏加载事件处理
func _on_game_loaded_event(event: SaveEvents.GameLoadedEvent) -> void:
	# 重新加载皮肤数据
	_load_unlocked_skins()
	_load_selected_skins()

	# 应用皮肤效果
	_apply_skin_effects()

	_log_info("游戏加载后皮肤数据已更新")

# 加载皮肤配置
func _load_skin_configs() -> void:
	# 清空现有皮肤数据
	chess_skins.clear()
	board_skins.clear()
	ui_skins.clear()

	# 加载棋子皮肤
	var chess_skin_models = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.CHESS_SKINS)
	if not chess_skin_models.is_empty():
		for skin_id in chess_skin_models:
			var skin_model = chess_skin_models[skin_id]
			chess_skins[skin_id] = skin_model
			_log_info("加载棋子皮肤: " + skin_id)
	else:
		_log_warning("无法加载棋子皮肤配置")

	# 加载棋盘皮肤
	var board_skin_models = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.BOARD_SKINS)
	if not board_skin_models.is_empty():
		for skin_id in board_skin_models:
			var skin_model = board_skin_models[skin_id]
			board_skins[skin_id] = skin_model
			_log_info("加载棋盘皮肤: " + skin_id)
	else:
		_log_warning("无法加载棋盘皮肤配置")

	# 加载UI皮肤
	var ui_skin_models = GameManager.config_manager.get_all_config_models_enum(ConfigTypes.Type.UI_SKINS)
	if not ui_skin_models.is_empty():
		for skin_id in ui_skin_models:
			var skin_model = ui_skin_models[skin_id]
			ui_skins[skin_id] = skin_model
			_log_info("加载UI皮肤: " + skin_id)
	else:
		_log_warning("无法加载UI皮肤配置")

	_log_info("皮肤配置加载完成: 棋子皮肤" + str(chess_skins.size()) +
			  ", 棋盘皮肤" + str(board_skins.size()) +
			  ", UI皮肤" + str(ui_skins.size()))

# 加载已解锁的皮肤
func _load_unlocked_skins() -> void:
	# 从存档中加载已解锁的皮肤
	var save_data = GameManager.save_manager.get_save_data()

	if save_data.has("unlocked_skins"):
		unlocked_skins = save_data.unlocked_skins
	else:
		# 默认解锁基础皮肤
		unlocked_skins = {
			CHESS_SKIN_TYPE: ["default"],
			BOARD_SKIN_TYPE: ["default"],
			UI_SKIN_TYPE: ["default"]
		}

		# 保存到存档
		save_data.unlocked_skins = unlocked_skins
		GameManager.save_manager.save_game()

	_log_info("已解锁皮肤加载完成")

# 加载选中的皮肤
func _load_selected_skins() -> void:
	# 从存档中加载选中的皮肤
	var save_data = GameManager.save_manager.get_save_data()

	if save_data.has("selected_skins"):
		selected_skins = save_data.selected_skins
	else:
		# 默认选择基础皮肤
		selected_skins = {
			CHESS_SKIN_TYPE: "default",
			BOARD_SKIN_TYPE: "default",
			UI_SKIN_TYPE: "default"
		}

		# 保存到存档
		save_data.selected_skins = selected_skins
		GameManager.save_manager.save_game()

	_log_info("已选中皮肤加载完成")

# 获取所有皮肤
func get_all_skins(skin_type: String) -> Dictionary:
	match skin_type:
		CHESS_SKIN_TYPE:
			return chess_skins
		BOARD_SKIN_TYPE:
			return board_skins
		UI_SKIN_TYPE:
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

# 获取所有已解锁的皮肤数据
func get_all_unlocked_skin_data(skin_type: String) -> Array[SkinConfig]:
	var result: Array[SkinConfig] = []
	var unlocked = get_unlocked_skins(skin_type)
	var all_skins = get_all_skins(skin_type)

	for skin_id in unlocked:
		if all_skins.has(skin_id):
			result.append(all_skins[skin_id])

	return result

# 获取选中的皮肤
func get_selected_skins() -> Dictionary:
	return selected_skins.duplicate()

# 获取选中的皮肤ID
func get_selected_skin_id(skin_type: String) -> String:
	if selected_skins.has(skin_type):
		return selected_skins[skin_type]

	return "default"

# 获取选中的皮肤数据
func get_selected_skin_data(skin_type: String) -> SkinConfig:
	var skin_id = get_selected_skin_id(skin_type)
	return get_skin_data(skin_id, skin_type)

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
		var save_data = GameManager.save_manager.get_save_data()

		# 检查金币条件
		if unlock_condition.has("gold"):
			var required_gold = unlock_condition.gold
			if not save_data.has("gold") or save_data.gold < required_gold:
				_log_warning("金币不足，需要 " + str(required_gold) + " 金币")
				return false

			# 扣除金币
			save_data.gold -= required_gold
			_log_info("扣除 " + str(required_gold) + " 金币")

		# 检查成就条件
		if unlock_condition.has("achievement"):
			var required_achievement = unlock_condition.achievement
			if not save_data.has("achievements") or not save_data.achievements.has(required_achievement) or not save_data.achievements[required_achievement]:
				_log_warning("成就未解锁: " + required_achievement)
				return false

		# 检查等级条件
		if unlock_condition.has("level"):
			var required_level = unlock_condition.level
			if not save_data.has("level") or save_data.level < required_level:
				_log_warning("等级不足，需要等级 " + str(required_level))
				return false

		# 检查胜利次数条件
		if unlock_condition.has("win_count"):
			var required_wins = unlock_condition.win_count
			if not save_data.has("win_count") or save_data.win_count < required_wins:
				_log_warning("胜利次数不足，需要 " + str(required_wins) + " 次胜利")
				return false

	# 解锁皮肤
	if not unlocked_skins.has(skin_type):
		unlocked_skins[skin_type] = []

	unlocked_skins[skin_type].append(skin_id)
	_log_info("解锁皮肤: " + skin_id + " (类型: " + skin_type + ")")

	# 保存到存档
	var save_data = GameManager.save_manager.get_save_data()
	save_data.unlocked_skins = unlocked_skins
	GameManager.save_manager.save_game()

	# 发送解锁信号
	skin_unlocked.emit(skin_id, skin_type)

	# 发送事件通知
	GlobalEventBus.skin.dispatch_event(SkinEvents.SkinUnlockedEvent.new(skin_id, skin_type))

	return true

# 应用皮肤
func apply_skins(skins: Dictionary) -> void:
	# 检查皮肤是否已解锁
	for skin_type in skins:
		var skin_id = skins[skin_type]

		if not is_skin_unlocked(skin_id, skin_type):
			_log_warning("皮肤未解锁: " + skin_id)
			continue

		# 应用皮肤
		selected_skins[skin_type] = skin_id

		# 发送应用信号
		skin_applied.emit(skin_id, skin_type)

		# 发送事件通知
		match skin_type:
			CHESS_SKIN_TYPE:
				GlobalEventBus.skin.dispatch_event(SkinEvents.ChessSkinChangedEvent.new(skin_id))
			BOARD_SKIN_TYPE:
				GlobalEventBus.skin.dispatch_event(SkinEvents.BoardSkinChangedEvent.new(skin_id))
			UI_SKIN_TYPE:
				GlobalEventBus.skin.dispatch_event(SkinEvents.UISkinChangedEvent.new(skin_id))

	# 保存到存档
	var save_data = GameManager.save_manager.get_save_data()
	save_data.selected_skins = selected_skins
	GameManager.save_manager.save_game()

	# 应用皮肤效果
	_apply_skin_effects()

# 预览皮肤
func _preview_skin(skin_id: String, skin_type: String) -> void:
	# 获取皮肤数据
	var skin_model = get_skin_data(skin_id, skin_type)
	if skin_model == null:
		_log_warning("无法加载皮肤预览: " + skin_id)
		return

	# 根据皮肤类型发送预览事件
	match skin_type:
		CHESS_SKIN_TYPE:
			GlobalEventBus.skin.dispatch_event(SkinEvents.ChessSkinPreviewEvent.new(skin_id))
		BOARD_SKIN_TYPE:
			GlobalEventBus.skin.dispatch_event(SkinEvents.BoardSkinPreviewEvent.new(skin_id))
		UI_SKIN_TYPE:
			GlobalEventBus.skin.dispatch_event(SkinEvents.UISkinPreviewEvent.new(skin_id))

	_log_info("预览皮肤: " + skin_id + " (类型: " + skin_type + ")")

# 应用皮肤效果
func _apply_skin_effects() -> void:
	# 应用所有选中的皮肤
	for skin_type in selected_skins:
		var skin_id = selected_skins[skin_type]
		var skin_model = get_skin_data(skin_id, skin_type)

		if skin_model == null:
			_log_warning("无法加载皮肤: " + skin_id)
			continue

		# 根据皮肤类型应用效果
		match skin_type:
			CHESS_SKIN_TYPE:
				_apply_chess_skin(skin_model)
			BOARD_SKIN_TYPE:
				_apply_board_skin(skin_model)
			UI_SKIN_TYPE:
				_apply_ui_skin(skin_model)

	_log_info("皮肤效果应用完成")

# 应用棋子皮肤
func _apply_chess_skin(skin_model: SkinConfig) -> void:
	# 获取纹理覆盖
	var texture_overrides = skin_model.get_texture_overrides()

	# 通过事件总线发送皮肤变化信号
	GlobalEventBus.skin.dispatch_event(SkinEvents.ChessSkinAppliedEvent.new(skin_model.get_id(), texture_overrides))

	_log_info("应用棋子皮肤: " + skin_model.get_id())

# 应用棋盘皮肤
func _apply_board_skin(skin_model: SkinConfig) -> void:
	# 获取棋盘纹理和格子纹理
	var board_texture = skin_model.get_board_texture()
	var cell_textures = skin_model.get_cell_textures()

	# 通过事件总线发送皮肤变化信号
	GlobalEventBus.skin.dispatch_event(SkinEvents.BoardSkinAppliedEvent.new(skin_model.get_id(), board_texture, cell_textures))

	_log_info("应用棋盘皮肤: " + skin_model.get_id())

# 应用UI皮肤
func _apply_ui_skin(skin_model: SkinConfig) -> void:
	# 获取UI主题和颜色方案
	var theme_path = skin_model.get_theme_path()
	var color_scheme = skin_model.get_color_scheme()

	# 通过事件总线发送皮肤变化信号
	GlobalEventBus.skin.dispatch_event(SkinEvents.UISkinAppliedEvent.new(skin_model.get_id(), theme_path, color_scheme))

	_log_info("应用UI皮肤: " + skin_model.get_id())


# 重写重置方法
func _do_reset() -> void:
	# 重新加载皮肤配置
	_load_skin_configs()

	# 重新加载已解锁的皮肤
	_load_unlocked_skins()

	# 重新加载选中的皮肤
	_load_selected_skins()

	# 应用皮肤效果
	_apply_skin_effects()

	_log_info("皮肤管理器重置完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	GlobalEventBus.skin.remove_class_listener(SkinEvents.ChangeSkinEvent, _on_change_skin_event)
	GlobalEventBus.skin.remove_class_listener(SkinEvents.UnlockSkinEvent, _on_unlock_skin_event)
	GlobalEventBus.skin.remove_class_listener(SkinEvents.PreviewSkinEvent, _on_preview_skin_event)
	GlobalEventBus.save.remove_class_listener(SaveEvents.GameLoadedEvent, _on_game_loaded_event)

	# 清空皮肤数据
	chess_skins.clear()
	board_skins.clear()
	ui_skins.clear()

	_log_info("皮肤管理器清理完成")
