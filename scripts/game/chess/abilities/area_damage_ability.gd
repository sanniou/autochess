extends Ability
class_name AreaDamageAbility
## 区域伤害技能
## 对范围内的敌人造成伤害

# 注意：使用基类中定义的 damage_type 属性
var radius: float = 2.0  # 伤害半径（格子数）

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPieceEntity) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置伤害类型和半径
	damage_type = ability_data.get("damage_type", "magical")
	radius = ability_data.get("radius", 2.0)

	# 设置目标类型为区域
	target_type = "area"

# 执行技能效果
func _execute_effect(target = null) -> void:

	var board_manager = GameManager.board_manager

	# 获取中心位置（如果有目标使用目标位置，否则使用自身位置）
	var center_pos = owner.board_position
	if target and target is ChessPieceEntity:
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

		# 创建伤害特效参数
		var params = {
			"duration": 0.5,
			"damage_type": damage_type,
			"damage_amount": actual_damage
		}

		# 设置颜色
		if GameManager and GameManager.game_effect_manager:
			params["color"] = GameManager.game_effect_manager.get_effect_color(damage_type)
		else:
			params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值

		# 使用游戏效果管理器创建特效
		if GameManager and GameManager.game_effect_manager:
			GameManager.game_effect_manager.create_damage_effect(
				owner,
				enemy,
				actual_damage,
				damage_type,
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

	var board_manager = GameManager.board_manager

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
	var params = {}

	# 设置颜色
	if GameManager and GameManager.game_effect_manager:
		params["color"] = GameManager.game_effect_manager.get_effect_color(damage_type)
	elif GameManager and GameManager.visual_manager:
		params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值
	else:
		params["color"] = Color(0.2, 0.2, 0.8, 0.8) # 蓝色默认值

	# 设置其他参数
	params["duration"] = 2.0
	params["damage_type"] = damage_type
	params["radius"] = radius * board_manager.cell_size.x  # 转换为像素单位

	# 使用特效管理器创建特效
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.create_visual_effect(
			GameManager.game_effect_manager.VisualEffectType.AREA_DAMAGE,
			effect_node,
			params
		)
	# 如果没有效果管理器，使用视觉管理器
	elif GameManager and GameManager.visual_manager:
		GameManager.visual_manager.create_combined_effect(
			effect_node.global_position,
			"area_damage_" + damage_type,
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
