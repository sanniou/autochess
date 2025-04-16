extends Node
class_name BattleManager
## 战斗管理器
## 管理战斗流程和战斗逻辑

# 战斗状态枚举
enum BattleState {
	PREPARE,    # 准备阶段
	BATTLE,     # 战斗阶段
	RESULT      # 结算阶段
}

# 战斗配置
@export var prepare_time: float = 30.0   # 准备时间(秒)
@export var battle_time: float = 90.0    # 战斗时间(秒)

# 战斗数据
var current_state: int = BattleState.PREPARE
var timer: float = 0.0
var is_player_turn: bool = true
var battle_result: Dictionary = {}

# 战斗双方棋子
var player_pieces = []  # 玩家棋子
var enemy_pieces = []   # 敌方棋子

# 战斗计时器
var max_battle_time: float = 90.0  # 最大战斗时间(秒)

# 战斗速度
var battle_speed: float = 1.0  # 战斗速度倍数

# 战斗回合
var current_round: int = 1  # 当前回合

# 战斗难度
var difficulty: int = 1  # 当前难度

# 战斗奖励
var battle_rewards = {}  # 战斗奖励

# AI控制器
var ai_controller: AIController

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
@onready var board_manager: BoardManager = get_node("/root/GameManager/BoardManager")
@onready var synergy_manager: SynergyManager = get_node("/root/GameManager/SynergyManager")

func _ready():
	# 连接信号
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.chess_piece_died.connect(_on_chess_piece_died)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.healing_done.connect(_on_healing_done)
	EventBus.ability_used.connect(_on_ability_used)

func _process(delta):
	match current_state:
		BattleState.PREPARE:
			_update_prepare_phase(delta)
		BattleState.BATTLE:
			_update_battle_phase(delta)
		BattleState.RESULT:
			_update_result_phase(delta)

# 开始战斗
func start_battle(player_team: Array = [], enemy_team: Array = []):
	# 设置战斗状态
	current_state = BattleState.PREPARE
	timer = prepare_time

	# 设置棋子数组
	player_pieces = player_team
	enemy_pieces = enemy_team

	# 设置棋子阵营
	for piece in player_pieces:
		piece.is_player_piece = true
		piece.add_to_group("player_chess_pieces")

	for piece in enemy_pieces:
		piece.is_player_piece = false
		piece.add_to_group("enemy_chess_pieces")

	# 重置棋盘
	board_manager.reset_board()

	# 初始化AI控制器
	ai_controller = AIController.new(self, board_manager, difficulty)

	# 重置战斗统计
	_reset_battle_stats()

	# 发送战斗开始信号
	EventBus.battle_started.emit()

# 结束战斗
func end_battle(victory: bool = false):
	current_state = BattleState.RESULT
	timer = 3.0  # 结算显示时间

	# 计算战斗结果
	_calculate_battle_result(victory)

	# 发送战斗结束信号
	EventBus.battle_ended.emit(battle_result)

	# 清理战场
	_cleanup_battle()

# 更新准备阶段
func _update_prepare_phase(delta):
	timer -= delta
	if timer <= 0:
		current_state = BattleState.BATTLE
		timer = battle_time

		# 开始战斗阶段
		_start_battle_phase()

# 更新战斗阶段
func _update_battle_phase(delta):
	# 应用战斗速度
	var adjusted_delta = delta * battle_speed

	timer -= delta  # 计时器使用原始时间
	battle_stats.battle_duration += delta

	# 检查战斗超时
	if timer <= 0:
		# 超时判负
		end_battle(false)
		return

	# 更新所有棋子状态
	_update_chess_pieces(adjusted_delta)

	# 更新AI控制器
	if ai_controller:
		ai_controller.update(adjusted_delta, enemy_pieces)

	# 检查战斗是否结束
	if _check_battle_end():
		# 计算胜利条件
		var victory = _calculate_victory_condition()
		end_battle(victory)

# 更新结算阶段
func _update_result_phase(delta):
	timer -= delta
	if timer <= 0:
		# 战斗完全结束
		current_state = BattleState.PREPARE

# 开始战斗阶段
func _start_battle_phase():
	# 激活所有羁绊效果
	synergy_manager._update_synergies()

	# 设置所有棋子为战斗状态
	var pieces = board_manager.pieces
	for piece in pieces:
		# 重置棋子的控制效果状态
		piece.is_silenced = false
		piece.is_disarmed = false
		piece.is_frozen = false
		piece.taunted_by = null

		# 清除状态效果管理器中的所有效果
		if piece.status_effect_manager:
			piece.status_effect_manager.clear_all_effects()

		# 切换到空闲状态
		piece.change_state(ChessPiece.ChessState.IDLE)

# 更新棋子状态
func _update_chess_pieces(delta):
	var pieces = board_manager.pieces

	for piece in pieces:
		if piece.current_state == ChessPiece.ChessState.DEAD:
			continue

		# 自动寻找目标
		if piece.current_state == ChessPiece.ChessState.IDLE:
			# 寻找最近的敌人棋子
			var target = _find_nearest_enemy(piece)
			if target:
				piece.set_target(target)

		# 处理移动逻辑
		if piece.current_state == ChessPiece.ChessState.MOVING:
			_process_movement(piece, delta)

		# 处理攻击逻辑
		if piece.current_state == ChessPiece.ChessState.ATTACKING:
			_process_attack(piece, delta)

# 处理移动逻辑
func _process_movement(piece, delta):
	# 检查目标是否有效
	if not piece.target or piece.target.current_state == ChessPiece.ChessState.DEAD:
		piece.clear_target()
		return

	# 检查是否被冰冻
	if piece.is_frozen:
		return

	# 检查是否被嘲讽
	if piece.taunted_by and is_instance_valid(piece.taunted_by) and piece.taunted_by.current_state != ChessPiece.ChessState.DEAD:
		# 如果被嘲讽，强制将嘲讽源设为目标
		if piece.target != piece.taunted_by:
			piece.set_target(piece.taunted_by)

	# 简化版移动逻辑 - 实际项目中需要更复杂的寻路
	var target_pos = piece.target.board_position
	var dir = (Vector2(target_pos) - Vector2(piece.board_position)).normalized()

	# 移动棋子
	piece.position += dir * piece.move_speed * delta

	# 如果有状态效果管理器，处理移动时的效果（如流血）
	if piece.status_effect_manager:
		piece.status_effect_manager.process_movement_effects()

	# 检查是否到达攻击范围
	var distance = piece.position.distance_to(piece.target.position)
	if distance <= piece.attack_range * board_manager.cell_size.x:
		piece.change_state(ChessPiece.ChessState.ATTACKING)

# 处理攻击逻辑
func _process_attack(piece, delta):
	# 检查目标是否有效
	if not piece.target or piece.target.current_state == ChessPiece.ChessState.DEAD:
		piece.clear_target()
		return

	# 检查是否被嘲讽
	if piece.taunted_by and is_instance_valid(piece.taunted_by) and piece.taunted_by.current_state != ChessPiece.ChessState.DEAD:
		# 如果被嘲讽，强制将嘲讽源设为目标
		if piece.target != piece.taunted_by:
			piece.set_target(piece.taunted_by)
			return

	# 检查是否被缴械
	if piece.is_disarmed:
		return

	# 更新攻击计时器
	piece.attack_timer += delta
	if piece.attack_timer >= 1.0 / piece.attack_speed:
		piece.attack_timer = 0
		piece._perform_attack()

# 检查战斗是否结束
func _check_battle_end() -> bool:
	var player_pieces = board_manager.get_ally_pieces(is_player_turn)
	var enemy_pieces = board_manager.get_enemy_pieces(is_player_turn)

	return player_pieces.is_empty() or enemy_pieces.is_empty()

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

# 计算战斗结果
func _calculate_battle_result(victory: bool):
	# 计算奖励
	var rewards = {}
	if victory:
		# 根据难度和回合计算奖励
		var gold_reward = 5 + current_round + difficulty
		var exp_reward = 2 + current_round / 2

		# 根据战斗统计调整奖励
		var performance_bonus = 0

		# 根据玩家造成伤害增加奖励
		if battle_stats.player_damage_dealt > 500:
			performance_bonus += 2

		# 根据玩家击杀数增加奖励
		performance_bonus += battle_stats.player_kills

		# 根据战斗时间调整奖励
		if battle_stats.battle_duration < 30:
			performance_bonus += 3  # 快速胜利奖励

		# 应用效率加成
		gold_reward += performance_bonus
		exp_reward += performance_bonus / 2

		# 添加到奖励中
		rewards["gold"] = gold_reward
		rewards["exp"] = exp_reward

		# 根据难度和回合随机生成装备或棋子
		var equipment_chance = 0.3 + difficulty * 0.1 + performance_bonus * 0.02
		if randf() < equipment_chance:  # 装备概率
			rewards["equipment"] = true

			# 根据难度和表现决定装备稀有度
			var rarity_roll = randf()
			if rarity_roll < 0.1 + difficulty * 0.05 + performance_bonus * 0.02:
				rewards["equipment_rarity"] = "epic"
			elif rarity_roll < 0.3 + difficulty * 0.1 + performance_bonus * 0.03:
				rewards["equipment_rarity"] = "rare"
			else:
				rewards["equipment_rarity"] = "common"

		var chess_piece_chance = 0.2 + current_round * 0.02 + performance_bonus * 0.03
		if randf() < chess_piece_chance:  # 棋子概率
			rewards["chess_piece"] = true

			# 根据难度和表现决定棋子稀有度
			var rarity_roll = randf()
			if rarity_roll < 0.05 + difficulty * 0.03 + performance_bonus * 0.01:
				rewards["chess_piece_rarity"] = "epic"
			elif rarity_roll < 0.2 + difficulty * 0.05 + performance_bonus * 0.02:
				rewards["chess_piece_rarity"] = "rare"
			else:
				rewards["chess_piece_rarity"] = "common"

	# 设置战斗结果
	battle_result = {
		"is_victory": victory,
		"player_pieces_left": player_pieces.size(),
		"enemy_pieces_left": enemy_pieces.size(),
		"round": current_round,
		"difficulty": difficulty,
		"rewards": rewards,
		"stats": battle_stats
	}

# 战斗开始事件处理
func _on_battle_started():
	print("Battle started")

	# 切换到战斗阶段
	current_state = BattleState.BATTLE
	timer = battle_time

	# 初始化棋子状态
	_initialize_chess_pieces()

# 战斗结束事件处理
func _on_battle_ended(result: Dictionary):
	print("Battle ended with result: ", result)

	# 处理战斗奖励
	_process_battle_rewards(result)

# 设置战斗速度
func set_battle_speed(speed: float) -> void:
	# 限制速度范围
	battle_speed = clamp(speed, 0.5, 3.0)

	# 应用速度到棋子
	for piece in player_pieces + enemy_pieces:
		if piece.has_method("set_animation_speed"):
			piece.set_animation_speed(battle_speed)

	# 发送战斗速度变化信号
	EventBus.battle_speed_changed.emit(battle_speed)

# 棋子死亡事件处理
func _on_chess_piece_died(piece):
	# 从对应数组中移除
	if piece.is_player_piece:
		player_pieces.erase(piece)
		# 更新战斗统计 - 敌方击杀数
		battle_stats.enemy_kills += 1
	else:
		enemy_pieces.erase(piece)
		# 更新战斗统计 - 玩家击杀数
		battle_stats.player_kills += 1

	# 检查战斗是否结束
	if _check_battle_end():
		var victory = _calculate_victory_condition()
		end_battle(victory)

# 初始化棋子状态
func _initialize_chess_pieces():
	# 设置玩家棋子状态
	for piece in player_pieces:
		piece.change_state(ChessPiece.ChessState.IDLE)

	# 设置敌方棋子状态
	for piece in enemy_pieces:
		piece.change_state(ChessPiece.ChessState.IDLE)

# 清理战场
func _cleanup_battle():
	# 清理玩家棋子
	for piece in player_pieces:
		piece.reset()

	# 清理敌方棋子
	for piece in enemy_pieces:
		piece.queue_free()

	# 清空数组
	player_pieces.clear()
	enemy_pieces.clear()

	# 清理AI控制器
	if ai_controller:
		ai_controller.queue_free()
		ai_controller = null

# 计算胜利条件
func _calculate_victory_condition() -> bool:
	# 如果敌方棋子全部死亡，玩家胜利
	if enemy_pieces.is_empty():
		return true

	# 如果玩家棋子全部死亡，玩家失败
	if player_pieces.is_empty():
		return false

	# 如果时间结束，比较双方剩余棋子数量
	if timer <= 0:
		return player_pieces.size() >= enemy_pieces.size()

	return false

# 伤害事件处理
func _on_damage_dealt(source, target, amount: float, damage_type: String) -> void:
	# 更新战斗统计
	if source and source.is_player_piece:
		# 玩家造成伤害
		battle_stats.player_damage_dealt += amount
	elif source:
		# 敌方造成伤害
		battle_stats.enemy_damage_dealt += amount

# 治疗事件处理
func _on_healing_done(target, amount: float, source = null) -> void:
	# 更新战斗统计
	if target and target.is_player_piece:
		# 玩家治疗
		battle_stats.player_healing += amount
	elif target:
		# 敌方治疗
		battle_stats.enemy_healing += amount

# 技能使用事件处理
func _on_ability_used(piece, ability_data: Dictionary) -> void:
	# 更新战斗统计
	battle_stats.abilities_used += 1

# 处理战斗奖励
func _process_battle_rewards(result: Dictionary):
	if not result.has("rewards"):
		return

	var rewards = result["rewards"]

	# 处理金币奖励
	if rewards.has("gold"):
		var gold = rewards["gold"]
		EventBus.gold_changed.emit(gold)

	# 处理经验奖励
	if rewards.has("exp"):
		var exp = rewards["exp"]
		EventBus.exp_gained.emit(exp)

	# 处理装备奖励
	if rewards.has("equipment") and rewards["equipment"]:
		# 生成随机装备
		EventBus.equipment_obtained.emit(null)  # 暂时使用null，应该由装备系统生成

	# 处理棋子奖励
	if rewards.has("chess_piece") and rewards["chess_piece"]:
		# 生成随机棋子
		EventBus.chess_piece_obtained.emit(null)  # 暂时使用null，应该由棋子系统生成

# 寻找最近的敌人棋子
func _find_nearest_enemy(piece) -> Object:
	# 获取敌人棋子列表
	var target_pieces = []
	if piece.is_player_piece:
		target_pieces = enemy_pieces
	else:
		target_pieces = player_pieces

	# 如果没有敌人，返回null
	if target_pieces.is_empty():
		return null

	# 找到最近的敌人
	var nearest_enemy = null
	var min_distance = 9999.0

	for enemy in target_pieces:
		# 跳过死亡棋子
		if enemy.current_state == ChessPiece.ChessState.DEAD:
			continue

		# 计算距离
		var distance = piece.position.distance_to(enemy.position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy

	return nearest_enemy

