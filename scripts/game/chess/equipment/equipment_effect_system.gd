# extends Resource
# class_name EquipmentEffectSystem
# ## 装备效果系统
# ## 处理装备效果的应用和触发

# # 信号
# signal effect_applied(equipment, effect, target)
# signal effect_removed(equipment, effect, target)
# signal effect_triggered(equipment, effect, target, context)

# # 效果映射
# var applied_effects: Dictionary = {}  # {装备ID: {效果ID: {效果数据}}}
# var effect_modifiers: Dictionary = {}  # {目标ID: {属性名: [修改器ID]}}

# # 初始化
# func _init():
# 	pass

# # 应用装备效果
# func apply_effects(equipment, target) -> void:
# 	# 检查参数
# 	if not equipment or not target:
# 		return
	
# 	# 获取装备ID
# 	var equipment_id = ""
# 	if equipment.has_method("get_id"):
# 		equipment_id = equipment.get_id()
# 	elif equipment.has("id"):
# 		equipment_id = equipment.id
	
# 	if equipment_id.is_empty():
# 		return
	
# 	# 获取装备效果
# 	var effects = []
# 	if equipment.has_method("get_effects"):
# 		effects = equipment.get_effects()
# 	elif equipment.has("effects"):
# 		effects = equipment.effects
	
# 	# 初始化装备效果映射
# 	if not applied_effects.has(equipment_id):
# 		applied_effects[equipment_id] = {}
	
# 	# 应用所有效果
# 	for effect in effects:
# 		# 获取效果ID
# 		var effect_id = ""
# 		if effect.has("id"):
# 			effect_id = effect.id
# 		else:
# 			effect_id = equipment_id + "_effect_" + str(effects.find(effect))
		
# 		# 应用效果
# 		_apply_effect(equipment, effect, effect_id, target)
		
# 		# 添加到映射
# 		applied_effects[equipment_id][effect_id] = effect
		
# 		# 发送效果应用信号
# 		effect_applied.emit(equipment, effect, target)

# # 移除装备效果
# func remove_effects(equipment, target) -> void:
# 	# 检查参数
# 	if not equipment or not target:
# 		return
	
# 	# 获取装备ID
# 	var equipment_id = ""
# 	if equipment.has_method("get_id"):
# 		equipment_id = equipment.get_id()
# 	elif equipment.has("id"):
# 		equipment_id = equipment.id
	
# 	if equipment_id.is_empty() or not applied_effects.has(equipment_id):
# 		return
	
# 	# 获取装备效果
# 	var effects = applied_effects[equipment_id]
	
# 	# 移除所有效果
# 	for effect_id in effects:
# 		var effect = effects[effect_id]
		
# 		# 移除效果
# 		_remove_effect(equipment, effect, effect_id, target)
		
# 		# 发送效果移除信号
# 		effect_removed.emit(equipment, effect, target)
	
# 	# 清空映射
# 	applied_effects.erase(equipment_id)

# # 触发装备效果
# func trigger_effects(equipment, context: Dictionary = {}) -> Array:
# 	# 检查参数
# 	if not equipment:
# 		return []
	
# 	# 获取装备ID
# 	var equipment_id = ""
# 	if equipment.has_method("get_id"):
# 		equipment_id = equipment.get_id()
# 	elif equipment.has("id"):
# 		equipment_id = equipment.id
	
# 	if equipment_id.is_empty() or not applied_effects.has(equipment_id):
# 		return []
	
# 	# 获取装备效果
# 	var effects = applied_effects[equipment_id]
	
# 	# 触发的效果列表
# 	var triggered_effects = []
	
# 	# 触发所有效果
# 	for effect_id in effects:
# 		var effect = effects[effect_id]
		
# 		# 检查触发条件
# 		if _check_trigger_condition(effect, context):
# 			# 获取目标
# 			var target = context.get("target", null)
			
# 			# 触发效果
# 			_trigger_effect(equipment, effect, effect_id, target, context)
			
# 			# 添加到触发列表
# 			triggered_effects.append(effect)
			
# 			# 发送效果触发信号
# 			effect_triggered.emit(equipment, effect, target, context)
	
# 	return triggered_effects

# # 触发指定类型的效果
# func trigger_effects_by_type(equipment, trigger_type: String, context: Dictionary = {}) -> Array:
# 	# 检查参数
# 	if not equipment:
# 		return []
	
# 	# 获取装备ID
# 	var equipment_id = ""
# 	if equipment.has_method("get_id"):
# 		equipment_id = equipment.get_id()
# 	elif equipment.has("id"):
# 		equipment_id = equipment.id
	
# 	if equipment_id.is_empty() or not applied_effects.has(equipment_id):
# 		return []
	
# 	# 获取装备效果
# 	var effects = applied_effects[equipment_id]
	
# 	# 触发的效果列表
# 	var triggered_effects = []
	
# 	# 触发指定类型的效果
# 	for effect_id in effects:
# 		var effect = effects[effect_id]
		
# 		# 检查触发类型
# 		var effect_trigger = effect.get("trigger", "")
# 		if effect_trigger == trigger_type:
# 			# 检查触发条件
# 			if _check_trigger_condition(effect, context):
# 				# 获取目标
# 				var target = context.get("target", null)
				
# 				# 触发效果
# 				_trigger_effect(equipment, effect, effect_id, target, context)
				
# 				# 添加到触发列表
# 				triggered_effects.append(effect)
				
# 				# 发送效果触发信号
# 				effect_triggered.emit(equipment, effect, target, context)
	
# 	return triggered_effects

# # 应用效果
# func _apply_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 获取效果类型
# 	var effect_type = effect.get("type", "")
	
# 	# 根据效果类型应用不同效果
# 	match effect_type:
# 		"attribute":
# 			_apply_attribute_effect(equipment, effect, effect_id, target)
# 		"ability":
# 			_apply_ability_effect(equipment, effect, effect_id, target)
# 		"special":
# 			_apply_special_effect(equipment, effect, effect_id, target)

# # 移除效果
# func _remove_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 获取效果类型
# 	var effect_type = effect.get("type", "")
	
# 	# 根据效果类型移除不同效果
# 	match effect_type:
# 		"attribute":
# 			_remove_attribute_effect(equipment, effect, effect_id, target)
# 		"ability":
# 			_remove_ability_effect(equipment, effect, effect_id, target)
# 		"special":
# 			_remove_special_effect(equipment, effect, effect_id, target)

# # 触发效果
# func _trigger_effect(equipment, effect: Dictionary, effect_id: String, target, context: Dictionary) -> void:
# 	# 获取效果类型
# 	var effect_type = effect.get("type", "")
	
# 	# 根据效果类型触发不同效果
# 	match effect_type:
# 		"attribute":
# 			_trigger_attribute_effect(equipment, effect, effect_id, target, context)
# 		"ability":
# 			_trigger_ability_effect(equipment, effect, effect_id, target, context)
# 		"special":
# 			_trigger_special_effect(equipment, effect, effect_id, target, context)

# # 检查触发条件
# func _check_trigger_condition(effect: Dictionary, context: Dictionary) -> bool:
# 	# 获取触发条件
# 	var condition = effect.get("condition", {})
# 	if condition.is_empty():
# 		return true
	
# 	# 检查条件类型
# 	var condition_type = condition.get("type", "")
	
# 	# 根据条件类型检查不同条件
# 	match condition_type:
# 		"health_percent":
# 			# 检查生命值百分比条件
# 			var target = context.get("target", null)
# 			if not target:
# 				return false
			
# 			# 获取目标生命值百分比
# 			var health_percent = 1.0
			
# 			if target.has_method("get_component"):
# 				var attribute_component = target.get_component("AttributeComponent")
# 				if attribute_component:
# 					health_percent = attribute_component.get_health_percent()
# 			elif target.has("current_health") and target.has("max_health"):
# 				health_percent = target.current_health / target.max_health
			
# 			# 获取条件参数
# 			var operator = condition.get("operator", "<=")
# 			var value = condition.get("value", 0.5)
			
# 			# 检查条件
# 			match operator:
# 				"<=":
# 					return health_percent <= value
# 				"<":
# 					return health_percent < value
# 				">=":
# 					return health_percent >= value
# 				">":
# 					return health_percent > value
# 				"==":
# 					return health_percent == value
		
# 		"mana_percent":
# 			# 检查法力值百分比条件
# 			var target = context.get("target", null)
# 			if not target:
# 				return false
			
# 			# 获取目标法力值百分比
# 			var mana_percent = 1.0
			
# 			if target.has_method("get_component"):
# 				var attribute_component = target.get_component("AttributeComponent")
# 				if attribute_component:
# 					mana_percent = attribute_component.get_mana_percent()
# 			elif target.has("current_mana") and target.has("max_mana"):
# 				mana_percent = target.current_mana / target.max_mana
			
# 			# 获取条件参数
# 			var operator = condition.get("operator", ">=")
# 			var value = condition.get("value", 0.5)
			
# 			# 检查条件
# 			match operator:
# 				"<=":
# 					return mana_percent <= value
# 				"<":
# 					return mana_percent < value
# 				">=":
# 					return mana_percent >= value
# 				">":
# 					return mana_percent > value
# 				"==":
# 					return mana_percent == value
		
# 		"chance":
# 			# 检查几率条件
# 			var chance = condition.get("value", 0.5)
# 			return randf() <= chance
		
# 		"state":
# 			# 检查状态条件
# 			var target = context.get("target", null)
# 			if not target:
# 				return false
			
# 			# 获取目标状态
# 			var state = -1
			
# 			if target.has_method("get_component"):
# 				var state_component = target.get_component("StateComponent")
# 				if state_component:
# 					state = state_component.current_state
# 			elif target.has("current_state"):
# 				state = target.current_state
			
# 			# 获取条件参数
# 			var state_value = condition.get("value", 0)
			
# 			# 检查条件
# 			return state == state_value
		
# 		"has_effect":
# 			# 检查是否有效果条件
# 			var target = context.get("target", null)
# 			if not target:
# 				return false
			
# 			# 获取效果ID
# 			var effect_id = condition.get("value", "")
			
# 			# 检查目标是否有效果
# 			if target.has_method("has_effect"):
# 				return target.has_effect(effect_id)
			
# 			return false
	
# 	return true

# # 应用属性效果
# func _apply_attribute_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 获取属性组件
# 	var attribute_component = null
# 	if target.has_method("get_component"):
# 		attribute_component = target.get_component("AttributeComponent")
	
# 	if not attribute_component:
# 		return
	
# 	# 获取效果参数
# 	var attribute_name = effect.get("attribute", "")
# 	var value = effect.get("value", 0)
# 	var is_percentage = effect.get("is_percentage", false)
	
# 	# 添加属性修改器
# 	if not attribute_name.is_empty():
# 		var modifier_id = attribute_component.add_attribute_modifier(attribute_name, {
# 			"value": value,
# 			"type": "percent_add" if is_percentage else "add",
# 			"duration": -1,  # 永久修改器
# 			"source": "equipment:" + equipment.id
# 		})
		
# 		# 保存修改器ID
# 		var target_id = ""
# 		if target.has_method("get_id"):
# 			target_id = target.get_id()
# 		elif target.has_method("get_instance_id"):
# 			target_id = str(target.get_instance_id())
		
# 		if not target_id.is_empty():
# 			if not effect_modifiers.has(target_id):
# 				effect_modifiers[target_id] = {}
			
# 			if not effect_modifiers[target_id].has(attribute_name):
# 				effect_modifiers[target_id][attribute_name] = []
			
# 			effect_modifiers[target_id][attribute_name].append(modifier_id)

# # 移除属性效果
# func _remove_attribute_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 获取属性组件
# 	var attribute_component = null
# 	if target.has_method("get_component"):
# 		attribute_component = target.get_component("AttributeComponent")
	
# 	if not attribute_component:
# 		return
	
# 	# 获取目标ID
# 	var target_id = ""
# 	if target.has_method("get_id"):
# 		target_id = target.get_id()
# 	elif target.has_method("get_instance_id"):
# 		target_id = str(target.get_instance_id())
	
# 	if target_id.is_empty() or not effect_modifiers.has(target_id):
# 		return
	
# 	# 获取效果参数
# 	var attribute_name = effect.get("attribute", "")
	
# 	# 移除属性修改器
# 	if not attribute_name.is_empty() and effect_modifiers[target_id].has(attribute_name):
# 		for modifier_id in effect_modifiers[target_id][attribute_name]:
# 			attribute_component.remove_attribute_modifier(modifier_id)
		
# 		# 清空修改器ID
# 		effect_modifiers[target_id].erase(attribute_name)
		
# 		# 如果目标没有修改器，移除目标
# 		if effect_modifiers[target_id].is_empty():
# 			effect_modifiers.erase(target_id)

# # 触发属性效果
# func _trigger_attribute_effect(equipment, effect: Dictionary, effect_id: String, target, context: Dictionary) -> void:
# 	# 属性效果通常不需要触发，因为它们是被动效果
# 	pass

# # 应用技能效果
# func _apply_ability_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 获取技能组件
# 	var ability_component = null
# 	if target.has_method("get_component"):
# 		ability_component = target.get_component("AbilityComponent")
	
# 	if not ability_component:
# 		return
	
# 	# 获取效果参数
# 	var ability_id = effect.get("ability_id", "")
	
# 	# 如果有技能ID，加载技能
# 	if not ability_id.is_empty():
# 		# 获取技能数据
# 		var ability_data = GameManager.ability_manager.get_ability_data(ability_id)
# 		if ability_data:
# 			# 初始化技能
# 			ability_component.initialize_ability(ability_data)

# # 移除技能效果
# func _remove_ability_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 技能效果通常不需要移除，因为技能组件会在重新初始化时覆盖
# 	pass

# # 触发技能效果
# func _trigger_ability_effect(equipment, effect: Dictionary, effect_id: String, target, context: Dictionary) -> void:
# 	# 获取技能组件
# 	var ability_component = null
# 	if target.has_method("get_component"):
# 		ability_component = target.get_component("AbilityComponent")
	
# 	if not ability_component:
# 		return
	
# 	# 获取效果参数
# 	var ability_id = effect.get("ability_id", "")
	
# 	# 如果有技能ID，触发技能
# 	if not ability_id.is_empty():
# 		# 使用技能
# 		ability_component.cast_ability()

# # 应用特殊效果
# func _apply_special_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 获取效果参数
# 	var special_type = effect.get("special_type", "")
	
# 	# 根据特殊效果类型应用不同效果
# 	match special_type:
# 		"elemental":
# 			# 应用元素效果
# 			var element_type = effect.get("element_type", "")
			
# 			# 获取战斗组件
# 			var combat_component = null
# 			if target.has_method("get_component"):
# 				combat_component = target.get_component("CombatComponent")
			
# 			if combat_component and not element_type.is_empty():
# 				combat_component.set_elemental_type(element_type)
		
# 		"immunity":
# 			# 应用免疫效果
# 			var immunity_type = effect.get("immunity_type", "")
			
# 			# 获取状态组件
# 			var state_component = null
# 			if target.has_method("get_component"):
# 				state_component = target.get_component("StateComponent")
			
# 			if state_component and not immunity_type.is_empty():
# 				# 根据免疫类型设置不同的免疫
# 				match immunity_type:
# 					"silence":
# 						state_component.set_silenced(false)
# 						state_component.lock_state(state_component.ChessState.CASTING)
# 					"stun":
# 						state_component.set_stunned(false)
# 						state_component.lock_state(state_component.ChessState.STUNNED)
# 					"disarm":
# 						state_component.set_disarmed(false)
# 					"freeze":
# 						state_component.set_frozen(false)

# # 移除特殊效果
# func _remove_special_effect(equipment, effect: Dictionary, effect_id: String, target) -> void:
# 	# 获取效果参数
# 	var special_type = effect.get("special_type", "")
	
# 	# 根据特殊效果类型移除不同效果
# 	match special_type:
# 		"elemental":
# 			# 移除元素效果
# 			# 获取战斗组件
# 			var combat_component = null
# 			if target.has_method("get_component"):
# 				combat_component = target.get_component("CombatComponent")
			
# 			if combat_component:
# 				combat_component.set_elemental_type("")
		
# 		"immunity":
# 			# 移除免疫效果
# 			var immunity_type = effect.get("immunity_type", "")
			
# 			# 获取状态组件
# 			var state_component = null
# 			if target.has_method("get_component"):
# 				state_component = target.get_component("StateComponent")
			
# 			if state_component and not immunity_type.is_empty():
# 				# 根据免疫类型移除不同的免疫
# 				match immunity_type:
# 					"silence":
# 						state_component.unlock_state(state_component.ChessState.CASTING)
# 					"stun":
# 						state_component.unlock_state(state_component.ChessState.STUNNED)
# 					"disarm":
# 						pass
# 					"freeze":
# 						pass

# # 触发特殊效果
# func _trigger_special_effect(equipment, effect: Dictionary, effect_id: String, target, context: Dictionary) -> void:
# 	# 获取效果参数
# 	var special_type = effect.get("special_type", "")
	
# 	# 根据特殊效果类型触发不同效果
# 	match special_type:
# 		"damage":
# 			# 触发伤害效果
# 			var damage_amount = effect.get("damage_amount", 0)
# 			var damage_type = effect.get("damage_type", "physical")
			
# 			# 获取战斗组件
# 			var combat_component = null
# 			if target.has_method("get_component"):
# 				combat_component = target.get_component("CombatComponent")
			
# 			if combat_component:
# 				# 获取目标
# 				var damage_target = context.get("target", null)
# 				if damage_target:
# 					combat_component.deal_damage(damage_target, damage_amount, damage_type, false)
		
# 		"heal":
# 			# 触发治疗效果
# 			var heal_amount = effect.get("heal_amount", 0)
			
# 			# 获取战斗组件
# 			var combat_component = null
# 			if target.has_method("get_component"):
# 				combat_component = target.get_component("CombatComponent")
			
# 			if combat_component:
# 				# 获取目标
# 				var heal_target = context.get("target", target)
# 				if heal_target:
# 					combat_component.heal_target(heal_target, heal_amount)
		
# 		"status":
# 			# 触发状态效果
# 			var status_type = effect.get("status_type", "")
# 			var duration = effect.get("duration", 3.0)
			
# 			# 获取状态组件
# 			var state_component = null
# 			if target.has_method("get_component"):
# 				state_component = target.get_component("StateComponent")
			
# 			if state_component and not status_type.is_empty():
# 				# 根据状态类型设置不同的状态
# 				match status_type:
# 					"silence":
# 						state_component.set_silenced(true)
						
# 						# 延迟解除状态
# 						await get_tree().create_timer(duration).timeout
						
# 						if is_instance_valid(target) and target.has_method("get_component"):
# 							state_component = target.get_component("StateComponent")
# 							if state_component:
# 								state_component.set_silenced(false)
					
# 					"stun":
# 						state_component.set_stunned(true)
						
# 						# 延迟解除状态
# 						await get_tree().create_timer(duration).timeout
						
# 						if is_instance_valid(target) and target.has_method("get_component"):
# 							state_component = target.get_component("StateComponent")
# 							if state_component:
# 								state_component.set_stunned(false)
					
# 					"disarm":
# 						state_component.set_disarmed(true)
						
# 						# 延迟解除状态
# 						await get_tree().create_timer(duration).timeout
						
# 						if is_instance_valid(target) and target.has_method("get_component"):
# 							state_component = target.get_component("StateComponent")
# 							if state_component:
# 								state_component.set_disarmed(false)
					
# 					"freeze":
# 						state_component.set_frozen(true)
						
# 						# 延迟解除状态
# 						await get_tree().create_timer(duration).timeout
						
# 						if is_instance_valid(target) and target.has_method("get_component"):
# 							state_component = target.get_component("StateComponent")
# 							if state_component:
# 								state_component.set_frozen(false)
