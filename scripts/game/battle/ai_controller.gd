extends Node
class_name AIController
## AI控制器
## 负责管理战斗中的AI行为和决策

# AI难度
enum AIDifficulty {
	EASY,    # 简单
	NORMAL,  # 普通
	HARD,    # 困难
	EXPERT   # 专家
}

# AI行为类型
enum AIBehavior {
	RANDOM,      # 随机行为
	AGGRESSIVE,  # 激进行为
	DEFENSIVE,   # 防御行为
	BALANCED,    # 平衡行为
	TACTICAL     # 战术行为
}

# AI配置
var difficulty: int = AIDifficulty.NORMAL
var behavior: int = AIBehavior.BALANCED
var aggression: float = 0.5  # 0.0-1.0，影响目标选择和技能使用
var reaction_time: float = 0.5  # 反应时间（秒）
var decision_interval: float = 1.0  # 决策间隔（秒）

# 决策计时器
var decision_timer: float = 0.0

# 引用
var battle_manager: BattleManager
var board_manager: BoardManager

# 初始化
func _init(battle_mgr: BattleManager, board_mgr: BoardManager, diff: int = AIDifficulty.NORMAL):
	battle_manager = battle_mgr
	board_manager = board_mgr
	set_difficulty(diff)

# 设置难度
func set_difficulty(diff: int) -> void:
	difficulty = diff

	# 根据难度设置AI参数
	match difficulty:
		AIDifficulty.EASY:
			behavior = AIBehavior.RANDOM
			aggression = 0.3
			reaction_time = 1.0
			decision_interval = 1.5

		AIDifficulty.NORMAL:
			behavior = AIBehavior.BALANCED
			aggression = 0.5
			reaction_time = 0.7
			decision_interval = 1.0

		AIDifficulty.HARD:
			behavior = AIBehavior.TACTICAL
			aggression = 0.7
			reaction_time = 0.4
			decision_interval = 0.8

		AIDifficulty.EXPERT:
			behavior = AIBehavior.TACTICAL
			aggression = 0.9
			reaction_time = 0.2
			decision_interval = 0.5

# 更新AI
func update(delta: float, enemy_pieces: Array) -> void:
	# 更新决策计时器
	decision_timer += delta

	# 检查是否需要做决策
	if decision_timer >= decision_interval:
		decision_timer = 0.0

		# 为每个敌方棋子做决策
		for piece in enemy_pieces:
			if piece.current_state == ChessPiece.ChessState.DEAD:
				continue

			# 做出决策
			make_decision(piece)

# 为棋子做决策
func make_decision(piece: ChessPiece) -> void:
	# 检查棋子是否可以行动
	if piece.current_state == ChessPiece.ChessState.STUNNED:
		return  # 如果被眩晕，无法行动

	# 根据行为类型选择决策方法
	match behavior:
		AIBehavior.RANDOM:
			_make_random_decision(piece)

		AIBehavior.AGGRESSIVE:
			_make_aggressive_decision(piece)

		AIBehavior.DEFENSIVE:
			_make_defensive_decision(piece)

		AIBehavior.BALANCED:
			_make_balanced_decision(piece)

		AIBehavior.TACTICAL:
			_make_tactical_decision(piece)

# 随机决策
func _make_random_decision(piece: ChessPiece) -> void:
	# 随机选择目标
	var player_pieces = board_manager.get_ally_pieces(true)
	if player_pieces.size() > 0:
		var random_target = player_pieces[randi() % player_pieces.size()]
		piece.set_target(random_target)

	# 随机使用技能
	if piece.ability and piece.current_mana >= piece.ability_cost and randf() < 0.3 and not piece.is_silenced:
		piece.use_ability()

# 激进决策
func _make_aggressive_decision(piece: ChessPiece) -> void:
	# 选择生命值最低的目标
	var player_pieces = board_manager.get_ally_pieces(true)
	var target = _find_lowest_health_target(player_pieces)

	if target:
		piece.set_target(target)

	# 积极使用技能
	if piece.ability and piece.current_mana >= piece.ability_cost and not piece.is_silenced:
		piece.use_ability()

# 防御决策
func _make_defensive_decision(piece: ChessPiece) -> void:
	# 选择距离最近的目标
	var player_pieces = board_manager.get_ally_pieces(true)
	var target = _find_nearest_target(piece, player_pieces)

	if target:
		piece.set_target(target)

	# 保守使用技能，优先保留法力值
	if piece.ability and piece.current_mana >= piece.ability_cost * 1.5 and randf() < 0.5 and not piece.is_silenced:
		piece.use_ability()

# 平衡决策
func _make_balanced_decision(piece: ChessPiece) -> void:
	# 根据多种因素选择目标
	var player_pieces = board_manager.get_ally_pieces(true)
	var target = _find_balanced_target(piece, player_pieces)

	if target:
		piece.set_target(target)

	# 平衡使用技能
	if piece.ability and piece.current_mana >= piece.ability_cost and randf() < 0.6 and not piece.is_silenced:
		piece.use_ability()

# 战术决策
func _make_tactical_decision(piece: ChessPiece) -> void:
	# 根据战术评分选择最佳目标
	var player_pieces = board_manager.get_ally_pieces(true)
	var target = _find_tactical_target(piece, player_pieces)

	if target:
		piece.set_target(target)

	# 智能使用技能
	if piece.ability and piece.current_mana >= piece.ability_cost and not piece.is_silenced:
		var should_use_ability = _evaluate_ability_usage(piece)
		if should_use_ability:
			piece.use_ability()

# 寻找生命值最低的目标
func _find_lowest_health_target(targets: Array) -> ChessPiece:
	if targets.size() == 0:
		return null

	var lowest_health_target = targets[0]
	var lowest_health = lowest_health_target.current_health

	for target in targets:
		if target.current_state == ChessPiece.ChessState.DEAD:
			continue

		if target.current_health < lowest_health:
			lowest_health = target.current_health
			lowest_health_target = target

	return lowest_health_target

# 寻找最近的目标
func _find_nearest_target(piece: ChessPiece, targets: Array) -> ChessPiece:
	if targets.size() == 0:
		return null

	var nearest_target = targets[0]
	var nearest_distance = piece.global_position.distance_to(nearest_target.global_position)

	for target in targets:
		if target.current_state == ChessPiece.ChessState.DEAD:
			continue

		var distance = piece.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = target

	return nearest_target

# 寻找平衡目标（考虑距离和生命值）
func _find_balanced_target(piece: ChessPiece, targets: Array) -> ChessPiece:
	if targets.size() == 0:
		return null

	var best_target = targets[0]
	var best_score = 0

	for target in targets:
		if target.current_state == ChessPiece.ChessState.DEAD:
			continue

		# 计算距离分数（距离越近分数越高）
		var distance = piece.global_position.distance_to(target.global_position)
		var distance_score = 1.0 - min(distance / 500.0, 1.0)

		# 计算生命值分数（生命值越低分数越高）
		var health_ratio = target.current_health / target.max_health
		var health_score = 1.0 - health_ratio

		# 综合评分（根据攻击性调整权重）
		var score = distance_score * (1.0 - aggression) + health_score * aggression

		if score > best_score:
			best_score = score
			best_target = target

	return best_target

# 寻找战术目标（考虑多种因素）
func _find_tactical_target(piece: ChessPiece, targets: Array) -> ChessPiece:
	if targets.size() == 0:
		return null

	var best_target = targets[0]
	var best_score = 0

	for target in targets:
		if target.current_state == ChessPiece.ChessState.DEAD:
			continue

		# 计算距离分数
		var distance = piece.global_position.distance_to(target.global_position)
		var distance_score = 1.0 - min(distance / 500.0, 1.0)

		# 计算生命值分数
		var health_ratio = target.current_health / target.max_health
		var health_score = 1.0 - health_ratio

		# 计算威胁分数（攻击力和攻击速度）
		var threat_score = (target.attack_damage * target.attack_speed) / 100.0

		# 计算特殊分数（如果目标有特殊能力或效果）
		var special_score = 0.0
		if target.ability:
			special_score += 0.2

		# 综合评分
		var score = distance_score * 0.2 + health_score * 0.3 + threat_score * 0.3 + special_score * 0.2

		if score > best_score:
			best_score = score
			best_target = target

	return best_target

# 评估是否应该使用技能
func _evaluate_ability_usage(piece: ChessPiece) -> bool:
	# 如果没有技能或法力值不足，不使用
	if not piece.ability or piece.current_mana < piece.ability_cost or piece.is_silenced:
		return false

	# 根据技能类型和战场情况评估
	var ability_type = piece.ability.ability_type

	match ability_type:
		"damage":
			# 伤害技能，当有多个敌人聚集时使用
			var targets_in_range = _count_targets_in_range(piece, piece.ability.ability_range)
			return targets_in_range >= 2

		"heal":
			# 治疗技能，当自己或队友生命值低时使用
			var ally_pieces = board_manager.get_ally_pieces(false)
			for ally in ally_pieces:
				if ally.current_health / ally.max_health < 0.5:
					return true
			return false

		"buff":
			# 增益技能，尽早使用
			return true

		"debuff":
			# 减益技能，当敌人有威胁时使用
			var player_pieces = board_manager.get_ally_pieces(true)
			for player in player_pieces:
				if player.attack_damage > 30 or player.ability:
					return true
			return false

		"summon":
			# 召唤技能，尽早使用
			return true

		_:
			# 默认行为
			return randf() < 0.7

# 计算范围内的目标数量
func _count_targets_in_range(piece: ChessPiece, ability_range: float) -> int:
	var count = 0
	var player_pieces = board_manager.get_ally_pieces(true)

	for target in player_pieces:
		if target.current_state == ChessPiece.ChessState.DEAD:
			continue

		var distance = piece.global_position.distance_to(target.global_position)
		if distance <= ability_range:
			count += 1

	return count
