extends Node
class_name StatusEffectManager
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
	StatusEffectType.STUN: 5,
	StatusEffectType.TAUNT: 4,
	StatusEffectType.SILENCE: 3,
	StatusEffectType.DISARM: 2,
	StatusEffectType.SLOW: 1,
	StatusEffectType.BURNING: 0,
	StatusEffectType.POISONED: 0,
	StatusEffectType.FROZEN: 3,
	StatusEffectType.BLEEDING: 0,
	StatusEffectType.BUFF: 0,
	StatusEffectType.DEBUFF: 0
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
	
	for effect_id in active_effects:
		var effect = active_effects[effect_id]
		if not effect.update(delta):
			effects_to_remove.append(effect_id)
	
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

# 添加效果
func add_effect(effect: StatusEffect) -> bool:
	# 检查是否免疫该效果
	if is_immune_to(effect.type):
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
				return true
			else:
				return false
	
	# 添加新效果
	active_effects[effect.id] = effect
	
	# 应用效果
	_apply_effect(effect)
	
	# 发送效果添加信号
	EventBus.status_effect_added.emit(chess_piece, effect)
	
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
	EventBus.status_effect_removed.emit(chess_piece, effect)

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
		if randf() < immune_chance:
			return true
	
	return false

# 应用效果
func _apply_effect(effect: StatusEffect) -> void:
	match effect.type:
		StatusEffectType.STUN:
			# 眩晕效果
			chess_piece.change_state(ChessPiece.ChessState.STUNNED)
		
		StatusEffectType.SILENCE:
			# 沉默效果
			chess_piece.is_silenced = true
		
		StatusEffectType.SLOW:
			# 减速效果
			chess_piece.move_speed *= (1.0 - effect.value)
			chess_piece.attack_speed *= (1.0 - effect.value * 0.5)  # 攻击速度减少一半的效果
		
		StatusEffectType.DISARM:
			# 缴械效果
			chess_piece.is_disarmed = true
		
		StatusEffectType.TAUNT:
			# 嘲讽效果
			chess_piece.taunted_by = effect.source
		
		StatusEffectType.BURNING:
			# 燃烧效果
			# 在update中处理持续伤害
			pass
		
		StatusEffectType.POISONED:
			# 中毒效果
			# 在update中处理持续伤害
			pass
		
		StatusEffectType.FROZEN:
			# 冰冻效果
			chess_piece.is_frozen = true
			chess_piece.move_speed = 0
		
		StatusEffectType.BLEEDING:
			# 流血效果
			# 在移动时处理伤害
			pass
		
		StatusEffectType.BUFF:
			# 增益效果
			# 根据效果值增加属性
			pass
		
		StatusEffectType.DEBUFF:
			# 减益效果
			# 根据效果值减少属性
			pass

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
			pass
		
		StatusEffectType.DEBUFF:
			# 取消减益效果
			# 恢复属性
			pass

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
			
			StatusEffectType.POISONED:
				# 中毒伤害
				var damage = effect.value * delta
				chess_piece.take_damage(damage, "poison", effect.source)
				
				# 播放中毒效果
				if chess_piece.has_method("_play_effect"):
					chess_piece._play_effect("poisoned", Color(0.5, 1.0, 0.0, 0.7))

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

# 获取所有活跃效果
func get_all_effects() -> Array:
	return active_effects.values()

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
