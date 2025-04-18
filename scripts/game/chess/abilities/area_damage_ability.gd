extends Ability
class_name AreaDamageAbility
## 区域伤害技能
## 对范围内的敌人造成伤害

# 伤害类型
var damage_type: String = "magical"  # 伤害类型(physical/magical/true)
var radius: float = 2.0  # 伤害半径（格子数）

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置伤害类型和半径
	damage_type = ability_data.get("damage_type", "magical")
	radius = ability_data.get("radius", 2.0)

	# 设置目标类型为区域
	target_type = "area"

# 执行技能效果
func _execute_effect(target = null) -> void:
	# 获取棋盘管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.board_manager:
		return

	var board_manager = game_manager.board_manager

	# 获取中心位置（如果有目标使用目标位置，否则使用自身位置）
	var center_pos = owner.board_position
	if target and target is ChessPiece:
		center_pos = target.board_position

	# 使用目标选择器获取范围内的所有敌人
	var selector = TargetSelector.new(
		owner,
		TargetSelector.SelectionStrategy.NEAREST,
		TargetSelector.TargetType.ENEMY,
		radius,
		0.0,
		100  # 足够大的数量来获取所有目标
	)

	var enemies = selector.select_targets()

	# 对范围内的所有敌人造成伤害
	for enemy in enemies:
		# 计算伤害（距离越远伤害越低）
		var distance = center_pos.distance_to(enemy.board_position)
		var damage_multiplier = 1.0 - (distance / radius) * 0.5  # 最远处伤害为50%
		var actual_damage = damage * damage_multiplier

		# 获取特效管理器
		var game_manager = Engine.get_singleton("GameManager")
		if game_manager and game_manager.effect_manager:
			# 创建伤害特效参数
			var params = {
				"color": game_manager.effect_manager.get_effect_color(damage_type),
				"duration": 0.5,
				"damage_type": damage_type,
				"damage_amount": actual_damage
			}

			# 使用特效管理器创建特效
			game_manager.effect_manager.create_visual_effect(
				game_manager.effect_manager.VisualEffectType.DAMAGE,
				enemy,
				params
			)

		# 直接造成伤害
		enemy.take_damage(actual_damage, damage_type, owner)

	# 播放技能特效
	_play_ability_effect(enemies)

	# 播放区域特效
	_play_area_visual_effect(center_pos, radius)

# 播放区域特效
func _play_area_visual_effect(center_pos: Vector2i, radius: float) -> void:
	# 获取棋盘管理器和特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.board_manager or not game_manager.effect_manager:
		return

	var board_manager = game_manager.board_manager

	# 计算特效位置
	var effect_pos = Vector2(
		center_pos.x * board_manager.cell_size.x + board_manager.cell_size.x / 2,
		center_pos.y * board_manager.cell_size.y + board_manager.cell_size.y / 2
	)

	# 创建一个临时节点来放置特效
	var effect_node = Node2D.new()
	effect_node.position = effect_pos
	board_manager.add_child(effect_node)

	# 创建区域伤害特效参数
	var params = {
		"color": game_manager.effect_manager.get_effect_color(damage_type),
		"duration": 2.0,
		"damage_type": damage_type,
		"radius": radius * board_manager.cell_size.x  # 转换为像素单位
	}

	# 使用特效管理器创建特效
	game_manager.effect_manager.create_visual_effect(
		game_manager.effect_manager.VisualEffectType.AREA_DAMAGE,
		effect_node,
		params
	)

	# 设置定时器删除节点
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	owner.add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

	if is_instance_valid(effect_node) and not effect_node.is_queued_for_deletion():
		effect_node.queue_free()

# 播放技能特效
func _play_ability_effect(targets: Array) -> void:
	# 获取特效管理器
	var game_manager = Engine.get_singleton("GameManager")
	if not game_manager or not game_manager.effect_manager:
		return

	# 播放技能音效
	_play_ability_sound()

	# 播放技能视觉效果
	for target in targets:
		# 创建视觉特效参数
		var params = {
			"color": game_manager.effect_manager.get_effect_color(damage_type),
			"duration": 0.5,
			"damage_type": damage_type,
			"damage_amount": damage
		}

		# 使用特效管理器创建特效
		game_manager.effect_manager.create_visual_effect(
			game_manager.effect_manager.VisualEffectType.DAMAGE,
			target,
			params
		)

	# 播放技能施法者效果
	_play_caster_effect()
