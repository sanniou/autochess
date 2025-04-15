extends Node
class_name BattleManager
## 战斗管理器
## 负责管理战斗逻辑和流程

# 战斗状态
enum BattleState {
	PREPARE,  # 准备阶段
	FIGHTING, # 战斗阶段
	RESULT    # 结果阶段
}

# 当前战斗状态
var current_state = BattleState.PREPARE

# 战斗双方棋子
var player_pieces = []
var enemy_pieces = []

# 战斗结果
var battle_result = false

# 战斗计时器
var battle_timer = 0.0
var max_battle_time = 60.0  # 最大战斗时间(秒)

# 初始化
func _ready():
	# 连接信号
	EventBus.chess_piece_died.connect(_on_chess_piece_died)

## 开始战斗
func start_battle(player_team: Array, enemy_team: Array) -> void:
	player_pieces = player_team
	enemy_pieces = enemy_team
	
	# 设置棋子阵营
	for piece in player_pieces:
		piece.is_player_piece = true
		piece.add_to_group("player_chess_pieces")
	
	for piece in enemy_pieces:
		piece.is_player_piece = false
		piece.add_to_group("enemy_chess_pieces")
	
	# 开始战斗阶段
	start_fighting_phase()

## 开始战斗阶段
func start_fighting_phase() -> void:
	current_state = BattleState.FIGHTING
	battle_timer = 0.0
	
	# 发送战斗开始信号
	EventBus.battle_started.emit()
	
	# 初始化棋子战斗状态
	for piece in player_pieces + enemy_pieces:
		piece.change_state(ChessPiece.ChessState.IDLE)

## 更新战斗逻辑
func _process(delta):
	if current_state != BattleState.FIGHTING:
		return
	
	battle_timer += delta
	
	# 检查战斗超时
	if battle_timer >= max_battle_time:
		end_battle(false)  # 超时判负
		return
	
	# 更新棋子战斗逻辑
	_update_pieces(delta)
	
	# 检查战斗结果
	_check_battle_result()

## 更新棋子战斗逻辑
func _update_pieces(delta: float) -> void:
	# 更新所有棋子状态
	for piece in player_pieces + enemy_pieces:
		if piece.current_state == ChessPiece.ChessState.DEAD:
			continue
		
		piece._physics_process(delta)
		
		# 自动寻找目标
		if piece.current_state == ChessPiece.ChessState.IDLE:
			_find_target_for_piece(piece)

## 为棋子寻找目标
func _find_target_for_piece(piece: ChessPiece) -> void:
	var target = null
	var targets = enemy_pieces if piece.is_player_piece else player_pieces
	
	# 寻找最近的目标
	var min_distance = INF
	for potential_target in targets:
		if potential_target.current_state == ChessPiece.ChessState.DEAD:
			continue
		
		var distance = piece.global_position.distance_to(potential_target.global_position)
		if distance < min_distance and distance <= piece.attack_range:
			min_distance = distance
			target = potential_target
	
	# 设置目标
	if target:
		piece.set_target(target)
	else:
		# 没有目标则尝试移动
		_move_to_enemy(piece)

## 棋子移动逻辑
func _move_to_enemy(piece: ChessPiece) -> void:
	var targets = enemy_pieces if piece.is_player_piece else player_pieces
	
	# 寻找最近的敌人
	var closest_enemy = null
	var min_distance = INF
	for enemy in targets:
		if enemy.current_state == ChessPiece.ChessState.DEAD:
			continue
		
		var distance = piece.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_enemy = enemy
	
	# 向敌人移动
	if closest_enemy:
		var direction = (closest_enemy.global_position - piece.global_position).normalized()
		piece.global_position += direction * piece.move_speed * get_process_delta_time()

## 检查战斗结果
func _check_battle_result() -> void:
	# 检查玩家棋子是否全部死亡
	var player_alive = false
	for piece in player_pieces:
		if piece.current_state != ChessPiece.ChessState.DEAD:
			player_alive = true
			break
	
	# 检查敌方棋子是否全部死亡
	var enemy_alive = false
	for piece in enemy_pieces:
		if piece.current_state != ChessPiece.ChessState.DEAD:
			enemy_alive = true
			break
	
	# 判定结果
	if not player_alive:
		end_battle(false)  # 玩家失败
	elif not enemy_alive:
		end_battle(true)   # 玩家胜利

## 棋子死亡处理
func _on_chess_piece_died(piece: ChessPiece) -> void:
	# 从对应数组中移除
	if piece.is_player_piece:
		player_pieces.erase(piece)
	else:
		enemy_pieces.erase(piece)
	
	# 检查战斗结果
	_check_battle_result()

## 结束战斗
func end_battle(victory: bool) -> void:
	current_state = BattleState.RESULT
	battle_result = victory
	
	# 发送战斗结束信号
	EventBus.battle_ended.emit(victory)
	
	# 清理战场
	_cleanup_battle()

## 清理战场
func _cleanup_battle() -> void:
	# 释放所有棋子
	for piece in player_pieces + enemy_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	
	player_pieces.clear()
	enemy_pieces.clear()

## 获取战斗状态
func get_battle_state() -> int:
	return current_state

## 获取战斗结果
func get_battle_result() -> bool:
	return battle_result

## 获取剩余战斗时间
func get_remaining_time() -> float:
	return max(0.0, max_battle_time - battle_timer)
