extends Node
class_name EffectManager
## 效果管理器
## 负责管理战斗中的所有效果

# 信号
signal effect_applied(effect)
signal effect_removed(effect)
signal effect_updated(effect)
signal effect_expired(effect)

# 效果列表
var active_effects: Dictionary = {}  # {目标ID: [效果列表]}
var effect_pool: Dictionary = {}     # {效果类型: [效果对象池]}

# 效果工厂
var effect_factory = null

# 初始化
func _init():
	# 创建效果工厂
	effect_factory = EffectFactory.new()

# 处理过程
func _process(delta: float) -> void:
	# 更新所有效果
	_update_all_effects(delta)

# 应用效果
func apply_effect(effect_data: Dictionary, source = null, target = null) -> BattleEffect:
	if not target or not is_instance_valid(target):
		return null
	
	# 获取目标ID
	var target_id = _get_entity_id(target)
	if target_id.is_empty():
		return null
	
	# 创建效果
	var effect = effect_factory.create_effect(effect_data, source, target)
	if not effect:
		return null
	
	# 检查目标是否已有相同效果
	var existing_effect = _find_existing_effect(target_id, effect)
	if existing_effect:
		# 如果效果可叠加，增加叠加层数
		if existing_effect.is_stackable and existing_effect.stack_count < existing_effect.max_stacks:
			existing_effect.add_stack()
			effect_updated.emit(existing_effect)
			return existing_effect
		
		# 如果效果不可叠加，刷新持续时间
		existing_effect.remaining_time = effect.duration
		effect_updated.emit(existing_effect)
		return existing_effect
	
	# 添加效果到目标
	if not active_effects.has(target_id):
		active_effects[target_id] = []
	
	active_effects[target_id].append(effect)
	
	# 应用效果
	effect.apply()
	
	# 连接效果信号
	_connect_effect_signals(effect)
	
	# 发送效果应用信号
	effect_applied.emit(effect)
	
	return effect

# 移除效果
func remove_effect(effect: BattleEffect) -> bool:
	if not effect or not effect.target or not is_instance_valid(effect.target):
		return false
	
	# 获取目标ID
	var target_id = _get_entity_id(effect.target)
	if target_id.is_empty() or not active_effects.has(target_id):
		return false
	
	# 从目标效果列表中移除
	var effects = active_effects[target_id]
	if effects.has(effect):
		effects.erase(effect)
		
		# 移除效果
		effect.remove()
		
		# 断开效果信号
		_disconnect_effect_signals(effect)
		
		# 发送效果移除信号
		effect_removed.emit(effect)
		
		# 回收效果对象
		_recycle_effect(effect)
		
		return true
	
	return false

# 移除目标的所有效果
func remove_all_effects_from_target(target) -> int:
	if not target or not is_instance_valid(target):
		return 0
	
	# 获取目标ID
	var target_id = _get_entity_id(target)
	if target_id.is_empty() or not active_effects.has(target_id):
		return 0
	
	# 获取目标的所有效果
	var effects = active_effects[target_id].duplicate()
	var removed_count = 0
	
	# 移除所有效果
	for effect in effects:
		if remove_effect(effect):
			removed_count += 1
	
	return removed_count

# 移除所有战斗效果
func remove_all_battle_effects() -> int:
	var removed_count = 0
	
	# 获取所有目标ID
	var target_ids = active_effects.keys().duplicate()
	
	# 移除所有目标的所有效果
	for target_id in target_ids:
		var effects = active_effects[target_id].duplicate()
		
		for effect in effects:
			if remove_effect(effect):
				removed_count += 1
	
	return removed_count

# 获取目标的所有效果
func get_target_effects(target) -> Array:
	if not target or not is_instance_valid(target):
		return []
	
	# 获取目标ID
	var target_id = _get_entity_id(target)
	if target_id.is_empty() or not active_effects.has(target_id):
		return []
	
	return active_effects[target_id].duplicate()

# 检查目标是否有指定类型的效果
func has_effect_type(target, effect_type: int) -> bool:
	var effects = get_target_effects(target)
	
	for effect in effects:
		if effect.effect_type == effect_type:
			return true
	
	return false

# 检查目标是否有指定标签的效果
func has_effect_tag(target, tag: String) -> bool:
	var effects = get_target_effects(target)
	
	for effect in effects:
		if effect.tags.has(tag):
			return true
	
	return false

# 获取目标的指定类型效果
func get_effects_by_type(target, effect_type: int) -> Array:
	var effects = get_target_effects(target)
	var type_effects = []
	
	for effect in effects:
		if effect.effect_type == effect_type:
			type_effects.append(effect)
	
	return type_effects

# 获取目标的指定标签效果
func get_effects_by_tag(target, tag: String) -> Array:
	var effects = get_target_effects(target)
	var tag_effects = []
	
	for effect in effects:
		if effect.tags.has(tag):
			tag_effects.append(effect)
	
	return tag_effects

# 更新所有效果
func _update_all_effects(delta: float) -> void:
	# 获取所有目标ID
	var target_ids = active_effects.keys().duplicate()
	
	# 更新所有目标的所有效果
	for target_id in target_ids:
		var effects = active_effects[target_id].duplicate()
		
		for effect in effects:
			# 更新效果
			if not effect.update(delta):
				# 如果效果更新失败（可能已过期），移除效果
				remove_effect(effect)

# 查找目标已有的相同效果
func _find_existing_effect(target_id: String, effect: BattleEffect) -> BattleEffect:
	if not active_effects.has(target_id):
		return null
	
	for existing_effect in active_effects[target_id]:
		# 检查是否是相同类型的效果
		if existing_effect.effect_type == effect.effect_type:
			# 对于状态效果，检查状态类型
			if effect is StatusEffect and existing_effect is StatusEffect:
				if existing_effect.status_type == effect.status_type:
					return existing_effect
			
			# 对于持续伤害效果，检查伤害类型
			elif effect is DotEffect and existing_effect is DotEffect:
				if existing_effect.dot_type == effect.dot_type:
					return existing_effect
			
			# 对于属性效果，检查修改的属性
			elif effect is StatEffect and existing_effect is StatEffect:
				# 检查是否修改相同的属性
				var same_stats = true
				for stat_name in effect.stats:
					if not existing_effect.stats.has(stat_name):
						same_stats = false
						break
				
				if same_stats:
					return existing_effect
			
			# 对于其他类型的效果，检查ID
			elif existing_effect.id == effect.id:
				return existing_effect
	
	return null

# 连接效果信号
func _connect_effect_signals(effect: BattleEffect) -> void:
	effect.effect_applied.connect(_on_effect_applied.bind(effect))
	effect.effect_removed.connect(_on_effect_removed.bind(effect))
	effect.effect_updated.connect(_on_effect_updated.bind(effect))
	effect.effect_expired.connect(_on_effect_expired.bind(effect))
	effect.stack_added.connect(_on_effect_stack_added.bind(effect))

# 断开效果信号
func _disconnect_effect_signals(effect: BattleEffect) -> void:
	if effect.effect_applied.is_connected(_on_effect_applied):
		effect.effect_applied.disconnect(_on_effect_applied)
	
	if effect.effect_removed.is_connected(_on_effect_removed):
		effect.effect_removed.disconnect(_on_effect_removed)
	
	if effect.effect_updated.is_connected(_on_effect_updated):
		effect.effect_updated.disconnect(_on_effect_updated)
	
	if effect.effect_expired.is_connected(_on_effect_expired):
		effect.effect_expired.disconnect(_on_effect_expired)
	
	if effect.stack_added.is_connected(_on_effect_stack_added):
		effect.stack_added.disconnect(_on_effect_stack_added)

# 回收效果对象
func _recycle_effect(effect: BattleEffect) -> void:
	# 获取效果类型
	var effect_class = effect.get_class()
	
	# 如果对象池中没有该类型的列表，创建一个
	if not effect_pool.has(effect_class):
		effect_pool[effect_class] = []
	
	# 重置效果状态
	effect.reset()
	
	# 添加到对象池
	effect_pool[effect_class].append(effect)

# 从对象池获取效果对象
func _get_effect_from_pool(effect_class: String) -> BattleEffect:
	if not effect_pool.has(effect_class) or effect_pool[effect_class].is_empty():
		return null
	
	# 从对象池中取出一个效果对象
	return effect_pool[effect_class].pop_back()

# 获取实体ID
func _get_entity_id(entity) -> String:
	if entity.has_method("get_id"):
		return entity.get_id()
	
	if entity.has_method("get_instance_id"):
		return str(entity.get_instance_id())
	
	return ""

# 效果信号处理
func _on_effect_applied(effect: BattleEffect) -> void:
	effect_applied.emit(effect)

func _on_effect_removed(effect: BattleEffect) -> void:
	effect_removed.emit(effect)

func _on_effect_updated(effect: BattleEffect) -> void:
	effect_updated.emit(effect)

func _on_effect_expired(effect: BattleEffect) -> void:
	effect_expired.emit(effect)

func _on_effect_stack_added(effect: BattleEffect, old_stack: int, new_stack: int) -> void:
	# 可以添加特殊处理
	pass
