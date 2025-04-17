extends Node
class_name Relic
## 遗物基类
## 定义遗物的基本属性和行为

# 信号
signal effect_triggered(effect_data)
signal activated
signal deactivated

# 遗物属性
var id: String = ""                # 遗物ID
var display_name: String = ""      # 显示名称
var description: String = ""       # 描述
var rarity: int = 0                # 稀有度 (0-3: 普通、稀有、史诗、传说)
var icon: Texture2D                # 图标
var is_active: bool = false        # 是否激活
var owner_player = null            # 拥有者

# 效果属性
var effects: Array = []            # 效果列表
var cooldown: float = 0.0          # 冷却时间
var current_cooldown: float = 0.0  # 当前冷却时间
var is_passive: bool = true        # 是否为被动遗物
var charges: int = -1              # 使用次数 (-1表示无限)

# 触发条件
var trigger_conditions: Dictionary = {}  # 触发条件

# 视觉组件
var visual_effect: Node2D

func _ready():
	# 初始化视觉效果
	_initialize_visuals()

# 初始化遗物
func initialize(relic_data: Dictionary) -> void:
	id = relic_data.id
	display_name = relic_data.name
	description = relic_data.description
	rarity = relic_data.rarity

	# 设置效果
	if relic_data.has("effects"):
		effects = relic_data.effects

	# 设置触发条件
	if relic_data.has("trigger_conditions"):
		trigger_conditions = relic_data.trigger_conditions

	# 设置其他属性
	if relic_data.has("cooldown"):
		cooldown = relic_data.cooldown

	if relic_data.has("is_passive"):
		is_passive = relic_data.is_passive

	if relic_data.has("charges"):
		charges = relic_data.charges

	# 加载图标
	if relic_data.has("icon_path"):
		var icon_path = relic_data.icon_path
		if ResourceLoader.exists(icon_path):
			icon = load(icon_path)

	# 更新视觉效果
	_update_visuals()

# 激活遗物
func activate() -> bool:
	if not can_activate():
		return false

	is_active = true

	# 应用被动效果
	if is_passive:
		_apply_passive_effects()

	# 消耗充能
	if charges > 0:
		charges -= 1

	# 设置冷却
	current_cooldown = cooldown

	# 发送激活信号
	activated.emit()
	EventBus.relic.relic_activated.emit(self)

	return true

# 检查是否可以激活
func can_activate() -> bool:
	# 检查冷却
	if current_cooldown > 0:
		return false

	# 检查充能
	if charges == 0:
		return false

	return true

# 触发效果
func trigger_effect(trigger_type: String, context: Dictionary = {}) -> bool:
	# 检查触发条件
	if not _check_trigger_conditions(trigger_type, context):
		return false

	# 获取对应触发类型的效果
	var triggered_effects = []
	for effect in effects:
		if effect.has("trigger") and effect.trigger == trigger_type:
			triggered_effects.append(effect)

	if triggered_effects.is_empty():
		return false

	# 应用效果
	for effect in triggered_effects:
		_apply_effect(effect, context)

		# 发送效果触发信号
		effect_triggered.emit(effect)
		EventBus.relic.relic_effect_triggered.emit(self, effect)

	return true

# 更新遗物状态
func update(delta: float) -> void:
	# 更新冷却时间
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown < 0:
			current_cooldown = 0

# 停用遗物
func deactivate() -> void:
	if not is_active:
		return

	is_active = false

	# 移除被动效果
	if is_passive:
		_remove_passive_effects()

	# 发送停用信号
	deactivated.emit()

# 应用被动效果
func _apply_passive_effects() -> void:
	for effect in effects:
		if effect.has("is_passive") and effect.is_passive:
			_apply_effect(effect)

# 移除被动效果
func _remove_passive_effects() -> void:
	# 检查是否有拥有者
	if owner_player == null:
		return

	# 逆向应用所有被动效果
	for effect in effects:
		if effect.has("is_passive") and effect.is_passive:
			_remove_effect(effect)

# 应用效果
func _apply_effect(effect: Dictionary, context: Dictionary = {}) -> void:
	# 根据效果类型应用不同效果
	if effect.has("type"):
		match effect.type:
			"stat_boost":
				# 属性提升效果
				_apply_stat_boost(effect, context)

			"damage":
				# 伤害效果
				_apply_damage_effect(effect, context)

			"heal":
				# 治疗效果
				_apply_heal_effect(effect, context)

			"gold":
				# 金币效果
				_apply_gold_effect(effect, context)

			"shop":
				# 商店效果
				_apply_shop_effect(effect, context)

			"synergy":
				# 羁绊效果
				_apply_synergy_effect(effect, context)

			"special":
				# 特殊效果
				_apply_special_effect(effect, context)

# 检查触发条件
func _check_trigger_conditions(trigger_type: String, context: Dictionary) -> bool:
	# 如果没有设置触发条件，默认可以触发
	if not trigger_conditions.has(trigger_type):
		return true

	var conditions = trigger_conditions[trigger_type]

	# 检查每个条件
	for condition in conditions:
		if not _check_single_condition(condition, context):
			return false

	return true

# 检查单个条件
func _check_single_condition(condition: Dictionary, context: Dictionary) -> bool:
	# 根据条件类型进行检查
	if condition.has("type"):
		match condition.type:
			"health_below":
				# 生命值低于阈值
				if not context.has("player") or not context.player.has("health"):
					return false
				return context.player.health < condition.value

			"gold_above":
				# 金币高于阈值
				if not context.has("player") or not context.player.has("gold"):
					return false
				return context.player.gold > condition.value

			"synergy_active":
				# 羁绊激活
				if not context.has("synergies"):
					return false
				return context.synergies.has(condition.value)

			"round_number":
				# 回合数
				if not context.has("round"):
					return false
				return context.round == condition.value

			"chance":
				# 概率触发
				return randf() < condition.value

	return true

# 应用属性提升效果
func _apply_stat_boost(effect: Dictionary, context: Dictionary = {}) -> void:
	if not context.has("target"):
		return

	var target = context.target

	if effect.has("stats"):
		var stats = effect.stats

		# 应用属性提升
		for stat_name in stats:
			var value = stats[stat_name]

			match stat_name:
				"health":
					target.max_health += value
					target.current_health += value
				"attack_damage":
					target.attack_damage += value
				"attack_speed":
					target.attack_speed += value
				"armor":
					target.armor += value
				"magic_resist":
					target.magic_resist += value
				"spell_power":
					target.spell_power += value
				"crit_chance":
					target.crit_chance += value
				"crit_damage":
					target.crit_damage += value
				"dodge_chance":
					target.dodge_chance += value

# 应用伤害效果
func _apply_damage_effect(effect: Dictionary, context: Dictionary = {}) -> void:
	if not context.has("target"):
		return

	var target = context.target
	var damage = effect.value
	var damage_type = effect.get("damage_type", "physical")

	target.take_damage(damage, damage_type, self)

# 应用治疗效果
func _apply_heal_effect(effect: Dictionary, context: Dictionary = {}) -> void:
	if not context.has("target"):
		return

	var target = context.target
	var heal_amount = effect.value

	target.heal(heal_amount, self)

# 应用金币效果
func _apply_gold_effect(effect: Dictionary, context: Dictionary = {}) -> void:
	if not context.has("player"):
		return

	var player = context.player
	var gold_amount = effect.value

	if effect.has("operation") and effect.operation == "subtract":
		player.remove_gold(gold_amount)
	else:
		player.add_gold(gold_amount)

# 应用商店效果
func _apply_shop_effect(effect: Dictionary, _context: Dictionary = {}) -> void:
	var shop_manager = get_node("/root/GameManager/ShopManager")

	if effect.has("operation"):
		match effect.operation:
			"refresh":
				shop_manager.refresh_shop(true)  # 免费刷新
			"discount":
				shop_manager.apply_discount(effect.value)
			"add_item":
				if effect.has("item_id"):
					shop_manager.add_specific_item(effect.item_id)

# 应用羁绊效果
func _apply_synergy_effect(effect: Dictionary, _context: Dictionary = {}) -> void:
	var synergy_manager = get_node("/root/GameManager/SynergyManager")

	if effect.has("operation"):
		match effect.operation:
			"add_level":
				synergy_manager.add_synergy_level(effect.synergy_id, effect.value)
			"activate":
				synergy_manager.force_activate_synergy(effect.synergy_id)

# 应用特殊效果
func _apply_special_effect(effect: Dictionary, context: Dictionary = {}) -> void:
	# 特殊效果需要在子类中实现
	pass

# 移除效果
func _remove_effect(effect: Dictionary, context: Dictionary = {}) -> void:
	# 根据效果类型移除不同效果
	if effect.has("type"):
		match effect.type:
			"stat_boost":
				# 属性提升效果
				_remove_stat_boost(effect, context)

			"shop":
				# 商店效果
				_remove_shop_effect(effect, context)

			"synergy":
				# 羁绊效果
				_remove_synergy_effect(effect, context)

			"special":
				# 特殊效果
				_remove_special_effect(effect, context)

# 移除属性提升效果
func _remove_stat_boost(effect: Dictionary, context: Dictionary = {}) -> void:
	if not context.has("target"):
		# 如果没有指定目标，使用拥有者
		if owner_player == null:
			return
		context["target"] = owner_player

	var target = context.target

	if effect.has("stats"):
		var stats = effect.stats

		# 移除属性提升
		for stat_name in stats:
			var value = stats[stat_name]

			match stat_name:
				"health":
					target.max_health -= value
					target.current_health = min(target.current_health, target.max_health)
				"attack_damage":
					target.attack_damage -= value
				"attack_speed":
					target.attack_speed -= value
				"armor":
					target.armor -= value
				"magic_resist":
					target.magic_resist -= value
				"spell_power":
					target.spell_power -= value
				"crit_chance":
					target.crit_chance -= value
				"crit_damage":
					target.crit_damage -= value
				"dodge_chance":
					target.dodge_chance -= value

# 移除商店效果
func _remove_shop_effect(effect: Dictionary, _context: Dictionary = {}) -> void:
	var shop_manager = get_node("/root/GameManager/ShopManager")

	if effect.has("operation"):
		match effect.operation:
			"discount":
				# 恢复原始折扣
				shop_manager.apply_discount(1.0)

# 移除羁绊效果
func _remove_synergy_effect(effect: Dictionary, _context: Dictionary = {}) -> void:
	var synergy_manager = get_node("/root/GameManager/SynergyManager")

	if effect.has("operation"):
		match effect.operation:
			"add_level":
				synergy_manager.remove_synergy_level(effect.synergy_id, effect.value)
			"activate":
				synergy_manager.deactivate_forced_synergy(effect.synergy_id)

# 移除特殊效果
func _remove_special_effect(effect: Dictionary, context: Dictionary = {}) -> void:
	# 特殊效果需要在子类中实现
	pass

# 初始化视觉组件
func _initialize_visuals() -> void:
	visual_effect = Node2D.new()
	add_child(visual_effect)

# 更新视觉效果
func _update_visuals() -> void:
	# 更新图标
	var sprite = $Sprite2D
	if icon:
		sprite.texture = icon

	# 设置图标颜色
	var color = Color.WHITE
	match rarity:
		0: # 普通
			color = Color(0.8, 0.8, 0.8, 1.0)
		1: # 稀有
			color = Color(0.2, 0.6, 1.0, 1.0)
		2: # 史诗
			color = Color(0.8, 0.4, 1.0, 1.0)
		3: # 传说
			color = Color(1.0, 0.8, 0.2, 1.0)

	sprite.modulate = color

	# 设置名称
	var name_label = $NameLabel
	name_label.text = display_name

	# 设置描述
	var desc_label = $DescriptionLabel
	desc_label.text = description

	# 添加效果
	if is_active:
		_add_active_effect()
	else:
		_remove_active_effect()

# 添加激活效果
func _add_active_effect() -> void:
	# 清除现有效果
	for child in $EffectContainer.get_children():
		child.queue_free()

	# 创建效果
	var effect = ColorRect.new()
	effect.color = Color(1.0, 1.0, 1.0, 0.3)
	effect.custom_minimum_size = Vector2(60, 60)
	effect.position = Vector2(-30, -30)
	$EffectContainer.add_child(effect)

	# 添加动画效果
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0.5), 0.8)
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0.2), 0.8)

# 移除激活效果
func _remove_active_effect() -> void:
	# 清除现有效果
	for child in $EffectContainer.get_children():
		child.queue_free()

# 获取遗物信息
func get_info() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"description": description,
		"rarity": rarity,
		"is_active": is_active,
		"cooldown": cooldown,
		"current_cooldown": current_cooldown,
		"charges": charges,
		"is_passive": is_passive
	}

# 获取遗物效果描述
func get_effect_description() -> String:
	var desc = ""

	for effect in effects:
		if effect.has("description"):
			desc += effect.description + "\n"

	return desc.strip_edges()
