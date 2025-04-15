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

# 引用
@onready var board_manager: BoardManager = get_node("/root/GameManager/BoardManager")
@onready var synergy_manager: SynergyManager = get_node("/root/GameManager/SynergyManager")

func _ready():
	# 连接信号
	EventBus.battle_start.connect(_on_battle_start)
	EventBus.battle_end.connect(_on_battle_end)

func _process(delta):
	match current_state:
		BattleState.PREPARE:
			_update_prepare_phase(delta)
		BattleState.BATTLE:
			_update_battle_phase(delta)
		BattleState.RESULT:
			_update_result_phase(delta)

# 开始战斗
func start_battle(is_player: bool):
	is_player_turn = is_player
	current_state = BattleState.PREPARE
	timer = prepare_time
	
	# 重置棋盘
	board_manager.reset_board()
	
	# 发送战斗开始信号
	EventBus.battle_start.emit(is_player)

# 结束战斗
func end_battle():
	current_state = BattleState.RESULT
	timer = 3.0  # 结算显示时间
	
	# 计算战斗结果
	_calculate_battle_result()
	
	# 发送战斗结束信号
	EventBus.battle_end.emit(battle_result)

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
	
	# 更新所有棋子状态
	_update_chess_pieces(delta)
	
	# 检查战斗是否结束
	if _check_battle_end():
		end_battle()

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
func _calculate_battle_result():
	battle_result = {
		"is_player_turn": is_player_turn,
		"player_pieces": board_manager.get_ally_pieces(is_player_turn).size(),
		"enemy_pieces": board_manager.get_enemy_pieces(is_player_turn).size(),
		"is_victory": board_manager.get_enemy_pieces(is_player_turn).is_empty()
	}

# 战斗开始事件处理
func _on_battle_start(is_player: bool):
	print("Battle started for player: ", is_player)

# 战斗结束事件处理
func _on_battle_end(result: Dictionary):
	print("Battle ended with result: ", result)
