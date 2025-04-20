extends Ability
class_name DamageAbility
## 伤害技能
## 对目标造成伤害

# 注意：使用基类中定义的 damage_type 属性

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPieceEntity) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置伤害类型
	damage_type = ability_data.get("damage_type", "magical")

# 执行技能效果
func _execute_effect(target = null) -> void:
	# 如果没有指定目标，查找目标
	if target == null:
		target = get_target()

	if target == null:
		return

	# 创建伤害特效
	var params = {
		"damage_type": damage_type,
		"damage_amount": damage
	}
	# 使用特效管理器创建特效
	GameManager.effect_manager.create_effect(GameManager.effect_manager.EffectType.DAMAGE, target, params)

	# 直接造成伤害
	target.take_damage(damage, damage_type, owner)

	# 播放技能特效
	_play_ability_effect([target])
