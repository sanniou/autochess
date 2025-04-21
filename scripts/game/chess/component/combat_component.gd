extends Component
class_name CombatComponent
## 战斗组件
## 处理棋子的战斗相关功能，如伤害、治疗等

# 信号
signal damage_dealt(target, amount, damage_type, is_critical)
signal damage_taken(source, amount, damage_type, is_critical)
signal healing_done(target, amount)
signal healing_received(source, amount)
signal dodge_successful(attacker)
signal critical_hit(target, damage)
signal elemental_effect_triggered(target, element_type)

# 战斗属性
var attack_timer: float = 0.0  # 攻击计时器
var elemental_type: String = ""  # 元素类型

# 初始化
func _init(p_owner = null, p_name: String = "CombatComponent"):
	super._init(p_owner, p_name)
	priority = 70  # 高优先级，确保战斗在目标之后更新

# 造成伤害
func deal_damage(target, amount: float, damage_type: String = "physical", is_critical: bool = false) -> float:
	if not _is_valid_target(target):
		return 0.0

	# 获取目标的战斗组件
	var target_combat_component = null
	if target.has_method("get_component"):
		target_combat_component = target.get_component("CombatComponent")

	# 如果目标有战斗组件，使用它来处理伤害
	if target_combat_component:
		var _actual_damage = target_combat_component.take_damage(owner, amount, damage_type, is_critical)

		# 发送伤害信号
		damage_dealt.emit(target, _actual_damage, damage_type, is_critical)

		# 发送暴击信号
		if is_critical:
			critical_hit.emit(target, _actual_damage)

		# 处理生命偷取
		_process_lifesteal(_actual_damage)

		# 处理元素效果
		_process_elemental_effect(target)

		return _actual_damage

	# 如果目标没有战斗组件，使用传统方式处理伤害
	var actual_damage = amount

	# 应用护甲或魔抗
	var target_armor = 0.0
	var target_magic_resist = 0.0

	if target.has_method("get_component"):
		var target_attribute_component = target.get_component("AttributeComponent")
		if target_attribute_component:
			target_armor = target_attribute_component.get_attribute("armor")
			target_magic_resist = target_attribute_component.get_attribute("magic_resist")
	elif target.has("armor") and target.has("magic_resist"):
		target_armor = target.armor
		target_magic_resist = target.magic_resist

	if damage_type == "physical":
		actual_damage *= (100.0 / (100.0 + target_armor))
	elif damage_type == "magical":
		actual_damage *= (100.0 / (100.0 + target_magic_resist))

	# 减少目标生命值
	if target.has_method("get_component"):
		var target_attribute_component = target.get_component("AttributeComponent")
		if target_attribute_component:
			target_attribute_component.reduce_health(actual_damage)
	elif target.has_method("take_damage"):
		target.take_damage(actual_damage, damage_type, owner)
	elif target.has("current_health"):
		target.current_health -= actual_damage

	# 发送伤害信号
	damage_dealt.emit(target, actual_damage, damage_type, is_critical)

	# 发送暴击信号
	if is_critical:
		critical_hit.emit(target, actual_damage)

	# 处理生命偷取
	_process_lifesteal(actual_damage)

	# 处理元素效果
	_process_elemental_effect(target)

	return actual_damage

# 受到伤害
func take_damage(source, amount: float, damage_type: String = "physical", is_critical: bool = false) -> float:
	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return 0.0

	# 检查是否死亡
	if attribute_component.is_dead():
		return 0.0

	# 检查闪避
	var dodge_chance = attribute_component.get_attribute("dodge_chance")
	if randf() < dodge_chance:
		# 触发闪避效果
		dodge_successful.emit(source)

		# 发送事件
		EventBus.chess.emit_event("chess_piece_dodged", [owner, source])

		return 0.0

	# 计算实际伤害
	var actual_damage = amount

	# 应用护甲或魔抗
	var armor = attribute_component.get_attribute("armor")
	var magic_resist = attribute_component.get_attribute("magic_resist")

	if damage_type == "physical":
		actual_damage *= (100.0 / (100.0 + armor))
	elif damage_type == "magical":
		actual_damage *= (100.0 / (100.0 + magic_resist))

	# 应用伤害减免
	var damage_reduction = attribute_component.get_attribute("damage_reduction")
	actual_damage *= (1.0 - damage_reduction)

	# 减少生命值
	attribute_component.reduce_health(actual_damage)

	# 发送伤害信号
	damage_taken.emit(source, actual_damage, damage_type, is_critical)

	# 发送事件
	EventBus.chess.emit_event("chess_piece_damaged", [owner, source, actual_damage, damage_type, is_critical])
	EventBus.battle.emit_event("damage_dealt", [source, owner, actual_damage, damage_type, is_critical])

	# 检查是否死亡
	if attribute_component.is_dead():
		# 切换到死亡状态
		var state_component = owner.get_component("StateComponent")
		if state_component:
			state_component.change_state(state_component.ChessState.DEAD)

	return actual_damage

# 治疗目标
func heal_target(target, amount: float) -> float:
	if not _is_valid_target(target):
		return 0.0

	# 获取目标的战斗组件
	var target_combat_component = null
	if target.has_method("get_component"):
		target_combat_component = target.get_component("CombatComponent")

	# 如果目标有战斗组件，使用它来处理治疗
	if target_combat_component:
		var _actual_damage = target_combat_component.receive_healing(owner, amount)

		# 发送治疗信号
		healing_done.emit(target, _actual_damage)

		return _actual_damage

	# 如果目标没有战斗组件，使用传统方式处理治疗
	var actual_healing = amount

	# 增加目标生命值
	if target.has_method("get_component"):
		var target_attribute_component = target.get_component("AttributeComponent")
		if target_attribute_component:
			target_attribute_component.add_health(actual_healing)
	elif target.has_method("heal"):
		target.heal(actual_healing, owner)
	elif target.has("current_health") and target.has("max_health"):
		target.current_health = min(target.current_health + actual_healing, target.max_health)

	# 发送治疗信号
	healing_done.emit(target, actual_healing)

	return actual_healing

# 接收治疗
func receive_healing(source, amount: float) -> float:
	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return 0.0

	# 检查是否死亡
	if attribute_component.is_dead():
		return 0.0

	# 计算实际治疗量
	var actual_healing = amount

	# 应用治疗加成
	var healing_bonus = attribute_component.get_attribute("healing_bonus")
	actual_healing *= (1.0 + healing_bonus)

	# 增加生命值
	attribute_component.add_health(actual_healing)

	# 发送治疗信号
	healing_received.emit(source, actual_healing)

	# 发送事件
	EventBus.chess.emit_event("chess_piece_healed", [owner, source, actual_healing])
	EventBus.battle.emit_event("heal_received", [source, owner, actual_healing])

	return actual_healing

# 处理生命偷取
func _process_lifesteal(damage_amount: float) -> void:
	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return

	# 获取生命偷取值
	var lifesteal = attribute_component.get_attribute("lifesteal")
	if lifesteal <= 0:
		return

	# 计算回复量
	var heal_amount = damage_amount * lifesteal

	# 回复生命值
	attribute_component.add_health(heal_amount)

	# 发送治疗信号
	healing_received.emit(owner, heal_amount)

	# 发送事件
	EventBus.chess.emit_event("chess_piece_healed", [owner, owner, heal_amount])

# 处理元素效果
func _process_elemental_effect(target) -> void:
	if elemental_type.is_empty():
		return

	# 获取属性组件
	var attribute_component = owner.get_component("AttributeComponent")
	if not attribute_component:
		return

	# 获取元素效果触发几率
	var elemental_effect_chance = attribute_component.get_attribute("elemental_effect_chance")
	if elemental_effect_chance <= 0:
		return

	# 检查是否触发元素效果
	if randf() >= elemental_effect_chance:
		return

	# 获取战斗管理器
	var battle_manager = GameManager.get_manager("BattleManager")
	if not battle_manager:
		return

	# 根据元素类型应用不同效果
	match elemental_type:
		"fire":
			# 火元素：持续伤害
			battle_manager.apply_dot_effect(owner, target, 0, 10.0, 3.0, "magical")
		"ice":
			# 冰元素：减速和冰冻
			var target_state_component = null
			if target.has_method("get_component"):
				target_state_component = target.get_component("StateComponent")

			if target_state_component:
				target_state_component.set_frozen(true)

			# 添加减速效果
			var target_attribute_component = null
			if target.has_method("get_component"):
				target_attribute_component = target.get_component("AttributeComponent")

			if target_attribute_component:
				target_attribute_component.add_attribute_modifier("move_speed", {
					"value": -0.3,
					"type": "percent_add",
					"duration": 3.0,
					"source": owner
				})
		"lightning":
			# 闪电元素：眩晕
			var target_state_component = null
			if target.has_method("get_component"):
				target_state_component = target.get_component("StateComponent")

			if target_state_component:
				target_state_component.set_stunned(true)

				# 延迟解除眩晕
				# 使用 owner 创建定时器
				if owner and owner is Node:
					var timer = owner.get_tree().create_timer(1.0)
					await timer.timeout

					if is_instance_valid(target) and target.has_method("get_component"):
						target_state_component = target.get_component("StateComponent")
						if target_state_component:
							target_state_component.set_stunned(false)
				else:
					# 如果无法创建定时器，使用其他方式处理
					# 可以通过事件总线或其他方式实现
					EventBus.battle.emit_event("delayed_stun_removal", [target, 1.0])
		"poison":
			# 毒元素：持续伤害和减益
			battle_manager.apply_dot_effect(owner, target, 1, 5.0, 5.0, "magical")

			# 添加减益效果
			var target_attribute_component = null
			if target.has_method("get_component"):
				target_attribute_component = target.get_component("AttributeComponent")

			if target_attribute_component:
				target_attribute_component.add_attribute_modifier("attack_damage", {
					"value": -0.15,
					"type": "percent_add",
					"duration": 5.0,
					"source": owner
				})

	# 发送元素效果触发信号
	elemental_effect_triggered.emit(target, elemental_type)

	# 发送事件
	EventBus.chess.emit_event("chess_piece_elemental_effect_triggered", [owner, target, elemental_type])

# 设置元素类型
func set_elemental_type(type: String) -> void:
	elemental_type = type

# 获取元素类型
func get_elemental_type() -> String:
	return elemental_type

# 检查目标是否有效
func _is_valid_target(target) -> bool:
	if target == null:
		return false

	if not is_instance_valid(target):
		return false

	# 检查目标是否死亡
	var state_component = null
	if target.has_method("get_component"):
		state_component = target.get_component("StateComponent")

	if state_component and state_component.is_in_state(state_component.ChessState.DEAD):
		return false

	return true
