extends Component
class_name TargetComponent
## 目标组件
## 管理棋子的目标选择和移动

# 信号
signal target_changed(old_target, new_target)
signal target_reached(target)
signal target_lost(target)

# 目标属性
var target = null  # 当前目标
var target_position: Vector2 = Vector2.ZERO  # 目标位置
var board_position: Vector2i = Vector2i(-1, -1)  # 棋盘位置

# 目标选择策略
enum TargetStrategy {
	NEAREST,        # 最近的敌人
	FURTHEST,       # 最远的敌人
	LOWEST_HEALTH,  # 生命值最低的敌人
	HIGHEST_HEALTH, # 生命值最高的敌人
	HIGHEST_DAMAGE, # 伤害最高的敌人
	RANDOM          # 随机敌人
}

var target_strategy: int = TargetStrategy.NEAREST  # 默认目标选择策略

# 初始化
func _init(p_owner = null, p_name: String = "TargetComponent"):
	super._init(p_owner, p_name)
	priority = 80  # 高优先级，确保目标在状态之后更新

# 更新组件
func _process_update(delta: float) -> void:
	# 检查目标是否有效
	if not _is_valid_target(target):
		clear_target()

# 设置目标
func set_target(new_target) -> void:
	# 如果目标相同，不做任何操作
	if new_target == target:
		return

	# 检查目标是否有效
	if not _is_valid_target(new_target):
		clear_target()
		return

	# 保存旧目标
	var old_target = target

	# 设置新目标
	target = new_target

	# 更新目标位置
	if target and target.has_method("get_global_position"):
		target_position = target.get_global_position()
	elif target and target is Node2D:
		target_position = target.global_position

	# 发送目标变化信号
	target_changed.emit(old_target, target)

	# 发送目标变化事件
	if GlobalEventBus:
		var event = ComponentEvents.TargetChangedEvent.new(owner, old_target, target)
		GlobalEventBus.get_group("component").dispatch_event(event)

# 清除目标
func clear_target() -> void:
	if target:
		var old_target = target
		target = null
		target_position = Vector2.ZERO

		# 发送目标变化信号
		target_changed.emit(old_target, null)

		# 发送目标丢失信号
		target_lost.emit(old_target)

		# 发送目标变化事件
		if GlobalEventBus:
			var event = ComponentEvents.TargetChangedEvent.new(owner, old_target, null)
			GlobalEventBus.get_group("component").dispatch_event(event)

# 获取目标
func get_target():
	return target

# 是否有目标
func has_target() -> bool:
	return target != null and _is_valid_target(target)

# 获取到目标的距离
func get_distance_to_target(target_obj = null) -> float:
	if target_obj == null:
		target_obj = target

	if not _is_valid_target(target_obj):
		return INF

	# 获取目标位置
	var target_pos = Vector2.ZERO
	if target_obj.has_method("get_global_position"):
		target_pos = target_obj.get_global_position()
	elif target_obj is Node2D:
		target_pos = target_obj.global_position

	# 获取自身位置
	var self_pos = Vector2.ZERO
	if owner.has_method("get_global_position"):
		self_pos = owner.get_global_position()
	elif owner is Node2D:
		self_pos = owner.global_position

	return self_pos.distance_to(target_pos)

# 移动到目标
func move_towards_target(target_obj = null, delta: float = 0.0) -> void:
	if target_obj == null:
		target_obj = target

	if not _is_valid_target(target_obj):
		return

	# 获取目标位置
	var target_pos = Vector2.ZERO
	if target_obj.has_method("get_global_position"):
		target_pos = target_obj.get_global_position()
	elif target_obj is Node2D:
		target_pos = target_obj.global_position

	# 获取自身位置
	var self_pos = Vector2.ZERO
	if owner.has_method("get_global_position"):
		self_pos = owner.get_global_position()
	elif owner is Node2D:
		self_pos = owner.global_position

	# 计算方向
	var direction = (target_pos - self_pos).normalized()

	# 获取移动速度
	var move_speed = 300.0  # 默认移动速度
	var attribute_component = owner.get_component("AttributeComponent")
	if attribute_component:
		move_speed = attribute_component.get_attribute("move_speed")

	# 移动
	if owner is Node2D:
		owner.global_position += direction * move_speed * delta

	# 检查是否到达目标
	var distance = self_pos.distance_to(target_pos)
	var attack_range = 1.0  # 默认攻击范围
	if attribute_component:
		attack_range = attribute_component.get_attribute("attack_range")

	if distance <= attack_range * 64:  # 假设一个格子是64像素
		# 发送目标到达信号
		target_reached.emit(target_obj)

# 自动选择目标
func auto_select_target() -> void:
	# 获取所有可能的目标
	var potential_targets = _get_potential_targets()

	# 如果没有可能的目标，清除目标
	if potential_targets.is_empty():
		clear_target()
		return

	# 根据策略选择目标
	var selected_target = null

	match target_strategy:
		TargetStrategy.NEAREST:
			selected_target = _select_nearest_target(potential_targets)
		TargetStrategy.FURTHEST:
			selected_target = _select_furthest_target(potential_targets)
		TargetStrategy.LOWEST_HEALTH:
			selected_target = _select_lowest_health_target(potential_targets)
		TargetStrategy.HIGHEST_HEALTH:
			selected_target = _select_highest_health_target(potential_targets)
		TargetStrategy.HIGHEST_DAMAGE:
			selected_target = _select_highest_damage_target(potential_targets)
		TargetStrategy.RANDOM:
			selected_target = _select_random_target(potential_targets)

	# 设置选择的目标
	set_target(selected_target)

# 设置目标选择策略
func set_target_strategy(strategy: int) -> void:
	target_strategy = strategy

# 设置棋盘位置
func set_board_position(position: Vector2i) -> void:
	board_position = position

# 获取棋盘位置
func get_board_position() -> Vector2i:
	return board_position

# 检查目标是否有效
func _is_valid_target(target_obj) -> bool:
	if target_obj == null:
		return false

	if not is_instance_valid(target_obj):
		return false

	# 检查目标是否隐身
	if "is_invisible" in target_obj and target_obj.is_invisible:
		return false

	# 检查目标是否死亡
	var state_component = null
	if target_obj.has_method("get_component"):
		state_component = target_obj.get_component("StateComponent")

	if state_component and state_component.is_in_state(state_component.ChessState.DEAD):
		return false

	# 检查目标是否是敌人
	var is_player_piece = false
	if owner.has_method("is_player_piece"):
		is_player_piece = owner.is_player_piece()
	elif owner.has("is_player_piece"):
		is_player_piece = owner.is_player_piece

	var target_is_player_piece = false
	if target_obj.has_method("is_player_piece"):
		target_is_player_piece = target_obj.is_player_piece()
	elif target_obj.has("is_player_piece"):
		target_is_player_piece = target_obj.is_player_piece

	return is_player_piece != target_is_player_piece

# 获取所有可能的目标
func _get_potential_targets() -> Array:
	var targets = []

	# 获取棋盘管理器
	var board_manager = GameManager.get_manager("BoardManager")
	if not board_manager:
		return targets

	# 获取敌方棋子
	var is_player_piece = false
	if owner.has_method("is_player_piece"):
		is_player_piece = owner.is_player_piece()
	elif owner.has("is_player_piece"):
		is_player_piece = owner.is_player_piece

	var enemy_pieces = board_manager.get_enemy_pieces(is_player_piece)

	# 过滤掉无效目标
	for piece in enemy_pieces:
		if _is_valid_target(piece):
			targets.append(piece)

	return targets

# 选择最近的目标
func _select_nearest_target(targets: Array):
	if targets.is_empty():
		return null

	var nearest_target = targets[0]
	var nearest_distance = get_distance_to_target(nearest_target)

	for target_obj in targets:
		var distance = get_distance_to_target(target_obj)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = target_obj

	return nearest_target

# 选择最远的目标
func _select_furthest_target(targets: Array):
	if targets.is_empty():
		return null

	var furthest_target = targets[0]
	var furthest_distance = get_distance_to_target(furthest_target)

	for target_obj in targets:
		var distance = get_distance_to_target(target_obj)
		if distance > furthest_distance:
			furthest_distance = distance
			furthest_target = target_obj

	return furthest_target

# 选择生命值最低的目标
func _select_lowest_health_target(targets: Array):
	if targets.is_empty():
		return null

	var lowest_health_target = targets[0]
	var lowest_health = INF

	for target_obj in targets:
		var health = INF

		# 获取目标生命值
		var attribute_component = null
		if target_obj.has_method("get_component"):
			attribute_component = target_obj.get_component("AttributeComponent")

		if attribute_component:
			health = attribute_component.get_attribute("current_health")
		elif target_obj.has("current_health"):
			health = target_obj.current_health

		if health < lowest_health:
			lowest_health = health
			lowest_health_target = target_obj

	return lowest_health_target

# 选择生命值最高的目标
func _select_highest_health_target(targets: Array):
	if targets.is_empty():
		return null

	var highest_health_target = targets[0]
	var highest_health = 0

	for target_obj in targets:
		var health = 0

		# 获取目标生命值
		var attribute_component = null
		if target_obj.has_method("get_component"):
			attribute_component = target_obj.get_component("AttributeComponent")

		if attribute_component:
			health = attribute_component.get_attribute("current_health")
		elif target_obj.has("current_health"):
			health = target_obj.current_health

		if health > highest_health:
			highest_health = health
			highest_health_target = target_obj

	return highest_health_target

# 选择伤害最高的目标
func _select_highest_damage_target(targets: Array):
	if targets.is_empty():
		return null

	var highest_damage_target = targets[0]
	var highest_damage = 0

	for target_obj in targets:
		var damage = 0

		# 获取目标伤害
		var attribute_component = null
		if target_obj.has_method("get_component"):
			attribute_component = target_obj.get_component("AttributeComponent")

		if attribute_component:
			damage = attribute_component.get_attribute("attack_damage")
		elif target_obj.has("attack_damage"):
			damage = target_obj.attack_damage

		if damage > highest_damage:
			highest_damage = damage
			highest_damage_target = target_obj

	return highest_damage_target

# 选择随机目标
func _select_random_target(targets: Array):
	if targets.is_empty():
		return null

	return targets[randi() % targets.size()]
