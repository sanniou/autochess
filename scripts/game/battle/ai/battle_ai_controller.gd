extends Node
class_name BattleAIController
## 战斗AI控制器
## 负责控制敌方单位的AI行为

# AI难度枚举
enum AIDifficulty {
	EASY,    # 简单
	NORMAL,  # 普通
	HARD,    # 困难
	EXPERT   # 专家
}

# AI行为类型枚举
enum AIBehavior {
	RANDOM,     # 随机行为
	AGGRESSIVE, # 激进行为
	DEFENSIVE,  # 防御行为
	BALANCED,   # 平衡行为
	TACTICAL    # 战术行为
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
var battle_engine = null
var board_manager = null

# 行为树
var behavior_tree = null

# 初始化
func _init(engine, board_mgr, diff: int = AIDifficulty.NORMAL):
	battle_engine = engine
	board_manager = board_mgr
	set_difficulty(diff)
	
	# 初始化行为树
	_initialize_behavior_tree()

# 设置难度
func set_difficulty(diff: int) -> void:
	difficulty = diff
	
	# 根据难度调整AI参数
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
			reaction_time = 0.5
			decision_interval = 0.8
		
		AIDifficulty.EXPERT:
			behavior = AIBehavior.TACTICAL
			aggression = 0.9
			reaction_time = 0.3
			decision_interval = 0.5

# 更新AI
func update(delta: float, enemy_units: Array) -> void:
	# 更新决策计时器
	decision_timer += delta
	
	# 检查是否需要做决策
	if decision_timer >= decision_interval:
		decision_timer = 0.0
		
		# 更新行为树
		if behavior_tree:
			behavior_tree.update(delta, enemy_units)
		else:
			# 如果行为树未初始化，使用传统方法
			_update_traditional(delta, enemy_units)

# 传统更新方法（兼容旧代码）
func _update_traditional(delta: float, enemy_units: Array) -> void:
	# 为每个敌方单位做决策
	for unit in enemy_units:
		if unit.current_state == unit.ChessState.DEAD:
			continue
		
		# 做出决策
		make_decision(unit)

# 为单位做决策
func make_decision(unit) -> void:
	# 检查单位是否可以行动
	if unit.current_state == unit.ChessState.STUNNED:
		return  # 如果被眩晕，无法行动
	
	# 检查单位是否被嘲讽
	if unit.taunted_by and is_instance_valid(unit.taunted_by):
		# 如果被嘲讽，直接选择嘲讽源作为目标
		unit.set_target(unit.taunted_by)
		
		# 即使被嘲讽，仍然可以使用技能
		_try_use_ability(unit)
		return
	
	# 根据行为类型选择决策方法
	match behavior:
		AIBehavior.RANDOM:
			_make_random_decision(unit)
		
		AIBehavior.AGGRESSIVE:
			_make_aggressive_decision(unit)
		
		AIBehavior.DEFENSIVE:
			_make_defensive_decision(unit)
		
		AIBehavior.BALANCED:
			_make_balanced_decision(unit)
		
		AIBehavior.TACTICAL:
			_make_tactical_decision(unit)

# 初始化行为树
func _initialize_behavior_tree() -> void:
	# 创建行为树根节点
	behavior_tree = BehaviorTreeRoot.new()
	
	# 创建选择器节点
	var root_selector = BehaviorSelector.new()
	behavior_tree.set_root(root_selector)
	
	# 添加被嘲讽行为序列
	var taunt_sequence = BehaviorSequence.new()
	root_selector.add_child(taunt_sequence)
	
	# 添加被嘲讽条件
	taunt_sequence.add_child(BehaviorCondition.new(func(unit): return unit.taunted_by != null and is_instance_valid(unit.taunted_by)))
	
	# 添加设置嘲讽目标动作
	taunt_sequence.add_child(BehaviorAction.new(func(unit): 
		unit.set_target(unit.taunted_by)
		return true
	))
	
	# 添加尝试使用技能动作
	taunt_sequence.add_child(BehaviorAction.new(func(unit): 
		_try_use_ability(unit)
		return true
	))
	
	# 添加战术行为序列
	var tactical_sequence = BehaviorSequence.new()
	root_selector.add_child(tactical_sequence)
	
	# 添加战术条件
	tactical_sequence.add_child(BehaviorCondition.new(func(unit): return behavior == AIBehavior.TACTICAL))
	
	# 添加战术决策动作
	tactical_sequence.add_child(BehaviorAction.new(func(unit): 
		_make_tactical_decision(unit)
		return true
	))
	
	# 添加激进行为序列
	var aggressive_sequence = BehaviorSequence.new()
	root_selector.add_child(aggressive_sequence)
	
	# 添加激进条件
	aggressive_sequence.add_child(BehaviorCondition.new(func(unit): return behavior == AIBehavior.AGGRESSIVE))
	
	# 添加激进决策动作
	aggressive_sequence.add_child(BehaviorAction.new(func(unit): 
		_make_aggressive_decision(unit)
		return true
	))
	
	# 添加防御行为序列
	var defensive_sequence = BehaviorSequence.new()
	root_selector.add_child(defensive_sequence)
	
	# 添加防御条件
	defensive_sequence.add_child(BehaviorCondition.new(func(unit): return behavior == AIBehavior.DEFENSIVE))
	
	# 添加防御决策动作
	defensive_sequence.add_child(BehaviorAction.new(func(unit): 
		_make_defensive_decision(unit)
		return true
	))
	
	# 添加平衡行为序列
	var balanced_sequence = BehaviorSequence.new()
	root_selector.add_child(balanced_sequence)
	
	# 添加平衡条件
	balanced_sequence.add_child(BehaviorCondition.new(func(unit): return behavior == AIBehavior.BALANCED))
	
	# 添加平衡决策动作
	balanced_sequence.add_child(BehaviorAction.new(func(unit): 
		_make_balanced_decision(unit)
		return true
	))
	
	# 添加随机行为序列（默认行为）
	var random_sequence = BehaviorSequence.new()
	root_selector.add_child(random_sequence)
	
	# 添加随机决策动作
	random_sequence.add_child(BehaviorAction.new(func(unit): 
		_make_random_decision(unit)
		return true
	))

# 尝试使用技能
func _try_use_ability(unit) -> bool:
	# 如果没有技能或法力值不足，不使用
	if not unit.ability or unit.current_mana < unit.ability_cost or unit.is_silenced:
		return false
	
	# 根据难度决定使用技能的概率
	var use_chance = 0.5
	match difficulty:
		AIDifficulty.EASY:
			use_chance = 0.3
		AIDifficulty.NORMAL:
			use_chance = 0.5
		AIDifficulty.HARD:
			use_chance = 0.7
		AIDifficulty.EXPERT:
			use_chance = 0.9
	
	# 根据概率决定是否使用技能
	if randf() < use_chance:
		unit.use_ability()
		return true
	
	return false

# 随机决策
func _make_random_decision(unit) -> void:
	# 随机选择目标
	var player_units = board_manager.get_ally_pieces(true)
	if player_units.size() > 0:
		var random_target = player_units[randi() % player_units.size()]
		unit.set_target(random_target)
	
	# 尝试使用技能
	_try_use_ability(unit)

# 激进决策
func _make_aggressive_decision(unit) -> void:
	# 选择生命值最低的目标
	var player_units = board_manager.get_ally_pieces(true)
	var target = _find_lowest_health_target(player_units)
	
	if target:
		unit.set_target(target)
	
	# 尝试使用技能（激进模式下更容易使用技能）
	var old_difficulty = difficulty
	difficulty = AIDifficulty.EXPERT # 暂时提高难度以增加使用技能的概率
	_try_use_ability(unit)
	difficulty = old_difficulty # 恢复原始难度

# 防御决策
func _make_defensive_decision(unit) -> void:
	# 选择距离最近的目标
	var player_units = board_manager.get_ally_pieces(true)
	var target = _find_nearest_target(unit, player_units)
	
	if target:
		unit.set_target(target)
	
	# 尝试使用技能（防御模式下更保守）
	var old_difficulty = difficulty
	difficulty = AIDifficulty.EASY # 暂时降低难度以减少使用技能的概率
	
	# 只有当法力值足够多时才考虑使用技能
	if unit.current_mana >= unit.ability_cost * 1.5:
		_try_use_ability(unit)
	
	difficulty = old_difficulty # 恢复原始难度

# 平衡决策
func _make_balanced_decision(unit) -> void:
	# 根据多种因素选择目标
	var player_units = board_manager.get_ally_pieces(true)
	var target = _find_balanced_target(unit, player_units)
	
	if target:
		unit.set_target(target)
	
	# 尝试使用技能（保持当前难度）
	_try_use_ability(unit)

# 战术决策
func _make_tactical_decision(unit) -> void:
	# 根据战术评分选择最佳目标
	var player_units = board_manager.get_ally_pieces(true)
	var target = _find_tactical_target(unit, player_units)
	
	if target:
		unit.set_target(target)
	
	# 智能使用技能
	if unit.ability and unit.current_mana >= unit.ability_cost and not unit.is_silenced:
		var should_use_ability = _evaluate_ability_usage(unit)
		if should_use_ability:
			# 如果战术评估表明应该使用技能，则强制使用
			unit.use_ability()
		else:
			# 否则根据正常概率决定
			_try_use_ability(unit)

# 寻找生命值最低的目标
func _find_lowest_health_target(targets: Array):
	if targets.size() == 0:
		return null
	
	var lowest_health_target = targets[0]
	var lowest_health = lowest_health_target.current_health
	
	for target in targets:
		if target.current_state == target.ChessState.DEAD:
			continue
		
		if target.current_health < lowest_health:
			lowest_health = target.current_health
			lowest_health_target = target
	
	return lowest_health_target

# 寻找最近的目标
func _find_nearest_target(unit, targets: Array):
	if targets.size() == 0:
		return null
	
	var nearest_target = targets[0]
	var nearest_distance = unit.global_position.distance_to(nearest_target.global_position)
	
	for target in targets:
		if target.current_state == target.ChessState.DEAD:
			continue
		
		var distance = unit.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = target
	
	return nearest_target

# 寻找嘲讽目标
func _find_taunting_targets(targets: Array) -> Array:
	var taunting_targets = []
	
	for target in targets:
		if target.current_state == target.ChessState.DEAD:
			continue
		
		# 检查目标是否有嘲讽效果
		if target.has_method("has_effect") and target.has_effect("taunt"):
			taunting_targets.append(target)
	
	return taunting_targets

# 寻找平衡目标（考虑距离和生命值）
func _find_balanced_target(unit, targets: Array):
	if targets.size() == 0:
		return null
	
	# 检查是否有嘲讽目标
	var taunting_targets = _find_taunting_targets(targets)
	if taunting_targets.size() > 0:
		# 如果有嘲讽目标，优先选择嘲讽目标中的最佳目标
		return _find_best_target_by_score(unit, taunting_targets)
	
	# 如果没有嘲讽目标，选择最佳目标
	return _find_best_target_by_score(unit, targets)

# 根据评分选择最佳目标
func _find_best_target_by_score(unit, targets: Array):
	if targets.size() == 0:
		return null
	
	var best_target = targets[0]
	var best_score = 0
	
	for target in targets:
		if target.current_state == target.ChessState.DEAD:
			continue
		
		# 计算距离分数（距离越近分数越高）
		var distance = unit.global_position.distance_to(target.global_position)
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
func _find_tactical_target(unit, targets: Array):
	if targets.size() == 0:
		return null
	
	# 检查是否有嘲讽目标
	var taunting_targets = _find_taunting_targets(targets)
	if taunting_targets.size() > 0:
		# 如果有嘲讽目标，优先选择嘲讽目标中的最佳目标
		return _find_tactical_target_by_score(unit, taunting_targets)
	
	# 如果没有嘲讽目标，选择最佳目标
	return _find_tactical_target_by_score(unit, targets)

# 根据战术评分选择最佳目标
func _find_tactical_target_by_score(unit, targets: Array):
	if targets.size() == 0:
		return null
	
	var best_target = targets[0]
	var best_score = 0
	
	for target in targets:
		if target.current_state == target.ChessState.DEAD:
			continue
		
		# 计算距离分数
		var distance = unit.global_position.distance_to(target.global_position)
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
		
		# 检查目标是否有法力值
		if target.current_mana > target.max_mana * 0.8:
			special_score += 0.3  # 如果目标法力值快满，提高威胁分数
		
		# 检查目标是否有重要效果
		if target.has_method("has_effect"):
			if target.has_effect("invulnerable"):
				special_score -= 0.5  # 如果目标无敌，降低分数
			if target.has_effect("taunt"):
				special_score += 0.4  # 如果目标有嘲讽，提高分数
		
		# 综合评分
		var score = distance_score * 0.2 + health_score * 0.3 + threat_score * 0.3 + special_score * 0.2
		
		if score > best_score:
			best_score = score
			best_target = target
	
	return best_target

# 评估是否应该使用技能
func _evaluate_ability_usage(unit) -> bool:
	if not unit.ability:
		return false
	
	# 根据技能类型和战场情况评估
	var ability_type = unit.ability.ability_type
	
	match ability_type:
		"damage":
			# 伤害技能，当有多个敌人聚集时使用
			var targets_in_range = _count_targets_in_range(unit, unit.ability.ability_range)
			return targets_in_range >= 2
		
		"heal":
			# 治疗技能，当自己或队友生命值低时使用
			var ally_units = board_manager.get_ally_pieces(false)
			for ally in ally_units:
				if ally.current_health / ally.max_health < 0.5:
					return true
			return false
		
		"buff":
			# 增益技能，尽早使用
			return true
		
		"debuff":
			# 减益技能，当敌人有威胁时使用
			var player_units = board_manager.get_ally_pieces(true)
			for player in player_units:
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
func _count_targets_in_range(unit, ability_range: float) -> int:
	var targets = board_manager.get_ally_pieces(true)
	var count = 0
	
	for target in targets:
		if target.current_state == target.ChessState.DEAD:
			continue
		
		var distance = unit.global_position.distance_to(target.global_position)
		if distance <= ability_range * 64:  # 假设一个格子是64像素
			count += 1
	
	return count
