# extends BattleEffect
# class_name AuraEffect
# ## 光环效果
# ## 为周围单位提供效果

# # 光环类型枚举
# enum AuraType {
# 	BUFF,       # 增益光环
# 	DEBUFF,     # 减益光环
# 	HEALING,    # 治疗光环
# 	DAMAGE,     # 伤害光环
# 	PROTECTION, # 保护光环
# 	VAMPIRIC    # 吸血光环
# }

# # 光环效果属性
# var aura_type: int = AuraType.BUFF
# var radius: float = 300.0  # 光环半径
# var affected_units: Array = []  # 受影响的单位
# var effect_data: Dictionary = {}  # 光环提供的效果数据
# var update_interval: float = 0.5  # 更新间隔（秒）
# var update_timer: float = 0.0  # 更新计时器
# var aura_visual: Node2D = null  # 光环视觉效果

# # 初始化
# func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "", 
# 		effect_duration: float = 0.0, aura_type_value: int = AuraType.BUFF, 
# 		radius_value: float = 300.0, effect_data_value: Dictionary = {}, 
# 		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
# 	super._init(effect_id, effect_name, effect_description, effect_duration, 
# 			EffectType.AURA, effect_source, effect_target, effect_params)
	
# 	aura_type = aura_type_value
# 	radius = radius_value
# 	effect_data = effect_data_value
	
# 	# 设置更新间隔
# 	if effect_params.has("update_interval"):
# 		update_interval = effect_params.update_interval
	
# 	# 设置图标路径
# 	icon_path = _get_aura_icon_path(aura_type)
	
# 	# 设置名称和描述
# 	if name.is_empty():
# 		name = _get_aura_name(aura_type)
	
# 	if description.is_empty():
# 		description = _generate_aura_description()

# # 应用效果
# func apply() -> bool:
# 	if not super.apply():
# 		return false
	
# 	if not target or not is_instance_valid(target):
# 		return false
	
# 	# 创建光环视觉效果
# 	_create_aura_visual()
	
# 	# 立即更新一次受影响的单位
# 	_update_affected_units()
	
# 	# 应用光环效果
# 	_apply_aura_effects()
	
# 	return true

# # 移除效果
# func remove() -> bool:
# 	if not super.remove():
# 		return false
	
# 	# 移除光环效果
# 	_remove_aura_effects()
	
# 	# 移除光环视觉效果
# 	_remove_aura_visual()
	
# 	return true

# # 更新效果
# func update(delta: float) -> bool:
# 	if not super.update(delta):
# 		return false
	
# 	# 更新计时器
# 	update_timer += delta
	
# 	# 检查是否应该更新受影响的单位
# 	if update_timer >= update_interval:
# 		_update_affected_units()
# 		update_timer -= update_interval
	
# 	return true

# # 更新受影响的单位
# func _update_affected_units() -> void:
# 	if not target or not is_instance_valid(target):
# 		return
	
# 	# 获取当前受影响的单位
# 	var current_affected = affected_units.duplicate()
# 	affected_units.clear()
	
# 	# 获取所有棋子
# 	var board_manager = GameManager.board_manager
# 	if not board_manager:
# 		return
	
# 	var all_pieces = board_manager.pieces
	
# 	# 检查每个棋子是否在光环范围内
# 	for piece in all_pieces:
# 		if not is_instance_valid(piece) or piece == target:
# 			continue
		
# 		# 检查是否在光环范围内
# 		var distance = piece.global_position.distance_to(target.global_position)
# 		if distance <= radius:
# 			# 检查是否是友方或敌方
# 			var is_friendly = piece.is_player_piece == target.is_player_piece
			
# 			# 根据光环类型决定是否影响该单位
# 			var should_affect = false
			
# 			match aura_type:
# 				AuraType.BUFF, AuraType.HEALING, AuraType.PROTECTION:
# 					# 增益光环只影响友方单位
# 					should_affect = is_friendly
				
# 				AuraType.DEBUFF, AuraType.DAMAGE:
# 					# 减益光环只影响敌方单位
# 					should_affect = not is_friendly
				
# 				AuraType.VAMPIRIC:
# 					# 吸血光环只影响敌方单位
# 					should_affect = not is_friendly
			
# 			if should_affect:
# 				affected_units.append(piece)
	
# 	# 检查新增的单位
# 	for piece in affected_units:
# 		if not current_affected.has(piece):
# 			# 为新增的单位应用效果
# 			_apply_aura_effect_to_unit(piece)
	
# 	# 检查移除的单位
# 	for piece in current_affected:
# 		if not affected_units.has(piece) and is_instance_valid(piece):
# 			# 为移除的单位移除效果
# 			_remove_aura_effect_from_unit(piece)

# # 应用光环效果
# func _apply_aura_effects() -> void:
# 	for unit in affected_units:
# 		_apply_aura_effect_to_unit(unit)

# # 移除光环效果
# func _remove_aura_effects() -> void:
# 	for unit in affected_units:
# 		if is_instance_valid(unit):
# 			_remove_aura_effect_from_unit(unit)
	
# 	affected_units.clear()

# # 为单位应用光环效果
# func _apply_aura_effect_to_unit(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 根据光环类型应用不同的效果
# 	match aura_type:
# 		AuraType.BUFF:
# 			_apply_buff_effect(unit)
		
# 		AuraType.DEBUFF:
# 			_apply_debuff_effect(unit)
		
# 		AuraType.HEALING:
# 			_apply_healing_effect(unit)
		
# 		AuraType.DAMAGE:
# 			_apply_damage_effect(unit)
		
# 		AuraType.PROTECTION:
# 			_apply_protection_effect(unit)
		
# 		AuraType.VAMPIRIC:
# 			_apply_vampiric_effect(unit)

# # 为单位移除光环效果
# func _remove_aura_effect_from_unit(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 移除单位上的光环效果
# 	var effect_id = id + "_" + str(unit.get_instance_id())
	
# 	# 使用效果管理器移除效果
# 	var effect_manager = GameManager.battle_manager.effect_manager
# 	if effect_manager:
# 		var unit_effects = effect_manager.get_target_effects(unit)
		
# 		for effect in unit_effects:
# 			if effect.id == effect_id:
# 				effect_manager.remove_effect(effect)
# 				break

# # 应用增益效果
# func _apply_buff_effect(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 创建增益效果数据
# 	var buff_data = {
# 		"id": id + "_" + str(unit.get_instance_id()),
# 		"name": name + " (光环)",
# 		"description": description,
# 		"effect_type": BattleEffect.EffectType.STAT_MOD,
# 		"duration": 0.5,  # 短持续时间，会在下次更新时刷新
# 		"stats": effect_data.get("stats", {}),
# 		"is_percentage": effect_data.get("is_percentage", false),
# 		"tags": ["aura", "buff"]
# 	}
	
# 	# 使用效果管理器应用效果
# 	var effect_manager = GameManager.battle_manager.effect_manager
# 	if effect_manager:
# 		effect_manager.apply_effect(buff_data, target, unit)

# # 应用减益效果
# func _apply_debuff_effect(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 创建减益效果数据
# 	var debuff_data = {
# 		"id": id + "_" + str(unit.get_instance_id()),
# 		"name": name + " (光环)",
# 		"description": description,
# 		"effect_type": BattleEffect.EffectType.STAT_MOD,
# 		"duration": 0.5,  # 短持续时间，会在下次更新时刷新
# 		"stats": effect_data.get("stats", {}),
# 		"is_percentage": effect_data.get("is_percentage", false),
# 		"tags": ["aura", "debuff"]
# 	}
	
# 	# 使用效果管理器应用效果
# 	var effect_manager = GameManager.battle_manager.effect_manager
# 	if effect_manager:
# 		effect_manager.apply_effect(debuff_data, target, unit)

# # 应用治疗效果
# func _apply_healing_effect(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 创建持续治疗效果数据
# 	var hot_data = {
# 		"id": id + "_" + str(unit.get_instance_id()),
# 		"name": name + " (光环)",
# 		"description": description,
# 		"effect_type": BattleEffect.EffectType.HOT,
# 		"duration": 0.5,  # 短持续时间，会在下次更新时刷新
# 		"hot_type": HotEffect.HotType.HEALING_AURA,
# 		"heal_per_second": effect_data.get("heal_per_second", 0.0),
# 		"tick_interval": effect_data.get("tick_interval", 1.0),
# 		"tags": ["aura", "healing"]
# 	}
	
# 	# 使用效果管理器应用效果
# 	var effect_manager = GameManager.battle_manager.effect_manager
# 	if effect_manager:
# 		effect_manager.apply_effect(hot_data, target, unit)

# # 应用伤害效果
# func _apply_damage_effect(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 创建持续伤害效果数据
# 	var dot_data = {
# 		"id": id + "_" + str(unit.get_instance_id()),
# 		"name": name + " (光环)",
# 		"description": description,
# 		"effect_type": BattleEffect.EffectType.DOT,
# 		"duration": 0.5,  # 短持续时间，会在下次更新时刷新
# 		"dot_type": effect_data.get("dot_type", DotEffect.DotType.BURNING),
# 		"damage_per_second": effect_data.get("damage_per_second", 0.0),
# 		"damage_type": effect_data.get("damage_type", "magical"),
# 		"tick_interval": effect_data.get("tick_interval", 1.0),
# 		"tags": ["aura", "damage"]
# 	}
	
# 	# 使用效果管理器应用效果
# 	var effect_manager = GameManager.battle_manager.effect_manager
# 	if effect_manager:
# 		effect_manager.apply_effect(dot_data, target, unit)

# # 应用保护效果
# func _apply_protection_effect(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 创建护盾效果数据
# 	var shield_data = {
# 		"id": id + "_" + str(unit.get_instance_id()),
# 		"name": name + " (光环)",
# 		"description": description,
# 		"effect_type": BattleEffect.EffectType.SHIELD,
# 		"duration": 0.5,  # 短持续时间，会在下次更新时刷新
# 		"shield_type": effect_data.get("shield_type", ShieldEffect.ShieldType.NORMAL),
# 		"shield_amount": effect_data.get("shield_amount", 0.0),
# 		"damage_reduction": effect_data.get("damage_reduction", 0.0),
# 		"tags": ["aura", "protection"]
# 	}
	
# 	# 使用效果管理器应用效果
# 	var effect_manager = GameManager.battle_manager.effect_manager
# 	if effect_manager:
# 		effect_manager.apply_effect(shield_data, target, unit)

# # 应用吸血效果
# func _apply_vampiric_effect(unit) -> void:
# 	if not unit or not is_instance_valid(unit):
# 		return
	
# 	# 创建吸血效果数据
# 	var vampiric_data = {
# 		"id": id + "_" + str(unit.get_instance_id()),
# 		"name": name + " (光环)",
# 		"description": description,
# 		"effect_type": BattleEffect.EffectType.DOT,
# 		"duration": 0.5,  # 短持续时间，会在下次更新时刷新
# 		"dot_type": DotEffect.DotType.BLEEDING,
# 		"damage_per_second": effect_data.get("damage_per_second", 0.0),
# 		"damage_type": "vampiric",
# 		"tick_interval": effect_data.get("tick_interval", 1.0),
# 		"tags": ["aura", "vampiric"]
# 	}
	
# 	# 使用效果管理器应用效果
# 	var effect_manager = GameManager.battle_manager.effect_manager
# 	if effect_manager:
# 		effect_manager.apply_effect(vampiric_data, target, unit)
	
# 	# 连接伤害事件，用于吸血
# 	if not EventBus.battle.is_connected("damage_dealt", _on_vampiric_damage_dealt):
# 		GlobalEventBus.battle.add_listener("damage_dealt", _on_vampiric_damage_dealt)

# # 吸血伤害事件处理
# func _on_vampiric_damage_dealt(source, damage_target, damage_amount: float, damage_type: String) -> void:
# 	# 检查是否是吸血伤害
# 	if damage_type != "vampiric":
# 		return
	
# 	# 检查是否是光环影响的单位
# 	if not affected_units.has(damage_target):
# 		return
	
# 	# 计算吸血量
# 	var lifesteal_amount = damage_amount * effect_data.get("lifesteal_percent", 0.3)
	
# 	# 为光环源提供治疗
# 	if target and is_instance_valid(target):
# 		var battle_manager = GameManager.battle_manager
# 		if battle_manager:
# 			battle_manager.apply_heal(source, target, lifesteal_amount)
		
# 		# 发送吸血事件
# 		GlobalEventBus.battle.dispatch_event(BattleEvents.VampiricHealEvent.new(target, lifesteal_amount, damage_target))

# # 创建光环视觉效果
# func _create_aura_visual() -> void:
# 	if not target or not is_instance_valid(target):
# 		return
	
# 	# 加载光环视觉效果场景
# 	var aura_scene = load("res://scenes/effects/aura_effect_visual.tscn")
# 	if aura_scene:
# 		aura_visual = aura_scene.instantiate()
# 		target.add_child(aura_visual)
		
# 		# 设置光环视觉效果参数
# 		if aura_visual.has_method("initialize"):
# 			aura_visual.initialize(self)
		
# 		# 设置光环颜色和半径
# 		_set_aura_visual_properties()

# # 移除光环视觉效果
# func _remove_aura_visual() -> void:
# 	if aura_visual and is_instance_valid(aura_visual):
# 		aura_visual.queue_free()
# 		aura_visual = null

# # 设置光环视觉效果属性
# func _set_aura_visual_properties() -> void:
# 	if not aura_visual or not is_instance_valid(aura_visual):
# 		return
	
# 	# 设置光环半径
# 	if aura_visual.has_method("set_radius"):
# 		aura_visual.set_radius(radius)
	
# 	# 设置光环颜色
# 	var aura_color = Color.WHITE
	
# 	match aura_type:
# 		AuraType.BUFF:
# 			aura_color = Color(0.0, 0.7, 1.0, 0.3)  # 蓝色
# 		AuraType.DEBUFF:
# 			aura_color = Color(1.0, 0.0, 0.0, 0.3)  # 红色
# 		AuraType.HEALING:
# 			aura_color = Color(0.0, 1.0, 0.0, 0.3)  # 绿色
# 		AuraType.DAMAGE:
# 			aura_color = Color(1.0, 0.5, 0.0, 0.3)  # 橙色
# 		AuraType.PROTECTION:
# 			aura_color = Color(0.7, 0.7, 1.0, 0.3)  # 淡蓝色
# 		AuraType.VAMPIRIC:
# 			aura_color = Color(0.7, 0.0, 0.7, 0.3)  # 紫色
	
# 	if aura_visual.has_method("set_color"):
# 		aura_visual.set_color(aura_color)

# # 获取光环类型图标路径
# func _get_aura_icon_path(aura_type: int) -> String:
# 	match aura_type:
# 		AuraType.BUFF:
# 			return "res://assets/icons/effects/aura_buff.png"
# 		AuraType.DEBUFF:
# 			return "res://assets/icons/effects/aura_debuff.png"
# 		AuraType.HEALING:
# 			return "res://assets/icons/effects/aura_healing.png"
# 		AuraType.DAMAGE:
# 			return "res://assets/icons/effects/aura_damage.png"
# 		AuraType.PROTECTION:
# 			return "res://assets/icons/effects/aura_protection.png"
# 		AuraType.VAMPIRIC:
# 			return "res://assets/icons/effects/aura_vampiric.png"
	
# 	return ""

# # 获取光环类型名称
# func _get_aura_name(aura_type: int) -> String:
# 	match aura_type:
# 		AuraType.BUFF:
# 			return "增益光环"
# 		AuraType.DEBUFF:
# 			return "减益光环"
# 		AuraType.HEALING:
# 			return "治疗光环"
# 		AuraType.DAMAGE:
# 			return "伤害光环"
# 		AuraType.PROTECTION:
# 			return "保护光环"
# 		AuraType.VAMPIRIC:
# 			return "吸血光环"
	
# 	return "未知光环"

# # 生成光环描述
# func _generate_aura_description() -> String:
# 	var desc = ""
	
# 	match aura_type:
# 		AuraType.BUFF:
# 			desc = "为周围友方单位提供增益效果"
			
# 			# 添加属性描述
# 			var stats = effect_data.get("stats", {})
# 			var is_percentage = effect_data.get("is_percentage", false)
			
# 			if not stats.is_empty():
# 				desc += "："
# 				var stat_descs = []
				
# 				for stat_name in stats:
# 					var stat_value = stats[stat_name]
# 					var stat_display = _get_stat_display_name(stat_name)
					
# 					if is_percentage:
# 						stat_descs.append(stat_display + "+" + str(int(stat_value * 100)) + "%")
# 					else:
# 						stat_descs.append(stat_display + "+" + str(int(stat_value)))
				
# 				desc += ", ".join(stat_descs)
		
# 		AuraType.DEBUFF:
# 			desc = "为周围敌方单位施加减益效果"
			
# 			# 添加属性描述
# 			var stats = effect_data.get("stats", {})
# 			var is_percentage = effect_data.get("is_percentage", false)
			
# 			if not stats.is_empty():
# 				desc += "："
# 				var stat_descs = []
				
# 				for stat_name in stats:
# 					var stat_value = stats[stat_name]
# 					var stat_display = _get_stat_display_name(stat_name)
					
# 					if is_percentage:
# 						stat_descs.append(stat_display + "-" + str(int(abs(stat_value) * 100)) + "%")
# 					else:
# 						stat_descs.append(stat_display + "-" + str(int(abs(stat_value))))
				
# 				desc += ", ".join(stat_descs)
		
# 		AuraType.HEALING:
# 			desc = "为周围友方单位提供持续治疗，每秒恢复" + str(effect_data.get("heal_per_second", 0.0)) + "点生命值"
		
# 		AuraType.DAMAGE:
# 			desc = "对周围敌方单位造成持续伤害，每秒造成" + str(effect_data.get("damage_per_second", 0.0)) + "点" + _get_damage_type_name(effect_data.get("damage_type", "magical")) + "伤害"
		
# 		AuraType.PROTECTION:
# 			desc = "为周围友方单位提供护盾，吸收" + str(effect_data.get("shield_amount", 0.0)) + "点伤害"
			
# 			if effect_data.get("damage_reduction", 0.0) > 0:
# 				desc += "，减免" + str(int(effect_data.damage_reduction * 100)) + "%伤害"
		
# 		AuraType.VAMPIRIC:
# 			desc = "对周围敌方单位造成持续伤害，每秒造成" + str(effect_data.get("damage_per_second", 0.0)) + "点伤害，并将" + str(int(effect_data.get("lifesteal_percent", 0.3) * 100)) + "%的伤害转化为生命值"
	
# 	return desc

# # 获取属性显示名称
# func _get_stat_display_name(stat_name: String) -> String:
# 	match stat_name:
# 		"attack_damage":
# 			return "攻击力"
# 		"attack_speed":
# 			return "攻击速度"
# 		"armor":
# 			return "护甲"
# 		"magic_resist":
# 			return "魔法抗性"
# 		"max_health":
# 			return "最大生命值"
# 		"health_regen":
# 			return "生命回复"
# 		"move_speed":
# 			return "移动速度"
# 		"crit_chance":
# 			return "暴击几率"
# 		"crit_damage":
# 			return "暴击伤害"
# 		"dodge_chance":
# 			return "闪避几率"
# 		"spell_power":
# 			return "法术强度"
# 		"cooldown_reduction":
# 			return "冷却缩减"
# 		"mana_regen":
# 			return "法力回复"
# 		"max_mana":
# 			return "最大法力值"
	
# 	return stat_name

# # 获取伤害类型名称
# func _get_damage_type_name(damage_type: String) -> String:
# 	match damage_type:
# 		"physical":
# 			return "物理"
# 		"magical":
# 			return "魔法"
# 		"true":
# 			return "真实"
# 		"fire":
# 			return "火焰"
# 		"ice":
# 			return "冰霜"
# 		"lightning":
# 			return "闪电"
# 		"poison":
# 			return "毒素"
# 		"vampiric":
# 			return "吸血"
	
# 	return damage_type

# # 获取效果数据
# func get_data() -> Dictionary:
# 	var data = super.get_data()
# 	data["aura_type"] = aura_type
# 	data["radius"] = radius
# 	data["effect_data"] = effect_data.duplicate()
# 	data["update_interval"] = update_interval
# 	return data

# # 从数据创建效果
# static func create_from_data(data: Dictionary, source = null, target = null) -> AuraEffect:
# 	return AuraEffect.new(
# 		data.get("id", ""),
# 		data.get("name", ""),
# 		data.get("description", ""),
# 		data.get("duration", 0.0),
# 		data.get("aura_type", AuraType.BUFF),
# 		data.get("radius", 300.0),
# 		data.get("effect_data", {}),
# 		source,
# 		target,
# 		{
# 			"update_interval": data.get("update_interval", 0.5)
# 		}
# 	)
