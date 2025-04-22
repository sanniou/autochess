extends Ability
class_name HealAbility
## 治疗技能
## 治疗目标

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPieceEntity) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置目标类型
	target_type = ability_data.get("target_type", "ally")

# 执行技能效果
func _execute_effect(target = null) -> void:
	# 如果没有指定目标，查找目标
	if target == null:
		target = get_target()

	if target == null:
		return

	# 创建治疗特效
	var params = {
		"heal_amount": damage  # 使用damage字段作为基础治疗量
	}
	# 使用游戏效果管理器创建特效
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.create_heal_effect(owner, target, damage, params)

	# 直接治疗目标
	target.heal(damage)

	# 播放技能特效
	_play_ability_effect([target])
