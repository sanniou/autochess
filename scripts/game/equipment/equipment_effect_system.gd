extends Node
class_name EquipmentEffectSystem
## 装备效果系统
## 统一处理所有装备效果的应用、触发和移除

# 引入常量
const EffectConsts = preload("res://scripts/constants/effect_constants.gd")

# 活跃效果 {装备ID: {效果数据}}
var active_effects: Dictionary = {}

# 效果处理器映射 {效果类型: 处理方法}
var effect_handlers: Dictionary = {}

# 初始化
func _init():
	# 注册效果处理器
	_register_effect_handlers()

# 注册效果处理器
func _register_effect_handlers() -> void:
	# 属性提升效果
	effect_handlers[EffectConsts.EffectType.STAT_BOOST] = _handle_stat_boost_effect
	
	# 伤害效果
	effect_handlers[EffectConsts.EffectType.DAMAGE] = _handle_damage_effect
	
	# 治疗效果
	effect_handlers[EffectConsts.EffectType.HEAL] = _handle_heal_effect
	
	# 特殊效果
	effect_handlers[EffectConsts.EffectType.SPECIAL] = _handle_special_effect
	
	# 状态效果
	effect_handlers[EffectConsts.EffectType.STATUS] = _handle_status_effect
	
	# 移动效果
	effect_handlers[EffectConsts.EffectType.MOVEMENT] = _handle_movement_effect

# 应用装备效果
func apply_effects(equipment: Equipment, target: ChessPieceEntity) -> void:
	# 检查参数
	if equipment == null or target == null:
		return
	
	# 获取装备效果
	var effects = equipment.effects
	if effects.is_empty():
		return
	
	# 记录活跃效果
	active_effects[equipment.id] = {
		"equipment": equipment,
		"target": target,
		"effects": effects,
		"connections": []
	}
	
	# 应用基础属性
	_apply_stats(equipment, target)
	
	# 应用特殊效果
	for effect in effects:
		_apply_effect(equipment, target, effect)

# 移除装备效果
func remove_effects(equipment: Equipment, target: ChessPieceEntity) -> void:
	# 检查参数
	if equipment == null or target == null:
		return
	
	# 检查是否有活跃效果
	if not active_effects.has(equipment.id):
		return
	
	# 获取活跃效果数据
	var effect_data = active_effects[equipment.id]
	
	# 移除基础属性
	_remove_stats(equipment, target)
	
	# 断开信号连接
	for connection in effect_data.connections:
		if connection.has("signal") and connection.has("callable"):
			if connection.signal.is_connected(connection.callable):
				connection.signal.disconnect(connection.callable)
	
	# 移除活跃效果
	active_effects.erase(equipment.id)

# 触发效果
func trigger_effect(equipment: Equipment, effect_data: Dictionary, trigger_context: Dictionary = {}) -> void:
	# 检查参数
	if equipment == null or effect_data == null:
		return
	
	# 获取效果类型
	var effect_type = effect_data.get("type", "")
	if effect_type is String:
		effect_type = EffectConsts.string_to_effect_type(effect_type)
	
	# 检查是否有处理器
	if not effect_handlers.has(effect_type):
		return
	
	# 获取目标
	var target = null
	if active_effects.has(equipment.id):
		target = active_effects[equipment.id].target
	
	if target == null:
		return
	
	# 检查触发条件
	if not _check_trigger_condition(effect_data, trigger_context):
		return
	
	# 调用处理器
	effect_handlers[effect_type].call(equipment, target, effect_data, trigger_context)
	
	# 发送效果触发事件
	equipment.effect_triggered.emit(effect_data)
	GlobalEventBus.equipment.dispatch_event(EquipmentEvents.EquipmentEffectTriggeredEvent.new(equipment, effect_data))

# 应用基础属性
func _apply_stats(equipment: Equipment, target: ChessPieceEntity) -> void:
	var stats = equipment.stats
	if stats.is_empty():
		return
	
	for stat in stats:
		var value = stats[stat]
		match stat:
			"health":
				target.max_health += value
				target.current_health += value
			"attack_damage":
				target.attack_damage += value
			"attack_speed":
				target.attack_speed += value
			"armor":
				target.armor += value
			"magic_resist":
				target.magic_resist += value
			"spell_power":
				target.spell_power += value
			"move_speed":
				target.move_speed += value
			"crit_chance":
				target.crit_chance += value
			"crit_damage":
				target.crit_damage += value
			"dodge_chance":
				target.dodge_chance += value

# 移除基础属性
func _remove_stats(equipment: Equipment, target: ChessPieceEntity) -> void:
	var stats = equipment.stats
	if stats.is_empty():
		return
	
	for stat in stats:
		var value = stats[stat]
		match stat:
			"health":
				target.max_health -= value
				target.current_health = min(target.current_health, target.max_health)
			"attack_damage":
				target.attack_damage -= value
			"attack_speed":
				target.attack_speed -= value
			"armor":
				target.armor -= value
			"magic_resist":
				target.magic_resist -= value
			"spell_power":
				target.spell_power -= value
			"move_speed":
				target.move_speed -= value
			"crit_chance":
				target.crit_chance -= value
			"crit_damage":
				target.crit_damage -= value
			"dodge_chance":
				target.dodge_chance -= value

# 应用特殊效果
func _apply_effect(equipment: Equipment, target: ChessPieceEntity, effect_data: Dictionary) -> void:
	# 获取触发类型
	var trigger_type = effect_data.get("trigger", "")
	if trigger_type is String:
		trigger_type = EffectConsts.string_to_trigger_type(trigger_type)
	
	# 根据触发类型连接信号
	match trigger_type:
		EffectConsts.TriggerType.ON_ATTACK:
			# 连接攻击信号
			var callable = func(attack_target): 
				trigger_effect(equipment, effect_data, {"target": attack_target})
			target.attack_performed.connect(callable)
			
			# 记录连接
			if active_effects.has(equipment.id):
				active_effects[equipment.id].connections.append({
					"signal": target.attack_performed,
					"callable": callable
				})
		
		EffectConsts.TriggerType.ON_HIT:
			# 连接受伤信号
			var callable = func(old_value, new_value, attacker): 
				trigger_effect(equipment, effect_data, {"old_value": old_value, "new_value": new_value, "attacker": attacker})
			target.health_changed.connect(callable)
			
			# 记录连接
			if active_effects.has(equipment.id):
				active_effects[equipment.id].connections.append({
					"signal": target.health_changed,
					"callable": callable
				})
		
		EffectConsts.TriggerType.ON_ABILITY:
			# 连接技能释放信号
			var callable = func(ability_target): 
				trigger_effect(equipment, effect_data, {"target": ability_target})
			target.ability_used.connect(callable)
			
			# 记录连接
			if active_effects.has(equipment.id):
				active_effects[equipment.id].connections.append({
					"signal": target.ability_used,
					"callable": callable
				})
		
		EffectConsts.TriggerType.ON_CRIT:
			# 连接暴击信号
			var callable = func(crit_target, damage): 
				trigger_effect(equipment, effect_data, {"target": crit_target, "damage": damage})
			target.critical_hit.connect(callable)
			
			# 记录连接
			if active_effects.has(equipment.id):
				active_effects[equipment.id].connections.append({
					"signal": target.critical_hit,
					"callable": callable
				})
		
		EffectConsts.TriggerType.ON_DODGE:
			# 连接闪避信号
			var callable = func(attacker): 
				trigger_effect(equipment, effect_data, {"attacker": attacker})
			target.dodge.connect(callable)
			
			# 记录连接
			if active_effects.has(equipment.id):
				active_effects[equipment.id].connections.append({
					"signal": target.dodge,
					"callable": callable
				})
		
		EffectConsts.TriggerType.ON_LOW_HEALTH:
			# 连接生命值变化信号
			var callable = func(old_value, new_value, _attacker): 
				# 检查是否低于阈值
				var threshold = effect_data.get("threshold", 0.3)
				if new_value <= target.max_health * threshold:
					trigger_effect(equipment, effect_data, {"old_value": old_value, "new_value": new_value})
			target.health_changed.connect(callable)
			
			# 记录连接
			if active_effects.has(equipment.id):
				active_effects[equipment.id].connections.append({
					"signal": target.health_changed,
					"callable": callable
				})

# 检查触发条件
func _check_trigger_condition(effect_data: Dictionary, trigger_context: Dictionary) -> bool:
	# 检查概率
	if effect_data.has("chance"):
		var chance = effect_data.chance
		if randf() > chance:
			return false
	
	# 检查冷却时间
	if effect_data.has("cooldown_time"):
		var cooldown_time = effect_data.cooldown_time
		var last_trigger_time = effect_data.get("last_trigger_time", 0.0)
		var current_time = Time.get_unix_time_from_system()
		
		if current_time - last_trigger_time < cooldown_time:
			return false
		
		# 更新上次触发时间
		effect_data["last_trigger_time"] = current_time
	
	return true

# 处理属性提升效果
func _handle_stat_boost_effect(_equipment: Equipment, target: ChessPieceEntity, effect_data: Dictionary, _trigger_context: Dictionary) -> void:
	# 获取属性和值
	var stat = effect_data.get("stat", "")
	var value = effect_data.get("value", 0.0)
	
	# 应用属性提升
	match stat:
		"health":
			target.max_health += value
			target.current_health += value
		"attack_damage":
			target.attack_damage += value
		"attack_speed":
			target.attack_speed += value
		"armor":
			target.armor += value
		"magic_resist":
			target.magic_resist += value
		"spell_power":
			target.spell_power += value
		"move_speed":
			target.move_speed += value
		"crit_chance":
			target.crit_chance += value
		"crit_damage":
			target.crit_damage += value
		"dodge_chance":
			target.dodge_chance += value

# 处理伤害效果
func _handle_damage_effect(_equipment: Equipment, _target: ChessPieceEntity, effect_data: Dictionary, trigger_context: Dictionary) -> void:
	# 获取目标
	var damage_target = trigger_context.get("target")
	if damage_target == null:
		return
	
	# 获取伤害值和类型
	var damage = effect_data.get("damage", 0.0)
	var damage_type = effect_data.get("damage_type", "physical")
	
	# 造成伤害
	damage_target.take_damage(damage, _target, damage_type)

# 处理治疗效果
func _handle_heal_effect(_equipment: Equipment, target: ChessPieceEntity, effect_data: Dictionary, _trigger_context: Dictionary) -> void:
	# 获取治疗值
	var heal_amount = effect_data.get("heal_amount", 0.0)
	
	# 如果是百分比治疗
	if effect_data.get("is_percent", false):
		heal_amount = target.max_health * heal_amount
	
	# 治疗目标
	target.heal(heal_amount)

# 处理特殊效果
func _handle_special_effect(_equipment: Equipment, target: ChessPieceEntity, effect_data: Dictionary, trigger_context: Dictionary) -> void:
	# 获取效果名称
	var effect = effect_data.get("effect", "")
	
	# 根据效果类型处理
	match effect:
		"cooldown_reduction":
			# 冷却时间减少
			var reduction = effect_data.get("reduction", 0.0)
			target.reduce_ability_cooldown(reduction)
		
		"multi_attack":
			# 多重攻击
			var attacks = effect_data.get("attacks", 2)
			var attack_target = trigger_context.get("target")
			
			if attack_target:
				for i in range(attacks - 1):  # 减1是因为已经进行了一次攻击
					target.perform_attack(attack_target)
		
		"death_immunity":
			# 死亡免疫
			var heal_percent = effect_data.get("heal_percent", 0.3)
			target.resurrect(heal_percent)
		
		"stealth":
			# 隐身效果
			var duration = effect_data.get("duration", 3.0)
			target.add_status_effect("stealth", duration)
		
		"bleed":
			# 出血效果
			var bleed_target = trigger_context.get("target")
			var damage = effect_data.get("damage", 0.0)
			var duration = effect_data.get("duration", 3.0)
			
			if bleed_target:
				bleed_target.add_status_effect("bleed", duration, {"damage": damage, "source": target})

# 处理状态效果
func _handle_status_effect(_equipment: Equipment, _target: ChessPieceEntity, effect_data: Dictionary, trigger_context: Dictionary) -> void:
	# 获取目标
	var status_target = trigger_context.get("target", _target)
	if status_target == null:
		return
	
	# 获取状态类型和持续时间
	var status_type = effect_data.get("status_type", "")
	var duration = effect_data.get("duration", 3.0)
	
	# 应用状态效果
	status_target.add_status_effect(status_type, duration, effect_data)

# 处理移动效果
func _handle_movement_effect(_equipment: Equipment, target: ChessPieceEntity, effect_data: Dictionary, _trigger_context: Dictionary) -> void:
	# 获取移动类型
	var movement_type = effect_data.get("movement_type", "")
	
	# 根据移动类型处理
	match movement_type:
		"dash":
			# 冲刺
			var distance = effect_data.get("distance", 3.0)
			target.dash(distance)
		
		"teleport":
			# 传送
			var position = effect_data.get("position")
			if position:
				target.teleport(position)
		
		"knockback":
			# 击退
			var knockback_target = _trigger_context.get("target")
			var force = effect_data.get("force", 2.0)
			
			if knockback_target:
				knockback_target.apply_knockback(target.global_position, force)
