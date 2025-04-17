extends "res://scripts/core/base_manager.gd"
class_name StatusEffectManager

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "StatusEffectManager"
## 状态效果管理器
## 负责管理棋子的各种状态效果

# 状态效果类型
enum StatusEffectType {
	STUN,       # 眩晕：无法行动
	SILENCE,    # 沉默：无法施放技能
	SLOW,       # 减速：移动速度降低
	DISARM,     # 缴械：无法普通攻击
	TAUNT,      # 嘲讽：强制攻击施法者
	BURNING,    # 燃烧：持续受到伤害
	POISONED,   # 中毒：持续受到伤害
	FROZEN,     # 冰冻：无法移动
	BLEEDING,   # 流血：移动时受到伤害
	BUFF,       # 增益：提升属性
	DEBUFF      # 减益：降低属性
}

# 状态效果优先级
const EFFECT_PRIORITY = {
	StatusEffectType.STUN: 5,      # 眩晕优先级最高
	StatusEffectType.TAUNT: 4,     # 嘲讽次之
	StatusEffectType.SILENCE: 3,   # 沉默
	StatusEffectType.FROZEN: 3,    # 冰冻与沉默同级
	StatusEffectType.DISARM: 2,    # 缴械
	StatusEffectType.SLOW: 1,      # 减速
	StatusEffectType.BURNING: 0,   # 燃烧（伤害效果）
	StatusEffectType.POISONED: 0,  # 中毒（伤害效果）
	StatusEffectType.BLEEDING: 0,  # 流血（伤害效果）
	StatusEffectType.BUFF: 0,      # 增益效果
	StatusEffectType.DEBUFF: 0     # 减益效果
}

# 控制效果互斥规则
const EFFECT_EXCLUSIVITY = {
	StatusEffectType.STUN: [StatusEffectType.SILENCE, StatusEffectType.DISARM, StatusEffectType.SLOW], # 眩晕包含沉默、缴械和减速效果
	StatusEffectType.FROZEN: [StatusEffectType.SLOW], # 冰冻包含减速效果
	StatusEffectType.SILENCE: [], # 沉默不与其他效果互斥
	StatusEffectType.DISARM: [], # 缴械不与其他效果互斥
	StatusEffectType.SLOW: [], # 减速不与其他效果互斥
	StatusEffectType.TAUNT: [] # 嘲讽不与其他效果互斥
}

# 状态效果数据
class StatusEffect:
	var id: String                  # 唯一标识符
	var type: StatusEffectType      # 效果类型
	var name: String                # 效果名称
	var description: String         # 效果描述
	var icon: String                # 效果图标
	var duration: float             # 持续时间(秒)
	var remaining_time: float       # 剩余时间(秒)
	var value: float                # 效果值
	var source                      # 效果来源
	var is_stackable: bool = false  # 是否可叠加
	var stack_count: int = 1        # 叠加层数
	var immunity_time: float = 0.5  # 免疫时间(秒)
	var visual_effect: String = ""  # 视觉效果
	var sound_effect: String = ""   # 音效

	func _init(effect_id: String, effect_type: StatusEffectType, effect_name: String,
			effect_description: String, effect_duration: float, effect_value: float = 0.0,
			effect_source = null, effect_icon: String = "", effect_stackable: bool = false):
		id = effect_id
		type = effect_type
		name = effect_name
		description = effect_description
		duration = effect_duration
		remaining_time = effect_duration
		value = effect_value
		source = effect_source
		icon = effect_icon
		is_stackable = effect_stackable

	# 更新效果
	func update(delta: float) -> bool:
		remaining_time -= delta
		return remaining_time > 0

	# 刷新持续时间
	func refresh(new_duration: float = -1) -> void:
		if new_duration > 0:
			duration = new_duration
			remaining_time = new_duration
		else:
			remaining_time = duration

	# 增加叠加层数
	func add_stack() -> void:
		if is_stackable:
			stack_count += 1

	# 获取效果描述
	func get_description() -> String:
		var desc = description
		if is_stackable and stack_count > 1:
			desc += " (x" + str(stack_count) + ")"
		return desc

	# 获取剩余时间文本
	func get_remaining_time_text() -> String:
		return "%.1f秒" % remaining_time

# 棋子引用
var chess_piece: ChessPiece

# 活跃效果列表
var active_effects: Dictionary = {}  # 效果ID -> StatusEffect

# 效果免疫计时器
var immunity_timers: Dictionary = {}  # 效果类型 -> 剩余免疫时间

# 初始化
func _init(piece: ChessPiece):
	chess_piece = piece

# 更新所有效果
func update(delta: float) -> void:
	# 更新活跃效果
	var effects_to_remove = []
	var effects_changed = false

	for effect_id in active_effects:
		var effect = active_effects[effect_id]
		if not effect.update(delta):
			effects_to_remove.append(effect_id)
			effects_changed = true

	# 移除过期效果
	for effect_id in effects_to_remove:
		remove_effect(effect_id)

	# 更新免疫计时器
	var immunities_to_remove = []

	for effect_type in immunity_timers:
		immunity_timers[effect_type] -= delta
		if immunity_timers[effect_type] <= 0:
			immunities_to_remove.append(effect_type)

	# 移除过期免疫
	for effect_type in immunities_to_remove:
		immunity_timers.erase(effect_type)

	# 如果效果发生变化，更新视觉显示
	if effects_changed or effects_to_remove.size() > 0 or immunities_to_remove.size() > 0:
		update_effect_visuals()

# 添加效果
func add_effect(effect: StatusEffect) -> bool:
	# 检查是否免疫该效果
	if is_immune_to(effect.type):
		# 显示免疫视觉效果
		_show_immunity_effect()

		# 发送免疫触发信号
		EventBus.status_effect.status_effect_immunity_triggered.emit(chess_piece, effect.type)
		return false

	# 检查是否已有同类型效果
	var existing_effect = get_effect_by_type(effect.type)
	if existing_effect:
		# 如果新效果优先级更高或持续时间更长，则替换
		if EFFECT_PRIORITY[effect.type] > EFFECT_PRIORITY[existing_effect.type] or \
		   (EFFECT_PRIORITY[effect.type] == EFFECT_PRIORITY[existing_effect.type] and \
			effect.duration > existing_effect.remaining_time):
			remove_effect(existing_effect.id)
		else:
			# 如果可叠加，增加叠加层数
			if existing_effect.is_stackable:
				existing_effect.add_stack()

				# 发送效果叠加信号
				EventBus.status_effect.status_effect_stacked.emit(chess_piece, existing_effect, existing_effect.stack_count)

				# 显示叠加视觉效果
				_show_stack_visual(existing_effect)
				return true
			else:
				# 如果不可叠加，刷新持续时间
				existing_effect.refresh(effect.duration)

				# 发送效果刷新信号
				EventBus.status_effect.status_effect_refreshed.emit(chess_piece, existing_effect)
				return false

	# 检查互斥效果
	if EFFECT_EXCLUSIVITY.has(effect.type):
		for excluded_type in EFFECT_EXCLUSIVITY[effect.type]:
			var excluded_effect = get_effect_by_type(excluded_type)
			if excluded_effect:
				remove_effect(excluded_effect.id)

	# 添加新效果
	active_effects[effect.id] = effect

	# 应用效果
	_apply_effect(effect)

	# 发送效果添加信号
	EventBus.status_effect.status_effect_added.emit(chess_piece, effect)

	# 显示效果添加视觉反馈
	_show_effect_applied_visual(effect)

	return true

# 移除效果
func remove_effect(effect_id: String) -> void:
	if not active_effects.has(effect_id):
		return

	var effect = active_effects[effect_id]

	# 取消效果
	_unapply_effect(effect)

	# 设置免疫时间
	immunity_timers[effect.type] = effect.immunity_time

	# 移除效果
	active_effects.erase(effect_id)

	# 发送效果移除信号
	EventBus.status_effect.status_effect_removed.emit(chess_piece, effect)

# 清除所有效果
func clear_all_effects() -> void:
	var effect_ids = active_effects.keys()
	for effect_id in effect_ids:
		remove_effect(effect_id)

# 检查是否有特定类型的效果
func has_effect_type(effect_type: StatusEffectType) -> bool:
	for effect_id in active_effects:
		if active_effects[effect_id].type == effect_type:
			return true
	return false

# 获取特定类型的效果
func get_effect_by_type(effect_type: StatusEffectType):
	for effect_id in active_effects:
		if active_effects[effect_id].type == effect_type:
			return active_effects[effect_id]
	return null

# 检查是否有特定类型的效果
func has_effect(effect_type: StatusEffectType) -> bool:
	for effect_id in active_effects:
		if active_effects[effect_id].type == effect_type:
			return true
	return false

# 检查是否免疫特定类型的效果
func is_immune_to(effect_type: StatusEffectType) -> bool:
	# 检查免疫计时器
	if immunity_timers.has(effect_type) and immunity_timers[effect_type] > 0:
		return true

	# 检查控制抗性
	var control_resistance = chess_piece.control_resistance
	if control_resistance > 0:
		# 根据控制抗性计算免疫概率
		var immune_chance = min(control_resistance / 100.0, 0.7)  # 最高70%免疫概率

		# 根据效果类型调整免疫概率
		if effect_type == StatusEffectType.STUN:
			# 眩晕效果更难免疫
			immune_chance *= 0.8
		elif effect_type == StatusEffectType.SILENCE:
			# 沉默效果正常免疫
			immune_chance *= 1.0
		elif effect_type == StatusEffectType.DISARM:
			# 缴械效果正常免疫
			immune_chance *= 1.0
		elif effect_type == StatusEffectType.SLOW:
			# 减速效果更容易免疫
			immune_chance *= 1.2
		elif effect_type == StatusEffectType.FROZEN:
			# 冰冻效果更难免疫
			immune_chance *= 0.9

		# 根据棋子星级提升免疫概率
		immune_chance *= (1.0 + 0.1 * (chess_piece.star_level - 1))

		if randf() < immune_chance:
			# 设置短暂免疫
			immunity_timers[effect_type] = 1.0
			return true

	return false

# 应用效果
func _apply_effect(effect: StatusEffect) -> void:
	match effect.type:
		StatusEffectType.STUN:
			# 眩晕效果
			chess_piece.change_state(ChessPiece.ChessState.STUNNED)
			# 添加眩晕视觉效果
			_add_stun_visual_effect()

		StatusEffectType.SILENCE:
			# 沉默效果
			chess_piece.is_silenced = true
			# 添加沉默视觉效果
			_add_silence_visual_effect()

		StatusEffectType.SLOW:
			# 减速效果
			chess_piece.move_speed *= (1.0 - effect.value)
			chess_piece.attack_speed *= (1.0 - effect.value * 0.5)  # 攻击速度减少一半的效果
			# 添加减速视觉效果
			_add_slow_visual_effect()

		StatusEffectType.DISARM:
			# 缴械效果
			chess_piece.is_disarmed = true
			# 添加缴械视觉效果
			_add_disarm_visual_effect()

		StatusEffectType.TAUNT:
			# 嘲讽效果
			chess_piece.taunted_by = effect.source
			# 添加嘲讽视觉效果
			_add_taunt_visual_effect(effect.source)

		StatusEffectType.BURNING:
			# 燃烧效果
			# 在update中处理持续伤害
			_add_burning_visual_effect()

		StatusEffectType.POISONED:
			# 中毒效果
			# 在update中处理持续伤害
			_add_poison_visual_effect()

		StatusEffectType.FROZEN:
			# 冰冻效果
			chess_piece.is_frozen = true
			chess_piece.move_speed = 0
			# 添加冰冻视觉效果
			_add_frozen_visual_effect()

		StatusEffectType.BLEEDING:
			# 流血效果
			# 在移动时处理伤害
			_add_bleeding_visual_effect()

		StatusEffectType.BUFF:
			# 增益效果
			# 根据效果值增加属性
			if effect.source and effect.source.has_meta("buff_stats"):
				var buff_stats = effect.source.get_meta("buff_stats")
				for stat_name in buff_stats:
					var stat_value = buff_stats[stat_name]
					_apply_stat_change(stat_name, stat_value)
			# 添加增益视觉效果
			_add_buff_visual_effect()

		StatusEffectType.DEBUFF:
			# 减益效果
			# 根据效果值减少属性
			if effect.source and effect.source.has_meta("debuff_stats"):
				var debuff_stats = effect.source.get_meta("debuff_stats")
				for stat_name in debuff_stats:
					var stat_value = debuff_stats[stat_name]
					_apply_stat_change(stat_name, -stat_value)
			# 添加减益视觉效果
			_add_debuff_visual_effect()

# 取消效果
func _unapply_effect(effect: StatusEffect) -> void:
	match effect.type:
		StatusEffectType.STUN:
			# 取消眩晕效果
			if chess_piece.current_state == ChessPiece.ChessState.STUNNED:
				chess_piece.change_state(ChessPiece.ChessState.IDLE)

		StatusEffectType.SILENCE:
			# 取消沉默效果
			chess_piece.is_silenced = false

		StatusEffectType.SLOW:
			# 取消减速效果
			chess_piece.move_speed /= (1.0 - effect.value)
			chess_piece.attack_speed /= (1.0 - effect.value * 0.5)

		StatusEffectType.DISARM:
			# 取消缴械效果
			chess_piece.is_disarmed = false

		StatusEffectType.TAUNT:
			# 取消嘲讽效果
			chess_piece.taunted_by = null

		StatusEffectType.FROZEN:
			# 取消冰冻效果
			chess_piece.is_frozen = false
			chess_piece.move_speed = chess_piece.base_move_speed

		StatusEffectType.BUFF:
			# 取消增益效果
			# 恢复属性
			if effect.source and effect.source.has_meta("buff_stats"):
				var buff_stats = effect.source.get_meta("buff_stats")
				for stat_name in buff_stats:
					var stat_value = buff_stats[stat_name]
					_apply_stat_change(stat_name, -stat_value)

		StatusEffectType.DEBUFF:
			# 取消减益效果
			# 恢复属性
			if effect.source and effect.source.has_meta("debuff_stats"):
				var debuff_stats = effect.source.get_meta("debuff_stats")
				for stat_name in debuff_stats:
					var stat_value = debuff_stats[stat_name]
					_apply_stat_change(stat_name, stat_value)

# 处理持续伤害效果
func process_dot_effects(delta: float) -> void:
	for effect_id in active_effects:
		var effect = active_effects[effect_id]

		match effect.type:
			StatusEffectType.BURNING:
				# 燃烧伤害
				var damage = effect.value * delta
				chess_piece.take_damage(damage, "fire", effect.source)

				# 播放燃烧效果
				if chess_piece.has_method("_play_effect"):
					chess_piece._play_effect("burning", Color(1.0, 0.5, 0.0, 0.7))

				# 发送持续伤害触发信号
				EventBus.status_effect.status_effect_dot_triggered.emit(chess_piece, effect, damage)

			StatusEffectType.POISONED:
				# 中毒伤害
				var damage = effect.value * delta
				chess_piece.take_damage(damage, "poison", effect.source)

				# 播放中毒效果
				if chess_piece.has_method("_play_effect"):
					chess_piece._play_effect("poisoned", Color(0.5, 1.0, 0.0, 0.7))

				# 发送持续伤害触发信号
				EventBus.status_effect.status_effect_dot_triggered.emit(chess_piece, effect, damage)

# 处理移动时的效果
func process_movement_effects() -> void:
	for effect_id in active_effects:
		var effect = active_effects[effect_id]

		match effect.type:
			StatusEffectType.BLEEDING:
				# 流血伤害
				var damage = effect.value
				chess_piece.take_damage(damage, "physical", effect.source)

				# 播放流血效果
				if chess_piece.has_method("_play_effect"):
					chess_piece._play_effect("bleeding", Color(1.0, 0.0, 0.0, 0.7))

				# 发送持续伤害触发信号
				EventBus.status_effect.status_effect_dot_triggered.emit(chess_piece, effect, damage)

# 获取所有活跃效果
func get_all_effects() -> Array:
	return active_effects.values()

# 应用属性变化
func _apply_stat_change(stat_name: String, value: float) -> void:
	# 根据属性名称应用变化
	if not chess_piece:
		return

	match stat_name:
		"attack_damage":
			chess_piece.attack_damage += value
		"attack_speed":
			chess_piece.attack_speed += value
		"armor":
			chess_piece.armor += value
		"magic_resist":
			chess_piece.magic_resist += value
		"move_speed":
			chess_piece.move_speed += value
		"max_health":
			chess_piece.max_health += value
			# 如果增加最大生命值，同时增加当前生命值
			if value > 0:
				chess_piece.current_health += value
		"spell_power":
			chess_piece.spell_power += value
		"crit_chance":
			chess_piece.crit_chance += value
		"crit_damage":
			chess_piece.crit_damage += value
		"dodge_chance":
			chess_piece.dodge_chance += value
		"control_resistance":
			chess_piece.control_resistance += value

	# 更新视觉效果
	chess_piece._update_visuals()

# 获取效果图标
func get_effect_icon(effect_type: StatusEffectType) -> String:
	match effect_type:
		StatusEffectType.STUN:
			return "res://assets/images/effects/stun_icon.png"
		StatusEffectType.SILENCE:
			return "res://assets/images/effects/silence_icon.png"
		StatusEffectType.SLOW:
			return "res://assets/images/effects/slow_icon.png"
		StatusEffectType.DISARM:
			return "res://assets/images/effects/disarm_icon.png"
		StatusEffectType.TAUNT:
			return "res://assets/images/effects/taunt_icon.png"
		StatusEffectType.BURNING:
			return "res://assets/images/effects/burning_icon.png"
		StatusEffectType.POISONED:
			return "res://assets/images/effects/poison_icon.png"
		StatusEffectType.FROZEN:
			return "res://assets/images/effects/frozen_icon.png"
		StatusEffectType.BLEEDING:
			return "res://assets/images/effects/bleeding_icon.png"
		StatusEffectType.BUFF:
			return "res://assets/images/effects/buff_icon.png"
		StatusEffectType.DEBUFF:
			return "res://assets/images/effects/debuff_icon.png"
		_:
			return ""

# 显示效果应用视觉效果
func _show_effect_applied_visual(effect: StatusEffect) -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	chess_piece.add_child(effect_container)

	# 根据效果类型设置颜色
	var effect_color = Color.WHITE
	match effect.type:
		StatusEffectType.STUN:
			effect_color = Color(1.0, 1.0, 0.0, 0.7) # 黄色
		StatusEffectType.SILENCE:
			effect_color = Color(0.5, 0.5, 0.8, 0.7) # 蓝紫色
		StatusEffectType.SLOW:
			effect_color = Color(0.0, 0.5, 1.0, 0.7) # 蓝色
		StatusEffectType.DISARM:
			effect_color = Color(0.8, 0.4, 0.0, 0.7) # 棕色
		StatusEffectType.TAUNT:
			effect_color = Color(1.0, 0.0, 0.0, 0.7) # 红色
		StatusEffectType.BURNING:
			effect_color = Color(1.0, 0.5, 0.0, 0.7) # 橙色
		StatusEffectType.POISONED:
			effect_color = Color(0.0, 0.8, 0.0, 0.7) # 绿色
		StatusEffectType.FROZEN:
			effect_color = Color(0.0, 0.8, 1.0, 0.7) # 浅蓝色
		StatusEffectType.BLEEDING:
			effect_color = Color(1.0, 0.0, 0.0, 0.7) # 红色
		StatusEffectType.BUFF:
			effect_color = Color(0.0, 1.0, 0.5, 0.7) # 青绿色
		StatusEffectType.DEBUFF:
			effect_color = Color(0.8, 0.0, 0.8, 0.7) # 紫色

	# 创建效果视觉对象
	var visual = ColorRect.new()
	visual.color = effect_color
	visual.size = Vector2(60, 60)
	visual.position = Vector2(-30, -30)
	effect_container.add_child(visual)

	# 创建效果文本
	var label = Label.new()
	label.text = effect.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(60, 60)
	label.position = Vector2(-30, -30)
	effect_container.add_child(label)

	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(effect_container, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(effect_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(effect_container, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect_container.queue_free)

# 显示免疫视觉效果
func _show_immunity_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 创建免疫效果容器
	var immunity_container = Node2D.new()
	chess_piece.add_child(immunity_container)

	# 创建免疫视觉对象
	var shield = ColorRect.new()
	shield.color = Color(0.8, 0.8, 1.0, 0.5) # 淡蓝色盾牌
	shield.size = Vector2(70, 70)
	shield.position = Vector2(-35, -35)
	immunity_container.add_child(shield)

	# 创建免疫文本
	var label = Label.new()
	label.text = "免疫"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(70, 70)
	label.position = Vector2(-35, -35)
	immunity_container.add_child(label)

	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(immunity_container, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(immunity_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(immunity_container, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(immunity_container.queue_free)

# 更新效果视觉显示
func update_effect_visuals() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 清除现有效果图标
	if chess_piece.has_node("EffectIcons"):
		var effect_icons = chess_piece.get_node("EffectIcons")
		for child in effect_icons.get_children():
			child.queue_free()
	else:
		var effect_icons = Node2D.new()
		effect_icons.name = "EffectIcons"
		chess_piece.add_child(effect_icons)

	# 添加每个效果的图标
	var offset = 0
	for effect_id in active_effects:
		var effect = active_effects[effect_id]

		# 创建效果图标
		var icon = ColorRect.new()
		icon.color = _get_effect_color(effect.type)
		icon.size = Vector2(15, 15)
		icon.position = Vector2(offset - 30, -50)
		chess_piece.get_node("EffectIcons").add_child(icon)

		# 添加效果持续时间文本
		var duration_label = Label.new()
		duration_label.text = str(int(effect.remaining_time))
		duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		duration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		duration_label.size = Vector2(15, 15)
		duration_label.position = Vector2(offset - 30, -50)
		chess_piece.get_node("EffectIcons").add_child(duration_label)

		offset += 20

# 获取效果颜色
func _get_effect_color(effect_type: StatusEffectType) -> Color:
	match effect_type:
		StatusEffectType.STUN:
			return Color(1.0, 1.0, 0.0, 0.7) # 黄色
		StatusEffectType.SILENCE:
			return Color(0.5, 0.5, 0.8, 0.7) # 蓝紫色
		StatusEffectType.SLOW:
			return Color(0.0, 0.5, 1.0, 0.7) # 蓝色
		StatusEffectType.DISARM:
			return Color(0.8, 0.4, 0.0, 0.7) # 棕色
		StatusEffectType.TAUNT:
			return Color(1.0, 0.0, 0.0, 0.7) # 红色
		StatusEffectType.BURNING:
			return Color(1.0, 0.5, 0.0, 0.7) # 橙色
		StatusEffectType.POISONED:
			return Color(0.0, 0.8, 0.0, 0.7) # 绿色
		StatusEffectType.FROZEN:
			return Color(0.0, 0.8, 1.0, 0.7) # 浅蓝色
		StatusEffectType.BLEEDING:
			return Color(1.0, 0.0, 0.0, 0.7) # 红色
		StatusEffectType.BUFF:
			return Color(0.0, 1.0, 0.5, 0.7) # 青绿色
		StatusEffectType.DEBUFF:
			return Color(0.8, 0.0, 0.8, 0.7) # 紫色
		_:
			return Color.WHITE

# 添加眩晕视觉效果
func _add_stun_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现眩晕视觉效果
	# 检查是否已经有眩晕效果
	if chess_piece.has_node("StunEffect"):
		chess_piece.get_node("StunEffect").queue_free()

	# 创建眩晕效果容器
	var stun_container = Node2D.new()
	stun_container.name = "StunEffect"
	chess_piece.add_child(stun_container)

	# 创建眩晕星星效果
	for i in range(3): # 创建3个星星
		var star = ColorRect.new()
		star.color = Color(1.0, 1.0, 0.0, 0.7) # 黄色
		star.size = Vector2(10, 10)

		# 设置不同的初始位置
		var angle = i * 2.0 * PI / 3.0 # 均匀分布在圆周围
		var radius = 20.0 # 半径
		var pos_x = cos(angle) * radius
		var pos_y = sin(angle) * radius - 30 # 在棋子头顶上方
		star.position = Vector2(pos_x - 5, pos_y - 5) # 调整位置使星星居中

		stun_container.add_child(star)

		# 为每个星星创建旋转动画
		var tween = create_tween()
		tween.set_loops() # 无限循环

		# 添加旋转运动
		var center = Vector2(pos_x, pos_y)
		var rotation_radius = 5.0
		var rotation_speed = 1.0 + i * 0.2 # 每个星星速度不同

		# 创建完整的旋转动画
		for j in range(8): # 8个点形成圆形路径
			var rot_angle = j * PI / 4.0
			var new_x = center.x + cos(rot_angle) * rotation_radius - 5
			var new_y = center.y + sin(rot_angle) * rotation_radius - 5
			tween.tween_property(star, "position", Vector2(new_x, new_y), rotation_speed / 8.0)

	# 创建眩晕文本
	var stun_label = Label.new()
	stun_label.text = "眩晕"
	stun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stun_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stun_label.size = Vector2(60, 20)
	stun_label.position = Vector2(-30, -60)
	stun_container.add_child(stun_label)

	# 创建闪烁动画
	var label_tween = create_tween()
	label_tween.tween_property(stun_label, "modulate", Color(1, 1, 1, 0.3), 0.5)
	label_tween.tween_property(stun_label, "modulate", Color(1, 1, 1, 1.0), 0.5)
	label_tween.set_loops() # 无限循环

# 添加沉默视觉效果
func _add_silence_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现沉默视觉效果
	# 检查是否已经有沉默效果
	if chess_piece.has_node("SilenceEffect"):
		chess_piece.get_node("SilenceEffect").queue_free()

	# 创建沉默效果容器
	var silence_container = Node2D.new()
	silence_container.name = "SilenceEffect"
	chess_piece.add_child(silence_container)

	# 创建沉默图标（一个打叉的嘴巴）
	var silence_icon = Node2D.new()
	silence_icon.position = Vector2(0, -40)
	silence_container.add_child(silence_icon)

	# 创建嘴巴形状
	var mouth = ColorRect.new()
	mouth.color = Color(0.5, 0.5, 0.8, 0.7) # 蓝紫色
	mouth.size = Vector2(20, 10)
	mouth.position = Vector2(-10, -5)
	silence_icon.add_child(mouth)

	# 创建打叉线条
	var cross_line1 = Line2D.new()
	cross_line1.width = 2.0
	cross_line1.default_color = Color(1.0, 0.0, 0.0, 0.7) # 红色
	cross_line1.add_point(Vector2(-15, -10))
	cross_line1.add_point(Vector2(15, 10))
	silence_icon.add_child(cross_line1)

	var cross_line2 = Line2D.new()
	cross_line2.width = 2.0
	cross_line2.default_color = Color(1.0, 0.0, 0.0, 0.7) # 红色
	cross_line2.add_point(Vector2(15, -10))
	cross_line2.add_point(Vector2(-15, 10))
	silence_icon.add_child(cross_line2)

	# 创建沉默文本
	var silence_label = Label.new()
	silence_label.text = "沉默"
	silence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	silence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	silence_label.size = Vector2(60, 20)
	silence_label.position = Vector2(-30, -70)
	silence_container.add_child(silence_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(silence_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(silence_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加减速视觉效果
func _add_slow_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现减速视觉效果
	# 检查是否已经有减速效果
	if chess_piece.has_node("SlowEffect"):
		chess_piece.get_node("SlowEffect").queue_free()

	# 创建减速效果容器
	var slow_container = Node2D.new()
	slow_container.name = "SlowEffect"
	chess_piece.add_child(slow_container)

	# 创建减速图标
	var slow_icon = ColorRect.new()
	slow_icon.color = Color(0.0, 0.5, 1.0, 0.5) # 半透明蓝色
	slow_icon.size = Vector2(40, 40)
	slow_icon.position = Vector2(-20, -20)
	slow_container.add_child(slow_icon)

	# 创建减速波纹效果
	for i in range(3): # 创建3个波纹
		var wave = ColorRect.new()
		wave.color = Color(0.0, 0.5, 1.0, 0.3) # 半透明蓝色
		wave.size = Vector2(30 - i * 5, 5)
		wave.position = Vector2(-15 + i * 2.5, 10 + i * 8)
		slow_container.add_child(wave)

		# 创建波纹动画
		var tween = create_tween()
		tween.set_loops() # 无限循环
		tween.tween_property(wave, "position:x", wave.position.x - 10, 1.0 + i * 0.2)
		tween.tween_property(wave, "position:x", wave.position.x, 1.0 + i * 0.2)

	# 创建减速文本
	var slow_label = Label.new()
	slow_label.text = "减速"
	slow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slow_label.size = Vector2(60, 20)
	slow_label.position = Vector2(-30, -50)
	slow_container.add_child(slow_label)

	# 创建闪烁动画
	var label_tween = create_tween()
	label_tween.tween_property(slow_label, "modulate", Color(1, 1, 1, 0.3), 0.5)
	label_tween.tween_property(slow_label, "modulate", Color(1, 1, 1, 1.0), 0.5)
	label_tween.set_loops() # 无限循环

	# 修改棋子移动速度的视觉效果
	if chess_piece.has_method("set_animation_speed"):
		chess_piece.set_animation_speed(0.7) # 减速动画速度

# 添加缴械视觉效果
func _add_disarm_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现缴械视觉效果
	# 检查是否已经有缴械效果
	if chess_piece.has_node("DisarmEffect"):
		chess_piece.get_node("DisarmEffect").queue_free()

	# 创建缴械效果容器
	var disarm_container = Node2D.new()
	disarm_container.name = "DisarmEffect"
	chess_piece.add_child(disarm_container)

	# 创建武器图标
	var weapon_icon = ColorRect.new()
	weapon_icon.color = Color(0.7, 0.7, 0.7, 0.8) # 灰色
	weapon_icon.size = Vector2(20, 5) # 剑形状
	weapon_icon.position = Vector2(-10, -20)
	disarm_container.add_child(weapon_icon)

	# 创建禁止符号
	var ban_circle = ColorRect.new()
	ban_circle.color = Color(1.0, 0.0, 0.0, 0.5) # 半透明红色
	ban_circle.size = Vector2(30, 30)
	ban_circle.position = Vector2(-15, -30)
	disarm_container.add_child(ban_circle)

	# 创建禁止线
	var ban_line = ColorRect.new()
	ban_line.color = Color(1.0, 0.0, 0.0, 0.8) # 红色
	ban_line.size = Vector2(40, 3)
	ban_line.position = Vector2(-20, -16.5) # 使线正好穿过圆心
	ban_line.rotation = PI / 4 # 45度角度
	disarm_container.add_child(ban_line)

	# 创建缴械文本
	var disarm_label = Label.new()
	disarm_label.text = "缴械"
	disarm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disarm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	disarm_label.size = Vector2(60, 20)
	disarm_label.position = Vector2(-30, -50)
	disarm_container.add_child(disarm_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(ban_circle, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(ban_circle, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

	# 武器掉落动画
	var weapon_tween = create_tween()
	weapon_tween.tween_property(weapon_icon, "position", Vector2(-10, 20), 1.0) # 武器下落
	weapon_tween.parallel().tween_property(weapon_icon, "rotation", PI, 1.0) # 旋转180度
	weapon_tween.tween_callback(func():
		weapon_icon.position = Vector2(-10, -20) # 重置位置
		weapon_icon.rotation = 0 # 重置旋转
	)
	weapon_tween.set_loops() # 无限循环

# 添加嘲讽视觉效果
func _add_taunt_visual_effect(source: ChessPiece) -> void:
	if not chess_piece or not is_instance_valid(chess_piece) or not source or not is_instance_valid(source):
		return

	# 实现嘲讽视觉效果
	# 检查是否已经有嘲讽效果
	if chess_piece.has_node("TauntEffect"):
		chess_piece.get_node("TauntEffect").queue_free()

	# 创建嘲讽效果容器
	var taunt_container = Node2D.new()
	taunt_container.name = "TauntEffect"
	chess_piece.add_child(taunt_container)

	# 创建嘲讽线条
	var taunt_line = Line2D.new()
	taunt_line.width = 2.0
	taunt_line.default_color = Color(1.0, 0.0, 0.0, 0.7) # 红色
	taunt_line.add_point(Vector2.ZERO) # 起点（棋子位置）
	taunt_line.add_point(source.position - chess_piece.position) # 终点（嘲讽源位置）
	taunt_container.add_child(taunt_line)

	# 创建嘲讽图标
	var taunt_icon = ColorRect.new()
	taunt_icon.color = Color(1.0, 0.0, 0.0, 0.7) # 红色
	taunt_icon.size = Vector2(20, 20)
	taunt_icon.position = Vector2(-10, -10)
	taunt_container.add_child(taunt_icon)

	# 创建嘲讽文本
	var taunt_label = Label.new()
	taunt_label.text = "被嘲讽"
	taunt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	taunt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	taunt_label.size = Vector2(60, 20)
	taunt_label.position = Vector2(-30, -40)
	taunt_container.add_child(taunt_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(taunt_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(taunt_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

	# 添加更新回调，以便嘲讽线条跟随目标
	var update_line_callback = func():
		if is_instance_valid(chess_piece) and is_instance_valid(source) and chess_piece.has_node("TauntEffect"):
			var line = chess_piece.get_node("TauntEffect").get_child(0)
			if line is Line2D:
				line.set_point_position(1, source.position - chess_piece.position)

	# 添加定时器来更新线条
	var timer = Timer.new()
	timer.wait_time = 0.1 # 每0.1秒更新一次
	timer.autostart = true
	timer.timeout.connect(update_line_callback)
	taunt_container.add_child(timer)

# 添加燃烧视觉效果
func _add_burning_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现燃烧视觉效果
	# 检查是否已经有燃烧效果
	if chess_piece.has_node("BurnEffect"):
		chess_piece.get_node("BurnEffect").queue_free()

	# 创建燃烧效果容器
	var burn_container = Node2D.new()
	burn_container.name = "BurnEffect"
	chess_piece.add_child(burn_container)

	# 创建多个火焰粒子
	for i in range(8):
		var flame = ColorRect.new()
		flame.color = Color(1.0, 0.5, 0.0, 0.8) # 橙红色
		flame.size = Vector2(10, 20)

		# 将火焰分布在棋子周围
		var angle = i * PI / 4.0 # 均匀分布在圆周
		var radius = 30.0
		var pos_x = cos(angle) * radius
		var pos_y = sin(angle) * radius
		flame.position = Vector2(pos_x - 5, pos_y - 10)
		burn_container.add_child(flame)

		# 创建火焰动画
		var tween = create_tween()
		tween.set_loops() # 无限循环

		# 随机调整初始延迟，使火焰不同步
		tween.tween_interval(randf_range(0.0, 0.5))

		# 火焰上下摇摇晃晃
		tween.tween_property(flame, "position:y", flame.position.y - 10, 0.3)
		tween.tween_property(flame, "position:y", flame.position.y, 0.3)

		# 火焰大小变化
		tween.parallel().tween_property(flame, "size", Vector2(10, 25), 0.3)
		tween.parallel().tween_property(flame, "size", Vector2(10, 15), 0.3)

		# 透明度变化
		tween.parallel().tween_property(flame, "modulate", Color(1, 1, 1, 0.6), 0.3)
		tween.parallel().tween_property(flame, "modulate", Color(1, 1, 1, 1.0), 0.3)

	# 创建燃烧文本
	var burn_label = Label.new()
	burn_label.text = "燃烧"
	burn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	burn_label.size = Vector2(60, 20)
	burn_label.position = Vector2(-30, -60)
	burn_label.modulate = Color(1.0, 0.5, 0.0, 1.0) # 橙红色
	burn_container.add_child(burn_label)

	# 创建闪烁动画
	var label_tween = create_tween()
	label_tween.tween_property(burn_label, "modulate", Color(1.0, 0.5, 0.0, 0.5), 0.5)
	label_tween.tween_property(burn_label, "modulate", Color(1.0, 0.5, 0.0, 1.0), 0.5)
	label_tween.set_loops() # 无限循环

	# 添加棋子整体的颜色变化
	var piece_tween = create_tween()
	piece_tween.tween_property(chess_piece, "modulate", Color(1.2, 0.9, 0.9, 1.0), 0.5) # 红色色调
	piece_tween.tween_property(chess_piece, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	piece_tween.set_loops() # 无限循环

# 添加中毒视觉效果
func _add_poison_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现中毒视觉效果
	# 检查是否已经有中毒效果
	if chess_piece.has_node("PoisonEffect"):
		chess_piece.get_node("PoisonEffect").queue_free()

	# 创建中毒效果容器
	var poison_container = Node2D.new()
	poison_container.name = "PoisonEffect"
	chess_piece.add_child(poison_container)

	# 创建中毒气泡
	for i in range(5):
		var bubble = ColorRect.new()
		bubble.color = Color(0.0, 0.8, 0.0, 0.7) # 绿色
		bubble.size = Vector2(8, 8)

		# 随机分布在棋子周围
		var angle = randf() * 2.0 * PI
		var radius = randf_range(20.0, 40.0)
		var pos_x = cos(angle) * radius
		var pos_y = sin(angle) * radius
		bubble.position = Vector2(pos_x - 4, pos_y - 4) # 调整位置使气泡居中
		poison_container.add_child(bubble)

		# 创建气泡动画
		var tween = create_tween()
		tween.set_loops() # 无限循环

		# 随机调整初始延迟
		tween.tween_interval(randf_range(0.0, 1.0))

		# 气泡上升
		tween.tween_property(bubble, "position:y", bubble.position.y - 15, 1.5)

		# 气泡透明度变化
		tween.parallel().tween_property(bubble, "modulate", Color(1, 1, 1, 0), 1.5)

		# 重置气泡
		tween.tween_callback(func():
			bubble.position.y = bubble.position.y + 15
			bubble.modulate = Color(1, 1, 1, 1)
		)

	# 创建中毒文本
	var poison_label = Label.new()
	poison_label.text = "中毒"
	poison_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poison_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	poison_label.size = Vector2(60, 20)
	poison_label.position = Vector2(-30, -60)
	poison_label.modulate = Color(0.0, 0.8, 0.0, 1.0) # 绿色
	poison_container.add_child(poison_label)

	# 创建闪烁动画
	var label_tween = create_tween()
	label_tween.tween_property(poison_label, "modulate", Color(0.0, 0.8, 0.0, 0.5), 0.5)
	label_tween.tween_property(poison_label, "modulate", Color(0.0, 0.8, 0.0, 1.0), 0.5)
	label_tween.set_loops() # 无限循环

	# 添加棋子整体的颜色变化
	var piece_tween = create_tween()
	piece_tween.tween_property(chess_piece, "modulate", Color(0.8, 1.0, 0.8, 1.0), 0.5) # 绿色色调
	piece_tween.tween_property(chess_piece, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	piece_tween.set_loops() # 无限循环

# 添加冰冻视觉效果
func _add_frozen_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现冰冻视觉效果
	# 检查是否已经有冰冻效果
	if chess_piece.has_node("FrozenEffect"):
		chess_piece.get_node("FrozenEffect").queue_free()

	# 创建冰冻效果容器
	var frozen_container = Node2D.new()
	frozen_container.name = "FrozenEffect"
	chess_piece.add_child(frozen_container)

	# 创建冰冻外框
	var frozen_outline = ColorRect.new()
	frozen_outline.color = Color(0.0, 0.8, 1.0, 0.3) # 半透明浅蓝色
	frozen_outline.size = Vector2(60, 60)
	frozen_outline.position = Vector2(-30, -30)
	frozen_container.add_child(frozen_outline)

	# 创建冰晶效果（多个小冰晶）
	for i in range(6): # 创建6个冰晶
		var ice_crystal = ColorRect.new()
		ice_crystal.color = Color(0.0, 0.8, 1.0, 0.7) # 浅蓝色
		ice_crystal.size = Vector2(5, 5)

		# 随机分布在棋子周围
		var angle = randf() * 2.0 * PI
		var radius = randf_range(20.0, 35.0)
		var pos_x = cos(angle) * radius
		var pos_y = sin(angle) * radius
		ice_crystal.position = Vector2(pos_x - 2.5, pos_y - 2.5) # 调整位置使冰晶居中

		frozen_container.add_child(ice_crystal)

		# 为每个冰晶创建闪烁动画
		var tween = create_tween()
		tween.tween_property(ice_crystal, "modulate", Color(1, 1, 1, 0.3), randf_range(0.5, 1.0))
		tween.tween_property(ice_crystal, "modulate", Color(1, 1, 1, 1.0), randf_range(0.5, 1.0))
		tween.set_loops() # 无限循环

	# 创建冰冻文本
	var frozen_label = Label.new()
	frozen_label.text = "冰冻"
	frozen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frozen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frozen_label.size = Vector2(60, 20)
	frozen_label.position = Vector2(-30, -60)
	frozen_container.add_child(frozen_label)

	# 添加冰冻效果到棋子的材质
	if chess_piece.has_method("_update_visuals"):
		# 保存原始颜色
		if not chess_piece.has_meta("original_modulate"):
			chess_piece.set_meta("original_modulate", chess_piece.modulate)

		# 设置冰冻颜色
		chess_piece.modulate = Color(0.7, 0.9, 1.0, 1.0) # 添加蓝色色调

		# 创建定时器来检查冰冻状态
		var timer = Timer.new()
		timer.wait_time = 0.2 # 每0.2秒检查一次
		timer.autostart = true
		timer.timeout.connect(func():
			# 如果棋子不再被冰冻，恢复原始颜色
			if is_instance_valid(chess_piece) and not chess_piece.is_frozen and chess_piece.has_meta("original_modulate"):
				chess_piece.modulate = chess_piece.get_meta("original_modulate")
				timer.queue_free()
		)
		frozen_container.add_child(timer)

# 添加流血视觉效果
func _add_bleeding_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现流血视觉效果
	# 检查是否已经有流血效果
	if chess_piece.has_node("BleedEffect"):
		chess_piece.get_node("BleedEffect").queue_free()

	# 创建流血效果容器
	var bleed_container = Node2D.new()
	bleed_container.name = "BleedEffect"
	chess_piece.add_child(bleed_container)

	# 创建血滴
	for i in range(6):
		var blood_drop = ColorRect.new()
		blood_drop.color = Color(0.8, 0.0, 0.0, 0.9) # 红色
		blood_drop.size = Vector2(5, 10) # 血滴形状

		# 随机分布在棋子周围
		var angle = randf() * PI # 主要在下半部分
		var radius = randf_range(10.0, 30.0)
		var pos_x = cos(angle) * radius
		var pos_y = sin(angle) * radius + 20.0 # 偏移到下方
		blood_drop.position = Vector2(pos_x - 2.5, pos_y - 5)
		bleed_container.add_child(blood_drop)

		# 创建血滴动画
		var tween = create_tween()
		tween.set_loops() # 无限循环

		# 随机调整初始延迟
		tween.tween_interval(randf_range(0.0, 1.0))

		# 血滴下落
		tween.tween_property(blood_drop, "position:y", blood_drop.position.y + 20, 1.0)

		# 血滴透明度变化
		tween.parallel().tween_property(blood_drop, "modulate", Color(1, 1, 1, 0.3), 1.0)

		# 重置血滴
		tween.tween_callback(func():
			blood_drop.position.y = blood_drop.position.y - 20
			blood_drop.modulate = Color(1, 1, 1, 1)
		)

	# 创建流血文本
	var bleed_label = Label.new()
	bleed_label.text = "流血"
	bleed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bleed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bleed_label.size = Vector2(60, 20)
	bleed_label.position = Vector2(-30, -60)
	bleed_label.modulate = Color(0.8, 0.0, 0.0, 1.0) # 红色
	bleed_container.add_child(bleed_label)

	# 创建闪烁动画
	var label_tween = create_tween()
	label_tween.tween_property(bleed_label, "modulate", Color(0.8, 0.0, 0.0, 0.5), 0.5)
	label_tween.tween_property(bleed_label, "modulate", Color(0.8, 0.0, 0.0, 1.0), 0.5)
	label_tween.set_loops() # 无限循环

	# 添加棋子整体的颜色变化
	var piece_tween = create_tween()
	piece_tween.tween_property(chess_piece, "modulate", Color(1.2, 0.8, 0.8, 1.0), 0.5) # 红色色调
	piece_tween.tween_property(chess_piece, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	piece_tween.set_loops() # 无限循环

	# 添加血滴效果到地面
	var floor_blood = ColorRect.new()
	floor_blood.color = Color(0.8, 0.0, 0.0, 0.5) # 半透明红色
	floor_blood.size = Vector2(40, 20)
	floor_blood.position = Vector2(-20, 30) # 在棋子下方
	bleed_container.add_child(floor_blood)

	# 血池慢慢扩大
	var floor_tween = create_tween()
	floor_tween.tween_property(floor_blood, "size", Vector2(50, 25), 2.0)
	floor_tween.parallel().tween_property(floor_blood, "position", Vector2(-25, 30), 2.0)
	floor_tween.set_loops() # 无限循环

# 添加增益视觉效果
func _add_buff_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现增益视觉效果
	# 检查是否已经有增益效果
	if chess_piece.has_node("BuffEffect"):
		chess_piece.get_node("BuffEffect").queue_free()

	# 创建增益效果容器
	var buff_container = Node2D.new()
	buff_container.name = "BuffEffect"
	chess_piece.add_child(buff_container)

	# 创建光环效果
	var aura = ColorRect.new()
	aura.color = Color(1.0, 0.8, 0.0, 0.3) # 半透明金色
	aura.size = Vector2(60, 60)
	aura.position = Vector2(-30, -30)
	buff_container.add_child(aura)

	# 创建光环动画
	var aura_tween = create_tween()
	aura_tween.set_loops() # 无限循环
	aura_tween.tween_property(aura, "modulate", Color(1, 1, 1, 0.7), 1.0)
	aura_tween.tween_property(aura, "modulate", Color(1, 1, 1, 0.3), 1.0)

	# 创建上升箭头
	for i in range(4):
		var arrow = Polygon2D.new()
		arrow.color = Color(1.0, 0.8, 0.0, 0.8) # 金色

		# 设置箭头形状
		arrow.polygon = PackedVector2Array([
			Vector2(0, -10), # 箭头顶点
			Vector2(-5, 0),  # 左侧点
			Vector2(5, 0)    # 右侧点
		])

		# 分布在棋子周围
		var angle = i * PI / 2.0 # 四个方向
		var radius = 40.0
		var pos_x = cos(angle) * radius
		var pos_y = sin(angle) * radius
		arrow.position = Vector2(pos_x, pos_y)
		buff_container.add_child(arrow)

		# 创建箭头动画
		var arrow_tween = create_tween()
		arrow_tween.set_loops() # 无限循环

		# 设置初始延迟
		arrow_tween.tween_interval(i * 0.2)

		# 箭头上下移动
		arrow_tween.tween_property(arrow, "position", Vector2(pos_x, pos_y - 10), 0.5)
		arrow_tween.tween_property(arrow, "position", Vector2(pos_x, pos_y), 0.5)

	# 创建增益文本
	var buff_label = Label.new()
	buff_label.text = "增益"
	buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buff_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	buff_label.size = Vector2(60, 20)
	buff_label.position = Vector2(-30, -60)
	buff_label.modulate = Color(1.0, 0.8, 0.0, 1.0) # 金色
	buff_container.add_child(buff_label)

	# 创建闪烁动画
	var label_tween = create_tween()
	label_tween.tween_property(buff_label, "modulate", Color(1.0, 0.8, 0.0, 0.5), 0.5)
	label_tween.tween_property(buff_label, "modulate", Color(1.0, 0.8, 0.0, 1.0), 0.5)
	label_tween.set_loops() # 无限循环

	# 添加棋子整体的颜色变化
	var piece_tween = create_tween()
	piece_tween.tween_property(chess_piece, "modulate", Color(1.2, 1.2, 0.8, 1.0), 0.5) # 金色色调
	piece_tween.tween_property(chess_piece, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	piece_tween.set_loops() # 无限循环

# 显示叠加视觉效果
func _show_stack_visual(effect: StatusEffect) -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 创建叠加效果容器
	var stack_container = Node2D.new()
	chess_piece.add_child(stack_container)

	# 创建叠加数字文本
	var stack_label = Label.new()
	stack_label.text = "x" + str(effect.stack_count)
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack_label.size = Vector2(40, 40)
	stack_label.position = Vector2(-20, -20)
	stack_label.modulate = _get_effect_color(effect.type)
	stack_container.add_child(stack_label)

	# 创建效果名称文本
	var name_label = Label.new()
	name_label.text = effect.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size = Vector2(60, 20)
	name_label.position = Vector2(-30, -50)
	name_label.modulate = _get_effect_color(effect.type)
	stack_container.add_child(name_label)

	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(stack_container, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(stack_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(stack_container, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(stack_container.queue_free)

# 添加减益视觉效果
func _add_debuff_visual_effect() -> void:
	if not chess_piece or not is_instance_valid(chess_piece):
		return

	# 实现减益视觉效果
	# 检查是否已经有减益效果
	if chess_piece.has_node("DebuffEffect"):
		chess_piece.get_node("DebuffEffect").queue_free()

	# 创建减益效果容器
	var debuff_container = Node2D.new()
	debuff_container.name = "DebuffEffect"
	chess_piece.add_child(debuff_container)

	# 创建负面光环效果
	var aura = ColorRect.new()
	aura.color = Color(0.5, 0.0, 0.5, 0.3) # 半透明紫色
	aura.size = Vector2(60, 60)
	aura.position = Vector2(-30, -30)
	debuff_container.add_child(aura)

	# 创建光环动画
	var aura_tween = create_tween()
	aura_tween.set_loops() # 无限循环
	aura_tween.tween_property(aura, "modulate", Color(1, 1, 1, 0.7), 1.0)
	aura_tween.tween_property(aura, "modulate", Color(1, 1, 1, 0.3), 1.0)

	# 创建下降箭头
	for i in range(4):
		var arrow = Polygon2D.new()
		arrow.color = Color(0.5, 0.0, 0.5, 0.8) # 紫色

		# 设置箭头形状（向下的箭头）
		arrow.polygon = PackedVector2Array([
			Vector2(0, 10),  # 箭头底点
			Vector2(-5, 0),  # 左侧点
			Vector2(5, 0)    # 右侧点
		])

		# 分布在棋子周围
		var angle = i * PI / 2.0 # 四个方向
		var radius = 40.0
		var pos_x = cos(angle) * radius
		var pos_y = sin(angle) * radius
		arrow.position = Vector2(pos_x, pos_y)
		debuff_container.add_child(arrow)

		# 创建箭头动画
		var arrow_tween = create_tween()
		arrow_tween.set_loops() # 无限循环

		# 设置初始延迟
		arrow_tween.tween_interval(i * 0.2)

		# 箭头上下移动（向下移动）
		arrow_tween.tween_property(arrow, "position", Vector2(pos_x, pos_y + 10), 0.5)
		arrow_tween.tween_property(arrow, "position", Vector2(pos_x, pos_y), 0.5)

	# 创建减益文本
	var debuff_label = Label.new()
	debuff_label.text = "减益"
	debuff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debuff_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	debuff_label.size = Vector2(60, 20)
	debuff_label.position = Vector2(-30, -60)
	debuff_label.modulate = Color(0.5, 0.0, 0.5, 1.0) # 紫色
	debuff_container.add_child(debuff_label)

	# 创建闪烁动画
	var label_tween = create_tween()
	label_tween.tween_property(debuff_label, "modulate", Color(0.5, 0.0, 0.5, 0.5), 0.5)
	label_tween.tween_property(debuff_label, "modulate", Color(0.5, 0.0, 0.5, 1.0), 0.5)
	label_tween.set_loops() # 无限循环

	# 添加棋子整体的颜色变化
	var piece_tween = create_tween()
	piece_tween.tween_property(chess_piece, "modulate", Color(0.9, 0.8, 0.9, 1.0), 0.5) # 紫色色调
	piece_tween.tween_property(chess_piece, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	piece_tween.set_loops() # 无限循环

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
