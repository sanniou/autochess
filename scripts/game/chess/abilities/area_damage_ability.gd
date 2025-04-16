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
	var board_manager = owner.get_node("/root/GameManager").board_manager
	if not board_manager:
		return

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

		# 创建伤害效果
		var damage_effect = DamageEffect.new(
			AbilityEffect.EffectType.DAMAGE,
			actual_damage,
			0.0,
			0.0,
			owner,
			enemy
		)

		# 设置伤害类型
		damage_effect.damage_type = damage_type

		# 应用效果
		damage_effect.apply()

	# 播放技能特效
	_play_ability_effect(enemies)

	# 播放区域特效
	_play_area_visual_effect(center_pos, radius)

# 播放区域特效
func _play_area_visual_effect(center_pos: Vector2i, radius: float) -> void:
	# 获取棋盘管理器
	var board_manager = owner.get_node("/root/GameManager").board_manager
	if not board_manager:
		return

	# 创建区域特效
	var effect = ColorRect.new()
	effect.color = Color(0.8, 0.2, 0.8, 0.3)  # 半透明紫色

	# 计算特效大小（根据半径和格子大小）
	var effect_size = radius * 2 * board_manager.cell_size.x
	effect.size = Vector2(effect_size, effect_size)

	# 计算特效位置
	var effect_pos = Vector2(
		center_pos.x * board_manager.cell_size.x + board_manager.cell_size.x / 2,
		center_pos.y * board_manager.cell_size.y + board_manager.cell_size.y / 2
	)
	effect.position = effect_pos - Vector2(effect_size / 2, effect_size / 2)

	# 添加到棋盘
	board_manager.add_child(effect)

	# 创建消失动画
	var tween = create_tween()
	tween.tween_property(effect, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.tween_callback(effect.queue_free)


