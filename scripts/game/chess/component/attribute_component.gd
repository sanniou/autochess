extends Component
class_name AttributeComponent
## 属性组件
## 管理棋子的所有属性和属性修改

# 信号
signal attribute_changed(attribute_name, old_value, new_value)
signal attribute_modifier_added(attribute_name, modifier)
signal attribute_modifier_removed(attribute_name, modifier)

# 属性字典
var attributes: Dictionary = {}  # 当前属性值
var base_attributes: Dictionary = {}  # 基础属性值
var attribute_modifiers: Dictionary = {}  # 属性修改器 {属性名: [修改器列表]}
var attribute_dirty_flags: Dictionary = {}  # 属性脏标记 {属性名: 是否脏}

# 初始化
func _init(p_owner = null, p_name: String = "AttributeComponent"):
	super._init(p_owner, p_name)
	priority = 100  # 高优先级，确保属性先更新

# 初始化组件
func initialize() -> void:
	# 初始化基本属性
	_initialize_attributes()

	super.initialize()

# 初始化属性
func _initialize_attributes() -> void:
	# 基础属性
	set_base_attribute("max_health", 100.0)
	set_base_attribute("current_health", 100.0)
	set_base_attribute("attack_damage", 10.0)
	set_base_attribute("attack_speed", 1.0)
	set_base_attribute("attack_range", 1.0)
	set_base_attribute("armor", 0.0)
	set_base_attribute("magic_resist", 0.0)
	set_base_attribute("move_speed", 300.0)

	# 技能属性
	set_base_attribute("max_mana", 100.0)
	set_base_attribute("current_mana", 0.0)
	set_base_attribute("spell_power", 0.0)

	# 战斗增强属性
	set_base_attribute("crit_chance", 0.0)
	set_base_attribute("crit_damage", 1.5)
	set_base_attribute("dodge_chance", 0.0)
	set_base_attribute("lifesteal", 0.0)
	set_base_attribute("healing_bonus", 0.0)
	set_base_attribute("damage_reduction", 0.0)
	set_base_attribute("control_resistance", 0.0)
	set_base_attribute("elemental_effect_chance", 0.0)

# 设置基础属性
func set_base_attribute(attribute_name: String, value) -> void:
	var old_value = get_attribute(attribute_name)

	# 更新基础属性
	base_attributes[attribute_name] = value

	# 标记属性为脏
	attribute_dirty_flags[attribute_name] = true

	# 更新属性
	var new_value = _calculate_attribute(attribute_name)
	attributes[attribute_name] = new_value

	# 发送属性变化信号
	attribute_changed.emit(attribute_name, old_value, new_value)

	# 发送属性变化事件
	if GlobalEventBus:
		var event = ComponentEvents.AttributeChangedEvent.new(owner, attribute_name, old_value, new_value)
		GlobalEventBus.get_group("component").dispatch_event(event)

# 获取属性
func get_attribute(attribute_name: String, default_value = 0):
	# 如果属性脏，重新计算
	if attribute_dirty_flags.get(attribute_name, true):
		attributes[attribute_name] = _calculate_attribute(attribute_name)
		attribute_dirty_flags[attribute_name] = false

	return attributes.get(attribute_name, default_value)

# 获取基础属性
func get_base_attribute(attribute_name: String, default_value = 0):
	return base_attributes.get(attribute_name, default_value)

# 添加属性修改器
func add_attribute_modifier(attribute_name: String, modifier: Dictionary) -> String:
	# 创建修改器ID
	var modifier_id = attribute_name + "_" + str(randi())

	# 确保修改器包含必要字段
	modifier["id"] = modifier_id
	modifier["attribute"] = attribute_name

	if not modifier.has("value"):
		modifier["value"] = 0

	if not modifier.has("type"):
		modifier["type"] = "add"  # 默认为加法修改器

	if not modifier.has("duration"):
		modifier["duration"] = -1  # 默认为永久修改器

	if not modifier.has("remaining_time"):
		modifier["remaining_time"] = modifier["duration"]

	if not modifier.has("priority"):
		modifier["priority"] = 0  # 默认优先级

	if not modifier.has("source"):
		modifier["source"] = null

	# 添加修改器
	if not attribute_modifiers.has(attribute_name):
		attribute_modifiers[attribute_name] = []

	attribute_modifiers[attribute_name].append(modifier)

	# 标记属性为脏
	attribute_dirty_flags[attribute_name] = true

	# 重新计算属性
	var old_value = get_attribute(attribute_name)
	var new_value = _calculate_attribute(attribute_name)
	attributes[attribute_name] = new_value

	# 发送修改器添加信号
	attribute_modifier_added.emit(attribute_name, modifier)

	# 发送属性变化信号
	attribute_changed.emit(attribute_name, old_value, new_value)

	return modifier_id

# 移除属性修改器
func remove_attribute_modifier(modifier_id: String) -> bool:
	# 查找修改器
	for attribute_name in attribute_modifiers:
		var modifiers = attribute_modifiers[attribute_name]
		for i in range(modifiers.size()):
			if modifiers[i].id == modifier_id:
				# 获取旧值
				var old_value = get_attribute(attribute_name)

				# 移除修改器
				var modifier = modifiers[i]
				modifiers.remove_at(i)

				# 标记属性为脏
				attribute_dirty_flags[attribute_name] = true

				# 重新计算属性
				var new_value = _calculate_attribute(attribute_name)
				attributes[attribute_name] = new_value

				# 发送修改器移除信号
				attribute_modifier_removed.emit(attribute_name, modifier)

				# 发送属性变化信号
				attribute_changed.emit(attribute_name, old_value, new_value)

				return true

	return false

# 移除所有属性修改器
func remove_all_attribute_modifiers() -> void:
	# 保存所有属性的旧值
	var old_values = {}
	for attribute_name in attributes:
		old_values[attribute_name] = get_attribute(attribute_name)

	# 清空所有修改器
	for attribute_name in attribute_modifiers:
		for modifier in attribute_modifiers[attribute_name]:
			# 发送修改器移除信号
			attribute_modifier_removed.emit(attribute_name, modifier)

	attribute_modifiers.clear()

	# 标记所有属性为脏
	for attribute_name in attributes:
		attribute_dirty_flags[attribute_name] = true

		# 重新计算属性
		var new_value = _calculate_attribute(attribute_name)
		attributes[attribute_name] = new_value

		# 发送属性变化信号
		attribute_changed.emit(attribute_name, old_values[attribute_name], new_value)

# 移除来源的所有修改器
func remove_modifiers_by_source(source) -> void:
	# 查找来源的所有修改器
	var modifiers_to_remove = []

	for attribute_name in attribute_modifiers:
		var modifiers = attribute_modifiers[attribute_name]
		for modifier in modifiers:
			if modifier.source == source:
				modifiers_to_remove.append(modifier.id)

	# 移除找到的修改器
	for modifier_id in modifiers_to_remove:
		remove_attribute_modifier(modifier_id)

# 更新组件
func _process_update(delta: float) -> void:
	# 更新所有修改器
	var modifiers_to_remove = []

	for attribute_name in attribute_modifiers:
		var modifiers = attribute_modifiers[attribute_name]
		for modifier in modifiers:
			# 更新持续时间
			if modifier.duration > 0:
				modifier.remaining_time -= delta

				# 如果修改器过期，标记为移除
				if modifier.remaining_time <= 0:
					modifiers_to_remove.append(modifier.id)

	# 移除过期的修改器
	for modifier_id in modifiers_to_remove:
		remove_attribute_modifier(modifier_id)

# 计算属性值
func _calculate_attribute(attribute_name: String):
	# 获取基础值
	var base_value = base_attributes.get(attribute_name, 0)

	# 如果没有修改器，直接返回基础值
	if not attribute_modifiers.has(attribute_name) or attribute_modifiers[attribute_name].is_empty():
		return base_value

	# 获取修改器列表
	var modifiers = attribute_modifiers[attribute_name]

	# 按优先级排序
	modifiers.sort_custom(func(a, b): return a.priority > b.priority)

	# 应用修改器
	var flat_add = 0
	var percent_add = 0
	var percent_multiply = 1.0

	for modifier in modifiers:
		match modifier.type:
			"add":
				flat_add += modifier.value
			"percent_add":
				percent_add += modifier.value
			"percent_multiply":
				percent_multiply *= (1 + modifier.value)

	# 计算最终值
	var final_value = (base_value + flat_add) * (1 + percent_add) * percent_multiply

	return final_value

# 设置生命值
func set_health(value: float) -> void:
	var old_value = get_attribute("current_health")
	var max_health = get_attribute("max_health")

	# 限制生命值范围
	value = clamp(value, 0, max_health)

	# 更新生命值
	attributes["current_health"] = value

	# 发送属性变化信号
	attribute_changed.emit("current_health", old_value, value)

	# 发送属性变化事件
	if GlobalEventBus:
		var event = ComponentEvents.AttributeChangedEvent.new(owner, "current_health", old_value, value)
		GlobalEventBus.get_group("component").dispatch_event(event)

# 增加生命值
func add_health(value: float) -> void:
	var current_health = get_attribute("current_health")
	set_health(current_health + value)

# 减少生命值
func reduce_health(value: float) -> void:
	var current_health = get_attribute("current_health")
	set_health(current_health - value)

# 设置法力值
func set_mana(value: float) -> void:
	var old_value = get_attribute("current_mana")
	var max_mana = get_attribute("max_mana")

	# 限制法力值范围
	value = clamp(value, 0, max_mana)

	# 更新法力值
	attributes["current_mana"] = value

	# 发送属性变化信号
	attribute_changed.emit("current_mana", old_value, value)

	# 发送属性变化事件
	if GlobalEventBus:
		var event = ComponentEvents.AttributeChangedEvent.new(owner, "current_mana", old_value, value)
		GlobalEventBus.get_group("component").dispatch_event(event)

# 增加法力值
func add_mana(value: float) -> void:
	var current_mana = get_attribute("current_mana")
	set_mana(current_mana + value)

# 减少法力值
func reduce_mana(value: float) -> void:
	var current_mana = get_attribute("current_mana")
	set_mana(current_mana - value)

# 是否死亡
func is_dead() -> bool:
	return get_attribute("current_health") <= 0

# 是否满血
func is_full_health() -> bool:
	return get_attribute("current_health") >= get_attribute("max_health")

# 是否满蓝
func is_full_mana() -> bool:
	return get_attribute("current_mana") >= get_attribute("max_mana")

# 获取生命值百分比
func get_health_percent() -> float:
	var current_health = get_attribute("current_health")
	var max_health = get_attribute("max_health")

	if max_health <= 0:
		return 0

	return current_health / max_health

# 获取法力值百分比
func get_mana_percent() -> float:
	var current_mana = get_attribute("current_mana")
	var max_mana = get_attribute("max_mana")

	if max_mana <= 0:
		return 0

	return current_mana / max_mana

# 从字典初始化属性
func initialize_from_dict(data: Dictionary) -> void:
	# 设置基础属性
	for attribute_name in data:
		set_base_attribute(attribute_name, data[attribute_name])

# 获取所有属性
func get_all_attributes() -> Dictionary:
	var result = {}

	# 确保所有属性都是最新的
	for attribute_name in base_attributes:
		result[attribute_name] = get_attribute(attribute_name)

	return result

# 获取所有基础属性
func get_all_base_attributes() -> Dictionary:
	return base_attributes.duplicate()

# 重置属性
func reset_attributes() -> void:
	# 移除所有修改器
	remove_all_attribute_modifiers()

	# 重置生命值和法力值
	set_health(get_attribute("max_health"))
	set_mana(0)
