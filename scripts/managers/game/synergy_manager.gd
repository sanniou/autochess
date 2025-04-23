extends "res://scripts/managers/core/base_manager.gd"
class_name SynergyManager
## 羁绊管理器
## 管理棋子羁绊和羁绊效果

# 信号
signal synergy_activated(synergy_id, level)
signal synergy_deactivated(synergy_id, level)
signal synergy_level_changed(synergy_id, old_level, new_level)

# 羁绊配置
var synergy_configs: Dictionary = {}

# 当前激活的羁绊 {羁绊ID: 当前等级}
var active_synergies: Dictionary = {}

# 羁绊计数 {羁绊ID: 棋子数量}
var synergy_counts: Dictionary = {}

# 羁绊棋子映射 {羁绊ID: [棋子]}
var synergy_pieces: Dictionary = {}

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "SynergyManager"

	# 加载羁绊配置
	_load_synergy_configs()

	# 连接事件
	EventBus.chess.connect_event("chess_piece_added", _on_chess_piece_added)
	EventBus.chess.connect_event("chess_piece_removed", _on_chess_piece_removed)

	_log_info("羁绊管理器初始化完成")

# 重写重置方法
func _do_reset() -> void:
	# 清空激活的羁绊
	active_synergies.clear()

	# 清空羁绊计数
	synergy_counts.clear()

	# 清空羁绊棋子映射
	synergy_pieces.clear()

	_log_info("羁绊管理器已重置")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	EventBus.chess.disconnect_event("chess_piece_added", _on_chess_piece_added)
	EventBus.chess.disconnect_event("chess_piece_removed", _on_chess_piece_removed)

	# 断开配置变更信号连接
	if GameManager and GameManager.config_manager:
		if GameManager.config_manager.config_changed.is_connected(_on_config_changed):
			GameManager.config_manager.config_changed.disconnect(_on_config_changed)

	_log_info("羁绊管理器已清理")

## 配置变更回调
func _on_config_changed(config_type: String, config_id: String) -> void:
	# 检查是否是羁绊配置
	if config_type == ConfigTypes.int_to_string(ConfigTypes.Type.SYNERGIES):
		# 获取更新后的配置
		var synergy_config = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.SYNERGIES, config_id)
		if synergy_config:
			# 更新配置
			synergy_configs[config_id] = synergy_config
			_log_info("羁绊配置已更新: " + config_id)

			# 如果该羁绊当前处于激活状态，重新应用效果
			if active_synergies.has(config_id):
				var level = active_synergies[config_id]

				# 先停用羁绊
				_deactivate_synergy(config_id, level)

				# 重新激活羁绊
				_activate_synergy(config_id, level)

# 加载羁绊配置
func _load_synergy_configs() -> void:
	# 获取配置管理器
	var config_manager = GameManager.config_manager
	if not config_manager:
		_log_error("无法获取配置管理器")
		return

	# 清空现有配置
	synergy_configs.clear()

	# 使用新的配置管理器API获取所有羁绊配置
	var all_synergies = config_manager.get_all_config_models_enum(ConfigTypes.Type.SYNERGIES)

	# 存储配置
	for synergy_id in all_synergies:
		var synergy_config = all_synergies[synergy_id]
		synergy_configs[synergy_id] = synergy_config
		_log_debug("加载羁绊配置: " + synergy_id)

	# 连接配置变更信号
	if not config_manager.config_changed.is_connected(_on_config_changed):
		config_manager.config_changed.connect(_on_config_changed)

	_log_info("加载了 " + str(synergy_configs.size()) + " 个羁绊配置")

# 添加棋子
func _on_chess_piece_added(chess_piece) -> void:
	# 检查棋子是否有效
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 检查棋子是否属于玩家
	if not chess_piece.is_player_piece():
		return

	# 获取棋子的羁绊
	var chess_synergies = _get_chess_piece_synergies(chess_piece)

	# 更新羁绊计数
	for synergy_id in chess_synergies:
		# 更新羁绊计数
		if not synergy_counts.has(synergy_id):
			synergy_counts[synergy_id] = 0

		synergy_counts[synergy_id] += 1

		# 更新羁绊棋子映射
		if not synergy_pieces.has(synergy_id):
			synergy_pieces[synergy_id] = []

		synergy_pieces[synergy_id].append(chess_piece)

	# 更新羁绊状态
	_update_synergies()

# 移除棋子
func _on_chess_piece_removed(chess_piece) -> void:
	# 检查棋子是否有效
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 检查棋子是否属于玩家
	if not chess_piece.is_player_piece():
		return

	# 获取棋子的羁绊
	var chess_synergies = _get_chess_piece_synergies(chess_piece)

	# 更新羁绊计数
	for synergy_id in chess_synergies:
		# 更新羁绊计数
		if synergy_counts.has(synergy_id):
			synergy_counts[synergy_id] -= 1

			# 如果计数为0，移除羁绊
			if synergy_counts[synergy_id] <= 0:
				synergy_counts.erase(synergy_id)

		# 更新羁绊棋子映射
		if synergy_pieces.has(synergy_id):
			synergy_pieces[synergy_id].erase(chess_piece)

			# 如果没有棋子，移除羁绊
			if synergy_pieces[synergy_id].is_empty():
				synergy_pieces.erase(synergy_id)

	# 更新羁绊状态
	_update_synergies()

# 获取棋子的羁绊
func _get_chess_piece_synergies(chess_piece) -> Array:
	var synergies = []

	# 获取棋子的职业和种族
	var chess_class = chess_piece.get_class_type()
	var chess_race = chess_piece.get_race()

	# 添加职业羁绊
	if not chess_class.is_empty():
		synergies.append(chess_class)

	# 添加种族羁绊
	if not chess_race.is_empty():
		synergies.append(chess_race)

	return synergies

# 更新羁绊状态
func _update_synergies() -> void:
	# 保存旧的激活羁绊
	var old_active_synergies = active_synergies.duplicate()

	# 清空激活的羁绊
	active_synergies.clear()

	# 检查每个羁绊
	for synergy_id in synergy_counts:
		var count = synergy_counts[synergy_id]

		# 获取羁绊配置
		var synergy_config = synergy_configs.get(synergy_id)
		if not synergy_config:
			continue

		# 获取羁绊阈值
		var thresholds = synergy_config.get_thresholds()

		# 找到当前等级
		var current_level = 0

		for threshold in thresholds:
			if threshold.has("count") and count >= threshold.count:
				current_level = threshold.count

		# 如果有激活的等级，添加到激活羁绊
		if current_level > 0:
			active_synergies[synergy_id] = current_level

	# 处理羁绊变化
	_process_synergy_changes(old_active_synergies)

# 处理羁绊变化
func _process_synergy_changes(old_active_synergies: Dictionary) -> void:
	# 检查每个旧的激活羁绊
	for synergy_id in old_active_synergies:
		var old_level = old_active_synergies[synergy_id]

		# 如果羁绊不再激活，移除效果
		if not active_synergies.has(synergy_id):
			_deactivate_synergy(synergy_id, old_level)
		# 如果羁绊等级变化，更新效果
		elif active_synergies[synergy_id] != old_level:
			var new_level = active_synergies[synergy_id]
			_change_synergy_level(synergy_id, old_level, new_level)

	# 检查每个新的激活羁绊
	for synergy_id in active_synergies:
		var new_level = active_synergies[synergy_id]

		# 如果羁绊是新激活的，添加效果
		if not old_active_synergies.has(synergy_id):
			_activate_synergy(synergy_id, new_level)

# 激活羁绊
func _activate_synergy(synergy_id: String, level: int) -> void:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return

	# 获取羁绊效果
	var effects = synergy_config.get_effects_for_level(level)

	# 获取目标棋子
	var target_pieces = _get_target_pieces_for_synergy(synergy_id)

	# 应用羁绊效果
	SynergyEffectProcessor.apply_synergy_effects(synergy_id, level, effects, target_pieces)

	# 发送羁绊激活信号
	synergy_activated.emit(synergy_id, level)

	_log_info("激活羁绊: " + synergy_id + " 等级 " + str(level))

# 停用羁绊
func _deactivate_synergy(synergy_id: String, level: int) -> void:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return

	# 获取羁绊效果
	var effects = synergy_config.get_effects_for_level(level)

	# 获取目标棋子
	var target_pieces = _get_target_pieces_for_synergy(synergy_id)

	# 移除羁绊效果
	SynergyEffectProcessor.remove_synergy_effects(synergy_id, level, effects, target_pieces)

	# 发送羁绊停用信号
	synergy_deactivated.emit(synergy_id, level)

	_log_info("停用羁绊: " + synergy_id + " 等级 " + str(level))

# 改变羁绊等级
func _change_synergy_level(synergy_id: String, old_level: int, new_level: int) -> void:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return

	# 获取旧的羁绊效果
	var old_effects = synergy_config.get_effects_for_level(old_level)

	# 获取新的羁绊效果
	var new_effects = synergy_config.get_effects_for_level(new_level)

	# 获取目标棋子
	var target_pieces = _get_target_pieces_for_synergy(synergy_id)

	# 移除旧的羁绊效果
	SynergyEffectProcessor.remove_synergy_effects(synergy_id, old_level, old_effects, target_pieces)

	# 应用新的羁绊效果
	SynergyEffectProcessor.apply_synergy_effects(synergy_id, new_level, new_effects, target_pieces)

	# 发送羁绊等级变化信号
	synergy_level_changed.emit(synergy_id, old_level, new_level)

	_log_info("羁绊等级变化: " + synergy_id + " 从 " + str(old_level) + " 到 " + str(new_level))

# 获取羁绊的目标棋子
func _get_target_pieces_for_synergy(synergy_id: String) -> Array:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return []

	# 获取羁绊类型
	var synergy_type = synergy_config.get_type()

	# 根据羁绊类型获取目标棋子
	match synergy_type:
		"class":
			# 职业羁绊只影响该职业的棋子
			return synergy_pieces.get(synergy_id, [])
		"race":
			# 种族羁绊只影响该种族的棋子
			return synergy_pieces.get(synergy_id, [])
		"special":
			# 特殊羁绊影响所有玩家棋子
			return GameManager.chess_manager.get_player_pieces()
		_:
			return []

# 获取当前激活的羁绊
func get_active_synergies() -> Dictionary:
	return active_synergies

# 获取羁绊计数
func get_synergy_counts() -> Dictionary:
	return synergy_counts

# 获取羁绊配置
func get_synergy_config(synergy_id: String) -> SynergyConfig:
	# 先从缓存中获取
	if synergy_configs.has(synergy_id):
		return synergy_configs[synergy_id]

	# 如果缓存中没有，从 ConfigManager 获取
	var config = GameManager.config_manager.get_config_model_enum(ConfigTypes.Type.SYNERGIES, synergy_id)
	if config:
		# 更新缓存
		synergy_configs[synergy_id] = config
		return config

	return null

# 获取所有羁绊配置
func get_all_synergy_configs() -> Dictionary:
	# 如果缓存为空，重新加载
	if synergy_configs.is_empty():
		_load_synergy_configs()

	return synergy_configs

# 获取羁绊等级
func get_synergy_level(synergy_id: String) -> int:
	return active_synergies.get(synergy_id, 0)

# 获取羁绊数量
func get_synergy_count(synergy_id: String) -> int:
	return synergy_counts.get(synergy_id, 0)

# 获取羁绊棋子
func get_synergy_pieces(synergy_id: String) -> Array:
	return synergy_pieces.get(synergy_id, [])

# 检查羁绊是否激活
func is_synergy_active(synergy_id: String) -> bool:
	return active_synergies.has(synergy_id)

# 获取下一个阈值
func get_next_threshold(synergy_id: String) -> int:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return 0

	# 获取当前数量
	var current_count = synergy_counts.get(synergy_id, 0)

	# 获取所有阈值
	var thresholds = synergy_config.get_all_threshold_counts()

	# 找到下一个阈值
	var next_threshold = 0

	for threshold in thresholds:
		if threshold > current_count and (next_threshold == 0 or threshold < next_threshold):
			next_threshold = threshold

	return next_threshold

# 获取当前阈值
func get_current_threshold(synergy_id: String) -> int:
	return active_synergies.get(synergy_id, 0)

# 获取羁绊进度
func get_synergy_progress(synergy_id: String) -> Dictionary:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return {}

	# 获取当前数量
	var current_count = synergy_counts.get(synergy_id, 0)

	# 获取当前阈值
	var current_threshold = get_current_threshold(synergy_id)

	# 获取下一个阈值
	var next_threshold = get_next_threshold(synergy_id)

	return {
		"id": synergy_id,
		"count": current_count,
		"current_threshold": current_threshold,
		"next_threshold": next_threshold
	}

# 获取所有羁绊进度
func get_all_synergy_progress() -> Array:
	var progress = []

	# 获取所有羁绊
	var all_synergies = {}

	# 添加已有计数的羁绊
	for synergy_id in synergy_counts:
		all_synergies[synergy_id] = true

	# 添加已激活的羁绊
	for synergy_id in active_synergies:
		all_synergies[synergy_id] = true

	# 获取每个羁绊的进度
	for synergy_id in all_synergies:
		progress.append(get_synergy_progress(synergy_id))

	return progress

# 获取羁绊名称
func get_synergy_name(synergy_id: String) -> String:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return synergy_id

	return synergy_config.get_name()

# 获取羁绊描述
func get_synergy_description(synergy_id: String) -> String:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return ""

	return synergy_config.get_description()

# 获取羁绊图标路径
func get_synergy_icon_path(synergy_id: String) -> String:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return ""

	return synergy_config.get_icon_path()

# 获取羁绊颜色
func get_synergy_color(synergy_id: String) -> String:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return "#FFFFFF"

	return synergy_config.get_color()

# 获取羁绊阈值描述
func get_synergy_threshold_description(synergy_id: String, threshold: int) -> String:
	# 获取羁绊配置
	var synergy_config = synergy_configs.get(synergy_id)
	if not synergy_config:
		return ""

	# 获取阈值
	var threshold_data = synergy_config.get_threshold_for_count(threshold)
	if threshold_data.is_empty():
		return ""

	return threshold_data.get("description", "")
