extends Ability
class_name ChainAbility
## 连锁技能
## 对主目标造成伤害，然后连锁到附近的敌人

# 注意：使用基类中定义的 damage_type 属性
var chain_count: int = 3  # 连锁次数
var chain_range: float = 3.0  # 连锁范围（格子数）
var damage_reduction: float = 0.2  # 每次连锁的伤害衰减

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPieceEntity) -> void:
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

	var board_manager = GameManager.board_manager

	# 已经命中的目标
	var hit_targets = [target]

	# 当前伤害
	var current_damage = damage
	# 创建伤害特效参数
	# 使用特效管理器创建特效
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.create_visual_effect(
			GameManager.game_effect_manager.VisualEffectType.DAMAGE,
			target,
			{
			"color": GameManager.game_effect_manager.get_effect_color(damage_type),
			"duration": 0.5,
			"damage_type": damage_type,
			"damage_amount": current_damage
			}
		)
	# 如果没有效果管理器，使用视觉管理器
	elif GameManager and GameManager.visual_manager:
		GameManager.visual_manager.create_damage_number(
			target.global_position,
			current_damage,
			false,
			{"damage_type": damage_type}
		)

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

		# 使用特效管理器创建特效
		if GameManager and GameManager.game_effect_manager:
			GameManager.game_effect_manager.create_visual_effect(
				GameManager.game_effect_manager.VisualEffectType.DAMAGE,
				next_target,
				{
				"color": GameManager.game_effect_manager.get_effect_color(damage_type),
				"duration": 0.5,
				"damage_type": damage_type,
				"damage_amount": current_damage
				}
			)
		# 如果没有效果管理器，使用视觉管理器
		elif GameManager and GameManager.visual_manager:
			GameManager.visual_manager.create_damage_number(
				next_target.global_position,
				current_damage,
				false,
				{"damage_type": damage_type}
			)

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
func _find_next_chain_target(current_target: ChessPieceEntity, hit_targets: Array) -> ChessPieceEntity:

	var board_manager = GameManager.board_manager

	# 获取所有敌人
	var enemies = []
	var all_pieces = board_manager.pieces

	for piece in all_pieces:
		if piece.is_player_piece != owner.is_player_piece and piece.current_state != StateMachineComponent.ChessState.DEAD and not hit_targets.has(piece):
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
func _play_chain_visual_effect(from_target: ChessPieceEntity, to_target: ChessPieceEntity) -> void:
	# 创建一个临时节点来放置特效
	var effect_node = Node2D.new()
	effect_node.position = from_target.position
	owner.get_parent().add_child(effect_node)

	# 创建连锁特效参数
	var params = {}

	# 设置颜色
	if GameManager and GameManager.game_effect_manager:
		params["color"] = GameManager.game_effect_manager.get_effect_color(damage_type)
	elif GameManager and GameManager.visual_manager:
		params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值
	else:
		params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值

	# 设置其他参数
	params["duration"] = 0.5
	params["damage_type"] = damage_type
	params["from_position"] = from_target.position
	params["to_position"] = to_target.position

	# 使用特效管理器创建特效
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.create_visual_effect(
			GameManager.game_effect_manager.VisualEffectType.CHAIN,
			effect_node,
			params
		)
	# 如果没有效果管理器，使用视觉管理器
	elif GameManager and GameManager.visual_manager:
		GameManager.visual_manager.create_combined_effect(
			effect_node.global_position,
			"chain_" + damage_type,
			params
		)

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

# 播放技能特效
func _play_ability_effect(targets: Array) -> void:

	# 播放技能音效
	_play_ability_sound()

	# 播放技能视觉效果
	for target in targets:
		# 创建视觉特效参数
		var params = {}

		# 设置颜色
		if GameManager and GameManager.game_effect_manager:
			params["color"] = GameManager.game_effect_manager.get_effect_color(damage_type)
		elif GameManager and GameManager.visual_manager:
			params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值
		else:
			params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值

		# 设置其他参数
		params["duration"] = 0.5
		params["damage_type"] = damage_type
		params["damage_amount"] = damage

		# 使用特效管理器创建特效
		if GameManager and GameManager.game_effect_manager:
			GameManager.game_effect_manager.create_visual_effect(
				GameManager.game_effect_manager.VisualEffectType.DAMAGE,
				target,
				params
			)
		# 如果没有效果管理器，使用视觉管理器
		elif GameManager and GameManager.visual_manager:
			GameManager.visual_manager.create_damage_number(
				target.global_position,
				damage,
				false,
				{"damage_type": damage_type}
			)

	# 播放技能施法者效果
	_play_caster_effect()
