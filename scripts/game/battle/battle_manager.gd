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

# 战斗回合
var current_round: int = 1  # 当前回合

# 战斗难度
var difficulty: int = 1  # 当前难度

# 战斗奖励
var battle_rewards = {}  # 战斗奖励

# 引用
@onready var board_manager: BoardManager = get_node("/root/GameManager/BoardManager")
@onready var synergy_manager: SynergyManager = get_node("/root/GameManager/SynergyManager")

func _ready():
	# 连接信号
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.chess_piece_died.connect(_on_chess_piece_died)

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
	timer -= delta

	# 检查战斗超时
	if timer <= 0:
		# 超时判负
		end_battle(false)
		return

	# 更新所有棋子状态
	_update_chess_pieces(delta)

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
		piece.change_state(ChessPiece.ChessState.IDLE)

# 更新棋子状态
func _update_chess_pieces(delta):
	var pieces = board_manager.pieces

	for piece in pieces:
		if piece.current_state == ChessPiece.ChessState.DEAD:
			continue

		# 自动寻找目标
		if piece.current_state == ChessPiece.ChessState.IDLE:
			var target = board_manager.find_attack_target(piece)
			if target:
				piece.set_target(target)

		# 处理移动逻辑
		if piece.current_state == ChessPiece.ChessState.MOVING:
			_process_movement(piece, delta)

		# 处理攻击逻辑
		if piece.current_state == ChessPiece.ChessState.ATTACKING:
			_process_attack(piece, delta)

# 处理移动逻辑
func _process_movement(piece: ChessPiece, delta):
	# 简化版移动逻辑 - 实际项目中需要更复杂的寻路
	var target_pos = piece.target.board_position
	var dir = (Vector2(target_pos) - Vector2(piece.board_position)).normalized()

	# 移动棋子
	piece.position += dir * piece.move_speed * delta

	# 检查是否到达攻击范围
	var distance = piece.position.distance_to(piece.target.position)
	if distance <= piece.attack_range * board_manager.cell_size.x:
		piece.change_state(ChessPiece.ChessState.ATTACKING)

# 处理攻击逻辑
func _process_attack(piece: ChessPiece, delta):
	# 检查目标是否有效
	if not piece.target or piece.target.current_state == ChessPiece.ChessState.DEAD:
		piece.clear_target()
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

# 计算战斗结果
func _calculate_battle_result(victory: bool):
	# 计算奖励
	var rewards = {}
	if victory:
		# 根据难度和回合计算奖励
		var gold_reward = 5 + current_round + difficulty
		var exp_reward = 2 + current_round / 2

		# 添加到奖励中
		rewards["gold"] = gold_reward
		rewards["exp"] = exp_reward

		# 根据难度和回合随机生成装备或棋子
		if randf() < 0.3 + difficulty * 0.1:  # 30%+难度加成的概率获得装备
			rewards["equipment"] = true

		if randf() < 0.2 + current_round * 0.02:  # 20%+回合加成的概率获得棋子
			rewards["chess_piece"] = true

	# 设置战斗结果
	battle_result = {
		"is_victory": victory,
		"player_pieces_left": player_pieces.size(),
		"enemy_pieces_left": enemy_pieces.size(),
		"round": current_round,
		"difficulty": difficulty,
		"rewards": rewards
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

# 棋子死亡事件处理
func _on_chess_piece_died(piece: ChessPiece):
	# 从对应数组中移除
	if piece.is_player_piece:
		player_pieces.erase(piece)
	else:
		enemy_pieces.erase(piece)

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

# 更新棋子状态
func _update_chess_pieces(delta):
	# 更新玩家棋子
	for piece in player_pieces:
		# 跳过死亡棋子
		if piece.current_state == ChessPiece.ChessState.DEAD:
			continue

		# 更新状态
		piece.update_state(delta)

		# 如果没有目标，查找最近的敌人
		if piece.target == null and piece.current_state != ChessPiece.ChessState.DEAD:
			piece.target = _find_nearest_enemy(piece, enemy_pieces)

	# 更新敌方棋子
	for piece in enemy_pieces:
		# 跳过死亡棋子
		if piece.current_state == ChessPiece.ChessState.DEAD:
			continue

		# 更新状态
		piece.update_state(delta)

		# 如果没有目标，查找最近的敌人
		if piece.target == null and piece.current_state != ChessPiece.ChessState.DEAD:
			piece.target = _find_nearest_enemy(piece, player_pieces)

# 查找最近的敌人
func _find_nearest_enemy(piece: ChessPiece, enemies: Array) -> ChessPiece:
	if enemies.is_empty():
		return null

	var nearest_enemy = null
	var min_distance = INF

	for enemy in enemies:
		if enemy.current_state == ChessPiece.ChessState.DEAD:
			continue

		var distance = piece.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy

	return nearest_enemy
