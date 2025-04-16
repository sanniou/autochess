extends Node
class_name AttackSystem
## 攻击系统
## 处理棋子之间的攻击逻辑和伤害计算

# 伤害类型
enum DamageType {
	PHYSICAL,  # 物理伤害
	MAGICAL,   # 魔法伤害
	TRUE,      # 真实伤害
	PURE,      # 纯净伤害（无视所有减伤效果）
	FIRE,      # 火焰伤害（附带燃烧效果）
	ICE,       # 冰冻伤害（附带减速效果）
	LIGHTNING, # 闪电伤害（附带连锁效果）
	POISON     # 毒素伤害（附带持续伤害效果）
}

# 攻击效果
enum AttackEffect {
	NONE,      # 无特殊效果
	CRIT,      # 暴击
	DODGE,     # 闪避
	BLOCK,     # 格挡
	LIFESTEAL, # 吸血
	STUN,      # 眩晕
	SILENCE,   # 沉默
	SLOW,      # 减速
	DISARM,    # 缴械
	TAUNT      # 嘲讽
}

# 状态效果
class StatusEffect:
	var type: String        # 状态类型
	var duration: float     # 持续时间
	var value: float = 0.0  # 效果值
	var source = null       # 效果来源
	var id: String = ""     # 唯一标识符

	func _init(effect_type: String, effect_duration: float, effect_value: float = 0.0, effect_source = null):
		type = effect_type
		duration = effect_duration
		value = effect_value
		source = effect_source
		id = "effect_" + str(randi()) + "_" + effect_type  # 生成唯一ID

# 引用
@onready var board_manager = get_node("/root/GameManager/BoardManager")

# 初始化
func _ready():
	# 连接信号
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)

# 处理攻击
func process_attack(attacker: ChessPiece, defender: ChessPiece) -> Dictionary:
	# 检查攻击者和防御者是否有效
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return {}

	# 检查是否可以攻击
	if not can_attack(attacker, defender):
		return {}

	# 计算伤害
	var damage_result = calculate_damage(attacker, defender)

	# 应用伤害
	apply_damage(attacker, defender, damage_result)

	# 返回攻击结果
	return damage_result

# 检查是否可以攻击
func can_attack(attacker: ChessPiece, defender: ChessPiece) -> bool:
	# 检查攻击者和防御者状态
	if attacker.current_state == ChessPiece.ChessState.DEAD or defender.current_state == ChessPiece.ChessState.DEAD:
		return false

	# 检查攻击者是否在攻击冷却中
	if attacker.attack_timer > 0:
		return false

	# 检查攻击距离
	var attacker_cell = board_manager._find_cell_with_piece(attacker)
	var defender_cell = board_manager._find_cell_with_piece(defender)

	if not attacker_cell or not defender_cell:
		return false

	var distance = Vector2(attacker_cell.grid_position).distance_to(Vector2(defender_cell.grid_position))
	if distance > attacker.attack_range:
		return false

	return true

# 计算伤害
func calculate_damage(attacker: ChessPiece, defender: ChessPiece, damage_type: int = DamageType.PHYSICAL, base_damage: float = -1) -> Dictionary:
	var result = {
		"attacker": attacker,
		"defender": defender,
		"base_damage": base_damage if base_damage >= 0 else attacker.attack_damage,
		"final_damage": 0,
		"damage_type": damage_type,
		"effect": AttackEffect.NONE,
		"is_hit": true,
		"status_effects": []
	}

	# 检查闪避（只有物理攻击可以被闪避）
	if damage_type == DamageType.PHYSICAL and randf() < defender.dodge_chance:
		result.is_hit = false
		result.effect = AttackEffect.DODGE
		result.final_damage = 0
		return result

	# 计算基础伤害
	var damage = result.base_damage

	# 检查暴击（只有物理攻击可以暴击）
	if damage_type == DamageType.PHYSICAL and randf() < attacker.crit_chance:
		damage *= attacker.crit_damage
		result.effect = AttackEffect.CRIT

	# 应用护甲和魔抗减免
	if damage_type == DamageType.PHYSICAL:
		damage *= (100.0 / (100.0 + defender.armor))
	elif damage_type == DamageType.MAGICAL:
		damage *= (100.0 / (100.0 + defender.magic_resist))
	elif damage_type == DamageType.FIRE:
		# 火焰伤害受魔抗影响，并添加燃烧状态
		damage *= (100.0 / (100.0 + defender.magic_resist * 0.7))
		result.status_effects.append(StatusEffect.new("burning", 3.0, damage * 0.1, attacker))
	elif damage_type == DamageType.ICE:
		# 冰冻伤害受魔抗影响，并添加减速状态
		damage *= (100.0 / (100.0 + defender.magic_resist * 0.7))
		result.status_effects.append(StatusEffect.new("slowed", 2.0, 0.3, attacker))
	elif damage_type == DamageType.LIGHTNING:
		# 闪电伤害受魔抗影响，并有概率添加眩晕状态
		damage *= (100.0 / (100.0 + defender.magic_resist * 0.6))
		if randf() < 0.2:  # 20%概率眩晕
			result.status_effects.append(StatusEffect.new("stunned", 1.0, 0, attacker))
	elif damage_type == DamageType.POISON:
		# 毒素伤害受魔抗影响，并添加中毒状态
		damage *= (100.0 / (100.0 + defender.magic_resist * 0.5))
		result.status_effects.append(StatusEffect.new("poisoned", 4.0, damage * 0.05, attacker))

	# 应用伤害加成
	if attacker.has("damage_bonus"):
		damage *= (1.0 + attacker.damage_bonus)

	# 应用伤害减免（真实伤害和纯净伤害不受影响）
	if damage_type != DamageType.TRUE and damage_type != DamageType.PURE:
		if defender.has("damage_reduction"):
			damage *= (1.0 - defender.damage_reduction)

	# 检查格挡
	if defender.has("block_chance") and randf() < defender.block_chance:
		damage *= 0.5  # 格挡减免50%伤害
		result.effect = AttackEffect.BLOCK

	# 最终伤害不能小于1
	result.final_damage = max(1, round(damage))

	# 检查吸血效果
	if attacker.has("lifesteal") and attacker.lifesteal > 0:
		var heal_amount = result.final_damage * attacker.lifesteal
		attacker.heal(heal_amount, attacker)
		result.effect = AttackEffect.LIFESTEAL

	return result

# 应用伤害
func apply_damage(attacker: ChessPiece, defender: ChessPiece, damage_result: Dictionary) -> void:
	# 如果未命中，不造成伤害
	if not damage_result.is_hit:
		# 触发闪避效果
		_trigger_dodge_effects(defender, attacker)
		return

	# 确定伤害类型字符串
	var damage_type_str = "physical"
	match damage_result.damage_type:
		DamageType.MAGICAL: damage_type_str = "magical"
		DamageType.TRUE: damage_type_str = "true"
		DamageType.PURE: damage_type_str = "pure"
		DamageType.FIRE: damage_type_str = "fire"
		DamageType.ICE: damage_type_str = "ice"
		DamageType.LIGHTNING: damage_type_str = "lightning"
		DamageType.POISON: damage_type_str = "poison"

	# 造成伤害
	var actual_damage = defender.take_damage(damage_result.final_damage, damage_type_str, attacker)

	# 更新伤害结果
	damage_result.final_damage = actual_damage

	# 应用状态效果
	_apply_status_effects(defender, damage_result.status_effects)

	# 触发攻击效果
	_trigger_attack_effects(attacker, defender, damage_result)

	# 触发受伤效果
	_trigger_damage_effects(defender, attacker, damage_result)

	# 检查是否死亡
	if defender.current_health <= 0:
		defender.die()

	# 攻击者获得法力值
	attacker.gain_mana(10)

	# 防御者获得法力值 (基于受到的伤害)
	defender.gain_mana(actual_damage * 0.1)

	# 重置攻击计时器
	attacker.attack_timer = 1.0 / attacker.attack_speed

	# 发送伤害事件
	EventBus.damage_dealt.emit(attacker, defender, actual_damage, damage_type_str)

# 触发攻击效果
func _trigger_attack_effects(attacker: ChessPiece, defender: ChessPiece, damage_result: Dictionary) -> void:
	# 处理攻击者的效果
	for effect in attacker.active_effects:
		if effect.has("trigger") and effect.trigger == "on_attack":
			# 触发几率检查
			if not effect.has("chance") or randf() < effect.chance:
				_apply_effect(effect, attacker, defender)

# 触发受伤效果
func _trigger_damage_effects(defender: ChessPiece, attacker: ChessPiece, damage_result: Dictionary) -> void:
	# 处理防御者的效果
	for effect in defender.active_effects:
		if effect.has("trigger") and effect.trigger == "on_damaged":
			# 触发几率检查
			if not effect.has("chance") or randf() < effect.chance:
				_apply_effect(effect, defender, attacker)

# 触发闪避效果
func _trigger_dodge_effects(defender: ChessPiece, attacker: ChessPiece) -> void:
	# 处理防御者的效果
	for effect in defender.active_effects:
		if effect.has("trigger") and effect.trigger == "on_dodge":
			# 触发几率检查
			if not effect.has("chance") or randf() < effect.chance:
				_apply_effect(effect, defender, attacker)

# 应用状态效果
func _apply_status_effects(target: ChessPiece, effects: Array) -> void:
	# 检查目标是否有状态效果管理器
	if not target.status_effect_manager:
		return

	# 应用所有状态效果
	for effect in effects:
		# 根据状态类型创建相应的状态效果
		var status_effect_type = StatusEffectManager.StatusEffectType.BUFF  # 默认为增益效果

		# 根据状态类型设置相应的状态效果类型
		match effect.type:
			"stunned":
				status_effect_type = StatusEffectManager.StatusEffectType.STUN
			"silenced":
				status_effect_type = StatusEffectManager.StatusEffectType.SILENCE
			"slowed":
				status_effect_type = StatusEffectManager.StatusEffectType.SLOW
			"disarmed":
				status_effect_type = StatusEffectManager.StatusEffectType.DISARM
			"taunt":
				status_effect_type = StatusEffectManager.StatusEffectType.TAUNT
			"burning":
				status_effect_type = StatusEffectManager.StatusEffectType.BURNING
			"poisoned":
				status_effect_type = StatusEffectManager.StatusEffectType.POISONED
			"frozen":
				status_effect_type = StatusEffectManager.StatusEffectType.FROZEN
			"bleeding":
				status_effect_type = StatusEffectManager.StatusEffectType.BLEEDING

		# 创建状态效果对象
		var status_effect = StatusEffectManager.StatusEffect.new(
			effect.id,
			status_effect_type,
			effect.type.capitalize(),  # 使用首字母大写的状态类型作为名称
			"",  # 描述留空
			effect.duration,
			effect.value,
			effect.source,
			"",  # 图标留空
			false  # 不可叠加
		)

		# 添加到状态效果管理器
		target.status_effect_manager.add_effect(status_effect)

# 应用效果
func _apply_effect(effect: Dictionary, source: ChessPiece, target: ChessPiece) -> void:
	# 根据效果类型应用不同效果
	if effect.has("type"):
		match effect.type:
			"damage":
				# 额外伤害
				if effect.has("value"):
					var damage_type = effect.get("damage_type", "physical")
					target.take_damage(effect.value, damage_type, source)

			"heal":
				# 治疗效果
				if effect.has("value"):
					source.heal(effect.value)

			"stun":
				# 眩晕效果
				if effect.has("duration") and target.status_effect_manager:
					var stun_effect = StatusEffectManager.StatusEffect.new(
						"stun_" + str(randi()),
						StatusEffectManager.StatusEffectType.STUN,
						"Stun",
						"Cannot act",
						effect.duration,
						0.0,
						source
					)
					target.status_effect_manager.add_effect(stun_effect)

			"silence":
				# 沉默效果
				if effect.has("duration") and target.status_effect_manager:
					var silence_effect = StatusEffectManager.StatusEffect.new(
						"silence_" + str(randi()),
						StatusEffectManager.StatusEffectType.SILENCE,
						"Silence",
						"Cannot use abilities",
						effect.duration,
						0.0,
						source
					)
					target.status_effect_manager.add_effect(silence_effect)

			"slow":
				# 减速效果
				if effect.has("value") and effect.has("duration") and target.status_effect_manager:
					var slow_effect = StatusEffectManager.StatusEffect.new(
						"slow_" + str(randi()),
						StatusEffectManager.StatusEffectType.SLOW,
						"Slow",
						"Movement and attack speed reduced",
						effect.duration,
						effect.value,
						source
					)
					target.status_effect_manager.add_effect(slow_effect)

			"disarm":
				# 缴械效果
				if effect.has("duration") and target.status_effect_manager:
					var disarm_effect = StatusEffectManager.StatusEffect.new(
						"disarm_" + str(randi()),
						StatusEffectManager.StatusEffectType.DISARM,
						"Disarm",
						"Cannot attack",
						effect.duration,
						0.0,
						source
					)
					target.status_effect_manager.add_effect(disarm_effect)

			"taunt":
				# 嘲讽效果
				if effect.has("duration") and target.status_effect_manager:
					var taunt_effect = StatusEffectManager.StatusEffect.new(
						"taunt_" + str(randi()),
						StatusEffectManager.StatusEffectType.TAUNT,
						"Taunt",
						"Forced to attack source",
						effect.duration,
						0.0,
						source
					)
					target.status_effect_manager.add_effect(taunt_effect)

# 战斗开始事件处理
func _on_battle_started() -> void:
	# 重置所有棋子的攻击计时器
	var all_pieces = board_manager.pieces
	for piece in all_pieces:
		piece.attack_timer = 0

# 战斗结束事件处理
func _on_battle_ended(_result) -> void:
	# 清理战斗相关状态
	pass
