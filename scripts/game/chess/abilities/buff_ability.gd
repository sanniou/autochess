extends Ability
class_name BuffAbility
## 增益技能
## 为目标提供增益效果

# 增益类型
var buff_type: String = "attack"  # 增益类型(attack/defense/speed)
var buff_value: float = 0.0       # 增益值

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPiece) -> void:
	super.initialize(ability_data, owner_piece)

	# 设置增益类型和值
	buff_type = ability_data.get("buff_type", "attack")
	buff_value = ability_data.get("buff_value", 0.0)

	# 设置目标类型
	target_type = ability_data.get("target_type", "ally")

# 执行技能效果
func _execute_effect(target = null) -> void:
	# 如果没有指定目标，查找目标
	if target == null:
		target = get_target()

	if target == null:
		return

	# 创建增益特效
	var params = {
		"buff_type": buff_type,
		"buff_value": buff_value,
		"duration": duration
	}
	# 使用特效管理器创建特效
	GameManager.effect_manager.create_effect(GameManager.effect_manager.EffectType.BUFF, target, params)

	# 直接应用增益效果
	# 创建效果数据
	var effect_data = {
		"id": id + "_buff",
		"duration": duration,
		"stats": {}
	}

	# 根据增益类型设置效果
	match buff_type:
		"attack":
			effect_data.stats["attack_damage"] = buff_value
		"defense":
			effect_data.stats["armor"] = buff_value
		"speed":
			effect_data.stats["attack_speed"] = buff_value
		"health":
			effect_data.stats["health"] = buff_value

	# 应用效果
	target.add_effect(effect_data)

	# 播放技能特效
	_play_ability_effect([target])
