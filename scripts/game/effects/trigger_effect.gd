extends GameEffect
class_name TriggerEffect
## 触发效果
## 用于在特定条件下触发其他效果

# 触发类型
var trigger_type: String = ""

# 触发条件
var trigger_condition: Dictionary = {}

# 触发效果数据
var trigger_effect_data: Dictionary = {}

# 触发次数限制
var max_triggers: int = 0

# 当前触发次数
var trigger_count: int = 0

# 触发冷却时间
var trigger_cooldown: float = 0.0

# 上次触发时间
var last_trigger_time: float = 0.0

# 初始化
func _init(effect_id: String = "", effect_name: String = "", effect_description: String = "",
		effect_duration: float = 0.0, trigger_type_param: String = "",
		effect_source = null, effect_target = null, effect_params: Dictionary = {}):
	super._init(effect_id, effect_name, effect_description, effect_duration,
			EffectType.TRIGGER, effect_source, effect_target, effect_params)
	
	trigger_type = trigger_type_param
	
	# 设置触发条件
	trigger_condition = effect_params.get("trigger_condition", {})
	
	# 设置触发效果数据
	trigger_effect_data = effect_params.get("trigger_effect_data", {})
	
	# 设置触发次数限制
	max_triggers = effect_params.get("max_triggers", 0)  # 0表示无限制
	
	# 设置触发冷却时间
	trigger_cooldown = effect_params.get("trigger_cooldown", 0.0)
	
	# 设置标签
	if not tags.has("trigger"):
		tags.append("trigger")
	
	# 设置图标路径
	icon_path = "res://assets/icons/trigger/trigger.png"
	
	# 设置名称和描述
	if name.is_empty():
		name = "触发效果"
	
	if description.is_empty():
		description = _get_trigger_description(trigger_type, max_triggers, trigger_cooldown)

# 应用效果
func apply() -> bool:
	if not super.apply():
		return false
	
	# 连接相关信号
	_connect_trigger_signals()
	
	return true

# 移除效果
func remove() -> bool:
	if not super.remove():
		return false
	
	# 断开相关信号
	_disconnect_trigger_signals()
	
	return true

# 更新效果
func update(delta: float) -> bool:
	if not super.update(delta):
		return false
	
	# 更新上次触发时间
	if last_trigger_time > 0:
		last_trigger_time += delta
	
	return true

# 连接触发信号
func _connect_trigger_signals() -> void:
	# 检查EventBus是否可用
	if not EventBus:
		return
	
	# 根据触发类型连接不同的信号
	match trigger_type:
		"on_damage":
			# 连接伤害信号
			if not EventBus.damage_dealt.is_connected(_on_damage_dealt):
				EventBus.damage_dealt.connect(_on_damage_dealt)
		
		"on_heal":
			# 连接治疗信号
			if not EventBus.heal_applied.is_connected(_on_heal_applied):
				EventBus.heal_applied.connect(_on_heal_applied)
		
		"on_status":
			# 连接状态信号
			if not EventBus.status_applied.is_connected(_on_status_applied):
				EventBus.status_applied.connect(_on_status_applied)
		
		"on_kill":
			# 连接击杀信号
			if not EventBus.unit_killed.is_connected(_on_unit_killed):
				EventBus.unit_killed.connect(_on_unit_killed)
		
		"on_dodge":
			# 连接闪避信号
			if not EventBus.attack_dodged.is_connected(_on_attack_dodged):
				EventBus.attack_dodged.connect(_on_attack_dodged)
		
		"on_critical":
			# 连接暴击信号
			if not EventBus.critical_hit.is_connected(_on_critical_hit):
				EventBus.critical_hit.connect(_on_critical_hit)
		
		"on_shield_break":
			# 连接护盾破碎信号
			if not EventBus.shield_broken.is_connected(_on_shield_broken):
				EventBus.shield_broken.connect(_on_shield_broken)
		
		"on_health_threshold":
			# 连接生命值变化信号
			if target and is_instance_valid(target) and target.has_signal("health_changed"):
				if not target.health_changed.is_connected(_on_health_changed):
					target.health_changed.connect(_on_health_changed)

# 断开触发信号
func _disconnect_trigger_signals() -> void:
	# 检查EventBus是否可用
	if not EventBus:
		return
	
	# 根据触发类型断开不同的信号
	match trigger_type:
		"on_damage":
			# 断开伤害信号
			if EventBus.damage_dealt.is_connected(_on_damage_dealt):
				EventBus.damage_dealt.disconnect(_on_damage_dealt)
		
		"on_heal":
			# 断开治疗信号
			if EventBus.heal_applied.is_connected(_on_heal_applied):
				EventBus.heal_applied.disconnect(_on_heal_applied)
		
		"on_status":
			# 断开状态信号
			if EventBus.status_applied.is_connected(_on_status_applied):
				EventBus.status_applied.disconnect(_on_status_applied)
		
		"on_kill":
			# 断开击杀信号
			if EventBus.unit_killed.is_connected(_on_unit_killed):
				EventBus.unit_killed.disconnect(_on_unit_killed)
		
		"on_dodge":
			# 断开闪避信号
			if EventBus.attack_dodged.is_connected(_on_attack_dodged):
				EventBus.attack_dodged.disconnect(_on_attack_dodged)
		
		"on_critical":
			# 断开暴击信号
			if EventBus.critical_hit.is_connected(_on_critical_hit):
				EventBus.critical_hit.disconnect(_on_critical_hit)
		
		"on_shield_break":
			# 断开护盾破碎信号
			if EventBus.shield_broken.is_connected(_on_shield_broken):
				EventBus.shield_broken.disconnect(_on_shield_broken)
		
		"on_health_threshold":
			# 断开生命值变化信号
			if target and is_instance_valid(target) and target.has_signal("health_changed"):
				if target.health_changed.is_connected(_on_health_changed):
					target.health_changed.disconnect(_on_health_changed)

# 处理伤害事件
func _on_damage_dealt(damage_info: Dictionary) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_damage_condition(damage_info):
		return
	
	# 触发效果
	_trigger_effect(damage_info.get("target", null))

# 处理治疗事件
func _on_heal_applied(heal_info: Dictionary) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_heal_condition(heal_info):
		return
	
	# 触发效果
	_trigger_effect(heal_info.get("target", null))

# 处理状态事件
func _on_status_applied(status_info: Dictionary) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_status_condition(status_info):
		return
	
	# 触发效果
	_trigger_effect(status_info.get("target", null))

# 处理击杀事件
func _on_unit_killed(kill_info: Dictionary) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_kill_condition(kill_info):
		return
	
	# 触发效果
	_trigger_effect(kill_info.get("killer", null))

# 处理闪避事件
func _on_attack_dodged(dodge_info: Dictionary) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_dodge_condition(dodge_info):
		return
	
	# 触发效果
	_trigger_effect(dodge_info.get("target", null))

# 处理暴击事件
func _on_critical_hit(crit_info: Dictionary) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_critical_condition(crit_info):
		return
	
	# 触发效果
	_trigger_effect(crit_info.get("source", null))

# 处理护盾破碎事件
func _on_shield_broken(shield_info: Dictionary) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_shield_condition(shield_info):
		return
	
	# 触发效果
	_trigger_effect(shield_info.get("target", null))

# 处理生命值变化事件
func _on_health_changed(current_health: float, max_health: float) -> void:
	# 检查是否在冷却中
	if _is_on_cooldown():
		return
	
	# 检查是否达到触发次数限制
	if _reached_trigger_limit():
		return
	
	# 检查触发条件
	if not _check_health_threshold_condition(current_health, max_health):
		return
	
	# 触发效果
	_trigger_effect(target)

# 检查伤害条件
func _check_damage_condition(damage_info: Dictionary) -> bool:
	# 检查是否是目标造成的伤害
	if trigger_condition.has("source_is_target") and trigger_condition.source_is_target:
		if damage_info.get("source", null) != target:
			return false
	
	# 检查是否是目标受到的伤害
	if trigger_condition.has("target_is_target") and trigger_condition.target_is_target:
		if damage_info.get("target", null) != target:
			return false
	
	# 检查伤害类型
	if trigger_condition.has("damage_type"):
		if damage_info.get("type", "") != trigger_condition.damage_type:
			return false
	
	# 检查伤害值
	if trigger_condition.has("min_damage"):
		if damage_info.get("value", 0.0) < trigger_condition.min_damage:
			return false
	
	# 检查是否暴击
	if trigger_condition.has("is_critical"):
		if damage_info.get("is_critical", false) != trigger_condition.is_critical:
			return false
	
	return true

# 检查治疗条件
func _check_heal_condition(heal_info: Dictionary) -> bool:
	# 检查是否是目标提供的治疗
	if trigger_condition.has("source_is_target") and trigger_condition.source_is_target:
		if heal_info.get("source", null) != target:
			return false
	
	# 检查是否是目标接受的治疗
	if trigger_condition.has("target_is_target") and trigger_condition.target_is_target:
		if heal_info.get("target", null) != target:
			return false
	
	# 检查治疗值
	if trigger_condition.has("min_heal"):
		if heal_info.get("value", 0.0) < trigger_condition.min_heal:
			return false
	
	# 检查是否暴击
	if trigger_condition.has("is_critical"):
		if heal_info.get("is_critical", false) != trigger_condition.is_critical:
			return false
	
	return true

# 检查状态条件
func _check_status_condition(status_info: Dictionary) -> bool:
	# 检查是否是目标施加的状态
	if trigger_condition.has("source_is_target") and trigger_condition.source_is_target:
		if status_info.get("source", null) != target:
			return false
	
	# 检查是否是目标接受的状态
	if trigger_condition.has("target_is_target") and trigger_condition.target_is_target:
		if status_info.get("target", null) != target:
			return false
	
	# 检查状态类型
	if trigger_condition.has("status_type"):
		if status_info.get("status_type", -1) != trigger_condition.status_type:
			return false
	
	return true

# 检查击杀条件
func _check_kill_condition(kill_info: Dictionary) -> bool:
	# 检查是否是目标击杀的
	if trigger_condition.has("killer_is_target") and trigger_condition.killer_is_target:
		if kill_info.get("killer", null) != target:
			return false
	
	# 检查是否是目标被击杀
	if trigger_condition.has("victim_is_target") and trigger_condition.victim_is_target:
		if kill_info.get("victim", null) != target:
			return false
	
	return true

# 检查闪避条件
func _check_dodge_condition(dodge_info: Dictionary) -> bool:
	# 检查是否是目标的攻击被闪避
	if trigger_condition.has("source_is_target") and trigger_condition.source_is_target:
		if dodge_info.get("source", null) != target:
			return false
	
	# 检查是否是目标闪避了攻击
	if trigger_condition.has("target_is_target") and trigger_condition.target_is_target:
		if dodge_info.get("target", null) != target:
			return false
	
	return true

# 检查暴击条件
func _check_critical_condition(crit_info: Dictionary) -> bool:
	# 检查是否是目标造成的暴击
	if trigger_condition.has("source_is_target") and trigger_condition.source_is_target:
		if crit_info.get("source", null) != target:
			return false
	
	# 检查是否是目标受到的暴击
	if trigger_condition.has("target_is_target") and trigger_condition.target_is_target:
		if crit_info.get("target", null) != target:
			return false
	
	return true

# 检查护盾条件
func _check_shield_condition(shield_info: Dictionary) -> bool:
	# 检查是否是目标的护盾
	if trigger_condition.has("target_is_target") and trigger_condition.target_is_target:
		if shield_info.get("target", null) != target:
			return false
	
	return true

# 检查生命值阈值条件
func _check_health_threshold_condition(current_health: float, max_health: float) -> bool:
	# 计算生命值百分比
	var health_percent = current_health / max_health
	
	# 检查生命值阈值
	if trigger_condition.has("health_threshold"):
		var threshold = trigger_condition.health_threshold
		var below = trigger_condition.get("below_threshold", true)
		
		if below:
			# 检查是否低于阈值
			if health_percent > threshold:
				return false
		else:
			# 检查是否高于阈值
			if health_percent < threshold:
				return false
	
	return true

# 检查是否在冷却中
func _is_on_cooldown() -> bool:
	if trigger_cooldown <= 0:
		return false
	
	if last_trigger_time <= 0:
		return false
	
	return last_trigger_time < trigger_cooldown

# 检查是否达到触发次数限制
func _reached_trigger_limit() -> bool:
	if max_triggers <= 0:
		return false
	
	return trigger_count >= max_triggers

# 触发效果
func _trigger_effect(trigger_target = null) -> void:
	# 检查GameManager和EffectManager是否可用
	if not GameManager or not GameManager.effect_manager:
		return
	
	# 如果没有指定触发目标，使用效果目标
	if not trigger_target:
		trigger_target = target
	
	# 检查触发目标是否有效
	if not trigger_target or not is_instance_valid(trigger_target):
		return
	
	# 创建触发效果
	var effect = GameManager.effect_manager.apply_effect(trigger_effect_data, source, trigger_target)
	
	# 更新触发次数
	trigger_count += 1
	
	# 更新上次触发时间
	last_trigger_time = 0.0001  # 设置一个很小的值，表示刚刚触发
	
	# 发送触发效果事件
	if EventBus:
		EventBus.emit_signal("trigger_effect_activated", {
			"trigger": self,
			"source": source,
			"target": trigger_target,
			"effect": effect,
			"trigger_count": trigger_count
		})
	
	# 如果达到触发次数限制，移除效果
	if max_triggers > 0 and trigger_count >= max_triggers:
		remove()

# 获取触发描述
func _get_trigger_description(trigger_type: String, max_triggers: int, trigger_cooldown: float) -> String:
	var desc = ""
	
	match trigger_type:
		"on_damage":
			desc = "当造成伤害时触发"
		"on_heal":
			desc = "当治疗时触发"
		"on_status":
			desc = "当施加状态时触发"
		"on_kill":
			desc = "当击杀单位时触发"
		"on_dodge":
			desc = "当闪避攻击时触发"
		"on_critical":
			desc = "当造成暴击时触发"
		"on_shield_break":
			desc = "当护盾破碎时触发"
		"on_health_threshold":
			desc = "当生命值达到阈值时触发"
		_:
			desc = "在特定条件下触发"
	
	if max_triggers > 0:
		desc += "（最多触发 " + str(max_triggers) + " 次）"
	
	if trigger_cooldown > 0:
		desc += "（冷却时间：" + str(trigger_cooldown) + " 秒）"
	
	return desc

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["trigger_type"] = trigger_type
	data["trigger_condition"] = trigger_condition.duplicate()
	data["trigger_effect_data"] = trigger_effect_data.duplicate()
	data["max_triggers"] = max_triggers
	data["trigger_count"] = trigger_count
	data["trigger_cooldown"] = trigger_cooldown
	data["last_trigger_time"] = last_trigger_time
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> TriggerEffect:
	var effect = TriggerEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("duration", 0.0),
		data.get("trigger_type", ""),
		source,
		target,
		data.get("params", {})
	)
	
	effect.trigger_condition = data.get("trigger_condition", {})
	effect.trigger_effect_data = data.get("trigger_effect_data", {})
	effect.max_triggers = data.get("max_triggers", 0)
	effect.trigger_count = data.get("trigger_count", 0)
	effect.trigger_cooldown = data.get("trigger_cooldown", 0.0)
	effect.last_trigger_time = data.get("last_trigger_time", 0.0)
	
	return effect
