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
	
	# 应用法术强度加成
	if damage_type == "magical":
		current_damage += owner.spell_power
	
	# 对主目标造成伤害
	target.take_damage(current_damage, damage_type, owner)
	
	# 播放技能特效
	_play_effect(target)
	
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
		
		# 造成伤害
		next_target.take_damage(current_damage, damage_type, owner)
		
		# 播放技能特效
		_play_effect(next_target)
		
		# 播放连锁特效
		_play_chain_effect(current_target, next_target)
		
		# 更新当前目标
		current_target = next_target
		
		# 添加短暂延迟，使连锁效果更明显
		await owner.get_tree().create_timer(0.2).timeout

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
func _play_chain_effect(from_target: ChessPiece, to_target: ChessPiece) -> void:
	# 创建连线特效
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.8, 0.2, 0.8, 0.8)  # 紫色
	
	# 设置线的点
	line.add_point(from_target.position)
	line.add_point(to_target.position)
	
	# 添加到场景
	owner.get_parent().add_child(line)
	
	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(line, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(line.queue_free)

# 播放单体特效
func _play_effect(target: ChessPiece) -> void:
	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.2, 0.8, 0.5)  # 紫色
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)
	
	# 添加到目标
	target.add_child(effect)
	
	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)
