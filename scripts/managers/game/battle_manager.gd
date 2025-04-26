extends "res://scripts/managers/core/base_manager.gd"
class_name BattleManager
## 战斗管理器
## 管理战斗流程和战斗逻辑

# 引入战斗常量
const BC = preload("res://scripts/game/battle/battle_constants.gd")

# 战斗配置
@export var prepare_time: float = BC.DEFAULT_PREPARE_TIME   # 准备时间(秒)
@export var battle_time: float = BC.DEFAULT_BATTLE_TIME    # 战斗时间(秒)
@export var resolution_time: float = BC.DEFAULT_RESOLUTION_TIME # 结算时间(秒)

# 事件定义
const BattleEvents = preload("res://scripts/core/events/types/battle_events.gd")

# 战斗引擎
var battle_engine: BattleEngine = null

# 战斗难度
var difficulty: int = BC.AIDifficulty.NORMAL  # 当前难度

# 战斗统计
var battle_stats = {
	"player_damage_dealt": 0,
	"enemy_damage_dealt": 0,
	"player_healing": 0,
	"enemy_healing": 0,
	"player_kills": 0,
	"enemy_kills": 0,
	"battle_duration": 0,
	"abilities_used": 0
}

# 战斗结果
var battle_result = {}

# 玩家和敌方棋子
var player_pieces = []
var enemy_pieces = []

# 重写初始化方法
func _do_initialize() -> void:
	# 设置管理器名称
	manager_name = "BattleManager"

	# 添加依赖
	add_dependency("BoardManager")
	add_dependency("PlayerManager")
	add_dependency("StatsManager")

	# 连接信号 - 使用规范的事件连接方式和常量
	GlobalEventBus.battle.add_class_listener(BattleEvents.BattleStartedEvent, _on_battle_started)
	GlobalEventBus.battle.add_class_listener(BattleEvents.BattleEndedEvent, _on_battle_ended)
	GlobalEventBus.battle.add_class_listener(BattleEvents.BattlePreparingPhaseStartedEvent, _on_battle_preparing_phase_started)
	GlobalEventBus.battle.add_class_listener(BattleEvents.BattleFightingPhaseStartedEvent, _on_battle_fighting_phase_started)
	GlobalEventBus.battle.add_class_listener(BattleEvents.UnitDiedEvent, _on_unit_died)
	GlobalEventBus.battle.add_class_listener(BattleEvents.DamageDealtEvent, _on_damage_dealt)
	GlobalEventBus.battle.add_class_listener(BattleEvents.HealReceivedEvent, _on_heal_received)
	GlobalEventBus.battle.add_class_listener(BattleEvents.AbilityUsedEvent, _on_ability_used)
	GlobalEventBus.battle.add_class_listener(BattleEvents.DelayedStunRemovalEvent, _on_delayed_stun_removal)

	_log_info("战斗管理器初始化完成")

func _process(delta):
	# 如果战斗引擎存在，让它处理战斗逻辑
	# 战斗引擎已经处理了所有逻辑，我们只需要更新战斗统计
	if battle_engine:
		_update_battle_stats()

# 开始战斗
func start_battle(player_team: Array = [], enemy_team: Array = []):
	set_process(true)

	# 创建战斗引擎
	battle_engine = BattleEngine.new(self)
	add_child(battle_engine)

	# 连接战斗引擎信号
	_connect_battle_engine_signals()

	# 设置战斗引擎配置
	_configure_battle_engine()

	# 使用战斗引擎开始战斗
	battle_engine.start_battle(player_team, enemy_team)

	_log_info("使用战斗引擎开始战斗")

# 连接战斗引擎信号
func _connect_battle_engine_signals() -> void:
	battle_engine.battle_state_changed.connect(_on_battle_engine_state_changed)
	battle_engine.battle_phase_changed.connect(_on_battle_engine_phase_changed)
	battle_engine.battle_round_started.connect(_on_battle_engine_round_started)
	battle_engine.battle_round_ended.connect(_on_battle_engine_round_ended)
	battle_engine.battle_ended.connect(_on_battle_engine_ended)
	battle_engine.battle_command_executed.connect(_on_battle_engine_command_executed)
	battle_engine.battle_event_triggered.connect(_on_battle_engine_event_triggered)

# 配置战斗引擎
func _configure_battle_engine() -> void:
	battle_engine.config.prepare_time = prepare_time
	battle_engine.config.combat_time = battle_time
	battle_engine.config.resolution_time = resolution_time

# 结束战斗
func end_battle(victory: bool = false):
	# 使用战斗引擎结束战斗
	battle_engine.end_battle(victory)
	_log_info("战斗结束，胜利：" + str(victory))

# 更新战斗统计
func _update_battle_stats() -> void:
	# 如果战斗引擎存在，从战斗引擎获取最新的战斗统计
	var engine_stats = battle_engine.get_battle_stats()
	battle_stats.player_damage_dealt = engine_stats.player_damage_dealt
	battle_stats.enemy_damage_dealt = engine_stats.enemy_damage_dealt
	battle_stats.player_healing = engine_stats.player_healing
	battle_stats.enemy_healing = engine_stats.enemy_healing
	battle_stats.player_kills = engine_stats.player_kills
	battle_stats.enemy_kills = engine_stats.enemy_kills
	battle_stats.battle_duration = engine_stats.battle_duration
	battle_stats.abilities_used = engine_stats.abilities_used

# 战斗阶段开始事件处理
func _on_battle_fighting_phase_started(event:BattleEvents.BattleFightingPhaseStartedEvent):
	_log_info("Battle fighting phase started")

# 重置战斗统计
func _reset_battle_stats():
	battle_stats = {
		"player_damage_dealt": 0,
		"enemy_damage_dealt": 0,
		"player_healing": 0,
		"enemy_healing": 0,
		"player_kills": 0,
		"enemy_kills": 0,
		"battle_duration": 0,
		"abilities_used": 0
	}

# 战斗开始事件处理
func _on_battle_started(event:BattleEvents.BattleStartedEvent):
	_log_info("Battle started event received")

	# 通知 GameEffectManager 战斗开始
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.on_battle_started()

# 准备阶段开始事件处理
func _on_battle_preparing_phase_started(event:BattleEvents.BattlePreparingPhaseStartedEvent):
	_log_info("Battle preparing phase started")

# 战斗结束事件处理
func _on_battle_ended(event:BattleEvents.BattleEndedEvent):
	print("Battle ended with result: ", event.result)

	# 通知 GameEffectManager 战斗结束
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.on_battle_ended(event.result)

	# 处理战斗奖励
	_process_battle_rewards(event.result)

# 设置战斗速度
func set_battle_speed(speed: float) -> void:
	battle_engine.set_battle_speed(speed)
	_log_info("战斗速度设置为：" + str(speed))

# 棋子死亡事件处理
func _on_unit_died(event:BattleEvents.UnitDiedEvent):
	# 更新战斗统计
	if event.piece.is_player_piece:
		battle_stats.enemy_kills += 1
	else:
		battle_stats.player_kills += 1

# 延迟解除眩晕事件处理
func _on_delayed_stun_removal(target, duration: float) -> void:
	# 创建定时器
	var timer = get_tree().create_timer(duration)
	await timer.timeout

	# 检查目标是否仍然有效
	if is_instance_valid(target) and target.has_method("get_component"):
		var target_state_component = target.get_component("StateComponent")
		if target_state_component:
			target_state_component.set_stunned(false)
		else:
			# 如果使用新的状态机组件
			var state_machine_component = target.get_component("StateMachineComponent")
			if state_machine_component:
				state_machine_component.set_stunned(false)

# 清理战场
func _cleanup_battle():
	# 清理战斗引擎

	# 断开所有信号连接
	battle_engine.battle_state_changed.disconnect(_on_battle_engine_state_changed)
	battle_engine.battle_phase_changed.disconnect(_on_battle_engine_phase_changed)
	battle_engine.battle_round_started.disconnect(_on_battle_engine_round_started)
	battle_engine.battle_round_ended.disconnect(_on_battle_engine_round_ended)
	battle_engine.battle_ended.disconnect(_on_battle_engine_ended)
	battle_engine.battle_command_executed.disconnect(_on_battle_engine_command_executed)
	battle_engine.battle_event_triggered.disconnect(_on_battle_engine_event_triggered)
	# 清理战斗引擎
	battle_engine.queue_free()
	battle_engine = null

	# 清空数组
	player_pieces.clear()
	enemy_pieces.clear()

	# 清理所有效果
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.clear_all_effects()
		_log_info("清理所有效果")

	_log_info("战场清理完成")

# 重写清理方法
func _do_cleanup() -> void:
	# 断开事件连接
	GlobalEventBus.battle.remove_class_listener(BattleEvents.BattleStartedEvent, _on_battle_started)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.BattleEndedEvent, _on_battle_ended)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.BattlePreparingPhaseStartedEvent, _on_battle_preparing_phase_started)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.BattleFightingPhaseStartedEvent, _on_battle_fighting_phase_started)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.UnitDiedEvent, _on_unit_died)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.DamageDealtEvent, _on_damage_dealt)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.HealReceivedEvent, _on_heal_received)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.AbilityUsedEvent, _on_ability_used)
	GlobalEventBus.battle.remove_class_listener(BattleEvents.DelayedStunRemovalEvent, _on_delayed_stun_removal)

	_log_info("战斗管理器清理完成")

# 新效果系统方法

# 应用效果
func apply_effect(effect_data: Dictionary, source = null, target = null) -> GameEffect:
	# 检查目标是否有效
	if not target or not is_instance_valid(target):
		_log_warning("无法应用效果: 目标无效")
		return null

	# 使用新的游戏效果管理器应用效果
	if GameManager and GameManager.game_effect_manager:
		var effect = GameManager.game_effect_manager.apply_effect(effect_data, source, target)
		if effect:
			_log_info("应用效果成功: " + effect.name + " 到 " + (target.name if target and target.has_method("get_name") else "未知目标"))
		else:
			_log_warning("应用效果失败: " + str(effect_data))
		return effect

	_log_error("无法应用效果: GameEffectManager 不可用")
	return null

# 移除效果
func remove_effect(effect_id_or_effect) -> bool:
	# 使用新的游戏效果管理器移除效果
	if GameManager and GameManager.game_effect_manager:
		var result = GameManager.game_effect_manager.remove_effect(effect_id_or_effect)
		if result:
			_log_info("移除效果成功: " + str(effect_id_or_effect))
		else:
			_log_warning("移除效果失败: " + str(effect_id_or_effect))
		return result

	_log_error("无法移除效果: GameEffectManager 不可用")
	return false

# 移除目标的所有效果
func remove_all_effects_from_target(target) -> void:
	# 使用新的游戏效果管理器移除目标的所有效果
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.clear_target_effects(target)

# 移除所有战斗效果
func remove_all_battle_effects() -> void:
	# 使用新的游戏效果管理器移除所有效果
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.clear_all_effects()

# 获取目标的所有效果
func get_target_effects(target) -> Array:
	# 使用新的游戏效果管理器获取目标的所有效果
	if GameManager and GameManager.game_effect_manager:
		return GameManager.game_effect_manager.get_target_effects(target)
	return []

# 检查目标是否有指定类型的效果
func has_effect_type(target, effect_type: int) -> bool:
	# 使用新的游戏效果管理器检查目标是否有指定类型的效果
	if GameManager and GameManager.game_effect_manager:
		var effects = GameManager.game_effect_manager.get_target_effects_by_type(target, effect_type)
		return not effects.is_empty()
	return false

# 应用状态效果
func apply_status_effect(source, target, status_type: int, duration: float, params: Dictionary = {}) -> GameEffect:
	# 创建状态效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.STATUS,
		"status_type": status_type,
		"duration": duration,
		"params": params
	}

	# 应用效果
	var effect = apply_effect(effect_data, source, target)
	if effect:
		_log_info("应用状态效果: " + effect.name + " 到 " + (target.name if target and target.has_method("get_name") else "未知目标"))
	return effect

# 应用属性效果
func apply_stat_effect(source, target, stats: Dictionary, duration: float, is_debuff: bool = false, params: Dictionary = {}) -> GameEffect:
	# 创建属性效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.STAT_MOD,
		"stats": stats,
		"duration": duration,
		"is_percentage": params.get("is_percentage", false),
		"params": params
	}

	# 添加标签
	if is_debuff:
		effect_data["tags"] = ["debuff"]
	else:
		effect_data["tags"] = ["buff"]

	# 应用效果
	var effect = apply_effect(effect_data, source, target)
	if effect:
		_log_info("应用属性效果: " + effect.name + " 到 " + (target.name if target and target.has_method("get_name") else "未知目标"))
	return effect

# 应用持续伤害效果
func apply_dot_effect(source, target, dot_type: int, damage_per_second: float, duration: float, damage_type: String = "magical", params: Dictionary = {}) -> GameEffect:
	# 创建持续伤害效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.DOT,
		"dot_type": dot_type,
		"damage_per_second": damage_per_second,
		"duration": duration,
		"damage_type": damage_type,
		"tick_interval": params.get("tick_interval", 1.0),
		"params": params,
		"tags": ["dot", "debuff"]
	}

	# 应用效果
	var effect = apply_effect(effect_data, source, target)
	if effect:
		_log_info("应用持续伤害效果: " + effect.name + " 到 " + (target.name if target and target.has_method("get_name") else "未知目标"))
	return effect

# 应用持续治疗效果
func apply_hot_effect(source, target, hot_type: int, heal_per_second: float, duration: float, params: Dictionary = {}) -> GameEffect:
	# 创建持续治疗效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.HOT,
		"hot_type": hot_type,
		"heal_per_second": heal_per_second,
		"duration": duration,
		"tick_interval": params.get("tick_interval", 1.0),
		"params": params,
		"tags": ["hot", "buff"]
	}

	# 应用效果
	var effect = apply_effect(effect_data, source, target)
	if effect:
		_log_info("应用持续治疗效果: " + effect.name + " 到 " + (target.name if target and target.has_method("get_name") else "未知目标"))
	return effect

# 应用护盾效果
func apply_shield_effect(source, target, shield_type: int, shield_amount: float, duration: float, params: Dictionary = {}) -> GameEffect:
	# 创建护盾效果数据
	var effect_data = {
		"effect_type": GameEffect.EffectType.SHIELD,
		"shield_type": shield_type,
		"shield_amount": shield_amount,
		"duration": duration,
		"damage_reduction": params.get("damage_reduction", 0.0),
		"reflect_percent": params.get("reflect_percent", 0.0),
		"params": params,
		"tags": ["shield", "buff"]
	}

	# 应用效果
	var effect = apply_effect(effect_data, source, target)
	if effect:
		_log_info("应用护盾效果: " + effect.name + " 到 " + (target.name if target and target.has_method("get_name") else "未知目标"))
	return effect

# 应用伤害
func apply_damage(source, target, damage: float, damage_type: String = "magical", is_critical: bool = false, is_dodgeable: bool = true) -> float:
	# 如果战斗引擎存在，使用战斗引擎应用伤害
	return battle_engine.apply_damage(source, target, damage, damage_type, is_critical, is_dodgeable)

# 应用治疗
func apply_heal(source, target, heal_amount: float) -> float:
	# 如果战斗引擎存在，使用战斗引擎应用治疗
	return battle_engine.apply_heal(source, target, heal_amount)

# 创建浮动文本
func create_floating_text(position: Vector2, text: String, color: Color = Color.WHITE) -> void:
	# 如果战斗引擎存在，使用战斗引擎创建浮动文本
	battle_engine.create_floating_text(position, text, color)

# 重写重置方法
func _do_reset() -> void:
	# 重置战斗统计
	_reset_battle_stats()

	# 重置战斗结果
	battle_result.clear()

	# 清理棋子数组
	player_pieces.clear()
	enemy_pieces.clear()

	_log_info("战斗管理器重置完成")

# 伤害事件处理
func _on_damage_dealt(event:BattleEvents.DamageDealtEvent) -> void:
	# 更新战斗统计
	if event.source and event.source.is_player_piece:
		# 玩家造成伤害
		battle_stats.player_damage_dealt += event.amount
	else:
		if event.source:
			# 敌方造成伤害
			battle_stats.enemy_damage_dealt += event.amount

# 治疗事件处理
func _on_heal_received(event:BattleEvents.HealReceivedEvent) -> void:
	# 更新战斗统计
	if event.target and event.target.is_player_piece:
		# 玩家治疗
		battle_stats.player_healing += event.amount
	else:
		if event.target:
			# 敌方治疗
			battle_stats.enemy_healing += event.amount

# 技能使用事件处理
func _on_ability_used(event:BattleEvents.AbilityUsedEvent) -> void:
	# 更新战斗统计
	battle_stats.abilities_used += 1

# 处理战斗奖励
func _process_battle_rewards(result: Dictionary) -> void:
	if not result.has("rewards"):
		return

	var rewards = result.rewards
	var player_manager = get_manager("PlayerManager")
	if player_manager and player_manager.has_method("get_current_player"):
		var player = player_manager.get_current_player()
		if player:
			# 应用金币奖励
			if rewards.has("gold") and rewards.gold > 0:
				var economy_manager = get_manager("EconomyManager")
				if economy_manager:
					economy_manager.add_gold(rewards.gold)
					_log_info("玩家获得金币：" + str(rewards.gold))

			# 应用经验奖励
			if rewards.has("exp") and rewards.exp > 0:
				player.add_exp(rewards.exp)
				_log_info("玩家获得经验：" + str(rewards.exp))

			# 应用物品奖励
			if rewards.has("items") and not rewards.items.is_empty():
				for item in rewards.items:
					if item.type == "equipment":
						var equipment_manager = get_manager("EquipmentManager")
						if equipment_manager:
							var equipment = equipment_manager.create_random_equipment(item.rarity)
							if equipment:
								player.add_equipment(equipment)
								_log_info("玩家获得装备：" + equipment.name)

			# 应用棋子奖励
			if rewards.has("chess_pieces") and not rewards.chess_pieces.is_empty():
				for chess_data in rewards.chess_pieces:
					var chess_manager = get_manager("ChessManager")
					if chess_manager:
						var chess_id = chess_manager.get_random_chess_id(chess_data.rarity)
						if chess_id:
							chess_manager.add_chess_to_player(chess_id)
							_log_info("玩家获得棋子：" + chess_id)

			# 应用遗物奖励
			if rewards.has("relics") and not rewards.relics.is_empty():
				for relic_data in rewards.relics:
					var relic_manager = get_manager("RelicManager")
					if relic_manager:
						var relic = relic_manager.create_relic(relic_data.id)
						if relic:
							player.add_relic(relic)
							_log_info("玩家获得遗物：" + relic.name)

# 战斗引擎事件处理
func _on_battle_engine_state_changed(old_state, new_state):
	# 处理战斗状态变化
	_log_info("战斗状态变化: " + str(old_state) + " -> " + str(new_state))

	# 发送相应的事件
	var event_name
	match new_state:
		BC.BattleState.PREPARING:
			event_name = BattleEvents.BattlePreparingPhaseStartedEvent
		BC.BattleState.ACTIVE:
			event_name = BattleEvents.BattleFightingPhaseStartedEvent
		BC.BattleState.ENDED:
			event_name = BattleEvents.BattleResultPhaseStartedEvent

	GlobalEventBus.battle.dispatch_event(event_name.new())

func _on_battle_engine_phase_changed(old_phase, new_phase):
	# 处理战斗阶段变化
	_log_info("战斗阶段变化: " + str(old_phase) + " -> " + str(new_phase))

	# 发送相应的事件
	var event_name
	match new_phase:
		BC.BattlePhase.PREPARE:
			event_name = BattleEvents.BattlePreparingPhaseStartedEvent
		BC.BattlePhase.COMBAT:
			event_name = BattleEvents.BattleFightingPhaseStartedEvent
		BC.BattlePhase.RESOLUTION:
			event_name = BattleEvents.BattleResultPhaseStartedEvent

	GlobalEventBus.battle.dispatch_event(event_name.new())

func _on_battle_engine_round_started(round_number):
	# 处理战斗回合开始
	_log_info("战斗回合开始: " + str(round_number))

	# 发送回合开始事件
	GlobalEventBus.battle.dispatch_event(BattleEvents.BattleRoundStartedEvent.new(round_number))

func _on_battle_engine_round_ended(round_number):
	# 处理战斗回合结束
	_log_info("战斗回合结束: " + str(round_number))

	# 发送回合结束事件
	GlobalEventBus.battle.dispatch_event(BattleEvents.BattleRoundEndedEvent.new(round_number))

func _on_battle_engine_ended(result):
	# 处理战斗结束
	_log_info("战斗结束: " + str(result.victory))

	# 更新战斗统计
	_update_battle_stats()

	# 更新统计数据
	var stats_manager = GameManager.stats_manager
	if stats_manager:
		stats_manager.increment_stat("battles_played")
		if result.victory:
			stats_manager.increment_stat("battles_won")
		else:
			stats_manager.increment_stat("battles_lost")

		# 更新战斗统计
		stats_manager.increment_stat("total_damage_dealt", battle_stats.player_damage_dealt)
		stats_manager.increment_stat("total_damage_taken", battle_stats.enemy_damage_dealt)
		stats_manager.increment_stat("total_healing", battle_stats.player_healing)

	# 发送战斗结束事件
	GlobalEventBus.battle.dispatch_event(BattleEvents.BattleEndedEvent.new(result))

	# 清理战场
	_cleanup_battle()

func _on_battle_engine_command_executed(command):
	# 处理战斗命令执行
	_log_info("战斗命令执行: " + command.get_description())

func _on_battle_engine_event_triggered(event_type, data):
	# 处理战斗事件触发
	_log_info("战斗事件触发: " + event_type)
