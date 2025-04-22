extends Ability
class_name BuffAbility
## 增益技能
## 为目标提供增益效果

# 增益类型
var buff_type: String = "attack"  # 增益类型(attack/defense/speed)
var buff_value: float = 0.0       # 增益值

# 初始化技能
func initialize(ability_data: Dictionary, owner_piece: ChessPieceEntity) -> void:
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

	# 创建属性效果数据
	var stats = {}

	# 根据增益类型设置效果
	match buff_type:
		"attack":
			stats["attack_damage"] = buff_value
		"defense":
			stats["armor"] = buff_value
		"speed":
			stats["attack_speed"] = buff_value
		"health":
			stats["health"] = buff_value

	# 使用游戏效果管理器创建特效
	if GameManager and GameManager.game_effect_manager:
		GameManager.game_effect_manager.create_stat_effect(owner, target, stats, duration, false, params)

	# 注意：我们已经使用GameEffectManager创建了效果，不需要再直接应用

	# 播放技能特效
	_play_ability_effect([target])
