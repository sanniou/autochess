extends Node
class_name GameEffectManager
## 游戏效果管理器
## 负责管理所有影响游戏状态的效果

# 信号
signal effect_applied(effect)
signal effect_removed(effect)
signal effect_updated(effect)
signal effect_expired(effect)

# 活动效果字典 {目标ID: [效果列表]}
var active_effects: Dictionary = {}

# 效果工厂
var effect_factory = null

# 初始化
func _init() -> void:
	# 创建效果工厂
	effect_factory = GameEffectFactory.new()
	add_child(effect_factory)

# 处理过程
func _process(delta: float) -> void:
	# 更新所有效果
	_update_all_effects(delta)

# 应用效果
func apply_effect(effect_data: Dictionary, source = null, target = null) -> GameEffect:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		return null
	
	# 创建效果
	var effect = effect_factory.create_effect(effect_data, source, target)
	if not effect:
		return null
	
	# 获取目标ID
	var target_id = _get_target_id(target)
	
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
func remove_effect(effect_or_id) -> bool:
	# 如果是效果ID
	if effect_or_id is String:
		# 查找效果
		var effect = _find_effect_by_id(effect_or_id)
		if not effect:
			return false
		
		return remove_effect(effect)
	
	# 如果是效果对象
	var effect = effect_or_id
	if not effect or not is_instance_valid(effect):
		return false
	
	# 获取目标ID
	var target_id = _get_target_id(effect.target)
	
	# 检查目标是否有此效果
	if not active_effects.has(target_id) or not active_effects[target_id].has(effect):
		return false
	
	# 移除效果
	active_effects[target_id].erase(effect)
	
	# 如果目标没有效果了，移除目标
	if active_effects[target_id].is_empty():
		active_effects.erase(target_id)
	
	# 断开效果信号
	_disconnect_effect_signals(effect)
	
	# 移除效果
	effect.remove()
	
	# 发送效果移除信号
	effect_removed.emit(effect)
	
	return true

# 获取目标的所有效果
func get_target_effects(target) -> Array:
	# 获取目标ID
	var target_id = _get_target_id(target)
	
	# 检查目标是否有效果
	if not active_effects.has(target_id):
		return []
	
	return active_effects[target_id].duplicate()

# 获取目标的特定类型效果
func get_target_effects_by_type(target, effect_type: int) -> Array:
	# 获取目标所有效果
	var effects = get_target_effects(target)
	
	# 过滤特定类型的效果
	var filtered_effects = []
	for effect in effects:
		if effect.effect_type == effect_type:
			filtered_effects.append(effect)
	
	return filtered_effects

# 获取目标的特定标签效果
func get_target_effects_by_tag(target, tag: String) -> Array:
	# 获取目标所有效果
	var effects = get_target_effects(target)
	
	# 过滤特定标签的效果
	var filtered_effects = []
	for effect in effects:
		if effect.tags.has(tag):
			filtered_effects.append(effect)
	
	return filtered_effects

# 清理目标的所有效果
func clear_target_effects(target) -> void:
	# 获取目标ID
	var target_id = _get_target_id(target)
	
	# 检查目标是否有效果
	if not active_effects.has(target_id):
		return
	
	# 获取目标所有效果
	var effects = active_effects[target_id].duplicate()
	
	# 移除所有效果
	for effect in effects:
		remove_effect(effect)

# 清理所有效果
func clear_all_effects() -> void:
	# 获取所有目标ID
	var target_ids = active_effects.keys().duplicate()
	
	# 清理所有目标的效果
	for target_id in target_ids:
		var effects = active_effects[target_id].duplicate()
		for effect in effects:
			remove_effect(effect)

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

# 获取目标ID
func _get_target_id(target) -> String:
	if target is Node:
		return str(target.get_instance_id())
	return str(target)

# 查找目标已有的相同效果
func _find_existing_effect(target_id: String, effect: GameEffect) -> GameEffect:
	if not active_effects.has(target_id):
		return null
	
	for existing_effect in active_effects[target_id]:
		# 检查是否是相同类型的效果
		if existing_effect.effect_type == effect.effect_type:
			# 根据效果类型进行更详细的比较
			match effect.effect_type:
				GameEffect.EffectType.STATUS:
					# 状态效果需要比较状态类型
					if existing_effect.params.get("status_type", -1) == effect.params.get("status_type", -2):
						return existing_effect
				GameEffect.EffectType.STAT_MOD:
					# 属性修改效果需要比较修改的属性
					var existing_stats = existing_effect.params.get("stats", {})
					var new_stats = effect.params.get("stats", {})
					var same_stats = true
					for stat in new_stats:
						if not existing_stats.has(stat):
							same_stats = false
							break
					if same_stats:
						return existing_effect
				GameEffect.EffectType.DOT, GameEffect.EffectType.HOT:
					# DOT/HOT效果需要比较类型
					if existing_effect.params.get("dot_type", -1) == effect.params.get("dot_type", -2):
						return existing_effect
				_:
					# 其他类型的效果直接返回
					return existing_effect
	
	return null

# 查找效果通过ID
func _find_effect_by_id(effect_id: String) -> GameEffect:
	for target_id in active_effects:
		for effect in active_effects[target_id]:
			if effect.id == effect_id:
				return effect
	
	return null

# 连接效果信号
func _connect_effect_signals(effect: GameEffect) -> void:
	if not effect:
		return
	
	# 连接效果信号
	if not effect.effect_applied.is_connected(_on_effect_applied):
		effect.effect_applied.connect(_on_effect_applied)
	
	if not effect.effect_removed.is_connected(_on_effect_removed):
		effect.effect_removed.connect(_on_effect_removed)
	
	if not effect.effect_updated.is_connected(_on_effect_updated):
		effect.effect_updated.connect(_on_effect_updated)
	
	if not effect.effect_expired.is_connected(_on_effect_expired):
		effect.effect_expired.connect(_on_effect_expired)

# 断开效果信号
func _disconnect_effect_signals(effect: GameEffect) -> void:
	if not effect:
		return
	
	# 断开效果信号
	if effect.effect_applied.is_connected(_on_effect_applied):
		effect.effect_applied.disconnect(_on_effect_applied)
	
	if effect.effect_removed.is_connected(_on_effect_removed):
		effect.effect_removed.disconnect(_on_effect_removed)
	
	if effect.effect_updated.is_connected(_on_effect_updated):
		effect.effect_updated.disconnect(_on_effect_updated)
	
	if effect.effect_expired.is_connected(_on_effect_expired):
		effect.effect_expired.disconnect(_on_effect_expired)

# 效果应用信号处理
func _on_effect_applied(effect: GameEffect) -> void:
	effect_applied.emit(effect)

# 效果移除信号处理
func _on_effect_removed(effect: GameEffect) -> void:
	effect_removed.emit(effect)

# 效果更新信号处理
func _on_effect_updated(effect: GameEffect) -> void:
	effect_updated.emit(effect)

# 效果过期信号处理
func _on_effect_expired(effect: GameEffect) -> void:
	effect_expired.emit(effect)
	
	# 移除过期效果
	remove_effect(effect)

# 创建状态效果
func create_status_effect(source, target, status_type: int, duration: float, params: Dictionary = {}) -> GameEffect:
	# 创建效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.STATUS,
		"name": "状态效果",
		"description": "施加状态效果",
		"duration": duration,
		"status_type": status_type,
		"params": params,
		"tags": ["status", "debuff"],
		"visual_effect": true,
		"visual_params": {
			"duration": duration,
			"color": _get_status_color(status_type)
		}
	}
	
	# 应用效果
	return apply_effect(effect_data, source, target)

# 创建伤害效果
func create_damage_effect(source, target, damage_value: float, damage_type: String = "physical", params: Dictionary = {}) -> GameEffect:
	# 创建效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.DAMAGE,
		"name": "伤害效果",
		"description": "造成" + str(damage_value) + "点" + damage_type + "伤害",
		"duration": 0.0,  # 瞬时效果
		"value": damage_value,
		"damage_type": damage_type,
		"params": params,
		"tags": ["damage"],
		"visual_effect": true,
		"visual_params": {
			"duration": 0.5,
			"color": _get_damage_color(damage_type)
		}
	}
	
	# 应用效果
	return apply_effect(effect_data, source, target)

# 创建治疗效果
func create_heal_effect(source, target, heal_value: float, params: Dictionary = {}) -> GameEffect:
	# 创建效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.HEAL,
		"name": "治疗效果",
		"description": "恢复" + str(heal_value) + "点生命值",
		"duration": 0.0,  # 瞬时效果
		"value": heal_value,
		"params": params,
		"tags": ["heal"],
		"visual_effect": true,
		"visual_params": {
			"duration": 0.8,
			"color": Color(0, 0.8, 0, 0.8)  # 绿色
		}
	}
	
	# 应用效果
	return apply_effect(effect_data, source, target)

# 创建属性修改效果
func create_stat_effect(source, target, stats: Dictionary, duration: float, is_debuff: bool = false, params: Dictionary = {}) -> GameEffect:
	# 创建效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.STAT_MOD,
		"name": is_debuff ? "减益效果" : "增益效果",
		"description": (is_debuff ? "降低" : "提高") + "属性",
		"duration": duration,
		"stats": stats,
		"is_debuff": is_debuff,
		"params": params,
		"tags": is_debuff ? ["debuff"] : ["buff"],
		"visual_effect": true,
		"visual_params": {
			"duration": 0.8,
			"color": is_debuff ? Color(0.8, 0, 0.8, 0.8) : Color(0, 0.8, 0.8, 0.8)  # 紫色或青色
		}
	}
	
	# 应用效果
	return apply_effect(effect_data, source, target)

# 创建持续伤害效果
func create_dot_effect(source, target, dot_type: int, damage_per_second: float, duration: float, damage_type: String = "magical", params: Dictionary = {}) -> GameEffect:
	# 创建效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.DOT,
		"name": "持续伤害效果",
		"description": "每秒造成" + str(damage_per_second) + "点" + damage_type + "伤害",
		"duration": duration,
		"dot_type": dot_type,
		"damage_per_second": damage_per_second,
		"damage_type": damage_type,
		"tick_interval": params.get("tick_interval", 1.0),
		"params": params,
		"tags": ["dot", "debuff"],
		"visual_effect": true,
		"visual_params": {
			"duration": duration,
			"color": _get_dot_color(dot_type)
		}
	}
	
	# 应用效果
	return apply_effect(effect_data, source, target)

# 创建持续治疗效果
func create_hot_effect(source, target, heal_per_second: float, duration: float, params: Dictionary = {}) -> GameEffect:
	# 创建效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.HOT,
		"name": "持续治疗效果",
		"description": "每秒恢复" + str(heal_per_second) + "点生命值",
		"duration": duration,
		"heal_per_second": heal_per_second,
		"tick_interval": params.get("tick_interval", 1.0),
		"params": params,
		"tags": ["hot", "buff"],
		"visual_effect": true,
		"visual_params": {
			"duration": duration,
			"color": Color(0, 0.8, 0, 0.8)  # 绿色
		}
	}
	
	# 应用效果
	return apply_effect(effect_data, source, target)

# 创建护盾效果
func create_shield_effect(source, target, shield_amount: float, duration: float, params: Dictionary = {}) -> GameEffect:
	# 创建效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.SHIELD,
		"name": "护盾效果",
		"description": "提供" + str(shield_amount) + "点护盾",
		"duration": duration,
		"shield_amount": shield_amount,
		"params": params,
		"tags": ["shield", "buff"],
		"visual_effect": true,
		"visual_params": {
			"duration": 0.8,
			"color": Color(0.2, 0.6, 1.0, 0.8)  # 蓝色
		}
	}
	
	# 应用效果
	return apply_effect(effect_data, source, target)

# 获取状态颜色
func _get_status_color(status_type: int) -> Color:
	match status_type:
		0: # 眩晕
			return Color(1.0, 1.0, 0.0, 0.8)  # 黄色
		1: # 沉默
			return Color(0.5, 0.5, 0.5, 0.8)  # 灰色
		2: # 缴械
			return Color(0.8, 0.4, 0.0, 0.8)  # 橙色
		3: # 定身
			return Color(0.0, 0.6, 0.8, 0.8)  # 青色
		4: # 嘲讽
			return Color(1.0, 0.4, 0.0, 0.8)  # 橙红色
		5: # 冰冻
			return Color(0.0, 0.8, 1.0, 0.8)  # 浅蓝色
	return Color(0.8, 0.0, 0.8, 0.8)  # 默认紫色

# 获取伤害颜色
func _get_damage_color(damage_type: String) -> Color:
	match damage_type:
		"physical":
			return Color(0.8, 0.2, 0.2, 0.8)  # 红色
		"magical":
			return Color(0.2, 0.2, 0.8, 0.8)  # 蓝色
		"true":
			return Color(0.8, 0.8, 0.2, 0.8)  # 黄色
		"fire":
			return Color(0.8, 0.4, 0.0, 0.8)  # 橙色
		"ice":
			return Color(0.0, 0.8, 0.8, 0.8)  # 青色
		"lightning":
			return Color(0.8, 0.8, 0.0, 0.8)  # 黄色
		"poison":
			return Color(0.0, 0.8, 0.0, 0.8)  # 绿色
	return Color(0.8, 0.2, 0.2, 0.8)  # 默认红色

# 获取DOT颜色
func _get_dot_color(dot_type: int) -> Color:
	match dot_type:
		0: # 燃烧
			return Color(0.8, 0.4, 0.0, 0.8)  # 橙色
		1: # 中毒
			return Color(0.0, 0.8, 0.0, 0.8)  # 绿色
		2: # 流血
			return Color(0.8, 0.2, 0.2, 0.8)  # 红色
	return Color(0.8, 0.2, 0.2, 0.8)  # 默认红色
