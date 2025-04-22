# extends BattleEffect
# class_name StatEffect
# ## 属性效果
# ## 用于修改单位属性

# # 属性效果属性
# var stats: Dictionary = {}  # 属性修改 {属性名: 修改值}
# var is_percentage: bool = false  # 是否为百分比修改
# var original_stats: Dictionary = {}  # 原始属性值

# # 初始化
# func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "", 
# 		effect_duration: float = 0.0, stats_dict: Dictionary = {}, 
# 		percentage: bool = false, effect_source = null, effect_target = null, 
# 		effect_params: Dictionary = {}):
# 	super._init(effect_id, effect_name, effect_description, effect_duration, 
# 			EffectType.STAT_MOD, effect_source, effect_target, effect_params)
	
# 	stats = stats_dict
# 	is_percentage = percentage
	
# 	# 设置图标路径
# 	icon_path = _get_stat_icon_path(stats)
	
# 	# 设置名称和描述
# 	if name.is_empty():
# 		name = _generate_stat_effect_name(stats, is_percentage)
	
# 	if description.is_empty():
# 		description = _generate_stat_effect_description(stats, is_percentage)

# # 应用效果
# func apply() -> bool:
# 	if not super.apply():
# 		return false
	
# 	if not target or not is_instance_valid(target):
# 		return false
	
# 	# 保存原始属性值
# 	original_stats.clear()
	
# 	# 应用属性修改
# 	for stat_name in stats:
# 		var stat_value = stats[stat_name]
		
# 		# 保存原始值
# 		if target.has(stat_name):
# 			original_stats[stat_name] = target.get(stat_name)
		
# 		# 应用修改
# 		if target.has_method("modify_stat"):
# 			target.modify_stat(stat_name, stat_value, duration, is_percentage)
# 		elif target.has(stat_name):
# 			# 直接修改属性
# 			if is_percentage:
# 				var original_value = target.get(stat_name)
# 				target.set(stat_name, original_value * (1 + stat_value))
# 			else:
# 				target.set(stat_name, target.get(stat_name) + stat_value)
	
# 	return true

# # 移除效果
# func remove() -> bool:
# 	if not super.remove():
# 		return false
	
# 	if not target or not is_instance_valid(target):
# 		return false
	
# 	# 恢复原始属性值
# 	for stat_name in original_stats:
# 		if target.has_method("reset_stat"):
# 			target.reset_stat(stat_name)
# 		elif target.has(stat_name):
# 			target.set(stat_name, original_stats[stat_name])
	
# 	return true

# # 创建视觉效果
# func _create_visual_effect() -> void:
# 	if not target or not is_instance_valid(target):
# 		return
	
# 	# 创建属性效果视觉表现
# 	var effect_scene = load("res://scenes/effects/stat_effect_visual.tscn")
# 	if effect_scene:
# 		visual_effect = effect_scene.instantiate()
# 		target.add_child(visual_effect)
		
# 		# 设置视觉效果参数
# 		if visual_effect.has_method("initialize"):
# 			visual_effect.initialize(self)

# # 获取属性图标路径
# func _get_stat_icon_path(stats_dict: Dictionary) -> String:
# 	# 根据主要属性类型选择图标
# 	if stats_dict.has("attack_damage") or stats_dict.has("attack_speed"):
# 		return "res://assets/icons/status/attack_buff.png"
# 	elif stats_dict.has("armor") or stats_dict.has("magic_resist"):
# 		return "res://assets/icons/status/defense_buff.png"
# 	elif stats_dict.has("max_health") or stats_dict.has("health_regen"):
# 		return "res://assets/icons/status/health_buff.png"
# 	elif stats_dict.has("move_speed"):
# 		return "res://assets/icons/status/speed_buff.png"
# 	elif stats_dict.has("crit_chance") or stats_dict.has("crit_damage"):
# 		return "res://assets/icons/status/crit_buff.png"
	
# 	return "res://assets/icons/status/stat_buff.png"

# # 生成属性效果名称
# func _generate_stat_effect_name(stats_dict: Dictionary, percentage: bool) -> String:
# 	var buff_count = 0
# 	var debuff_count = 0
	
# 	for stat_name in stats_dict:
# 		var value = stats_dict[stat_name]
# 		if value > 0:
# 			buff_count += 1
# 		else:
# 			debuff_count += 1
	
# 	if buff_count > 0 and debuff_count == 0:
# 		return "增益效果"
# 	elif debuff_count > 0 and buff_count == 0:
# 		return "减益效果"
# 	else:
# 		return "属性效果"

# # 生成属性效果描述
# func _generate_stat_effect_description(stats_dict: Dictionary, percentage: bool) -> String:
# 	var descriptions = []
	
# 	for stat_name in stats_dict:
# 		var value = stats_dict[stat_name]
# 		var sign = "+" if value > 0 else ""
# 		var percent = "%" if percentage else ""
		
# 		var stat_display_name = _get_stat_display_name(stat_name)
# 		descriptions.append("%s%s%s %s" % [sign, value, percent, stat_display_name])
	
# 	return ", ".join(descriptions)

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

# # 获取效果数据
# func get_data() -> Dictionary:
# 	var data = super.get_data()
# 	data["stats"] = stats.duplicate()
# 	data["is_percentage"] = is_percentage
# 	data["original_stats"] = original_stats.duplicate()
# 	return data

# # 从数据创建效果
# static func create_from_data(data: Dictionary, source = null, target = null) -> StatEffect:
# 	var effect = StatEffect.new(
# 		data.get("id", ""),
# 		data.get("name", ""),
# 		data.get("description", ""),
# 		data.get("duration", 0.0),
# 		data.get("stats", {}),
# 		data.get("is_percentage", false),
# 		source,
# 		target,
# 		data.get("params", {})
# 	)
	
# 	effect.icon_path = data.get("icon_path", "")
# 	effect.is_permanent = data.get("is_permanent", false)
# 	effect.is_stackable = data.get("is_stackable", false)
# 	effect.stack_count = data.get("stack_count", 1)
# 	effect.max_stacks = data.get("max_stacks", 1)
# 	effect.tags = data.get("tags", [])
# 	effect.priority = data.get("priority", 0)
# 	effect.is_active = data.get("is_active", false)
# 	effect.is_expired = data.get("is_expired", false)
# 	effect.created_at = data.get("created_at", Time.get_ticks_msec())
# 	effect.original_stats = data.get("original_stats", {}).duplicate()
	
# 	return effect
