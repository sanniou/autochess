extends RefCounted
class_name BattleEvents
## 战斗事件类型
## 定义与战斗相关的事件

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
	func get_type() -> String:
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
		event.source = source
		return event

## 战斗结束事件
class BattleEndedEvent extends BusEvent:
	## 战斗ID
	var battle_id: String
	
	## 是否胜利
	var is_victory: bool
	
	## 战斗时长（秒）
	var duration: float
	
	## 剩余棋子
	var remaining_pieces: Array
	
	## 初始化
	func _init(p_battle_id: String, p_is_victory: bool, p_duration: float, p_remaining_pieces: Array):
		battle_id = p_battle_id
		is_victory = p_is_victory
		duration = p_duration
		remaining_pieces = p_remaining_pieces
	
	## 获取事件类型
	func get_type() -> String:
		return "battle.ended"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "BattleEndedEvent[battle_id=%s, is_victory=%s, duration=%.2f, remaining_pieces=%d]" % [
			battle_id, is_victory, duration, remaining_pieces.size()
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = BattleEndedEvent.new(battle_id, is_victory, duration, remaining_pieces.duplicate())
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 回合开始事件
class RoundStartedEvent extends BusEvent:
	## 回合数
	var round: int
	
	## 初始化
	func _init(p_round: int):
		round = p_round
	
	## 获取事件类型
	func get_type() -> String:
		return "battle.round_started"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RoundStartedEvent[round=%d]" % [round]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = RoundStartedEvent.new(round)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

## 回合结束事件
class RoundEndedEvent extends BusEvent:
	## 回合数
	var round: int
	
	## 初始化
	func _init(p_round: int):
		round = p_round
	
	## 获取事件类型
	func get_type() -> String:
		return "battle.round_ended"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "RoundEndedEvent[round=%d]" % [round]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = RoundEndedEvent.new(round)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
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
	func get_type() -> String:
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
		event.source = source
		return event

## 治疗事件
class HealReceivedEvent extends BusEvent:
	## 治疗来源
	var source_entity
	
	## 治疗目标
	var target_entity
	
	## 治疗数值
	var amount: float
	
	## 初始化
	func _init(p_source_entity, p_target_entity, p_amount: float):
		source_entity = p_source_entity
		target_entity = p_target_entity
		amount = p_amount
	
	## 获取事件类型
	func get_type() -> String:
		return "battle.heal_received"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "HealReceivedEvent[source=%s, target=%s, amount=%.1f]" % [
			source_entity, target_entity, amount
		]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = HealReceivedEvent.new(source_entity, target_entity, amount)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
		return event

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
	func get_type() -> String:
		return "battle.unit_died"
	
	## 获取事件的字符串表示
	func _to_string() -> String:
		return "UnitDiedEvent[unit=%s, killer=%s]" % [unit, killer]
	
	## 克隆事件
	func clone() ->BusEvent:
		var event = UnitDiedEvent.new(unit, killer)
		event.timestamp = timestamp
		event.canceled = canceled
		event.source = source
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
	func get_type() -> String:
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
		event.source = source
		return event

class OpponentSelectedEvent extends BusEvent:
	var current_opponent: Player
	## 初始化
	
	func _init(current_opponent: Player):
		self.current_opponent = current_opponent
