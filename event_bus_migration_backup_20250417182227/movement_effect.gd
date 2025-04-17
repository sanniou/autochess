extends AbilityEffect
class_name MovementEffect
## 移动效果
## 移动目标位置

# 移动类型
var movement_type: String = "knockback"  # 移动类型(knockback/pull/teleport/swap)
var distance: float = 1.0                # 移动距离（格子数）

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == ChessPiece.ChessState.DEAD:
		return

	# 获取棋盘管理器
	var board_manager = target.get_node("/root/GameManager/BoardManager")
	if not board_manager:
		return

	# 记录原始位置
	var original_position = target.board_position

	# 根据移动类型应用效果
	match movement_type:
		"knockback":
			# 击退效果
			_apply_knockback(board_manager)
		"pull":
			# 拉近效果
			_apply_pull(board_manager)
		"teleport":
			# 传送效果
			_apply_teleport(board_manager)
		"swap":
			# 交换位置效果
			_apply_swap(board_manager)

	# 发送效果应用信号
	EventBus.battle.ability_effect_applied.emit(source, target, "movement", movement_type)

	# 如果位置发生变化，发送棋子移动信号
	if target.board_position != original_position:
		EventBus.chess.chess_piece_moved.emit(target, original_position, target.board_position)

	# 播放移动特效
	_play_movement_effect()

# 应用击退效果
func _apply_knockback(board_manager) -> void:
	if not source or not is_instance_valid(source):
		return

	# 计算方向
	var direction = target.board_position - source.board_position
	if direction.length() == 0:
		return

	# 标准化方向
	direction = direction.normalized()

	# 计算目标位置
	var target_pos = target.board_position + Vector2i(round(direction.x * distance), round(direction.y * distance))

	# 检查目标位置是否有效
	if not board_manager.is_valid_position(target_pos):
		return

	# 检查目标位置是否已被占用
	if board_manager.is_position_occupied(target_pos):
		return

	# 移动目标
	board_manager.move_piece(target, target_pos)

# 应用拉近效果
func _apply_pull(board_manager) -> void:
	if not source or not is_instance_valid(source):
		return

	# 计算方向
	var direction = source.board_position - target.board_position
	if direction.length() == 0:
		return

	# 标准化方向
	direction = direction.normalized()

	# 计算目标位置
	var target_pos = target.board_position + Vector2i(round(direction.x * distance), round(direction.y * distance))

	# 检查目标位置是否有效
	if not board_manager.is_valid_position(target_pos):
		return

	# 检查目标位置是否已被占用
	if board_manager.is_position_occupied(target_pos):
		return

	# 移动目标
	board_manager.move_piece(target, target_pos)

# 应用传送效果
func _apply_teleport(board_manager) -> void:
	# 获取随机空位置
	var empty_positions = board_manager.get_empty_positions()
	if empty_positions.size() == 0:
		return

	# 随机选择一个位置
	var random_index = randi() % empty_positions.size()
	var target_pos = empty_positions[random_index]

	# 移动目标
	board_manager.move_piece(target, target_pos)

# 应用交换位置效果
func _apply_swap(board_manager) -> void:
	if not source or not is_instance_valid(source):
		return

	# 获取源和目标的位置
	var source_pos = source.board_position
	var target_pos = target.board_position

	# 交换位置
	board_manager.move_piece(source, target_pos)
	board_manager.move_piece(target, source_pos)

# 播放移动特效
func _play_movement_effect() -> void:
	if not target or not is_instance_valid(target):
		return

	# 创建特效
	var effect = ColorRect.new()

	# 根据移动类型设置颜色
	match movement_type:
		"knockback":
			effect.color = Color(0.8, 0.4, 0.0, 0.5)  # 橙色
		"pull":
			effect.color = Color(0.0, 0.4, 0.8, 0.5)  # 蓝色
		"teleport":
			effect.color = Color(0.8, 0.0, 0.8, 0.5)  # 紫色
		"swap":
			effect.color = Color(0.0, 0.8, 0.8, 0.5)  # 青色
		_:
			effect.color = Color(0.8, 0.4, 0.0, 0.5)  # 默认橙色

	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)

	# 添加到目标
	target.add_child(effect)

	# 创建消失动画
	var tween = target.create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(effect.queue_free)
