extends Ability
class_name DamageAbility
## 伤害技能
## 对目标造成伤害

# 伤害类型
var damage_type: String = "magical"  # 伤害类型(physical/magical)

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
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
	
	# 计算伤害
	var actual_damage = damage
	
	# 应用法术强度加成
	if damage_type == "magical":
		actual_damage += owner.spell_power
	
	# 造成伤害
	target.take_damage(actual_damage, damage_type, owner)
	
	# 播放技能特效
	_play_effect(target)
