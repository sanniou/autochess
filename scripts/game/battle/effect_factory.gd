# extends Resource
# class_name EffectFactory
# ## 效果工厂
# ## 负责创建各种战斗效果

# # 效果类型映射
# var effect_type_map = {
# 	BattleEffect.EffectType.STATUS: StatusEffect,
# 	BattleEffect.EffectType.DOT: DotEffect,
# 	BattleEffect.EffectType.STAT_MOD: StatEffect,
# 	BattleEffect.EffectType.SHIELD: ShieldEffect,
# 	BattleEffect.EffectType.HOT: HotEffect,
# 	BattleEffect.EffectType.AURA: AuraEffect,
# 	BattleEffect.EffectType.MOVEMENT: MovementEffect,
# 	BattleEffect.EffectType.VISUAL: VisualEffect,
# 	BattleEffect.EffectType.SOUND: SoundEffect
# }

# # 创建效果
# func create_effect(effect_data: Dictionary, source = null, target = null) -> BattleEffect:
# 	# 获取效果类型
# 	var effect_type = effect_data.get("effect_type", BattleEffect.EffectType.STATUS)

# 	# 根据效果类型创建相应的效果
# 	match effect_type:
# 		BattleEffect.EffectType.STATUS:
# 			return _create_status_effect(effect_data, source, target)

# 		BattleEffect.EffectType.DOT:
# 			return _create_dot_effect(effect_data, source, target)

# 		BattleEffect.EffectType.STAT_MOD:
# 			return _create_stat_effect(effect_data, source, target)

# 		BattleEffect.EffectType.SHIELD:
# 			return _create_shield_effect(effect_data, source, target)

# 		BattleEffect.EffectType.HOT:
# 			return _create_hot_effect(effect_data, source, target)

# 		BattleEffect.EffectType.AURA:
# 			return _create_aura_effect(effect_data, source, target)

# 		BattleEffect.EffectType.MOVEMENT:
# 			return _create_movement_effect(effect_data, source, target)

# 		BattleEffect.EffectType.VISUAL:
# 			return _create_visual_effect(effect_data, source, target)

# 		BattleEffect.EffectType.SOUND:
# 			return _create_sound_effect(effect_data, source, target)

# 		_:
# 			# 默认创建基础效果
# 			return _create_base_effect(effect_data, source, target)

# # 创建基础效果
# func _create_base_effect(effect_data: Dictionary, source = null, target = null) -> BattleEffect:
# 	var effect = BattleEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 0.0),
# 		effect_data.get("effect_type", BattleEffect.EffectType.STATUS),
# 		source,
# 		target,
# 		effect_data.get("params", {})
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)

# 	return effect

# # 创建状态效果
# func _create_status_effect(effect_data: Dictionary, source = null, target = null) -> StatusEffect:
# 	var effect = StatusEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 0.0),
# 		effect_data.get("status_type", StatusEffect.StatusType.STUN),
# 		source,
# 		target,
# 		effect_data.get("params", {})
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)
# 	effect.immunity_time = effect_data.get("immunity_time", 0.5)

# 	return effect

# # 创建持续伤害效果
# func _create_dot_effect(effect_data: Dictionary, source = null, target = null) -> DotEffect:
# 	var effect = DotEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 0.0),
# 		effect_data.get("dot_type", DotEffect.DotType.BURNING),
# 		effect_data.get("damage_per_second", 0.0),
# 		effect_data.get("damage_type", "magical"),
# 		source,
# 		target,
# 		effect_data.get("params", {})
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)
# 	effect.tick_interval = effect_data.get("tick_interval", 1.0)

# 	return effect

# # 创建属性效果
# func _create_stat_effect(effect_data: Dictionary, source = null, target = null) -> StatEffect:
# 	var effect = StatEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 0.0),
# 		effect_data.get("stats", {}),
# 		effect_data.get("is_percentage", false),
# 		source,
# 		target,
# 		effect_data.get("params", {})
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)

# 	return effect

# # 创建护盾效果
# func _create_shield_effect(effect_data: Dictionary, source = null, target = null) -> ShieldEffect:
# 	var effect = ShieldEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 0.0),
# 		effect_data.get("shield_type", ShieldEffect.ShieldType.NORMAL),
# 		effect_data.get("shield_amount", 0.0),
# 		source,
# 		target,
# 		{
# 			"damage_reduction": effect_data.get("damage_reduction", 0.0),
# 			"reflect_percent": effect_data.get("reflect_percent", 0.0)
# 		}
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)

# 	return effect

# # 创建持续治疗效果
# func _create_hot_effect(effect_data: Dictionary, source = null, target = null) -> HotEffect:
# 	var effect = HotEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 0.0),
# 		effect_data.get("hot_type", HotEffect.HotType.REGENERATION),
# 		effect_data.get("heal_per_second", 0.0),
# 		source,
# 		target,
# 		{
# 			"tick_interval": effect_data.get("tick_interval", 1.0)
# 		}
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)

# 	return effect

# # 创建光环效果
# func _create_aura_effect(effect_data: Dictionary, source = null, target = null) -> AuraEffect:
# 	var effect = AuraEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 0.0),
# 		effect_data.get("aura_type", AuraEffect.AuraType.BUFF),
# 		effect_data.get("radius", 300.0),
# 		effect_data.get("effect_data", {}),
# 		source,
# 		target,
# 		{
# 			"update_interval": effect_data.get("update_interval", 0.5)
# 		}
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)

# 	return effect

# # 创建移动效果
# func _create_movement_effect(effect_data: Dictionary, source = null, target = null) -> MovementEffect:
# 	var effect = MovementEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("movement_type", MovementEffect.MovementType.KNOCKBACK),
# 		effect_data.get("distance", 1.0),
# 		source,
# 		target,
# 		{}
# 	)

# 	# 设置方向
# 	var dir_data = effect_data.get("direction", {})
# 	if dir_data.has("x") and dir_data.has("y"):
# 		effect.direction = Vector2(dir_data.x, dir_data.y)

# 	# 设置目标位置
# 	var pos_data = effect_data.get("target_position", {})
# 	if pos_data.has("x") and pos_data.has("y"):
# 		effect.target_position = Vector2(pos_data.x, pos_data.y)

# 	# 设置速度
# 	effect.speed = effect_data.get("speed", 300.0)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.is_stackable = effect_data.get("is_stackable", false)
# 	effect.stack_count = effect_data.get("stack_count", 1)
# 	effect.max_stacks = effect_data.get("max_stacks", 1)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)

# 	return effect

# # 创建视觉效果
# func _create_visual_effect(effect_data: Dictionary, source = null, target = null) -> VisualEffect:
# 	var effect = VisualEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("duration", 1.0),
# 		effect_data.get("visual_type", VisualEffect.VisualType.PARTICLE),
# 		effect_data.get("scene_path", ""),
# 		source,
# 		target,
# 		{}
# 	)

# 	# 设置偏移
# 	var offset_data = effect_data.get("offset", {})
# 	if offset_data.has("x") and offset_data.has("y"):
# 		effect.offset = Vector2(offset_data.x, offset_data.y)

# 	# 设置缩放
# 	var scale_data = effect_data.get("scale", {})
# 	if scale_data.has("x") and scale_data.has("y"):
# 		effect.scale_value = Vector2(scale_data.x, scale_data.y)

# 	# 设置颜色
# 	var color_data = effect_data.get("color", {})
# 	if color_data.has("r") and color_data.has("g") and color_data.has("b") and color_data.has("a"):
# 		effect.color = Color(color_data.r, color_data.g, color_data.b, color_data.a)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.is_permanent = effect_data.get("is_permanent", false)
# 	effect.z_index = effect_data.get("z_index", 0)
# 	effect.auto_free = effect_data.get("auto_free", true)
# 	effect.tags = effect_data.get("tags", [])
# 	effect.priority = effect_data.get("priority", 0)

# 	return effect

# # 创建音效
# func _create_sound_effect(effect_data: Dictionary, source = null, target = null) -> SoundEffect:
# 	var effect = SoundEffect.new(
# 		effect_data.get("id", ""),
# 		effect_data.get("name", ""),
# 		effect_data.get("description", ""),
# 		effect_data.get("sound_type", SoundEffect.SoundType.ATTACK),
# 		effect_data.get("sound_path", ""),
# 		source,
# 		target,
# 		{
# 			"volume_db": effect_data.get("volume_db", 0.0),
# 			"pitch_scale": effect_data.get("pitch_scale", 1.0)
# 		}
# 	)

# 	# 设置其他属性
# 	effect.icon_path = effect_data.get("icon_path", "")
# 	effect.tags = effect_data.get("tags", [])

# 	return effect
