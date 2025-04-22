# extends BattleEffect
# class_name DotEffect
# ## 持续伤害效果
# ## 用于对单位造成持续伤害

# # 持续伤害类型枚举
# enum DotType {
# 	BURNING,    # 燃烧
# 	POISONED,   # 中毒
# 	BLEEDING,   # 流血
# 	ACID,       # 酸蚀
# 	DECAY       # 腐蚀
# }

# # 持续伤害效果属性
# var dot_type: int = DotType.BURNING
# var damage_per_second: float = 0.0
# var damage_type: String = "magical"
# var tick_interval: float = 1.0  # 伤害间隔（秒）
# var tick_timer: float = 0.0     # 伤害计时器
# var total_damage: float = 0.0   # 总伤害
# var tick_count: int = 0         # 伤害tick计数器

# # 初始化
# func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
# 		effect_duration: float = 0.0, dot_type_value: int = DotType.BURNING,
# 		damage_value: float = 0.0, damage_type_value: String = "magical",
# 		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
# 	super._init(effect_id, effect_name, effect_description, effect_duration,
# 			EffectType.DOT, effect_source, effect_target, effect_params)

# 	dot_type = dot_type_value
# 	damage_per_second = damage_value
# 	damage_type = damage_type_value

# 	# 设置伤害间隔
# 	tick_interval = effect_params.get("tick_interval", 1.0)
# 	tick_timer = 0.0

# 	# 设置图标路径
# 	icon_path = _get_dot_icon_path(dot_type)

# 	# 设置名称和描述
# 	if name.is_empty():
# 		name = get_dot_name(dot_type)

# 	if description.is_empty():
# 		description = get_dot_description(dot_type)

# # 应用效果
# func apply() -> bool:
# 	if not super.apply():
# 		return false

# 	# 应用初始效果
# 	_apply_initial_effect()

# 	return true

# # 更新效果
# func update(delta: float) -> bool:
# 	if not super.update(delta):
# 		return false

# 	# 更新伤害计时器
# 	tick_timer += delta

# 	# 检查是否应该造成伤害
# 	if tick_timer >= tick_interval:
# 		tick_timer -= tick_interval
# 		_apply_damage_tick()

# 	return true

# # 创建视觉效果
# func _create_visual_effect() -> void:
# 	if not target or not is_instance_valid(target):
# 		return

# 	# 创建持续伤害效果视觉表现
# 	var effect_scene = load("res://scenes/effects/dot_effect_visual.tscn")
# 	if effect_scene:
# 		visual_effect = effect_scene.instantiate()
# 		target.add_child(visual_effect)

# 		# 设置视觉效果参数
# 		if visual_effect.has_method("initialize"):
# 			visual_effect.initialize(self)

# # 应用初始效果
# func _apply_initial_effect() -> void:
# 	if not target or not is_instance_valid(target):
# 		return

# 	# 根据持续伤害类型应用初始效果
# 	match dot_type:
# 		DotType.BURNING:
# 			# 燃烧效果可能会降低目标的魔法抗性
# 			if target.has_method("modify_stat"):
# 				target.modify_stat("magic_resist", -5, duration)

# 		DotType.POISONED:
# 			# 中毒效果可能会降低目标的攻击速度
# 			if target.has_method("modify_stat"):
# 				target.modify_stat("attack_speed", -0.1, duration)

# 		DotType.BLEEDING:
# 			# 流血效果可能会降低目标的物理防御
# 			if target.has_method("modify_stat"):
# 				target.modify_stat("armor", -5, duration)

# 		DotType.ACID:
# 			# 酸蚀效果可能会降低目标的所有防御
# 			if target.has_method("modify_stat"):
# 				target.modify_stat("armor", -3, duration)
# 				target.modify_stat("magic_resist", -3, duration)

# 		DotType.DECAY:
# 			# 腐蚀效果可能会降低目标的最大生命值
# 			if target.has_method("modify_stat"):
# 				target.modify_stat("max_health", -target.max_health * 0.05, duration)

# # 应用伤害tick
# func _apply_damage_tick() -> void:
# 	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
# 		return

# 	# 计算伤害
# 	var damage = damage_per_second * tick_interval

# 	# 根据叠加层数调整伤害
# 	if is_stackable and stack_count > 1:
# 		damage *= (1 + (stack_count - 1) * 0.5)  # 每层增加50%伤害

# 	# 应用伤害
# 	var battle_manager = GameManager.battle_manager
# 	if battle_manager:
# 		var actual_damage = battle_manager.apply_damage(source, target, damage, damage_type)
# 		total_damage += actual_damage

# 		# 优化：只在伤害超过一定阈值时发送事件
# 		# 或者每隔3次tick发送一次事件
# 		# 使用实例变量而不是静态变量
# 		tick_count += 1

# 		if actual_damage > 10.0 or tick_count % 3 == 0:
# 			EventBus.battle.emit_event("dot_damage", [source, target, actual_damage, damage_type, dot_type])

# # 获取持续伤害图标路径
# func _get_dot_icon_path(dot_type: int) -> String:
# 	match dot_type:
# 		DotType.BURNING:
# 			return "res://assets/icons/status/burning.png"
# 		DotType.POISONED:
# 			return "res://assets/icons/status/poisoned.png"
# 		DotType.BLEEDING:
# 			return "res://assets/icons/status/bleeding.png"
# 		DotType.ACID:
# 			return "res://assets/icons/status/acid.png"
# 		DotType.DECAY:
# 			return "res://assets/icons/status/decay.png"

# 	return ""

# # 获取持续伤害名称
# static func get_dot_name(dot_type: int) -> String:
# 	match dot_type:
# 		DotType.BURNING:
# 			return "燃烧"
# 		DotType.POISONED:
# 			return "中毒"
# 		DotType.BLEEDING:
# 			return "流血"
# 		DotType.ACID:
# 			return "酸蚀"
# 		DotType.DECAY:
# 			return "腐蚀"

# 	return "未知持续伤害"

# # 获取持续伤害描述
# static func get_dot_description(dot_type: int) -> String:
# 	match dot_type:
# 		DotType.BURNING:
# 			return "持续受到火焰伤害"
# 		DotType.POISONED:
# 			return "持续受到毒素伤害并降低攻击速度"
# 		DotType.BLEEDING:
# 			return "持续受到物理伤害并降低护甲"
# 		DotType.ACID:
# 			return "持续受到酸蚀伤害并降低所有防御"
# 		DotType.DECAY:
# 			return "持续受到腐蚀伤害并降低最大生命值"

# 	return "未知持续伤害效果"

# # 获取效果数据
# func get_data() -> Dictionary:
# 	var data = super.get_data()
# 	data["dot_type"] = dot_type
# 	data["damage_per_second"] = damage_per_second
# 	data["damage_type"] = damage_type
# 	data["tick_interval"] = tick_interval
# 	data["total_damage"] = total_damage
# 	data["tick_count"] = tick_count
# 	return data

# # 从数据创建效果
# static func create_from_data(data: Dictionary, source = null, target = null) -> DotEffect:
# 	var effect = DotEffect.new(
# 		data.get("id", ""),
# 		data.get("name", ""),
# 		data.get("description", ""),
# 		data.get("duration", 0.0),
# 		data.get("dot_type", DotType.BURNING),
# 		data.get("damage_per_second", 0.0),
# 		data.get("damage_type", "magical"),
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
# 	effect.tick_interval = data.get("tick_interval", 1.0)
# 	effect.total_damage = data.get("total_damage", 0.0)
# 	effect.tick_count = data.get("tick_count", 0)

# 	return effect
