extends Node
class_name BattleEngine
## 战斗引擎
## 战斗系统的核心，负责战斗流程控制和状态管理

# 引入战斗常量
const BC = preload("res://scripts/game/battle/battle_constants.gd")

# 信号
signal battle_state_changed(old_state, new_state)
signal battle_phase_changed(old_phase, new_phase)
signal battle_round_started(round_number)
signal battle_round_ended(round_number)
signal battle_ended(result)
signal battle_command_executed(command)
signal battle_event_triggered(event_type, data)

# 战斗配置
var config = {
	"prepare_time": BC.DEFAULT_PREPARE_TIME,       # 准备时间(秒)
	"combat_time": BC.DEFAULT_BATTLE_TIME,        # 战斗时间(秒)
	"resolution_time": BC.DEFAULT_RESOLUTION_TIME,     # 结算时间(秒)
	"default_battle_speed": BC.DEFAULT_BATTLE_SPEED # 默认战斗速度
}

# 战斗状态
var current_state: int = BC.BattleState.INACTIVE
var current_phase: int = BC.BattlePhase.SETUP
var current_round: int = 0
var battle_timer: float = 0.0
var battle_speed: float = BC.DEFAULT_BATTLE_SPEED
var is_player_turn: bool = true

# AI更新计时器
var ai_update_timer: float = 0.0

# 事件计数器
var event_counters: Dictionary = {}

# 战斗参与者
var player_units: Array = []
var enemy_units: Array = []

# 战斗命令队列
var command_queue: Array = []
var executing_command: bool = false
var max_commands_per_frame: int = 5  # 每帧处理的最大命令数
var command_batch_timer: float = 0.0  # 命令批处理计时器
var command_batch_interval: float = 0.05  # 命令批处理间隔

# 战斗事件历史
var event_history: Array = []

# 战斗结果
var battle_result: Dictionary = {}

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

# 引用
var battle_manager: BattleManager = null
var board_manager = null
var effect_manager = null
var ai_controller = null

# 初始化
func _init(battle_mgr: BattleManager):
	battle_manager = battle_mgr

	# 获取其他管理器引用
	board_manager = battle_manager.get_manager("BoardManager")
	effect_manager = battle_manager.get_manager("EffectManager")

	# 设置默认战斗速度
	battle_speed = config.default_battle_speed

# 处理过程
func _process(delta: float) -> void:
	if current_state != BattleConstants.BattleState.ACTIVE:
		return

	# 更新战斗计时器
	battle_timer -= delta
	battle_stats.battle_duration += delta

	# 执行命令队列
	_process_command_queue(delta)

	# 更新当前阶段
	match current_phase:
		BattleConstants.BattlePhase.PREPARE:
			_update_prepare_phase(delta)
		BattleConstants.BattlePhase.COMBAT:
			_update_combat_phase(delta)
		BattleConstants.BattlePhase.RESOLUTION:
			_update_resolution_phase(delta)

# 开始战斗
func start_battle(player_team: Array = [], enemy_team: Array = []) -> void:
	# 设置战斗状态
	_change_state(BC.BattleState.PREPARING)
	_change_phase(BC.BattlePhase.SETUP)

	# 设置战斗参与者
	player_units = player_team
	enemy_units = enemy_team

	# 设置单位阵营
	for unit in player_units:
		unit.is_player_unit = true
		unit.add_to_group("player_units")

	for unit in enemy_units:
		unit.is_player_unit = false
		unit.add_to_group("enemy_units")

	# 重置战斗统计
	_reset_battle_stats()

	# 初始化AI控制器
	var difficulty = battle_manager.difficulty
	ai_controller = BattleAIController.new(self, board_manager, difficulty)
	add_child(ai_controller)

	# 触发战斗开始事件
	_trigger_battle_event("battle_started", {
		"player_units": player_units,
		"enemy_units": enemy_units,
		"round": current_round
	})

	# 开始准备阶段
	_start_prepare_phase()

# 暂停战斗
func pause_battle() -> void:
	if current_state == BC.BattleState.ACTIVE:
		_change_state(BC.BattleState.PAUSED)

		# 暂停所有单位动画
		for unit in player_units + enemy_units:
			if unit.has_method("pause_animations"):
				unit.pause_animations()

		# 触发战斗暂停事件
		_trigger_battle_event("battle_paused", {})

# 恢复战斗
func resume_battle() -> void:
	if current_state == BC.BattleState.PAUSED:
		_change_state(BC.BattleState.ACTIVE)

		# 恢复所有单位动画
		for unit in player_units + enemy_units:
			if unit.has_method("resume_animations"):
				unit.resume_animations()

		# 触发战斗恢复事件
		_trigger_battle_event("battle_resumed", {})

# 结束战斗
func end_battle(victory: bool) -> void:
	if current_state == BC.BattleState.ENDED:
		return

	# 设置战斗状态
	_change_state(BC.BattleState.ENDED)

	# 计算战斗结果
	battle_result = _calculate_battle_result(victory)

	# 触发战斗结束事件
	_trigger_battle_event("battle_ended", battle_result)

	# 发送战斗结束信号
	battle_ended.emit(battle_result)

# 设置战斗速度
func set_battle_speed(speed: float) -> void:
	# 限制速度范围
	battle_speed = clamp(speed, BC.MIN_BATTLE_SPEED, BC.MAX_BATTLE_SPEED)

	# 应用速度到单位
	for unit in player_units + enemy_units:
		if unit.has_method("set_animation_speed"):
			unit.set_animation_speed(battle_speed)

	# 触发战斗速度变化事件
	_trigger_battle_event("battle_speed_changed", {"speed": battle_speed})

# 添加战斗命令
func add_command(command: BattleCommand) -> void:
	command_queue.append(command)

# 清空命令队列
func clear_command_queue() -> void:
	command_queue.clear()
	executing_command = false

# 获取战斗状态
func get_battle_state() -> int:
	return current_state

# 获取战斗阶段
func get_battle_phase() -> int:
	return current_phase

# 获取战斗统计
func get_battle_stats() -> Dictionary:
	return battle_stats

# 获取战斗结果
func get_battle_result() -> Dictionary:
	return battle_result

# 获取战斗事件历史
func get_event_history() -> Array:
	return event_history

# 获取剩余时间
func get_remaining_time() -> float:
	return battle_timer

# 获取当前回合
func get_current_round() -> int:
	return current_round

# 检查战斗是否结束
func is_battle_ended() -> bool:
	return _check_battle_end_condition()

# 更新准备阶段
func _update_prepare_phase(delta: float) -> void:
	# 检查准备时间是否结束
	if battle_timer <= 0:
		_start_combat_phase()
		return

# 更新战斗阶段
func _update_combat_phase(delta: float) -> void:
	# 检查战斗是否结束
	if _check_battle_end_condition():
		var victory = _calculate_victory_condition()
		end_battle(victory)
		return

	# 检查战斗时间是否结束
	if battle_timer <= 0:
		var victory = _calculate_victory_condition()
		end_battle(victory)
		return

	# 应用战斗速度
	var adjusted_delta = delta * battle_speed

	# 使用帧率控制AI更新
	# 每秒更新AI的次数与战斗速度成正比
	ai_update_timer += adjusted_delta

	# 根据战斗速度调整AI更新间隔
	var ai_update_interval = 0.2 / battle_speed  # 战斗速度越快，更新间隔越短

	# 当达到更新间隔时更新AI
	if ai_update_timer >= ai_update_interval:
		ai_update_timer = 0.0

		# 更新AI控制器
		if ai_controller:
			ai_controller.update(adjusted_delta, enemy_units)

# 更新结算阶段
func _update_resolution_phase(delta: float) -> void:
	# 检查结算时间是否结束
	if battle_timer <= 0:
		_start_cleanup_phase()
		return

# 开始准备阶段
func _start_prepare_phase() -> void:
	# 设置战斗阶段
	_change_phase(BC.BattlePhase.PREPARE)

	# 设置准备时间
	battle_timer = config.prepare_time

	# 设置战斗状态
	_change_state(BC.BattleState.ACTIVE)

	# 触发准备阶段开始事件
	_trigger_battle_event("prepare_phase_started", {
		"time": battle_timer,
		"round": current_round
	})

	# 发送准备阶段开始信号
	battle_phase_changed.emit(BattleConstants.BattlePhase.SETUP, BattleConstants.BattlePhase.PREPARE)

# 开始战斗阶段
func _start_combat_phase() -> void:
	# 设置战斗阶段
	_change_phase(BC.BattlePhase.COMBAT)

	# 设置战斗时间
	battle_timer = config.combat_time

	# 增加回合数
	current_round += 1

	# 触发战斗阶段开始事件
	_trigger_battle_event("combat_phase_started", {
		"time": battle_timer,
		"round": current_round
	})

	# 发送战斗阶段开始信号
	battle_phase_changed.emit(BattleConstants.BattlePhase.PREPARE, BattleConstants.BattlePhase.COMBAT)
	battle_round_started.emit(current_round)

	# 激活所有单位
	_activate_all_units()

# 开始结算阶段
func _start_resolution_phase() -> void:
	# 设置战斗阶段
	_change_phase(BC.BattlePhase.RESOLUTION)

	# 设置结算时间
	battle_timer = config.resolution_time

	# 触发结算阶段开始事件
	_trigger_battle_event("resolution_phase_started", {
		"time": battle_timer,
		"round": current_round
	})

	# 发送结算阶段开始信号
	battle_phase_changed.emit(BattleConstants.BattlePhase.COMBAT, BattleConstants.BattlePhase.RESOLUTION)
	battle_round_ended.emit(current_round)

# 开始清理阶段
func _start_cleanup_phase() -> void:
	# 设置战斗阶段
	_change_phase(BC.BattlePhase.CLEANUP)

	# 清理战斗效果
	_cleanup_battle_effects()

	# 触发清理阶段开始事件
	_trigger_battle_event("cleanup_phase_started", {
		"round": current_round
	})

	# 发送清理阶段开始信号
	battle_phase_changed.emit(BattleConstants.BattlePhase.RESOLUTION, BattleConstants.BattlePhase.CLEANUP)

	# 开始下一回合准备阶段
	_start_prepare_phase()

# 激活所有单位
func _activate_all_units() -> void:
	# 激活所有羁绊效果
	var synergy_manager = battle_manager.get_manager("SynergyManager")
	if synergy_manager:
		synergy_manager._update_synergies()

	# 设置所有单位为战斗状态
	for unit in player_units + enemy_units:
		# 重置单位的控制效果状态
		unit.is_silenced = false
		unit.is_disarmed = false
		unit.is_frozen = false
		unit.taunted_by = null

		# 清除所有效果
		if effect_manager:
			effect_manager.remove_all_effects_from_target(unit)

		# 切换到空闲状态
		unit.state_machine.change_state("idle")

# 清理战斗效果
func _cleanup_battle_effects() -> void:
	# 清理所有战斗效果
	if effect_manager:
		effect_manager.remove_all_battle_effects()

	# 重置所有单位状态
	for unit in player_units + enemy_units:
		if unit.current_state != unit.ChessState.DEAD:
			unit.reset_battle_state()

# 处理命令队列
func _process_command_queue(delta: float) -> void:
	# 更新命令批处理计时器
	command_batch_timer += delta

	# 如果没有达到批处理间隔，返回
	if command_batch_timer < command_batch_interval:
		return

	# 重置批处理计时器
	command_batch_timer = 0.0

	# 如果正在执行命令，等待完成
	if executing_command:
		return

	# 如果命令队列为空，返回
	if command_queue.is_empty():
		return

	# 批量处理命令
	var commands_processed = 0
	while not command_queue.is_empty() and commands_processed < max_commands_per_frame:
		# 获取下一个命令
		var command = command_queue.pop_front()

		# 执行命令
		executing_command = true
		var result = command.execute()

		# 记录命令执行
		_record_command_execution(command, result)

		# 发送命令执行信号
		battle_command_executed.emit(command)

		# 标记命令执行完成
		executing_command = false

		# 增加已处理命令计数
		commands_processed += 1

# 记录命令执行
func _record_command_execution(command: BattleCommand, result: Dictionary) -> void:
	# 添加到事件历史
	event_history.append({
		"type": "command_executed",
		"command": command.get_command_type(),
		"source": command.get_source(),
		"target": command.get_target(),
		"result": result,
		"timestamp": Time.get_ticks_msec()
	})

# 触发战斗事件
func _trigger_battle_event(event_type: String, data: Dictionary) -> void:
	# 优化：跳过高频率事件
	var high_frequency_events = ["damage_dealt", "dot_damage", "healing_done"]

	# 如果是高频率事件，使用频率控制
	if event_type in high_frequency_events:
		# 使用类级别计数器进行频率控制
		if not event_counters.has(event_type):
			event_counters[event_type] = 0

		event_counters[event_type] += 1

		# 每间5次事件只记录和发送一次
		if event_counters[event_type] % 5 != 0:
			# 只发送信号，不记录历史和发送事件总线
			battle_event_triggered.emit(event_type, data)
			return

	# 添加时间戳
	data["timestamp"] = Time.get_ticks_msec()

	# 添加到事件历史
	# 优化：限制事件历史大小
	while event_history.size() >= 100:
		event_history.pop_front()

	event_history.append({
		"type": event_type,
		"data": data
	})

	# 发送事件信号
	battle_event_triggered.emit(event_type, data)

	# 发送到事件总线
	GlobalEventBus.battle.dispatch_event(BattleEvents.BattleTypeEvent.new(event_type,data))

# 改变战斗状态
func _change_state(new_state: int) -> void:
	if new_state == current_state:
		return

	var old_state = current_state
	current_state = new_state

	# 发送状态变化信号
	battle_state_changed.emit(old_state, new_state)

	# 触发状态变化事件
	_trigger_battle_event("battle_state_changed", {
		"old_state": old_state,
		"new_state": new_state
	})

# 改变战斗阶段
func _change_phase(new_phase: int) -> void:
	if new_phase == current_phase:
		return

	var old_phase = current_phase
	current_phase = new_phase

	# 发送阶段变化信号
	battle_phase_changed.emit(old_phase, new_phase)

	# 触发阶段变化事件
	_trigger_battle_event("battle_phase_changed", {
		"old_phase": old_phase,
		"new_phase": new_phase
	})

# 检查战斗结束条件
func _check_battle_end_condition() -> bool:
	# 更新单位列表
	player_units = board_manager.get_ally_pieces(true)
	enemy_units = board_manager.get_enemy_pieces(true)

	return player_units.is_empty() or enemy_units.is_empty()

# 计算胜利条件
func _calculate_victory_condition() -> bool:
	# 如果敌方单位全部死亡，玩家胜利
	if enemy_units.is_empty():
		return true

	# 如果玩家单位全部死亡，玩家失败
	if player_units.is_empty():
		return false

	# 如果时间结束，比较双方剩余单位数量
	if battle_timer <= 0:
		return player_units.size() >= enemy_units.size()

	return false

# 计算战斗结果
func _calculate_battle_result(victory: bool) -> Dictionary:
	# 创建战斗结果
	var result = {
		"victory": victory,
		"round": current_round,
		"duration": battle_stats.battle_duration,
		"player_units": {
			"initial": player_units.size() + battle_stats.enemy_kills,
			"remaining": player_units.size()
		},
		"enemy_units": {
			"initial": enemy_units.size() + battle_stats.player_kills,
			"remaining": enemy_units.size()
		},
		"stats": battle_stats,
		"rewards": _calculate_battle_rewards(victory)
	}

	return result

# 计算战斗奖励
func _calculate_battle_rewards(victory: bool) -> Dictionary:
	# 基础奖励
	var rewards = {
		"gold": 0,
		"exp": 0,
		"items": []
	}

	# 如果胜利，给予奖励
	if victory:
		# 基础金币奖励
		rewards.gold = 10 + current_round * 2

		# 基础经验奖励
		rewards.exp = 5 + current_round

		# 根据难度和回合数调整奖励
		var difficulty_multiplier = 1.0 + (battle_manager.difficulty * 0.1)
		rewards.gold = int(rewards.gold * difficulty_multiplier)
		rewards.exp = int(rewards.exp * difficulty_multiplier)

		# 随机物品奖励
		# TODO: 实现物品奖励逻辑

	return rewards

# 重置战斗统计
func _reset_battle_stats() -> void:
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

	# 重置事件计数器
	event_counters.clear()

	# 重置AI更新计时器
	ai_update_timer = 0.0

# 单位死亡事件处理
func _on_unit_died(unit) -> void:
	# 更新战斗统计
	if unit.is_player_unit:
		# 玩家单位死亡
		player_units.erase(unit)
		battle_stats.enemy_kills += 1
	else:
		# 敌方单位死亡
		enemy_units.erase(unit)
		battle_stats.player_kills += 1

	# 触发单位死亡事件
	_trigger_battle_event("unit_died", {
		"unit": unit,
		"is_player_unit": unit.is_player_unit
	})

	# 检查战斗是否结束
	if _check_battle_end_condition():
		var victory = _calculate_victory_condition()
		end_battle(victory)

# 伤害事件处理
func _on_damage_dealt(source, target, amount: float, damage_type: String) -> void:
	# 更新战斗统计
	if source and source.is_player_unit:
		# 玩家造成伤害
		battle_stats.player_damage_dealt += amount
	else:
		if source:
			# 敌方造成伤害
			battle_stats.enemy_damage_dealt += amount

	# 触发伤害事件
	_trigger_battle_event("damage_dealt", {
		"source": source,
		"target": target,
		"amount": amount,
		"damage_type": damage_type
	})

# 治疗事件处理
func _on_healing_done(source, target, amount: float) -> void:
	# 更新战斗统计
	if target and target.is_player_unit:
		# 玩家受到治疗
		battle_stats.player_healing += amount
	else:
		if target:
			# 敌方受到治疗
			battle_stats.enemy_healing += amount

	# 触发治疗事件
	_trigger_battle_event("healing_done", {
		"source": source,
		"target": target,
		"amount": amount
	})

# 技能使用事件处理
func _on_ability_used(source, ability_id: String, targets: Array) -> void:
	# 更新战斗统计
	battle_stats.abilities_used += 1

	# 触发技能使用事件
	_trigger_battle_event("ability_used", {
		"source": source,
		"ability_id": ability_id,
		"targets": targets
	})
