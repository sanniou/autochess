extends BaseEffect
class_name MovementEffect
## 移动效果类
## 移动目标位置

# 移动类型
enum MovementType {
	KNOCKBACK,  # 击退
	PULL,       # 拉近
	TELEPORT,   # 传送
	SWAP        # 交换位置
}

# 移动属性
var movement_type: int = MovementType.KNOCKBACK  # 移动类型
var distance: float = 1.0                        # 移动距离（格子数）

# 初始化
func _init(p_id: String = "", p_name: String = "", p_description: String = "",
		p_movement_type: int = MovementType.KNOCKBACK, p_distance: float = 1.0,
		p_source = null, p_target = null) -> void:
	super._init(p_id, BaseEffect.EffectType.MOVEMENT, p_name, p_description,
			0.0, p_distance, p_source, p_target, false)  # 移动效果默认为非减益
	movement_type = p_movement_type
	distance = p_distance

# 应用效果
func apply() -> void:
	if not target or not is_instance_valid(target) or target.current_state == target.ChessState.DEAD:
		return

	# 获取棋盘管理器
	var board_manager = target.get_node_or_null("/root/GameManager/BoardManager")
	if not board_manager:
		return

	# 记录原始位置
	var original_position = target.board_position

	# 根据移动类型应用效果
	match movement_type:
		MovementType.KNOCKBACK:
			# 击退效果
			_apply_knockback(board_manager)
		MovementType.PULL:
			# 拉近效果
			_apply_pull(board_manager)
		MovementType.TELEPORT:
			# 传送效果
			_apply_teleport(board_manager)
		MovementType.SWAP:
			# 交换位置效果
			_apply_swap(board_manager)

	# 发送效果应用信号
	var movement_type_str = ""
	match movement_type:
		MovementType.KNOCKBACK:
			movement_type_str = "knockback"
		MovementType.PULL:
			movement_type_str = "pull"
		MovementType.TELEPORT:
			movement_type_str = "teleport"
		MovementType.SWAP:
			movement_type_str = "swap"

	EventBus.battle.emit_event("ability_effect_applied", [source, target, "movement", movement_type_str])

	# 如果位置发生变化，发送棋子移动信号
	if target.board_position != original_position:
		EventBus.chess.emit_event("chess_piece_moved", [target, original_position, target.board_position])

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

	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 选择特效类型和颜色
	var effect_type = game_manager.effect_manager.VisualEffectType.BUFF
	var movement_name = ""

	match movement_type:
		MovementType.KNOCKBACK:
			movement_name = "knockback"
		MovementType.PULL:
			movement_name = "pull"
		MovementType.TELEPORT:
			effect_type = game_manager.effect_manager.VisualEffectType.TELEPORT_DISAPPEAR
			movement_name = "teleport"
		MovementType.SWAP:
			movement_name = "swap"
		_:
			movement_name = "movement"

	# 创建视觉特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color(movement_name),
		"duration": 0.5,
		"buff_type": movement_name
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		effect_type,
		target,
		params
	)

# 获取效果数据
func get_data() -> Dictionary:
	var data = super.get_data()
	data["movement_type"] = movement_type
	data["distance"] = distance
	return data

# 从数据创建效果
static func create_from_data(data: Dictionary, source = null, target = null) -> MovementEffect:
	return MovementEffect.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("movement_type", MovementType.KNOCKBACK),
		data.get("distance", 1.0),
		source,
		target
	)
