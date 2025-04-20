extends Node
class_name Equipment
## 装备基类
## 定义装备的基本属性和行为

# 引入常量
const GameConsts = preload("res://scripts/constants/game_constants.gd")
const EffectConsts = preload("res://scripts/constants/effect_constants.gd")

# 信号
signal equipped(character)  # 装备穿戴信号
signal unequipped(character) # 装备卸下信号
signal effect_triggered(effect_data) # 效果触发信号

# 装备属性
var id: String = ""
var display_name: String = ""
var description: String = ""
var type: String = ""  # weapon/armor/accessory
var rarity: int
var icon: String = ""

# 装备效果
var stats: Dictionary = {}  # 基础属性加成
var effects: Array = []     # 特殊效果
var combine_recipes: Array = [] # 合成配方
var recipe: Array = []      # 合成所需装备

# 当前穿戴者
var current_owner: ChessPiece = null

# 初始化
func initialize(data: Dictionary):
	id = data.id
	display_name = data.name
	description = data.description
	type = data.type
	rarity = data.rarity
	icon = data.icon_path

	if data.has("stats"):
		stats = data.stats
	if data.has("effects"):
		effects = data.effects
	if data.has("combine_recipes"):
		combine_recipes = data.combine_recipes
	if data.has("recipe"):
		recipe = data.recipe

# 装备到角色
func equip_to(character: ChessPiece) -> bool:
	if current_owner != null:
		return false

	current_owner = character

	# 应用基础属性
	_apply_stats()

	# 应用特殊效果
	_apply_effects()

	# 发送装备信号
	equipped.emit(character)
	EventBus.equipment.emit_event("equipment_equipped", [self, character])

	return true

# 从角色卸下
func unequip_from() -> bool:
	if current_owner == null:
		return false

	# 移除基础属性
	_remove_stats()

	# 移除特殊效果
	_remove_effects()

	# 发送卸下信号
	unequipped.emit(current_owner)
	EventBus.equipment.emit_event("equipment_unequipped", [self, current_owner])

	current_owner = null
	return true

# 应用基础属性
func _apply_stats():
	if current_owner == null:
		return

	for stat in stats:
		var value = stats[stat]
		match stat:
			"health":
				current_owner.max_health += value
				current_owner.current_health += value
			"attack_damage":
				current_owner.attack_damage += value
			"attack_speed":
				current_owner.attack_speed += value
			"armor":
				current_owner.armor += value
			"magic_resist":
				current_owner.magic_resist += value
			"spell_power":
				current_owner.spell_power += value
			"move_speed":
				current_owner.move_speed += value
			"crit_chance":
				current_owner.crit_chance += value
			"crit_damage":
				current_owner.crit_damage += value
			"dodge_chance":
				current_owner.dodge_chance += value

# 移除基础属性
func _remove_stats():
	if current_owner == null:
		return

	for stat in stats:
		var value = stats[stat]
		match stat:
			"health":
				current_owner.max_health -= value
				current_owner.current_health = min(current_owner.current_health, current_owner.max_health)
			"attack_damage":
				current_owner.attack_damage -= value
			"attack_speed":
				current_owner.attack_speed -= value
			"armor":
				current_owner.armor -= value
			"magic_resist":
				current_owner.magic_resist -= value
			"spell_power":
				current_owner.spell_power -= value
			"move_speed":
				current_owner.move_speed -= value
			"crit_chance":
				current_owner.crit_chance -= value
			"crit_damage":
				current_owner.crit_damage -= value
			"dodge_chance":
				current_owner.dodge_chance -= value

# 应用特殊效果
func _apply_effects():
	if current_owner == null:
		return

	for effect in effects:
		var effect_data = effect.duplicate()
		effect_data["source"] = self
		effect_data["id"] = "equip_%s_%s" % [id, effect.type]

		# 获取触发条件
		var trigger = effect.get("trigger", "")
		if trigger.is_empty() and effect.type != "passive":
			# 如果没有指定触发条件，使用默认触发条件
			trigger = EffectConsts.get_default_condition_for_trigger_name(effect.type)

		# 根据触发条件连接信号
		match trigger:
			"attack":
				current_owner.ability_activated.connect(_on_owner_attack.bind(effect_data))
			"take_damage":
				current_owner.health_changed.connect(_on_owner_take_damage.bind(effect_data))
			"ability_cast":
				current_owner.ability_activated.connect(_on_owner_ability.bind(effect_data))
			"low_health":
				current_owner.health_changed.connect(_on_owner_health_changed.bind(effect_data))
			"dodge":
				current_owner.dodge_successful.connect(_on_owner_dodge.bind(effect_data))
			"crit":
				current_owner.critical_hit.connect(_on_owner_crit.bind(effect_data))
			"elemental_effect":
				current_owner.elemental_effect_triggered.connect(_on_owner_elemental_effect.bind(effect_data))
			"health_percent":
				current_owner.health_changed.connect(_on_owner_health_percent.bind(effect_data))

		# 被动效果直接应用
		if effect.type == "passive":
			_apply_passive_effect(effect_data)
		else:
			current_owner.add_effect(effect_data)

# 移除特殊效果
func _remove_effects():
	if current_owner == null:
		return

	for effect in effects:
		var effect_id = "equip_%s_%s" % [id, effect.type]
		current_owner.remove_effect(effect_id)

# 攻击事件处理
func _on_owner_attack(_target, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])

# 受伤事件处理
func _on_owner_take_damage(_old_value, _new_value, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])

# 技能释放事件处理
func _on_owner_ability(_target, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])

# 生命值变化事件处理
func _on_owner_health_changed(_old_value, new_value, effect_data):
	var max_health = current_owner.max_health
	if effect_data.has("threshold") and new_value <= max_health * effect_data.threshold:
		effect_triggered.emit(effect_data)
		EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])

# 生命值百分比事件处理
func _on_owner_health_percent(_old_value, new_value, effect_data):
	var max_health = current_owner.max_health
	var health_percent = new_value / max_health

	if health_percent <= effect_data.threshold:
		# 如果生命值百分比低于阈值，触发效果
		if not effect_data.has("active") or not effect_data.active:
			effect_data.active = true
			_apply_health_percent_effect(effect_data)
			effect_triggered.emit(effect_data)
			EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])
	else:
		# 如果生命值百分比高于阈值，移除效果
		if effect_data.has("active") and effect_data.active:
			effect_data.active = false
			_remove_health_percent_effect(effect_data)

# 闪避事件处理
func _on_owner_dodge(_attacker, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])

		# 如果是隐身效果，应用隐身
		if effect_data.effect == "stealth":
			_apply_stealth_effect(effect_data)

# 暴击事件处理
func _on_owner_crit(target, _damage, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])

		# 如果是出血效果，应用出血
		if effect_data.effect == "bleed" and target:
			_apply_bleed_effect(target, effect_data)

# 元素效果事件处理
func _on_owner_elemental_effect(target, element_type, effect_data):
	effect_triggered.emit(effect_data)
	EventBus.equipment.emit_event("equipment_effect_triggered", [self, effect_data])

	# 如果是持续时间增加效果
	if effect_data.effect == "duration_increase" and target:
		_increase_elemental_duration(target, element_type, effect_data)

# 检查是否可以合成
func can_combine_with(other_equipment: Equipment) -> bool:
	return other_equipment.id in combine_recipes

# 获取合成结果
func get_combine_result(other_equipment: Equipment) -> String:
	if can_combine_with(other_equipment):
		for recipe_id in combine_recipes:
			var recipe_model = ConfigManager.get_equipment_config(recipe_id)
			if recipe_model and other_equipment.id in recipe_model.get_components():
				return recipe_id
	return ""

# 获取装备数据
func get_data() -> Dictionary:
	# 返回装备的完整数据
	var data = {
		"id": id,
		"name": display_name,
		"description": description,
		"type": type,
		"rarity": rarity,
		"icon": icon,
		"stats": stats.duplicate(),
		"effects": effects.duplicate(),
		"combine_recipes": combine_recipes.duplicate(),
		"recipe": recipe.duplicate()
	}
	return data

# 应用被动效果
func _apply_passive_effect(effect_data: Dictionary) -> void:
	if current_owner == null:
		return

	match effect_data.effect:
		"health_regen":
			_apply_health_regen_effect(effect_data)
			# 添加视觉效果
			if effect_data.has("percent"):
				_add_health_regen_visual(effect_data.percent)
		"summon_boost":
			_apply_summon_boost_effect(effect_data)
			# 添加视觉效果
			if effect_data.has("health_boost") and effect_data.has("damage_boost"):
				_add_summon_boost_visual(effect_data.health_boost, effect_data.damage_boost)
		"damage_boost":
			# 伤害提升效果在生命值百分比事件中处理
			if effect_data.has("boost"):
				_add_damage_boost_visual(effect_data.boost)
		"attack_speed_boost":
			# 攻击速度提升效果在生命值百分比事件中处理
			if effect_data.has("boost"):
				_add_attack_speed_boost_visual(effect_data.boost)
		"damage_reduction":
			# 伤害减免效果
			if effect_data.has("reduction"):
				current_owner.set_meta("damage_reduction_" + id, effect_data.reduction)
				_add_damage_reduction_visual(effect_data.reduction)
		"multi_attack":
			# 连击效果
			if effect_data.has("chance") and effect_data.has("attacks"):
				current_owner.set_meta("multi_attack_chance_" + id, effect_data.chance)
				current_owner.set_meta("multi_attack_count_" + id, effect_data.attacks)
				_add_multi_attack_visual(effect_data.attacks)
		"death_immunity":
			# 死亡免疫效果
			if effect_data.has("chance") and effect_data.has("cooldown_time") and effect_data.has("heal_percent"):
				current_owner.set_meta("death_immunity_chance_" + id, effect_data.chance)
				current_owner.set_meta("death_immunity_cooldown_" + id, effect_data.cooldown_time)
				current_owner.set_meta("death_immunity_heal_" + id, effect_data.heal_percent)
				current_owner.set_meta("death_immunity_ready_" + id, true)
				_add_death_immunity_visual()
		"periodic_buff":
			# 周期性增益效果
			if effect_data.has("interval") and effect_data.has("duration") and effect_data.has("stats"):
				# 创建定时器
				var timer = Timer.new()
				timer.wait_time = effect_data.interval
				timer.autostart = true
				timer.timeout.connect(_on_periodic_buff_tick.bind(effect_data))
				add_child(timer)
				current_owner.set_meta("periodic_buff_timer_" + id, timer)
				_add_periodic_buff_visual(effect_data.stats)

# 应用生命值百分比效果
func _apply_health_percent_effect(effect_data: Dictionary) -> void:
	if current_owner == null:
		return

	match effect_data.effect:
		"damage_boost":
			# 增加攻击力
			var boost_amount = current_owner.attack_damage * effect_data.boost
			current_owner.attack_damage += boost_amount
			effect_data.boost_amount = boost_amount  # 保存增加的数值以便移除
		"attack_speed_boost":
			# 增加攻击速度
			var boost_amount = current_owner.attack_speed * effect_data.boost
			current_owner.attack_speed += boost_amount
			effect_data.boost_amount = boost_amount  # 保存增加的数值以便移除

# 移除生命值百分比效果
func _remove_health_percent_effect(effect_data: Dictionary) -> void:
	if current_owner == null or not effect_data.has("boost_amount"):
		return

	match effect_data.effect:
		"damage_boost":
			# 移除攻击力加成
			current_owner.attack_damage -= effect_data.boost_amount
		"attack_speed_boost":
			# 移除攻击速度加成
			current_owner.attack_speed -= effect_data.boost_amount

# 应用隐身效果
func _apply_stealth_effect(effect_data: Dictionary) -> void:
	if current_owner == null:
		return

	# 设置隐身状态
	current_owner.set_meta("stealth", true)

	# 创建隐身视觉效果
	var stealth_effect = ColorRect.new()
	stealth_effect.name = "StealthEffect"
	stealth_effect.color = Color(0.5, 0.5, 0.5, 0.5)
	stealth_effect.size = Vector2(60, 60)
	stealth_effect.position = Vector2(-30, -30)
	current_owner.add_child(stealth_effect)

	# 设置定时器移除隐身
	var timer = get_tree().create_timer(effect_data.duration)
	timer.timeout.connect(_on_stealth_timeout.bind(current_owner))

# 隐身超时处理
func _on_stealth_timeout(character: ChessPiece) -> void:
	if is_instance_valid(character):
		# 移除隐身状态
		character.remove_meta("stealth")

		# 移除隐身视觉效果
		if character.has_node("StealthEffect"):
			character.get_node("StealthEffect").queue_free()

# 应用出血效果
func _apply_bleed_effect(target: ChessPiece, effect_data: Dictionary) -> void:
	if target == null or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 创建出血效果数据
	var bleed_data = {
		"id": "bleed_" + str(randi()),
		"name": "出血",
		"description": "每秒造成" + str(effect_data.damage) + "点伤害",
		"duration": effect_data.duration,
		"damage": effect_data.damage,
		"source": current_owner,
		"tick_interval": 1.0,
		"ticks_remaining": effect_data.duration
	}

	# 添加效果
	target.add_effect(bleed_data)

	# 创建出血视觉效果
	var bleed_effect = ColorRect.new()
	bleed_effect.name = "BleedEffect_" + bleed_data.id
	bleed_effect.color = Color(0.8, 0.0, 0.0, 0.5)
	bleed_effect.size = Vector2(40, 40)
	bleed_effect.position = Vector2(-20, -20)
	target.add_child(bleed_effect)

	# 创建定时器处理出血伤害
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(_on_bleed_tick.bind(target, bleed_data))

# 出血效果计时器
func _on_bleed_tick(target: ChessPiece, bleed_data: Dictionary) -> void:
	# 检查目标是否有效
	if not is_instance_valid(target) or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 造成伤害
	target.take_damage(bleed_data.damage, "physical", bleed_data.source)

	# 减少剩余计时器
	bleed_data.ticks_remaining -= 1

	# 如果还有剩余计时器，创建新的定时器
	if bleed_data.ticks_remaining > 0:
		var timer = get_tree().create_timer(bleed_data.tick_interval)
		timer.timeout.connect(_on_bleed_tick.bind(target, bleed_data))
	else:
		# 移除出血视觉效果
		if target.has_node("BleedEffect_" + bleed_data.id):
			target.get_node("BleedEffect_" + bleed_data.id).queue_free()

# 增加元素效果持续时间
func _increase_elemental_duration(target: ChessPiece, element_type: String, effect_data: Dictionary) -> void:
	if target == null or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 查找对应的元素效果
	for effect in target.active_effects:
		if effect.has("element_type") and effect.element_type == element_type:
			# 增加持续时间
			effect.duration += effect_data.increase
			break

# 应用生命值恢复效果
func _apply_health_regen_effect(effect_data: Dictionary) -> void:
	if current_owner == null:
		return

	# 创建生命值恢复定时器
	var timer = Timer.new()
	timer.name = "HealthRegenTimer"
	timer.wait_time = effect_data.interval
	timer.autostart = true
	timer.timeout.connect(_on_health_regen_tick.bind(effect_data))
	current_owner.add_child(timer)

# 生命值恢复计时器
func _on_health_regen_tick(effect_data: Dictionary) -> void:
	if current_owner == null or current_owner.current_state == ChessPiece.ChessState.DEAD:
		return

	# 计算恢复量
	var regen_amount = current_owner.max_health * effect_data.percent

	# 恢复生命值
	current_owner.heal(regen_amount)

# 应用召唤物加成效果
func _apply_summon_boost_effect(effect_data: Dictionary) -> void:
	if current_owner == null:
		return

	# 设置召唤物加成数据
	current_owner.set_meta("summon_health_boost", effect_data.health_boost)
	current_owner.set_meta("summon_damage_boost", effect_data.damage_boost)

# 添加伤害提升视觉效果
func _add_damage_boost_visual(boost_value: float) -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "DamageBoostEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(1.0, 0.0, 0.0, 0.5) # 红色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	effect_label.text = "+" + str(int(boost_value * 100)) + "%"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(40, 20)
	effect_label.position = Vector2(-20, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加攻击速度提升视觉效果
func _add_attack_speed_boost_visual(boost_value: float) -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "AttackSpeedBoostEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(1.0, 1.0, 0.0, 0.5) # 黄色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	effect_label.text = "+" + str(int(boost_value * 100)) + "%"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(40, 20)
	effect_label.position = Vector2(-20, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加伤害减免视觉效果
func _add_damage_reduction_visual(reduction_value: float) -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "DamageReductionEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(0.0, 0.0, 1.0, 0.5) # 蓝色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	effect_label.text = "-" + str(int(reduction_value * 100)) + "%"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(40, 20)
	effect_label.position = Vector2(-20, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加生命值恢复视觉效果
func _add_health_regen_visual(percent_value: float) -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "HealthRegenEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(0.0, 1.0, 0.0, 0.5) # 绿色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	effect_label.text = "+" + str(int(percent_value * 100)) + "%"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(40, 20)
	effect_label.position = Vector2(-20, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加召唤物加成视觉效果
func _add_summon_boost_visual(health_boost: float, damage_boost: float) -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "SummonBoostEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(0.8, 0.0, 0.8, 0.5) # 紫色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	effect_label.text = "H+" + str(int(health_boost * 100)) + "% D+" + str(int(damage_boost * 100)) + "%"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(80, 20)
	effect_label.position = Vector2(-40, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加连击视觉效果
func _add_multi_attack_visual(attacks: int) -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "MultiAttackEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(1.0, 0.5, 0.0, 0.5) # 橙色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	effect_label.text = str(attacks) + "x"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(40, 20)
	effect_label.position = Vector2(-20, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加死亡免疫视觉效果
func _add_death_immunity_visual() -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "DeathImmunityEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(1.0, 1.0, 1.0, 0.5) # 白色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	effect_label.text = "免死"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(40, 20)
	effect_label.position = Vector2(-20, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 添加周期性增益视觉效果
func _add_periodic_buff_visual(stats: Dictionary) -> void:
	if current_owner == null:
		return

	# 创建效果容器
	var effect_container = Node2D.new()
	effect_container.name = "PeriodicBuffEffect_" + id
	current_owner.add_child(effect_container)

	# 创建效果图标
	var effect_icon = ColorRect.new()
	effect_icon.color = Color(0.0, 1.0, 1.0, 0.5) # 青色
	effect_icon.size = Vector2(20, 20)
	effect_icon.position = Vector2(-10, -40)
	effect_container.add_child(effect_icon)

	# 创建效果文本
	var effect_label = Label.new()
	var text = "周期"
	effect_label.text = text
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_label.size = Vector2(40, 20)
	effect_label.position = Vector2(-20, -40)
	effect_container.add_child(effect_label)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(effect_icon, "modulate", Color(1, 1, 1, 1.0), 0.5)
	tween.set_loops() # 无限循环

# 周期性增益计时器
func _on_periodic_buff_tick(effect_data: Dictionary) -> void:
	if current_owner == null or current_owner.current_state == ChessPiece.ChessState.DEAD:
		return

	# 检查是否已经有激活的增益
	var buff_active = current_owner.has_meta("periodic_buff_active_" + id) and current_owner.get_meta("periodic_buff_active_" + id)

	if buff_active:
		# 如果增益已经激活，不做任何操作
		return

	# 激活增益
	current_owner.set_meta("periodic_buff_active_" + id, true)

	# 应用属性加成
	var applied_stats = {}
	for stat_name in effect_data.stats:
		var value = effect_data.stats[stat_name]
		applied_stats[stat_name] = value

		match stat_name:
			"attack_speed":
				current_owner.attack_speed += value
			"move_speed":
				current_owner.move_speed += value
			"attack_damage":
				current_owner.attack_damage += value
			"spell_power":
				current_owner.spell_power += value

	# 保存应用的属性以便移除
	current_owner.set_meta("periodic_buff_stats_" + id, applied_stats)

	# 显示激活效果
	_show_periodic_buff_active()

	# 创建定时器移除增益
	var timer = get_tree().create_timer(effect_data.duration)
	timer.timeout.connect(_on_periodic_buff_end)

# 周期性增益结束
func _on_periodic_buff_end() -> void:
	if current_owner == null:
		return

	# 检查是否有激活的增益
	if not current_owner.has_meta("periodic_buff_active_" + id) or not current_owner.get_meta("periodic_buff_active_" + id):
		return

	# 移除增益状态
	current_owner.set_meta("periodic_buff_active_" + id, false)

	# 获取应用的属性
	var applied_stats = current_owner.get_meta("periodic_buff_stats_" + id)

	# 移除属性加成
	for stat_name in applied_stats:
		var value = applied_stats[stat_name]

		match stat_name:
			"attack_speed":
				current_owner.attack_speed -= value
			"move_speed":
				current_owner.move_speed -= value
			"attack_damage":
				current_owner.attack_damage -= value
			"spell_power":
				current_owner.spell_power -= value

	# 显示结束效果
	_show_periodic_buff_end()

# 显示周期性增益激活效果
func _show_periodic_buff_active() -> void:
	if current_owner == null:
		return

	# 创建激活效果
	var active_effect = ColorRect.new()
	active_effect.name = "PeriodicBuffActiveEffect_" + id
	active_effect.color = Color(0.0, 1.0, 1.0, 0.3) # 半透明青色
	active_effect.size = Vector2(60, 60)
	active_effect.position = Vector2(-30, -30)
	current_owner.add_child(active_effect)

	# 创建闪烁动画
	var tween = create_tween()
	tween.tween_property(active_effect, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(active_effect, "modulate", Color(1, 1, 1, 0.7), 0.5)
	tween.set_loops() # 无限循环

# 显示周期性增益结束效果
func _show_periodic_buff_end() -> void:
	if current_owner == null:
		return

	# 移除激活效果
	if current_owner.has_node("PeriodicBuffActiveEffect_" + id):
		var active_effect = current_owner.get_node("PeriodicBuffActiveEffect_" + id)

		# 创建消失动画
		var tween = create_tween()
		tween.tween_property(active_effect, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(active_effect.queue_free)
