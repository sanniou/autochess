extends Node
class_name Equipment
## 装备基类
## 定义装备的基本属性和行为

# 信号
signal equipped(character)  # 装备穿戴信号
signal unequipped(character) # 装备卸下信号
signal effect_triggered(effect_data) # 效果触发信号

# 装备属性
var id: String = ""
var display_name: String = ""
var description: String = ""
var type: String = ""  # weapon/armor/accessory
var rarity: String = "" # common/rare/epic/legendary
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
	icon = data.icon

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
	EventBus.equipment_equipped.emit(self, character)

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
	EventBus.equipment_unequipped.emit(self, current_owner)

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

		# 根据效果类型连接信号
		match effect.trigger:
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
		EventBus.equipment_effect_triggered.emit(self, effect_data)

# 受伤事件处理
func _on_owner_take_damage(_old_value, _new_value, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

# 技能释放事件处理
func _on_owner_ability(_target, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

# 生命值变化事件处理
func _on_owner_health_changed(_old_value, new_value, effect_data):
	var max_health = current_owner.max_health
	if effect_data.has("threshold") and new_value <= max_health * effect_data.threshold:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

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
			EventBus.equipment_effect_triggered.emit(self, effect_data)
	else:
		# 如果生命值百分比高于阈值，移除效果
		if effect_data.has("active") and effect_data.active:
			effect_data.active = false
			_remove_health_percent_effect(effect_data)

# 闪避事件处理
func _on_owner_dodge(_attacker, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

		# 如果是隐身效果，应用隐身
		if effect_data.effect == "stealth":
			_apply_stealth_effect(effect_data)

# 暴击事件处理
func _on_owner_crit(target, _damage, effect_data):
	if randf() <= effect_data.chance:
		effect_triggered.emit(effect_data)
		EventBus.equipment_effect_triggered.emit(self, effect_data)

		# 如果是出血效果，应用出血
		if effect_data.effect == "bleed" and target:
			_apply_bleed_effect(target, effect_data)

# 元素效果事件处理
func _on_owner_elemental_effect(target, element_type, effect_data):
	effect_triggered.emit(effect_data)
	EventBus.equipment_effect_triggered.emit(self, effect_data)

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
			var recipe_data = ConfigManager.get_equipment(recipe_id)
			if recipe_data and other_equipment.id in recipe_data.recipe:
				return recipe_id
	return ""

# 应用被动效果
func _apply_passive_effect(effect_data: Dictionary) -> void:
	if current_owner == null:
		return

	match effect_data.effect:
		"health_regen":
			_apply_health_regen_effect(effect_data)
		"summon_boost":
			_apply_summon_boost_effect(effect_data)
		"damage_boost":
			# 伤害提升效果在生命值百分比事件中处理
			pass
		"attack_speed_boost":
			# 攻击速度提升效果在生命值百分比事件中处理
			pass

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
