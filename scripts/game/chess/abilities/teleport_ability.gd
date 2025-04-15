extends Ability
class_name TeleportAbility
## 传送技能
## 传送到目标位置并造成伤害

# 传送相关属性
var damage_type: String = "magical"  # 伤害类型(physical/magical/true)
var teleport_range: float = 4.0     # 传送范围（格子数）
var damage_radius: float = 1.0      # 伤害半径（格子数）

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
	super.initialize(ability_data, owner_piece)
	
	# 设置传送属性
	damage_type = ability_data.get("damage_type", "magical")
	teleport_range = ability_data.get("teleport_range", 4.0)
	damage_radius = ability_data.get("damage_radius", 1.0)

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
	
	# 查找传送位置
	var teleport_pos = _find_teleport_position(target, board_manager)
	if teleport_pos == Vector2i(-1, -1):
		return
	
	# 播放消失特效
	_play_disappear_effect()
	
	# 移动到目标位置
	var from_pos = owner.board_position
	board_manager.move_piece(owner, teleport_pos)
	
	# 播放出现特效
	_play_appear_effect()
	
	# 对周围敌人造成伤害
	_deal_area_damage(teleport_pos, board_manager)
	
	# 播放技能特效
	_play_effect(target)

# 查找传送位置
func _find_teleport_position(target: ChessPiece, board_manager) -> Vector2i:
	# 获取目标位置
	var target_pos = target.board_position
	
	# 检查目标周围的位置
	var directions = [
		Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
		Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	# 随机打乱方向顺序
	directions.shuffle()
	
	# 检查每个方向
	for dir in directions:
		var check_pos = target_pos + dir
		if board_manager.is_valid_cell(check_pos):
			var cell = board_manager.get_cell(check_pos)
			if cell and not cell.current_piece:
				# 检查距离是否在传送范围内
				var distance = owner.board_position.distance_to(check_pos)
				if distance <= teleport_range:
					return check_pos
	
	# 如果没有找到合适的位置，返回无效位置
	return Vector2i(-1, -1)

# 对区域造成伤害
func _deal_area_damage(center_pos: Vector2i, board_manager) -> void:
	# 获取范围内的所有敌人
	var enemies = []
	var all_pieces = board_manager.pieces
	
	for piece in all_pieces:
		if piece.is_player_piece != owner.is_player_piece and piece.current_state != ChessPiece.ChessState.DEAD:
			# 计算距离
			var distance = center_pos.distance_to(piece.board_position)
			if distance <= damage_radius:
				enemies.append(piece)
	
	# 对范围内的所有敌人造成伤害
	for enemy in enemies:
		# 计算伤害
		var actual_damage = damage
		
		# 应用法术强度加成
		if damage_type == "magical":
			actual_damage += owner.spell_power
		
		# 造成伤害
		enemy.take_damage(actual_damage, damage_type, owner)
		
		# 播放伤害特效
		_play_damage_effect(enemy)

# 播放消失特效
func _play_disappear_effect() -> void:
	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.2, 0.8, 0.5)  # 紫色
	effect.size = Vector2(60, 60)
	effect.position = Vector2(-30, -30)
	
	# 添加到所有者
	owner.add_child(effect)
	
	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(0.1, 0.1), 0.3)
	tween.parallel().tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(effect.queue_free)
	
	# 暂时隐藏所有者
	owner.modulate.a = 0

# 播放出现特效
func _play_appear_effect() -> void:
	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.2, 0.8, 0.5)  # 紫色
	effect.size = Vector2(60, 60)
	effect.position = Vector2(-30, -30)
	effect.scale = Vector2(0.1, 0.1)
	
	# 添加到所有者
	owner.add_child(effect)
	
	# 创建出现动画
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(1, 1), 0.3)
	tween.parallel().tween_property(owner, "modulate:a", 1, 0.3)
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(effect.queue_free)

# 播放伤害特效
func _play_damage_effect(target: ChessPiece) -> void:
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

# 播放技能特效
func _play_effect(target: ChessPiece) -> void:
	# 创建特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.2, 0.8, 0.5)  # 紫色
	effect.size = Vector2(80, 80)
	effect.position = Vector2(-40, -40)
	
	# 添加到目标
	target.add_child(effect)
	
	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(effect.queue_free)
