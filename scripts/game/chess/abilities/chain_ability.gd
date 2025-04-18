extends Ability
class_name ChainAbility
## 连锁技能
## 对主目标造成伤害，然后连锁到附近的敌人

# 伤害类型
var damage_type: String = "magical"  # 伤害类型(physical/magical/true)
var chain_count: int = 3  # 连锁次数
var chain_range: float = 3.0  # 连锁范围（格子数）
var damage_reduction: float = 0.2  # 每次连锁的伤害衰减

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置伤害类型和连锁参数
	damage_type = ability_data.get("damage_type", "magical")
	chain_count = ability_data.get("chain_count", 3)
	chain_range = ability_data.get("chain_range", 3.0)
	damage_reduction = ability_data.get("damage_reduction", 0.2)

# 执行技能效果
func _execute_effect(target = null) -> void:
	# 如果没有指定目标，查找目标
	if target == null:
		target = get_target()

	if target == null:
		return

	# 获取棋盘管理器
	var board_manager = owner.get_node("/root/GameManager").board_manager
	if not board_manager:
		return

	# 已经命中的目标
	var hit_targets = [target]

	# 当前伤害
	var current_damage = damage

	# 获取特效管理器

	if GameManager.effect_manager:
		# 创建伤害特效
		var params = {
			"damage_type": damage_type,
			"damage_amount": current_damage
		}

		# 使用特效管理器创建特效
		GameManager.effect_manager.create_effect(GameManager.effect_manager.EffectType.DAMAGE, target, params)

	# 直接造成伤害
	target.take_damage(current_damage, damage_type, owner)

	# 播放技能特效
	_play_ability_effect([target])

	# 连锁伤害
	var current_target = target
	for i in range(chain_count - 1):
		# 减少伤害
		current_damage *= (1.0 - damage_reduction)

		# 查找下一个目标
		var next_target = _find_next_chain_target(current_target, hit_targets)
		if next_target == null:
			break

		# 添加到已命中列表
		hit_targets.append(next_target)

		# 获取特效管理器
		if GameManager.effect_manager:
			# 创建伤害特效
			var params = {
				"damage_type": damage_type,
				"damage_amount": current_damage
			}

			# 使用特效管理器创建特效
			GameManager.effect_manager.create_effect(GameManager.effect_manager.EffectType.DAMAGE, next_target, params)

		# 直接造成伤害
		next_target.take_damage(current_damage, damage_type, owner)

		# 播放技能特效
		_play_ability_effect([next_target])

		# 播放连锁特效
		_play_chain_visual_effect(current_target, next_target)

		# 更新当前目标
		current_target = next_target

		# 添加短暂延迟，使连锁效果更明显
		var delay_timer = Timer.new()
		delay_timer.wait_time = 0.2
		delay_timer.one_shot = true
		owner.add_child(delay_timer)
		delay_timer.start()
		await delay_timer.timeout
		delay_timer.queue_free()

# 查找下一个连锁目标
func _find_next_chain_target(current_target: ChessPiece, hit_targets: Array) -> ChessPiece:
	# 获取棋盘管理器
	var board_manager = owner.get_node("/root/GameManager").board_manager
	if not board_manager:
		return null

	# 获取所有敌人
	var enemies = []
	var all_pieces = board_manager.pieces

	for piece in all_pieces:
		if piece.is_player_piece != owner.is_player_piece and piece.current_state != ChessPiece.ChessState.DEAD and not hit_targets.has(piece):
			# 计算距离
			var distance = current_target.board_position.distance_to(piece.board_position)
			if distance <= chain_range:
				enemies.append({"piece": piece, "distance": distance})

	# 如果没有可用目标，返回null
	if enemies.size() == 0:
		return null

	# 按距离排序
	enemies.sort_custom(func(a, b): return a.distance < b.distance)

	# 返回最近的目标
	return enemies[0].piece

# 播放连锁特效
func _play_chain_visual_effect(from_target: ChessPiece, to_target: ChessPiece) -> void:
	# 获取特效管理器
	var game_manager = owner.get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 创建一个临时节点来放置特效
	var effect_node = Node2D.new()
	effect_node.position = from_target.position
	owner.get_parent().add_child(effect_node)

	# 创建连锁特效
	var params = {
		"damage_type": damage_type,
		"from_position": from_target.position,
		"to_position": to_target.position
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(game_manager.effect_manager.VisualEffectType.CHAIN, effect_node, params)

	# 设置定时器删除节点
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	owner.add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

	if is_instance_valid(effect_node) and not effect_node.is_queued_for_deletion():
		effect_node.queue_free()
