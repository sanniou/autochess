extends RefCounted
class_name BattleEvents
## 战斗事件类型
## 定义与战斗相关的事件


class BattleRoundEndedEvent extends BusEvent:

	## 回合数
	var round: int

	func _init(p_round: int):
		round=p_round

	## 获取事件类型
	static func get_type() -> String:
		return "battle.battle_round_ended"

class BattleRoundStartedEvent extends BusEvent:

	## 回合数
	var round: int

	func _init(p_round: int):
		round=p_round

	## 获取事件类型
	static func get_type() -> String:
		return "battle.battle_round_started"

## 战斗开始事件
class BattleStartedEvent extends BusEvent:
	## 战斗ID
	var battle_id: String

	## 回合数
	var round: int

	## 玩家棋子
	var player_pieces: Array

	## 敌人棋子
	var enemy_pieces: Array

	## 初始化
	func _init(p_battle_id: String, p_round: int, p_player_pieces: Array, p_enemy_pieces: Array):
		battle_id = p_battle_id
		round = p_round
		player_pieces = p_player_pieces
		enemy_pieces = p_enemy_pieces

	## 获取事件类型
	static func get_type() -> String:
		return "battle.started"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BattleStartedEvent[battle_id=%s, round=%d, player_pieces=%d, enemy_pieces=%d]" % [
			battle_id, round, player_pieces.size(), enemy_pieces.size()
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = BattleStartedEvent.new(battle_id, round, player_pieces.duplicate(), enemy_pieces.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 战斗结束事件
class BattleEndedEvent extends BusEvent:
	### 战斗ID
	#var battle_id: String
	#
	### 是否胜利
	#var is_victory: bool
	#
	### 战斗时长（秒）
	#var duration: float
	#
	### 剩余棋子
	#var remaining_pieces: Array

	var result

	## 初始化
	func _init(p_result):
		result = p_result

	static func get_type() -> String:
		return "battle.battle_endded"

## 回合开始事件
class RoundStartedEvent extends BusEvent:
	## 回合数
	var round: int

	## 初始化
	func _init(p_round: int):
		round = p_round

	## 获取事件类型
	static func get_type() -> String:
		return "battle.round_started"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RoundStartedEvent[round=%d]" % [round]

	## 克隆事件
	func clone() ->BusEvent:
		var event = RoundStartedEvent.new(round)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 回合结束事件
class RoundEndedEvent extends BusEvent:
	## 回合数
	var round: int

	## 初始化
	func _init(p_round: int):
		round = p_round

	## 获取事件类型
	static func get_type() -> String:
		return "battle.round_ended"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RoundEndedEvent[round=%d]" % [round]

	## 克隆事件
	func clone() ->BusEvent:
		var event = RoundEndedEvent.new(round)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 伤害事件
class DamageDealtEvent extends BusEvent:
	## 伤害来源
	var source_entity

	## 伤害目标
	var target_entity

	## 伤害数值
	var amount: float

	## 伤害类型
	var damage_type: String

	## 是否暴击
	var is_critical: bool

	## 初始化
	func _init(p_source_entity, p_target_entity, p_amount: float, p_damage_type: String, p_is_critical: bool = false):
		source_entity = p_source_entity
		target_entity = p_target_entity
		amount = p_amount
		damage_type = p_damage_type
		is_critical = p_is_critical

	## 获取事件类型
	static func get_type() -> String:
		return "battle.damage_dealt"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "DamageDealtEvent[source=%s, target=%s, amount=%.1f, type=%s, critical=%s]" % [
			source_entity, target_entity, amount, damage_type, is_critical
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = DamageDealtEvent.new(source_entity, target_entity, amount, damage_type, is_critical)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 治疗事件
class HealReceivedEvent extends BusEvent:
	## 治疗来源
	var source_entity

	## 治疗目标
	var target_entity

	## 治疗数值
	var amount: float

	## 是否暴击
	var is_critical: bool

	## 初始化
	func _init(p_source_entity, p_target_entity, p_amount: float,p_is_critical: bool):
		source_entity = p_source_entity
		target_entity = p_target_entity
		amount = p_amount
		is_critical = p_is_critical

	## 获取事件类型
	static func get_type() -> String:
		return "battle.heal_received"

class MovementStartedEvent extends BusEvent:
	var target
	var movement_type
	var distance
	var direction
	var initial_position
	## 初始化
	func _init(source,target, movement_type, distance,direction,initial_position):
		self.source=source
		self.target=target
		self.movement_type=movement_type
		self.distance=distance
		self.direction=direction
		self.initial_position=initial_position

	## 获取事件类型
	static func get_type() -> String:
		return "battle.movement_started"


class MovementEndedEvent extends BusEvent:
	var target
	var movement_type
	var moved_distance
	var final_position
	## 初始化
	func _init(source,target,movement_type,moved_distance,final_position):
		self.source=source
		self.target=target
		self.movement_type=movement_type
		self.moved_distance=moved_distance
		self.final_position=final_position

	## 获取事件类型
	static func get_type() -> String:
		return "battle.movement_ended"

class TeleportCompletedEvent extends BusEvent:
	var target
	var from
	var to
	## 初始化
	func _init(source,target,from,to):
		self.source=source
		self.target=target
		self.from=from
		self.to=to

	## 获取事件类型
	static func get_type() -> String:
		return "battle.teleport_completed"

class SwapCompletedEvent extends BusEvent:
	var target
	var source_from
	var source_to
	var target_from
	var target_to
	## 初始化
	func _init(source,target,source_from,source_to,target_from,target_to):
		self.source=source
		self.target=target
		self.source_from=source_from
		self.source_to=source_to
		self.target_from=target_from
		self.target_to=target_to

	## 获取事件类型
	static func get_type() -> String:
		return "battle.swap_completed"


## 单位死亡事件
class UnitDiedEvent extends BusEvent:
	## 死亡单位
	var unit

	## 击杀者
	var killer

	## 初始化
	func _init(p_unit, p_killer = null):
		unit = p_unit
		killer = p_killer

	## 获取事件类型
	static func get_type() -> String:
		return "battle.unit_died"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "UnitDiedEvent[unit=%s, killer=%s]" % [unit, killer]

	## 克隆事件
	func clone() ->BusEvent:
		var event = UnitDiedEvent.new(unit, killer)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 技能使用事件
class AbilityUsedEvent extends BusEvent:
	## 使用者
	var caster

	## 技能数据
	var ability_data: Dictionary

	## 目标
	var targets: Array

	## 初始化
	func _init(p_caster, p_ability_data: Dictionary, p_targets: Array = []):
		caster = p_caster
		ability_data = p_ability_data
		targets = p_targets

	## 获取事件类型
	static func get_type() -> String:
		return "battle.ability_used"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AbilityUsedEvent[caster=%s, ability=%s, targets=%d]" % [
			caster, ability_data.get("name", "unknown"), targets.size()
		]

	## 克隆事件
	func clone() ->BusEvent:
		var event = AbilityUsedEvent.new(caster, ability_data.duplicate(), targets.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled

		return event

class OpponentSelectedEvent extends BusEvent:
	var current_opponent: Player

	## 初始化
	func _init(current_opponent: Player):
		self.current_opponent = current_opponent

	## 获取事件类型
	static func get_type() -> String:
		return "battle.opponent_selected"

class DelayedStunRemovalEvent extends BusEvent:
	var traget
	var time:float

	func _init(traget , time:float):
		self.traget = traget
		self.time = time

	## 获取事件类型
	static func get_type() -> String:
		return "battle.delayed_stun_removal"

class CriticalHitEvent extends BusEvent:
	var traget
	var amount:float

	func _init(source,traget,amount:float):
		self.source = source
		self.traget = traget
		self.amount = amount

	## 获取事件类型
	static func get_type() -> String:
		return "battle.critical_hit"

class HotHealEvent extends BusEvent:
	var traget
	var amount:float

	func _init(source,traget,amount:float):
		self.source = source
		self.traget = traget
		self.amount = amount

	## 获取事件类型
	static func get_type() -> String:
		return "battle.hot_heal"

class HotDamageEvent extends BusEvent:
	var traget
	var amount:float
	var damage_type
	var dot_type

	func _init(source,traget,amount:float,damage_type,dot_type):
		self.source = source
		self.traget = traget
		self.amount = amount
		self.damage_type = damage_type
		self.dot_type = dot_type

	## 获取事件类型
	static func get_type() -> String:
		return "battle.hot_damage"

class ShieldAddedEvent extends BusEvent:
	var target
	var shield
	var amount
	var shield_type

	func _init(source,traget,shield,amount,shield_type):
		self.source=source
		self.target=target
		self.shield=shield
		self.amount=amount
		self.shield_type=shield_type

	## 获取事件类型
	static func get_type() -> String:
		return "battle.shield_added"

class ShieldRemovedEvent extends BusEvent:
	var target
	var shield
	var remaining
	var shield_type

	func _init(source,traget,shield,remaining,shield_type):
		self.source=source
		self.target=target
		self.shield=shield
		self.remaining=remaining
		self.shield_type=shield_type

	## 获取事件类型
	static func get_type() -> String:
		return "battle.shield_removed"

class ShieldAbsorbedEvent extends BusEvent:
	## 护盾
	var shield

	## 目标
	var target

	## 吸收的伤害值
	var absorbed_damage: float

	## 剩余护盾值
	var remaining_shield: float

	## 伤害类型
	var damage_type: String

	## 初始化
	func _init(p_shield, p_target, p_absorbed_damage: float, p_remaining_shield: float, p_damage_type: String):
		shield = p_shield
		target = p_target
		absorbed_damage = p_absorbed_damage
		remaining_shield = p_remaining_shield
		damage_type = p_damage_type

	## 获取事件类型
	static func get_type() -> String:
		return "battle.shield_absorbed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShieldAbsorbedEvent[shield=%s, target=%s, absorbed=%.1f, remaining=%.1f, type=%s]" % [
			shield, target, absorbed_damage, remaining_shield, damage_type
		]

	## 克隆事件
	func clone() -> BusEvent:
		var event = ShieldAbsorbedEvent.new(shield, target, absorbed_damage, remaining_shield, damage_type)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

class StatModifiedEvent extends BusEvent:
	var target
	var stats:Dictionary
	var is_percentage:bool
	var is_debuff:bool

	func _init(source,traget,stats:Dictionary,is_percentage:bool,is_debuff:bool):
		self.source = source
		self.traget = traget
		self.stats = stats
		self.is_percentage = is_percentage
		self.is_debuff = is_debuff

	## 获取事件类型
	static func get_type() -> String:
		return "battle.stat_modified"

class BattlePreparingPhaseStartdEvent extends BusEvent:
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "battle.preparing_phase_started"

class BattleFightingPhaseStartdEvent extends BusEvent:
	func _init():
		pass

	## 获取事件类型
	static func get_type() -> String:
		return "battle.fighting_phase_started"

class BattleTypeEvent extends BusEvent:
	var event_type: String
	var data: Dictionary
	func _init(event_type: String, data: Dictionary):
		self.event_type=event_type
		self.data=data

	## 获取事件类型
	static func get_type() -> String:
		return "battle.battle_type"

## 护盾反射伤害事件
class ShieldReflectedEvent extends BusEvent:
	## 护盾
	var shield

	## 目标
	var target

	## 伤害来源
	var damage_source

	## 反射伤害值
	var reflect_damage: float

	## 初始化
	func _init(p_shield, p_target, p_damage_source, p_reflect_damage: float):
		shield = p_shield
		target = p_target
		damage_source = p_damage_source
		reflect_damage = p_reflect_damage

	## 获取事件类型
	static func get_type() -> String:
		return "battle.shield_reflected"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShieldReflectedEvent[shield=%s, target=%s, damage_source=%s, reflect_damage=%.1f]" % [
			shield, target, damage_source, reflect_damage
		]

	## 克隆事件
	func clone() -> BusEvent:
		var event = ShieldReflectedEvent.new(shield, target, damage_source, reflect_damage)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 控制效果免疫事件
class ControlImmunityEvent extends BusEvent:
	## 护盾
	var shield

	## 目标
	var target

	## 控制类型
	var control_type: String

	## 初始化
	func _init(p_shield, p_target, p_control_type: String):
		shield = p_shield
		target = p_target
		control_type = p_control_type

	## 获取事件类型
	static func get_type() -> String:
		return "battle.control_immunity"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ControlImmunityEvent[shield=%s, target=%s, control_type=%s]" % [
			shield, target, control_type
		]

	## 克隆事件
	func clone() -> BusEvent:
		var event = ControlImmunityEvent.new(shield, target, control_type)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 光环效果应用事件
class AuraEffectAppliedEvent extends BusEvent:
	## 光环
	var aura

	## 光环来源
	var source

	## 目标
	var target

	## 应用的效果
	var effect

	## 初始化
	func _init(p_aura, p_source, p_target, p_effect):
		aura = p_aura
		source = p_source
		target = p_target
		effect = p_effect

	## 获取事件类型
	static func get_type() -> String:
		return "battle.aura_effect_applied"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AuraEffectAppliedEvent[aura=%s, source=%s, target=%s, effect=%s]" % [
			aura, source, target, effect
		]

	## 克隆事件
	func clone() -> BusEvent:
		var event = AuraEffectAppliedEvent.new(aura, source, target, effect)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 光环效果移除事件
class AuraEffectRemovedEvent extends BusEvent:
	## 光环
	var aura

	## 光环来源
	var source

	## 目标
	var target

	## 初始化
	func _init(p_aura, p_source, p_target):
		aura = p_aura
		source = p_source
		target = p_target

	## 获取事件类型
	static func get_type() -> String:
		return "battle.aura_effect_removed"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AuraEffectRemovedEvent[aura=%s, source=%s, target=%s]" % [
			aura, source, target
		]

	## 克隆事件
	func clone() -> BusEvent:
		var event = AuraEffectRemovedEvent.new(aura, source, target)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 触发效果激活事件
class TriggerEffectActivatedEvent extends BusEvent:
	## 触发器
	var trigger

	## 来源
	var source

	## 目标
	var target

	## 触发的效果
	var effect

	## 触发次数
	var trigger_count: int

	## 初始化
	func _init(p_trigger, p_source, p_target, p_effect, p_trigger_count: int):
		trigger = p_trigger
		source = p_source
		target = p_target
		effect = p_effect
		trigger_count = p_trigger_count

	## 获取事件类型
	static func get_type() -> String:
		return "battle.trigger_effect_activated"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "TriggerEffectActivatedEvent[trigger=%s, source=%s, target=%s, effect=%s, count=%d]" % [
			trigger, source, target, effect, trigger_count
		]

	## 克隆事件
	func clone() -> BusEvent:
		var event = TriggerEffectActivatedEvent.new(trigger, source, target, effect, trigger_count)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 攻击闪避事件
class AttackDodgedEvent extends BusEvent:
	## 攻击来源
	var source

	## 闪避目标
	var target

	## 初始化
	func _init(p_source, p_target):
		source = p_source
		target = p_target

	## 获取事件类型
	static func get_type() -> String:
		return "battle.attack_dodged"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "AttackDodgedEvent[source=%s, target=%s]" % [source, target]

	## 克隆事件
	func clone() -> BusEvent:
		var event = AttackDodgedEvent.new(source, target)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 护盾破碎事件
class ShieldBrokenEvent extends BusEvent:
	## 护盾
	var shield

	## 目标
	var target

	## 初始化
	func _init(p_shield, p_target):
		shield = p_shield
		target = p_target

	## 获取事件类型
	static func get_type() -> String:
		return "battle.shield_broken"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "ShieldBrokenEvent[shield=%s, target=%s]" % [shield, target]

	## 克隆事件
	func clone() -> BusEvent:
		var event = ShieldBrokenEvent.new(shield, target)
		event.timestamp = timestamp
		event.canceled = canceled

		return event

## 状态效果应用事件
class StatusAppliedEvent extends BusEvent:
	## 状态来源
	var source

	## 目标
	var target

	## 状态类型
	var status_type: String

	## 状态数据
	var status_data: Dictionary

	## 初始化
	func _init(p_source, p_target, p_status_type: String, p_status_data: Dictionary = {}):
		source = p_source
		target = p_target
		status_type = p_status_type
		status_data = p_status_data

	## 获取事件类型
	static func get_type() -> String:
		return "battle.status_applied"

	## 获取事件的字符串表示
	func _to_string() -> String:
		return "StatusAppliedEvent[source=%s, target=%s, type=%s]" % [source, target, status_type]

	## 克隆事件
	func clone() -> BusEvent:
		var event = StatusAppliedEvent.new(source, target, status_type, status_data.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled

		return event
