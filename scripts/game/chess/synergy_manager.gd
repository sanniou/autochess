extends "res://scripts/core/base_manager.gd"
class_name SynergyManager
## 羁绊管理器
## 负责处理棋子之间的羁绊效果和加成

# 当前激活的羁绊 {羁绊类型: 激活等级}
var _active_synergies = {}

# 羁绊配置
var _synergy_configs = {}

# 初始化
# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "SynergyManager"
	
	# 原 _ready 函数的内容
	# 加载羁绊配置
		_load_synergy_configs()
	
		# 连接信号
		EventBus.chess.chess_piece_created.connect(_on_chess_piece_created)
		EventBus.chess.chess_piece_sold.connect(_on_chess_piece_sold)
		EventBus.chess.chess_piece_upgraded.connect(_on_chess_piece_upgraded)
	
	## 加载羁绊配置
func _load_synergy_configs() -> void:
	_synergy_configs = ConfigManager.get_all_synergies()

## 棋子创建事件处理
func _on_chess_piece_created(piece: ChessPiece) -> void:
	# 更新羁绊计数
	_update_synergies()

## 棋子出售事件处理
func _on_chess_piece_sold(piece: ChessPiece) -> void:
	# 更新羁绊计数
	_update_synergies()

## 棋子升级事件处理
func _on_chess_piece_upgraded(piece: ChessPiece) -> void:
	# 更新羁绊计数
	_update_synergies()

## 更新所有羁绊状态
func _update_synergies() -> void:
	# 获取所有棋子
	var all_pieces = _get_all_chess_pieces()

	# 统计羁绊数量
	var synergy_counts = {}
	for piece in all_pieces:
		for synergy in piece.synergies:
			if not synergy_counts.has(synergy):
				synergy_counts[synergy] = 0
			synergy_counts[synergy] += 1

	# 检查羁绊激活状态
	var new_active_synergies = {}

	for synergy in synergy_counts:
		var count = synergy_counts[synergy]
		var config = _synergy_configs[synergy]

		if not config:
			continue

		# 检查满足的等级
		var max_level = 0
		for level in config.levels:
			if count >= level.count:
				max_level = level.level

		if max_level > 0:
			new_active_synergies[synergy] = max_level

	# 比较新旧羁绊状态
	_compare_synergy_changes(new_active_synergies)

## 比较羁绊变化并应用效果
func _compare_synergy_changes(new_synergies: Dictionary) -> void:
	# 检查新增或升级的羁绊
	for synergy in new_synergies:
		var new_level = new_synergies[synergy]

		if _active_synergies.has(synergy):
			var old_level = _active_synergies[synergy]
			if new_level > old_level:
				# 羁绊升级
				_upgrade_synergy(synergy, old_level, new_level)
		else:
			# 新激活羁绊
			_activate_synergy(synergy, new_level)

	# 检查移除或降级的羁绊
	for synergy in _active_synergies:
		if not new_synergies.has(synergy):
			# 羁绊失效
			_deactivate_synergy(synergy, _active_synergies[synergy])
		elif new_synergies[synergy] < _active_synergies[synergy]:
			# 羁绊降级
			_downgrade_synergy(synergy, _active_synergies[synergy], new_synergies[synergy])

	# 更新当前激活羁绊
	_active_synergies = new_synergies

## 激活羁绊
func _activate_synergy(synergy: String, level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return

	# 获取对应等级的效果
	var effect = _get_synergy_effect(synergy, level)
	if not effect:
		return

	# 应用效果给所有符合条件的棋子
	var all_pieces = _get_all_chess_pieces()
	for piece in all_pieces:
		if synergy in piece.synergies:
			piece.add_effect(effect)

	# 显示羁绊激活效果
	_show_synergy_activation_effect(synergy, level)

	# 发送羁绊激活信号
	EventBus.chess.synergy_activated.emit(synergy, level)

## 升级羁绊
func _upgrade_synergy(synergy: String, old_level: int, new_level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return

	# 移除旧效果
	var old_effect = _get_synergy_effect(synergy, old_level)
	if old_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.remove_effect(old_effect.id)

	# 添加新效果
	var new_effect = _get_synergy_effect(synergy, new_level)
	if new_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.add_effect(new_effect)

	# 显示羁绊升级效果
	_show_synergy_upgrade_effect(synergy, old_level, new_level)

	# 发送羁绊升级信号
	EventBus.chess.synergy_activated.emit(synergy, new_level)

## 降级羁绊
func _downgrade_synergy(synergy: String, old_level: int, new_level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return

	# 移除旧效果
	var old_effect = _get_synergy_effect(synergy, old_level)
	if old_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.remove_effect(old_effect.id)

	# 添加新效果
	var new_effect = _get_synergy_effect(synergy, new_level)
	if new_effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.add_effect(new_effect)

	# 发送羁绊降级信号
	EventBus.chess.synergy_activated.emit(synergy, new_level)

## 取消激活羁绊
func _deactivate_synergy(synergy: String, level: int) -> void:
	var config = _synergy_configs[synergy]
	if not config:
		return

	# 移除效果
	var effect = _get_synergy_effect(synergy, level)
	if effect:
		var all_pieces = _get_all_chess_pieces()
		for piece in all_pieces:
			if synergy in piece.synergies:
				piece.remove_effect(effect.id)

	# 显示羁绊失效效果
	_show_synergy_deactivation_effect(synergy, level)

	# 发送羁绊失效信号
	EventBus.chess.synergy_deactivated.emit(synergy)

## 获取羁绊效果
func _get_synergy_effect(synergy: String, level: int) -> Dictionary:
	var config = _synergy_configs[synergy]
	if not config:
		return {}

	# 查找对应等级的效果
	# 优先使用thresholds字段，如果不存在则尝试使用tiers字段（向后兼容）
	var levels = config.thresholds if config.has("thresholds") and config.thresholds.size() > 0 else config.tiers if config.has("tiers") else []
	for lvl in levels:
		if lvl.level == level:
			var effect = lvl.effect.duplicate(true)
			effect.id = "synergy_%s_%d" % [synergy, level]
			effect.synergy_id = synergy
			effect.level = level

			# 根据效果类型进行处理
			if effect.has("type"):
				match effect.type:
					"stat_boost":
						# 属性提升效果
						effect.is_passive = true

					"spell_amp":
						# 法术增强效果
						effect.is_passive = true

					"double_attack":
						# 二次攻击效果
						effect.is_passive = true

					"crit":
						# 暴击效果
						effect.is_passive = true

					"team_buff":
						# 团队增益效果
						effect.is_passive = true

					"cooldown_reduction":
						# 冷却缩减效果
						effect.is_passive = true

					"dodge":
						# 闪避效果
						effect.is_passive = true

					"summon_boost":
						# 召唤物加成效果
						effect.is_passive = true
						effect.is_summon_boost = true

					"elemental_effect":
						# 元素效果
						effect.is_passive = true
						effect.is_elemental_effect = true

			return effect

	return {}

## 获取所有棋子
func _get_all_chess_pieces() -> Array:
	var pieces = []

	# 获取玩家棋子
	var player_pieces = get_tree().get_nodes_in_group("player_chess_pieces")
	pieces.append_array(player_pieces)

	# 获取场上棋子（如果有）
	var board_pieces = get_tree().get_nodes_in_group("board_chess_pieces")
	pieces.append_array(board_pieces)

	return pieces

## 获取当前激活的羁绊
func get_active_synergies() -> Dictionary:
	return _active_synergies

## 获取特定羁绊的激活等级
func get_synergy_level(synergy: String) -> int:
	if _active_synergies.has(synergy):
		return _active_synergies[synergy]
	return 0

## 获取羁绊配置
func get_synergy_config(synergy: String) -> Dictionary:
	if _synergy_configs.has(synergy):
		return _synergy_configs[synergy]
	return {}

## 获取所有羁绊配置
func get_all_synergy_configs() -> Dictionary:
	return _synergy_configs

## 添加羁绊等级
func add_synergy_level(synergy_id: String, level_add: int) -> void:
	# 检查羁绊是否存在
	if not _synergy_configs.has(synergy_id):
		return

	# 获取当前等级
	var current_level = 0
	if _active_synergies.has(synergy_id):
		current_level = _active_synergies[synergy_id]

	# 计算新等级
	var new_level = current_level + level_add

	# 如果新等级小于等于0，取消羁绊
	if new_level <= 0:
		if _active_synergies.has(synergy_id):
			_deactivate_synergy(synergy_id, current_level)
			_active_synergies.erase(synergy_id)
		return

	# 如果羁绊已经激活，升级或降级
	if _active_synergies.has(synergy_id):
		if new_level > current_level:
			_upgrade_synergy(synergy_id, current_level, new_level)
		else:
			_downgrade_synergy(synergy_id, current_level, new_level)
	else:
		# 如果羁绊未激活，激活它
		_activate_synergy(synergy_id, new_level)

	# 更新激活羁绊
	_active_synergies[synergy_id] = new_level

## 强制激活羁绊
func force_activate_synergy(synergy_id: String, level: int = 1) -> void:
	# 检查羁绊是否存在
	if not _synergy_configs.has(synergy_id):
		return

	# 获取当前等级
	var current_level = 0
	if _active_synergies.has(synergy_id):
		current_level = _active_synergies[synergy_id]

		# 如果当前等级已经大于等于目标等级，不做任何操作
		if current_level >= level:
			return

		# 升级羁绊
		_upgrade_synergy(synergy_id, current_level, level)
	else:
		# 激活羁绊
		_activate_synergy(synergy_id, level)

	# 更新激活羁绊
	_active_synergies[synergy_id] = level

## 强制取消羁绊激活
func deactivate_forced_synergy(synergy_id: String) -> void:
	# 检查羁绊是否存在且已激活
	if not _active_synergies.has(synergy_id):
		return

	# 取消羁绊
	_deactivate_synergy(synergy_id, _active_synergies[synergy_id])
	_active_synergies.erase(synergy_id)

	# 重新计算羁绊
	_update_synergies()

## 重置羁绊管理器
func reset() -> void:
	# 取消所有激活的羁绊
	for synergy in _active_synergies:
		_deactivate_synergy(synergy, _active_synergies[synergy])

	_active_synergies = {}

## 显示羁结激活效果
func _show_synergy_activation_effect(synergy: String, level: int) -> void:
	# 获取羁结配置
	var config = _synergy_configs[synergy]
	if not config:
		return

	# 获取所有符合条件的棋子
	var affected_pieces = []
	var all_pieces = _get_all_chess_pieces()
	for piece in all_pieces:
		if synergy in piece.synergies:
			affected_pieces.append(piece)

	# 如果没有受影响的棋子，返回
	if affected_pieces.size() == 0:
		return

	# 获取羁结颜色
	var synergy_color = _get_synergy_color(synergy)

	# 为每个受影响的棋子创建效果
	for piece in affected_pieces:
		# 创建羁结效果容器
		var effect_container = Node2D.new()
		effect_container.name = "SynergyEffect_" + synergy
		piece.add_child(effect_container)

		# 创建羁结图标
		var effect_icon = ColorRect.new()
		effect_icon.color = synergy_color
		effect_icon.size = Vector2(30, 30)
		effect_icon.position = Vector2(-15, -50)
		effect_container.add_child(effect_icon)

		# 创建羁结文本
		var effect_label = Label.new()
		effect_label.text = config.name + " " + str(level)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		effect_label.size = Vector2(60, 20)
		effect_label.position = Vector2(-30, -80)
		effect_container.add_child(effect_label)

		# 创建效果动画
		var tween = piece.create_tween()
		tween.tween_property(effect_icon, "scale", Vector2(1.5, 1.5), 0.3)
		tween.tween_property(effect_icon, "scale", Vector2(1.0, 1.0), 0.3)
		tween.parallel().tween_property(effect_label, "modulate", synergy_color, 0.3)
		tween.tween_property(effect_container, "modulate", Color(1, 1, 1, 0), 1.0)
		tween.tween_callback(effect_container.queue_free)

	# 播放羁结激活音效
	EventBus.audio.play_sound.emit("synergy_activate", affected_pieces[0].global_position)

## 显示羁结升级效果
func _show_synergy_upgrade_effect(synergy: String, old_level: int, new_level: int) -> void:
	# 获取羁结配置
	var config = _synergy_configs[synergy]
	if not config:
		return

	# 获取所有符合条件的棋子
	var affected_pieces = []
	var all_pieces = _get_all_chess_pieces()
	for piece in all_pieces:
		if synergy in piece.synergies:
			affected_pieces.append(piece)

	# 如果没有受影响的棋子，返回
	if affected_pieces.size() == 0:
		return

	# 获取羁结颜色
	var synergy_color = _get_synergy_color(synergy)

	# 为每个受影响的棋子创建效果
	for piece in affected_pieces:
		# 创建羁结效果容器
		var effect_container = Node2D.new()
		effect_container.name = "SynergyUpgradeEffect_" + synergy
		piece.add_child(effect_container)

		# 创建羁结图标
		var effect_icon = ColorRect.new()
		effect_icon.color = synergy_color
		effect_icon.size = Vector2(30, 30)
		effect_icon.position = Vector2(-15, -50)
		effect_container.add_child(effect_icon)

		# 创建羁结文本
		var effect_label = Label.new()
		effect_label.text = config.name + " " + str(old_level) + " → " + str(new_level)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		effect_label.size = Vector2(80, 20)
		effect_label.position = Vector2(-40, -80)
		effect_container.add_child(effect_label)

		# 创建效果动画
		var tween = piece.create_tween()
		tween.tween_property(effect_icon, "scale", Vector2(1.5, 1.5), 0.3)
		tween.tween_property(effect_icon, "scale", Vector2(1.0, 1.0), 0.3)
		tween.parallel().tween_property(effect_label, "modulate", synergy_color, 0.3)
		tween.tween_property(effect_container, "modulate", Color(1, 1, 1, 0), 1.0)
		tween.tween_callback(effect_container.queue_free)

	# 播放羁结升级音效
	EventBus.audio.play_sound.emit("synergy_upgrade", affected_pieces[0].global_position)

## 显示羁结失效效果
func _show_synergy_deactivation_effect(synergy: String, level: int) -> void:
	# 获取羁结配置
	var config = _synergy_configs[synergy]
	if not config:
		return

	# 获取所有符合条件的棋子
	var affected_pieces = []
	var all_pieces = _get_all_chess_pieces()
	for piece in all_pieces:
		if synergy in piece.synergies:
			affected_pieces.append(piece)

	# 如果没有受影响的棋子，返回
	if affected_pieces.size() == 0:
		return

	# 获取羁结颜色
	var synergy_color = _get_synergy_color(synergy)

	# 为每个受影响的棋子创建效果
	for piece in affected_pieces:
		# 创建羁结效果容器
		var effect_container = Node2D.new()
		effect_container.name = "SynergyDeactivateEffect_" + synergy
		piece.add_child(effect_container)

		# 创建羁结图标
		var effect_icon = ColorRect.new()
		effect_icon.color = Color(0.5, 0.5, 0.5, 0.5) # 灰色
		effect_icon.size = Vector2(30, 30)
		effect_icon.position = Vector2(-15, -50)
		effect_container.add_child(effect_icon)

		# 创建羁结文本
		var effect_label = Label.new()
		effect_label.text = config.name + " 失效"
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		effect_label.size = Vector2(60, 20)
		effect_label.position = Vector2(-30, -80)
		effect_container.add_child(effect_label)

		# 创建效果动画
		var tween = piece.create_tween()
		tween.tween_property(effect_icon, "modulate", Color(0.5, 0.5, 0.5, 0.3), 0.5)
		tween.tween_property(effect_container, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(effect_container.queue_free)

	# 播放羁结失效音效
	EventBus.audio.play_sound.emit("synergy_deactivate", affected_pieces[0].global_position)

## 获取羁结颜色
func _get_synergy_color(synergy: String) -> Color:
	# 根据羁结类型返回不同的颜色
	match synergy:
		"warrior":
			return Color(0.8, 0.0, 0.0, 0.7) # 红色
		"mage":
			return Color(0.0, 0.0, 0.8, 0.7) # 蓝色
		"assassin":
			return Color(0.5, 0.0, 0.5, 0.7) # 紫色
		"ranger":
			return Color(0.0, 0.8, 0.0, 0.7) # 绿色
		"support":
			return Color(1.0, 1.0, 0.0, 0.7) # 黄色
		"summoner":
			return Color(0.0, 0.8, 0.8, 0.7) # 青色
		"elemental":
			return Color(1.0, 0.5, 0.0, 0.7) # 橙色
		"human":
			return Color(0.8, 0.8, 0.8, 0.7) # 白色
		"elf":
			return Color(0.0, 0.5, 0.0, 0.7) # 深绿色
		_:
			return Color(0.5, 0.5, 0.5, 0.7) # 灰色

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
