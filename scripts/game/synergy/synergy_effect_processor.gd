extends Node
class_name SynergyEffectProcessor
## 羁绊效果处理器
## 统一处理羁绊效果的应用和移除

# 效果类型
enum EffectType {
	ATTRIBUTE,  # 属性效果
	ABILITY,    # 技能效果
	SPECIAL     # 特殊效果
}

# 应用羁绊效果
static func apply_synergy_effects(synergy_id: String, level: int, effects: Array, target_pieces: Array) -> void:
	# 如果没有效果，直接返回
	if effects.is_empty():
		return
	
	# 遍历所有效果
	for effect in effects:
		# 检查效果是否有效
		if not effect is Dictionary:
			continue
		
		# 获取效果类型
		var effect_type = _get_effect_type(effect)
		
		# 根据效果类型应用效果
		match effect_type:
			EffectType.ATTRIBUTE:
				_apply_attribute_effect(synergy_id, level, effect, target_pieces)
			EffectType.ABILITY:
				_apply_ability_effect(synergy_id, level, effect, target_pieces)
			EffectType.SPECIAL:
				_apply_special_effect(synergy_id, level, effect, target_pieces)

# 移除羁绊效果
static func remove_synergy_effects(synergy_id: String, level: int, effects: Array, target_pieces: Array) -> void:
	# 如果没有效果，直接返回
	if effects.is_empty():
		return
	
	# 遍历所有效果
	for effect in effects:
		# 检查效果是否有效
		if not effect is Dictionary:
			continue
		
		# 获取效果类型
		var effect_type = _get_effect_type(effect)
		
		# 根据效果类型移除效果
		match effect_type:
			EffectType.ATTRIBUTE:
				_remove_attribute_effect(synergy_id, level, effect, target_pieces)
			EffectType.ABILITY:
				_remove_ability_effect(synergy_id, level, effect, target_pieces)
			EffectType.SPECIAL:
				_remove_special_effect(synergy_id, level, effect, target_pieces)

# 获取效果类型
static func _get_effect_type(effect: Dictionary) -> int:
	if not effect.has("type"):
		return -1
	
	match effect.type:
		"attribute":
			return EffectType.ATTRIBUTE
		"ability":
			return EffectType.ABILITY
		"special":
			return EffectType.SPECIAL
		_:
			return -1

# 应用属性效果
static func _apply_attribute_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 检查效果是否有必要字段
	if not effect.has("attribute") or not effect.has("value") or not effect.has("operation"):
		return
	
	# 获取效果数据
	var attribute = effect.attribute
	var value = effect.value
	var operation = effect.operation
	
	# 构建修饰符ID
	var modifier_id = "synergy_" + synergy_id + "_" + str(level) + "_" + effect.id
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取属性组件
		var attribute_component = piece.get_component("AttributeComponent")
		if not attribute_component:
			continue
		
		# 应用属性修饰符
		attribute_component.add_attribute_modifier(attribute, modifier_id, value, operation)

# 移除属性效果
static func _remove_attribute_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 检查效果是否有必要字段
	if not effect.has("attribute"):
		return
	
	# 获取效果数据
	var attribute = effect.attribute
	
	# 构建修饰符ID
	var modifier_id = "synergy_" + synergy_id + "_" + str(level) + "_" + effect.id
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取属性组件
		var attribute_component = piece.get_component("AttributeComponent")
		if not attribute_component:
			continue
		
		# 移除属性修饰符
		attribute_component.remove_attribute_modifier(attribute, modifier_id)

# 应用技能效果
static func _apply_ability_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 检查效果是否有必要字段
	if not effect.has("ability_id"):
		return
	
	# 获取效果数据
	var ability_id = effect.ability_id
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取技能组件
		var ability_component = piece.get_component("AbilityComponent")
		if not ability_component:
			continue
		
		# 添加技能
		ability_component.add_ability(ability_id)

# 移除技能效果
static func _remove_ability_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 检查效果是否有必要字段
	if not effect.has("ability_id"):
		return
	
	# 获取效果数据
	var ability_id = effect.ability_id
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取技能组件
		var ability_component = piece.get_component("AbilityComponent")
		if not ability_component:
			continue
		
		# 移除技能
		ability_component.remove_ability(ability_id)

# 应用特殊效果
static func _apply_special_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 检查效果是否有必要字段
	if not effect.has("special_id"):
		return
	
	# 获取效果数据
	var special_id = effect.special_id
	
	# 根据特殊效果ID应用效果
	match special_id:
		"double_attack":
			_apply_double_attack_effect(synergy_id, level, effect, target_pieces)
		"lifesteal":
			_apply_lifesteal_effect(synergy_id, level, effect, target_pieces)
		"mana_regen":
			_apply_mana_regen_effect(synergy_id, level, effect, target_pieces)
		"damage_reduction":
			_apply_damage_reduction_effect(synergy_id, level, effect, target_pieces)
		"critical_strike":
			_apply_critical_strike_effect(synergy_id, level, effect, target_pieces)
		_:
			# 使用效果系统处理其他特殊效果
			_apply_generic_special_effect(synergy_id, level, effect, target_pieces)

# 移除特殊效果
static func _remove_special_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 检查效果是否有必要字段
	if not effect.has("special_id"):
		return
	
	# 获取效果数据
	var special_id = effect.special_id
	
	# 根据特殊效果ID移除效果
	match special_id:
		"double_attack":
			_remove_double_attack_effect(synergy_id, level, effect, target_pieces)
		"lifesteal":
			_remove_lifesteal_effect(synergy_id, level, effect, target_pieces)
		"mana_regen":
			_remove_mana_regen_effect(synergy_id, level, effect, target_pieces)
		"damage_reduction":
			_remove_damage_reduction_effect(synergy_id, level, effect, target_pieces)
		"critical_strike":
			_remove_critical_strike_effect(synergy_id, level, effect, target_pieces)
		_:
			# 使用效果系统处理其他特殊效果
			_remove_generic_special_effect(synergy_id, level, effect, target_pieces)

# 应用双重攻击效果
static func _apply_double_attack_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_double_attack"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 创建双重攻击效果
		var double_attack_effect = {
			"id": effect_id,
			"name": "双重攻击",
			"description": "有几率进行两次攻击",
			"duration": -1,  # 永久效果
			"type": "buff",
			"trigger": "on_attack",
			"chance": effect.get("chance", 0.25),  # 默认25%几率
			"effect_data": {
				"extra_attacks": 1
			}
		}
		
		# 添加效果
		effect_component.add_effect(double_attack_effect)

# 移除双重攻击效果
static func _remove_double_attack_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_double_attack"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 移除效果
		effect_component.remove_effect(effect_id)

# 应用生命偷取效果
static func _apply_lifesteal_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_lifesteal"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 创建生命偷取效果
		var lifesteal_effect = {
			"id": effect_id,
			"name": "生命偷取",
			"description": "攻击时回复一定比例的生命值",
			"duration": -1,  # 永久效果
			"type": "buff",
			"trigger": "on_damage_dealt",
			"effect_data": {
				"lifesteal_percent": effect.get("percent", 0.15)  # 默认15%生命偷取
			}
		}
		
		# 添加效果
		effect_component.add_effect(lifesteal_effect)

# 移除生命偷取效果
static func _remove_lifesteal_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_lifesteal"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 移除效果
		effect_component.remove_effect(effect_id)

# 应用法力回复效果
static func _apply_mana_regen_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_mana_regen"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 创建法力回复效果
		var mana_regen_effect = {
			"id": effect_id,
			"name": "法力回复",
			"description": "每秒回复额外法力值",
			"duration": -1,  # 永久效果
			"type": "buff",
			"trigger": "on_update",
			"effect_data": {
				"mana_regen": effect.get("amount", 2.0)  # 默认每秒回复2点法力值
			}
		}
		
		# 添加效果
		effect_component.add_effect(mana_regen_effect)

# 移除法力回复效果
static func _remove_mana_regen_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_mana_regen"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 移除效果
		effect_component.remove_effect(effect_id)

# 应用伤害减免效果
static func _apply_damage_reduction_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_damage_reduction"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 创建伤害减免效果
		var damage_reduction_effect = {
			"id": effect_id,
			"name": "伤害减免",
			"description": "减少受到的伤害",
			"duration": -1,  # 永久效果
			"type": "buff",
			"trigger": "on_damage_received",
			"effect_data": {
				"damage_reduction_percent": effect.get("percent", 0.15)  # 默认减免15%伤害
			}
		}
		
		# 添加效果
		effect_component.add_effect(damage_reduction_effect)

# 移除伤害减免效果
static func _remove_damage_reduction_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_damage_reduction"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 移除效果
		effect_component.remove_effect(effect_id)

# 应用暴击效果
static func _apply_critical_strike_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_critical_strike"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 创建暴击效果
		var critical_strike_effect = {
			"id": effect_id,
			"name": "暴击",
			"description": "攻击有几率造成额外伤害",
			"duration": -1,  # 永久效果
			"type": "buff",
			"trigger": "on_attack",
			"effect_data": {
				"critical_chance": effect.get("chance", 0.25),  # 默认25%暴击几率
				"critical_damage": effect.get("damage", 1.5)    # 默认150%暴击伤害
			}
		}
		
		# 添加效果
		effect_component.add_effect(critical_strike_effect)

# 移除暴击效果
static func _remove_critical_strike_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_critical_strike"
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 移除效果
		effect_component.remove_effect(effect_id)

# 应用通用特殊效果
static func _apply_generic_special_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_" + effect.special_id
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 创建通用效果
		var generic_effect = {
			"id": effect_id,
			"name": effect.get("name", "特殊效果"),
			"description": effect.get("description", ""),
			"duration": -1,  # 永久效果
			"type": "buff",
			"trigger": effect.get("trigger", "on_update"),
			"effect_data": effect.get("effect_data", {})
		}
		
		# 添加效果
		effect_component.add_effect(generic_effect)

# 移除通用特殊效果
static func _remove_generic_special_effect(synergy_id: String, level: int, effect: Dictionary, target_pieces: Array) -> void:
	# 构建效果ID
	var effect_id = "synergy_" + synergy_id + "_" + str(level) + "_" + effect.special_id
	
	# 遍历所有目标棋子
	for piece in target_pieces:
		# 获取效果组件
		var effect_component = piece.get_component("EffectComponent")
		if not effect_component:
			continue
		
		# 移除效果
		effect_component.remove_effect(effect_id)
