# extends BattleEffect
# class_name StatusEffect
# ## 状态效果
# ## 用于控制单位状态（眩晕、沉默等）

# # 状态类型枚举
# enum StatusType {
# 	STUN,       # 眩晕：无法行动
# 	SILENCE,    # 沉默：无法施放技能
# 	DISARM,     # 缴械：无法普通攻击
# 	ROOT,       # 定身：无法移动
# 	TAUNT,      # 嘲讽：强制攻击施法者
# 	FROZEN,     # 冰冻：无法移动
# 	INVISIBLE,  # 隐身：不可被选为目标
# 	INVULNERABLE # 无敌：不受伤害
# }

# # 状态效果属性
# var status_type: int = StatusType.STUN
# var immunity_time: float = 0.5  # 免疫时间（效果结束后）

# # 初始化
# func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "", 
# 		effect_duration: float = 0.0, status_type_value: int = StatusType.STUN, 
# 		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
# 	super._init(effect_id, effect_name, effect_description, effect_duration, 
# 			EffectType.STATUS, effect_source, effect_target, effect_params)
	
# 	status_type = status_type_value
	
# 	# 设置免疫时间
# 	immunity_time = effect_params.get("immunity_time", 0.5)
	
# 	# 设置图标路径
# 	icon_path = _get_status_icon_path(status_type)

# # 应用效果
# func apply() -> bool:
# 	if not super.apply():
# 		return false
	
# 	if not target or not is_instance_valid(target):
# 		return false
	
# 	# 根据状态类型应用效果
# 	match status_type:
# 		StatusType.STUN:
# 			target.is_stunned = true
# 			target.stun_duration = duration
# 			if target.state_machine:
# 				target.state_machine.change_state("stunned")
		
# 		StatusType.SILENCE:
# 			target.is_silenced = true
		
# 		StatusType.DISARM:
# 			target.is_disarmed = true
		
# 		StatusType.ROOT:
# 			target.is_rooted = true
		
# 		StatusType.TAUNT:
# 			if source and is_instance_valid(source):
# 				target.taunted_by = source
# 				target.taunt_duration = duration
		
# 		StatusType.FROZEN:
# 			target.is_frozen = true
# 			target.frozen_duration = duration
		
# 		StatusType.INVISIBLE:
# 			target.is_invisible = true
# 			if target.has_method("set_visibility"):
# 				target.set_visibility(false)
		
# 		StatusType.INVULNERABLE:
# 			target.is_invulnerable = true
	
# 	return true

# # 移除效果
# func remove() -> bool:
# 	if not super.remove():
# 		return false
	
# 	if not target or not is_instance_valid(target):
# 		return false
	
# 	# 根据状态类型移除效果
# 	match status_type:
# 		StatusType.STUN:
# 			target.is_stunned = false
# 			target.stun_duration = 0
# 			if target.state_machine and target.state_machine.is_in_state("stunned"):
# 				target.state_machine.change_state("idle")
		
# 		StatusType.SILENCE:
# 			target.is_silenced = false
		
# 		StatusType.DISARM:
# 			target.is_disarmed = false
		
# 		StatusType.ROOT:
# 			target.is_rooted = false
		
# 		StatusType.TAUNT:
# 			target.taunted_by = null
# 			target.taunt_duration = 0
		
# 		StatusType.FROZEN:
# 			target.is_frozen = false
# 			target.frozen_duration = 0
		
# 		StatusType.INVISIBLE:
# 			target.is_invisible = false
# 			if target.has_method("set_visibility"):
# 				target.set_visibility(true)
		
# 		StatusType.INVULNERABLE:
# 			target.is_invulnerable = false
	
# 	return true

# # 创建视觉效果
# func _create_visual_effect() -> void:
# 	if not target or not is_instance_valid(target):
# 		return
	
# 	# 创建状态效果视觉表现
# 	var effect_scene = load("res://scenes/effects/status_effect_visual.tscn")
# 	if effect_scene:
# 		visual_effect = effect_scene.instantiate()
# 		target.add_child(visual_effect)
		
# 		# 设置视觉效果参数
# 		if visual_effect.has_method("initialize"):
# 			visual_effect.initialize(self)

# # 获取状态图标路径
# func _get_status_icon_path(status_type: int) -> String:
# 	match status_type:
# 		StatusType.STUN:
# 			return "res://assets/icons/status/stun.png"
# 		StatusType.SILENCE:
# 			return "res://assets/icons/status/silence.png"
# 		StatusType.DISARM:
# 			return "res://assets/icons/status/disarm.png"
# 		StatusType.ROOT:
# 			return "res://assets/icons/status/root.png"
# 		StatusType.TAUNT:
# 			return "res://assets/icons/status/taunt.png"
# 		StatusType.FROZEN:
# 			return "res://assets/icons/status/frozen.png"
# 		StatusType.INVISIBLE:
# 			return "res://assets/icons/status/invisible.png"
# 		StatusType.INVULNERABLE:
# 			return "res://assets/icons/status/invulnerable.png"
	
# 	return ""

# # 获取状态名称
# static func get_status_name(status_type: int) -> String:
# 	match status_type:
# 		StatusType.STUN:
# 			return "眩晕"
# 		StatusType.SILENCE:
# 			return "沉默"
# 		StatusType.DISARM:
# 			return "缴械"
# 		StatusType.ROOT:
# 			return "定身"
# 		StatusType.TAUNT:
# 			return "嘲讽"
# 		StatusType.FROZEN:
# 			return "冰冻"
# 		StatusType.INVISIBLE:
# 			return "隐身"
# 		StatusType.INVULNERABLE:
# 			return "无敌"
	
# 	return "未知状态"

# # 获取状态描述
# static func get_status_description(status_type: int) -> String:
# 	match status_type:
# 		StatusType.STUN:
# 			return "无法行动"
# 		StatusType.SILENCE:
# 			return "无法施放技能"
# 		StatusType.DISARM:
# 			return "无法普通攻击"
# 		StatusType.ROOT:
# 			return "无法移动"
# 		StatusType.TAUNT:
# 			return "强制攻击嘲讽源"
# 		StatusType.FROZEN:
# 			return "无法移动"
# 		StatusType.INVISIBLE:
# 			return "不可被选为目标"
# 		StatusType.INVULNERABLE:
# 			return "不受伤害"
	
# 	return "未知状态效果"

# # 获取效果数据
# func get_data() -> Dictionary:
# 	var data = super.get_data()
# 	data["status_type"] = status_type
# 	data["immunity_time"] = immunity_time
# 	return data

# # 从数据创建效果
# static func create_from_data(data: Dictionary, source = null, target = null) -> StatusEffect:
# 	var effect = StatusEffect.new(
# 		data.get("id", ""),
# 		data.get("name", ""),
# 		data.get("description", ""),
# 		data.get("duration", 0.0),
# 		data.get("status_type", StatusType.STUN),
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
# 	effect.immunity_time = data.get("immunity_time", 0.5)
	
# 	return effect
