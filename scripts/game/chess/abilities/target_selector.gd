extends Resource
class_name TargetSelector
## 目标选择器
## 提供多种目标选择策略

# 选择策略
enum SelectionStrategy {
	NEAREST,           # 最近的目标
	FURTHEST,          # 最远的目标
	LOWEST_HEALTH,     # 生命值最低的目标
	HIGHEST_HEALTH,    # 生命值最高的目标
	LOWEST_ARMOR,      # 护甲最低的目标
	HIGHEST_ARMOR,     # 护甲最高的目标
	LOWEST_MAGIC_RESIST, # 魔法抗性最低的目标
	HIGHEST_MAGIC_RESIST, # 魔法抗性最高的目标
	HIGHEST_DAMAGE,    # 攻击力最高的目标
	RANDOM,            # 随机目标
	CLUSTERED          # 聚集的目标（周围有多个目标）
}

# 目标类型
enum TargetType {
	ENEMY,             # 敌人
	ALLY,              # 友方
	SELF,              # 自身
	ALL                # 所有单位
}

# 选择器属性
var strategy: int = SelectionStrategy.NEAREST  # 选择策略
var target_type: int = TargetType.ENEMY        # 目标类型
var max_range: float = 10.0                    # 最大范围
var min_range: float = 0.0                     # 最小范围
var max_targets: int = 1                       # 最大目标数量
var ignore_invisible: bool = true              # 是否忽略隐形单位
var ignore_invulnerable: bool = true           # 是否忽略无敌单位
var owner: ChessPieceEntity = null                   # 所有者

# 初始化
func _init(p_owner: ChessPieceEntity = null, p_strategy: int = SelectionStrategy.NEAREST,
		p_target_type: int = TargetType.ENEMY, p_max_range: float = 10.0,
		p_min_range: float = 0.0, p_max_targets: int = 1) -> void:
	owner = p_owner
	strategy = p_strategy
	target_type = p_target_type
	max_range = p_max_range
	min_range = p_min_range
	max_targets = p_max_targets

# 选择目标
func select_targets() -> Array:
	if not owner:
		return []

	# 获取棋盘管理器
	var board_manager = GameManager.board_manager
	if not board_manager:
		return []

	# 获取所有棋子
	var all_pieces = board_manager.pieces

	# 筛选符合条件的目标
	var valid_targets = []
	for piece in all_pieces:
		# 检查目标类型
		if not _is_valid_target_type(piece):
			continue

		# 检查目标状态
		if not _is_valid_target_state(piece):
			continue

		# 检查距离
		var distance = owner.board_position.distance_to(piece.board_position)
		if distance < min_range or distance > max_range:
			continue

		# 添加到有效目标列表
		valid_targets.append(piece)

	# 如果没有有效目标，返回空数组
	if valid_targets.size() == 0:
		return []

	# 根据策略排序目标
	_sort_targets(valid_targets)

	# 返回指定数量的目标
	return valid_targets.slice(0, min(max_targets, valid_targets.size()))

# 检查目标类型是否有效
func _is_valid_target_type(piece: ChessPieceEntity) -> bool:
	match target_type:
		TargetType.ENEMY:
			return piece.is_player_piece != owner.is_player_piece
		TargetType.ALLY:
			return piece.is_player_piece == owner.is_player_piece and piece != owner
		TargetType.SELF:
			return piece == owner
		TargetType.ALL:
			return true
	return false

# 检查目标状态是否有效
func _is_valid_target_state(piece: ChessPieceEntity) -> bool:
	# 检查是否死亡
	if piece.current_state == StateMachineComponent.ChessState.DEAD:
		return false

	# 检查是否隐形
	if ignore_invisible and piece.is_invisible:
		return false

	# 检查是否无敌
	if ignore_invulnerable and piece.is_invulnerable:
		return false

	return true

# 根据策略排序目标
func _sort_targets(targets: Array) -> void:
	match strategy:
		SelectionStrategy.NEAREST:
			targets.sort_custom(func(a, b):
				return owner.board_position.distance_to(a.board_position) < owner.board_position.distance_to(b.board_position))

		SelectionStrategy.FURTHEST:
			targets.sort_custom(func(a, b):
				return owner.board_position.distance_to(a.board_position) > owner.board_position.distance_to(b.board_position))

		SelectionStrategy.LOWEST_HEALTH:
			targets.sort_custom(func(a, b):
				return a.current_health < b.current_health)

		SelectionStrategy.HIGHEST_HEALTH:
			targets.sort_custom(func(a, b):
				return a.current_health > b.current_health)

		SelectionStrategy.LOWEST_ARMOR:
			targets.sort_custom(func(a, b):
				return a.armor < b.armor)

		SelectionStrategy.HIGHEST_ARMOR:
			targets.sort_custom(func(a, b):
				return a.armor > b.armor)

		SelectionStrategy.LOWEST_MAGIC_RESIST:
			targets.sort_custom(func(a, b):
				return a.magic_resist < b.magic_resist)

		SelectionStrategy.HIGHEST_MAGIC_RESIST:
			targets.sort_custom(func(a, b):
				return a.magic_resist > b.magic_resist)

		SelectionStrategy.HIGHEST_DAMAGE:
			targets.sort_custom(func(a, b):
				return a.attack_damage > b.attack_damage)

		SelectionStrategy.RANDOM:
			targets.shuffle()

		SelectionStrategy.CLUSTERED:
			targets.sort_custom(func(a, b):
				return _count_nearby_pieces(a) > _count_nearby_pieces(b))

# 计算周围的棋子数量
func _count_nearby_pieces(piece: ChessPieceEntity, radius: float = 2.0) -> int:
	var count = 0
	var board_manager = GameManager.board_manager
	if not board_manager:
		return 0

	for other in board_manager.pieces:
		if other != piece and other.current_state != StateMachineComponent.ChessState.DEAD:
			var distance = piece.board_position.distance_to(other.board_position)
			if distance <= radius:
				count += 1

	return count

# 从字符串创建目标类型
static func target_type_from_string(type_str: String) -> int:
	match type_str.to_lower():
		"enemy":
			return TargetType.ENEMY
		"ally":
			return TargetType.ALLY
		"self":
			return TargetType.SELF
		"all":
			return TargetType.ALL
		_:
			return TargetType.ENEMY

# 从字符串创建选择策略
static func strategy_from_string(strategy_str: String) -> int:
	match strategy_str.to_lower():
		"nearest":
			return SelectionStrategy.NEAREST
		"furthest":
			return SelectionStrategy.FURTHEST
		"lowest_health":
			return SelectionStrategy.LOWEST_HEALTH
		"highest_health":
			return SelectionStrategy.HIGHEST_HEALTH
		"lowest_armor":
			return SelectionStrategy.LOWEST_ARMOR
		"highest_armor":
			return SelectionStrategy.HIGHEST_ARMOR
		"lowest_magic_resist":
			return SelectionStrategy.LOWEST_MAGIC_RESIST
		"highest_magic_resist":
			return SelectionStrategy.HIGHEST_MAGIC_RESIST
		"highest_damage":
			return SelectionStrategy.HIGHEST_DAMAGE
		"random":
			return SelectionStrategy.RANDOM
		"clustered":
			return SelectionStrategy.CLUSTERED
		_:
			return SelectionStrategy.NEAREST
